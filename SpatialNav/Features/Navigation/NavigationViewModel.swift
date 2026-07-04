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
    private(set) var isPaused = false
    private var announcedReady = false

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
    private let haptics: any HapticServicing
    private let settings: any SettingsStoring
    private let audioMap = SonarAudioMap()
    private let router = FeedbackRouter()
    private(set) var profile: FeedbackProfile = .default
    private var streamTasks: [Task<Void, Never>] = []
    private var hazardDebouncer = HazardDebouncer()
    private var alertPolicy = HazardAlertPolicy()
    private var relocalizationWatchdog = RelocalizationWatchdog()
    private var lastMeshCountRefresh: TimeInterval = 0
    private var lastSonarLog: TimeInterval = 0
    private var lastObstaclePing: TimeInterval = 0
    private var lastItemPing: TimeInterval = 0
    private let logger = Logger(subsystem: "com.thetpine.spatialnav", category: "sonar")
    private let signposter = OSSignposter(subsystem: "com.thetpine.spatialnav", category: "latency")

    init(
        provider: any ARSessionProviding,
        meshStore: any MeshStoring,
        cameraAuthorizer: any CameraAuthorizing,
        sonar: SonarSweepUseCase,
        objectDetection: ObjectDetectionUseCase?,
        governor: any PerformanceGoverning,
        audio: any SpatialAudioServicing,
        speech: any SpeechServicing,
        haptics: any HapticServicing,
        settings: any SettingsStoring
    ) {
        self.provider = provider
        self.meshStore = meshStore
        self.cameraAuthorizer = cameraAuthorizer
        self.sonar = sonar
        self.objectDetection = objectDetection
        self.governor = governor
        self.audio = audio
        self.speech = speech
        self.haptics = haptics
        self.settings = settings
    }

    func apply(profile newProfile: FeedbackProfile) {
        profile = newProfile
        alertPolicy.obstacleAlertDistance = newProfile.minimumAlertDistance
        alertPolicy.distanceUnit = newProfile.distanceUnit
        alertPolicy.strideLengthMeters = newProfile.strideLengthMeters
        let speech = speech
        Task { await speech.setRate(newProfile.speechRate) }
    }

    func guide(to item: SavedItem) {
        guidedItem = item
    }

    func stopGuiding() {
        guidedItem = nil
        itemGuidance = nil
    }

    /// Silences all guidance feedback while keeping tracking warm — sitting
    /// down for lunch shouldn't require quitting the app. Mapped to VoiceOver's
    /// Magic Tap as well as the Pause button.
    func togglePause() {
        isPaused.toggle()
        announceStatus(isPaused ? "Guidance paused." : "Guidance resumed.", priority: .high)
    }

    /// On-demand verbal snapshot of the surroundings. Spoken directly (not
    /// profile-routed): an explicit request for description is an explicit
    /// request for speech.
    func describeScene() {
        let text = SceneDescriber.describe(
            objects: detectedObjects,
            nearestObstacle: nearestObstacle,
            hazards: activeHazards,
            unit: profile.distanceUnit,
            strideLengthMeters: profile.strideLengthMeters
        )
        latestAlert = FeedbackEvent(kind: .navigationCue, priority: .high, direction: nil, distance: nil, message: text)
        let speech = speech
        Task { await speech.announce(text, priority: .high) }
    }

    func start() async {
        guard phase != .running else { return }
        announcedReady = false
        apply(profile: settings.loadProfile())
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
        // Warm the slow-start engines now so the first alert pays nothing.
        await haptics.prepare()
        await speech.prepare()
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
            // Degradation is announced, never silent — through whichever
            // channels the profile allows.
            let event = FeedbackEvent(
                kind: .status,
                priority: .low,
                direction: nil,
                distance: nil,
                message: "Reducing detail to keep the phone cool and save battery."
            )
            latestAlert = event
            let channels = router.channels(for: event, profile: profile)
            let speech = speech
            let haptics = haptics
            Task {
                if channels.speech, let message = event.message {
                    await speech.announce(message, priority: event.priority)
                }
                if channels.haptics {
                    await haptics.play(event)
                }
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

        // A blind user standing in a hallway needs to know when it is safe to
        // start walking; announce readiness once per session.
        if !announcedReady, snapshot.trackingQuality == .normal {
            announcedReady = true
            announceStatus("SpatialNav ready. Guidance is on.", priority: .normal)
        }

        // While paused: tracking and HUD stay live, all guidance output stops.
        guard !isPaused else { return }

        // Stuck relocalization: give up honestly and start a fresh session
        // rather than guiding on stale data.
        if relocalizationWatchdog.ingest(quality: snapshot.trackingQuality, at: snapshot.timestamp) {
            logger.notice("Relocalization timed out — starting a fresh session")
            announceStatus("I can't recognize this space. Starting fresh.", priority: .high)
            try? provider.start()
            return
        }
        // Mesh count is a coverage indicator for the HUD; 1 Hz is plenty.
        if snapshot.timestamp - lastMeshCountRefresh >= 1.0 {
            lastMeshCountRefresh = snapshot.timestamp
            meshAnchorCount = await meshStore.count()
        }

        // Sweeping inline applies natural backpressure: while a sweep is in
        // flight the stream (bufferingNewest 1) drops frames instead of queuing.
        await audio.updateListener(transform: snapshot.cameraTransform)

        let sweepInterval = signposter.beginInterval("sonarSweep")
        let result = await sonar.sweep(frame: snapshot, rayCount: processingTier.sonarRayCount)
        nearestObstacle = result.obstacles.min { $0.distance < $1.distance }

        var confirmedHazards = hazardDebouncer.ingest(result.hazards)
        if confirmedHazards.isEmpty, !result.hazards.isEmpty {
            // Burst confirmation: the debouncer needs three consecutive sweeps,
            // but nothing says they must come from three frames. Re-measure
            // immediately — three independent raycasts in milliseconds instead
            // of waiting ~200 ms of frame cadence while the user walks on.
            for _ in 0..<2 {
                let recheck = await sonar.sweep(frame: snapshot, rayCount: processingTier.sonarRayCount)
                confirmedHazards = hazardDebouncer.ingest(recheck.hazards)
                if !confirmedHazards.isEmpty || recheck.hazards.isEmpty { break }
            }
        }
        activeHazards = confirmedHazards
        signposter.endInterval("sonarSweep", sweepInterval)

        if let alert = alertPolicy.events(
            hazards: activeHazards,
            nearestObstacle: nearestObstacle,
            at: snapshot.timestamp
        ).first {
            latestAlert = alert
            logger.info("Alert: \(alert.message ?? "—", privacy: .public)")
            signposter.emitEvent("alertEmitted")
            let channels = router.channels(for: alert, profile: profile)
            if channels.speech, let message = alert.message {
                await speech.announce(message, priority: alert.priority)
            }
            if channels.haptics {
                await haptics.play(alert)
            }
        }

        // Sonar Mode: the nearest obstacle pings from its true direction,
        // faster and higher-pitched as it gets closer — or thumps harder,
        // depending on the sensory profile.
        if let nearest = nearestObstacle,
           snapshot.timestamp - lastObstaclePing >= audioMap.pulseInterval(forDistance: nearest.distance) {
            lastObstaclePing = snapshot.timestamp
            let ping = FeedbackEvent(
                kind: .obstacleProximity,
                priority: .normal,
                direction: nearest.direction,
                distance: nearest.distance,
                message: nil
            )
            let channels = router.channels(for: ping, profile: profile)
            if channels.spatialAudio {
                await audio.play(ping, at: nearest.worldPosition)
            }
            if channels.haptics {
                await haptics.play(ping)
            }
        }

        if let target = guidedItem?.lastKnownPosition {
            let guidance = ItemGuidance.toward(target, from: snapshot.cameraTransform)
            itemGuidance = guidance
            // Item beacon: a distinct signature from the item's location.
            if snapshot.timestamp - lastItemPing >= audioMap.pulseInterval(forDistance: guidance.distance) {
                lastItemPing = snapshot.timestamp
                let beacon = FeedbackEvent(
                    kind: .itemPing,
                    priority: .normal,
                    direction: guidance.direction,
                    distance: guidance.distance,
                    message: nil
                )
                let channels = router.channels(for: beacon, profile: profile)
                if channels.spatialAudio {
                    await audio.play(beacon, at: target)
                }
                if channels.haptics {
                    await haptics.play(beacon)
                }
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
            announceStatus("Guidance paused.", priority: .high)
        case .interruptionEnded:
            phase = .running
            announceStatus("Guidance resumed.", priority: .high)
        case .failed(let message):
            phase = .failed(message)
        }
    }

    /// Status announcements travel through whichever channels the profile allows.
    private func announceStatus(_ message: String, priority: FeedbackPriority) {
        let event = FeedbackEvent(kind: .status, priority: priority, direction: nil, distance: nil, message: message)
        latestAlert = event
        let channels = router.channels(for: event, profile: profile)
        let speech = speech
        let haptics = haptics
        Task {
            if channels.speech {
                await speech.announce(message, priority: priority)
            }
            if channels.haptics {
                await haptics.play(event)
            }
        }
    }
}
