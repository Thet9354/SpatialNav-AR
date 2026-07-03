//
//  NavigationViewModel.swift
//  SpatialNav
//

import Foundation
import Observation
import os

@MainActor
@Observable
final class NavigationViewModel {
    enum Phase: Equatable {
        case idle
        case unsupportedDevice
        case permissionDenied
        case running
        case interrupted
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var trackingQuality: TrackingQuality = .notAvailable
    private(set) var worldMappingStatus: WorldMappingStatus = .notAvailable
    private(set) var meshAnchorCount = 0
    private(set) var nearestObstacle: Obstacle?
    private(set) var activeHazards: [Hazard] = []
    private(set) var detectedObjects: [DetectedObject] = []
    private(set) var latestAlert: FeedbackEvent?
    private(set) var processingTier: ProcessingTier = .full
    private(set) var guidedItem: SavedItem?
    private(set) var itemGuidance: ItemGuidance?

    var lidarAvailable: Bool {
        provider.capabilities.supportsSceneReconstruction
    }

    var objectDetectionAvailable: Bool {
        objectDetection != nil
    }

    private let provider: any ARSessionProviding
    private let meshStore: any MeshStoring
    private let cameraAuthorizer: any CameraAuthorizing
    private let sonar: SonarSweepUseCase
    private let objectDetection: ObjectDetectionUseCase?
    private let governor: any PerformanceGoverning
    private let audio: any SpatialAudioServicing
    private let speech: any SpeechServicing
    private let audioMap = SonarAudioMap()
    private var streamTasks: [Task<Void, Never>] = []
    private var hazardDebouncer = HazardDebouncer()
    private var alertPolicy = HazardAlertPolicy()
    private var lastMeshCountRefresh: TimeInterval = 0
    private var lastSonarLog: TimeInterval = 0
    private var lastObstaclePing: TimeInterval = 0
    private var lastItemPing: TimeInterval = 0
    private let logger = Logger(subsystem: "com.thetpine.spatialnav", category: "sonar")

    init(
        provider: any ARSessionProviding,
        meshStore: any MeshStoring,
        cameraAuthorizer: any CameraAuthorizing,
        sonar: SonarSweepUseCase,
        objectDetection: ObjectDetectionUseCase?,
        governor: any PerformanceGoverning,
        audio: any SpatialAudioServicing,
        speech: any SpeechServicing
    ) {
        self.provider = provider
        self.meshStore = meshStore
        self.cameraAuthorizer = cameraAuthorizer
        self.sonar = sonar
        self.objectDetection = objectDetection
        self.governor = governor
        self.audio = audio
        self.speech = speech
    }

    func guide(to item: SavedItem) {
        guidedItem = item
    }

    func stopGuiding() {
        guidedItem = nil
        itemGuidance = nil
    }

    func start() async {
        guard phase != .running else { return }
        guard provider.capabilities.supportsWorldTracking else {
            phase = .unsupportedDevice
            return
        }
        switch cameraAuthorizer.status {
        case .authorized:
            break
        case .notDetermined:
            guard await cameraAuthorizer.requestAccess() else {
                phase = .permissionDenied
                return
            }
        case .denied, .restricted:
            phase = .permissionDenied
            return
        }
        do {
            try provider.start()
        } catch {
            phase = .failed(error.localizedDescription)
            return
        }
        phase = .running
        observeStreams()
        if let objectDetection {
            await objectDetection.start()
        }
        await governor.start()
        do {
            try await audio.startEngine()
        } catch {
            logger.error("Spatial audio unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() {
        streamTasks.forEach { $0.cancel() }
        streamTasks.removeAll()
        hazardDebouncer.reset()
        alertPolicy.reset()
        if let objectDetection {
            Task { await objectDetection.stop() }
        }
        let governor = governor
        let audio = audio
        let speech = speech
        Task {
            await governor.stop()
            await audio.stopEngine()
            await speech.stopSpeaking()
        }
        provider.stop()
        if phase == .running || phase == .interrupted {
            phase = .idle
        }
    }

    private func observeStreams() {
        streamTasks.forEach { $0.cancel() }
        let frameTask = Task { [weak self] in
            guard let frames = self?.provider.frames() else { return }
            for await snapshot in frames {
                guard let self, !Task.isCancelled else { return }
                await self.handle(snapshot)
            }
        }
        let eventTask = Task { [weak self] in
            guard let events = self?.provider.events() else { return }
            for await event in events {
                guard let self, !Task.isCancelled else { return }
                self.handle(event)
            }
        }
        streamTasks = [frameTask, eventTask]

        if let objectDetection {
            let detectionTask = Task { [weak self] in
                let results = await objectDetection.results()
                for await objects in results {
                    guard let self, !Task.isCancelled else { return }
                    self.detectedObjects = objects.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
                }
            }
            streamTasks.append(detectionTask)
        }

        let tierTask = Task { [weak self] in
            guard let governor = self?.governor else { return }
            let tiers = await governor.tiers()
            for await tier in tiers {
                guard let self, !Task.isCancelled else { return }
                self.apply(tier)
            }
        }
        streamTasks.append(tierTask)
    }

    private func apply(_ tier: ProcessingTier) {
        guard tier != processingTier else { return }
        let downgraded = tier < processingTier
        processingTier = tier
        provider.setMLSampleRate(framesPerSecond: tier.mlFramesPerSecond)
        logger.notice("Processing tier changed to \(String(describing: tier), privacy: .public)")
        if downgraded {
            // Degradation is announced, never silent.
            let event = FeedbackEvent(
                kind: .status,
                priority: .low,
                direction: nil,
                distance: nil,
                message: "Reducing detail to keep the phone cool and save battery."
            )
            latestAlert = event
            let speech = speech
            Task {
                await speech.announce(event.message ?? "", priority: event.priority)
            }
        }
    }

    private func handle(_ snapshot: ARFrameSnapshot) async {
        if snapshot.trackingQuality != trackingQuality {
            trackingQuality = snapshot.trackingQuality
        }
        if snapshot.worldMappingStatus != worldMappingStatus {
            worldMappingStatus = snapshot.worldMappingStatus
        }
        // Mesh count is a coverage indicator for the HUD; 1 Hz is plenty.
        if snapshot.timestamp - lastMeshCountRefresh >= 1.0 {
            lastMeshCountRefresh = snapshot.timestamp
            meshAnchorCount = await meshStore.count()
        }

        // Sweeping inline applies natural backpressure: while a sweep is in
        // flight the stream (bufferingNewest 1) drops frames instead of queuing.
        await audio.updateListener(transform: snapshot.cameraTransform)

        let result = await sonar.sweep(frame: snapshot, rayCount: processingTier.sonarRayCount)
        nearestObstacle = result.obstacles.min { $0.distance < $1.distance }
        activeHazards = hazardDebouncer.ingest(result.hazards)

        if let alert = alertPolicy.events(
            hazards: activeHazards,
            nearestObstacle: nearestObstacle,
            at: snapshot.timestamp
        ).first {
            latestAlert = alert
            logger.info("Alert: \(alert.message ?? "—", privacy: .public)")
            if let message = alert.message {
                await speech.announce(message, priority: alert.priority)
            }
        }

        // Sonar Mode: the nearest obstacle pings from its true direction,
        // faster and higher-pitched as it gets closer.
        if let nearest = nearestObstacle,
           snapshot.timestamp - lastObstaclePing >= audioMap.pulseInterval(forDistance: nearest.distance) {
            lastObstaclePing = snapshot.timestamp
            await audio.play(
                FeedbackEvent(
                    kind: .obstacleProximity,
                    priority: .normal,
                    direction: nearest.direction,
                    distance: nearest.distance,
                    message: nil
                ),
                at: nearest.worldPosition
            )
        }

        if let target = guidedItem?.lastKnownPosition {
            let guidance = ItemGuidance.toward(target, from: snapshot.cameraTransform)
            itemGuidance = guidance
            // Item beacon: a distinct ping from the item's location.
            if snapshot.timestamp - lastItemPing >= audioMap.pulseInterval(forDistance: guidance.distance) {
                lastItemPing = snapshot.timestamp
                await audio.play(
                    FeedbackEvent(
                        kind: .itemPing,
                        priority: .normal,
                        direction: guidance.direction,
                        distance: guidance.distance,
                        message: nil
                    ),
                    at: target
                )
            }
        }

        logSonar(at: snapshot.timestamp)
    }

    private func logSonar(at timestamp: TimeInterval) {
        guard timestamp - lastSonarLog >= 1.0 else { return }
        lastSonarLog = timestamp
        if let nearestObstacle {
            logger.debug("Nearest obstacle \(nearestObstacle.distance, format: .fixed(precision: 1)) m at \(nearestObstacle.direction.spokenDescription, privacy: .public)")
        } else {
            logger.debug("Path clear")
        }
        for hazard in activeHazards {
            logger.warning("\(hazard.kind.warningDescription, privacy: .public) — \(hazard.distance, format: .fixed(precision: 1)) m")
        }
        if let nearest = detectedObjects.first, let distance = nearest.distance {
            logger.debug("Object: \(nearest.label, privacy: .public) \(distance, format: .fixed(precision: 1)) m (\(self.detectedObjects.count) tracked)")
        }
    }

    private func handle(_ event: ARSessionEvent) {
        switch event {
        case .interrupted:
            phase = .interrupted
        case .interruptionEnded:
            phase = .running
        case .failed(let message):
            phase = .failed(message)
        }
    }
}
