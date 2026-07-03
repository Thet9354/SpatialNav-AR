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
    private var streamTasks: [Task<Void, Never>] = []
    private var lastMeshCountRefresh: TimeInterval = 0
    private var lastSonarLog: TimeInterval = 0
    private let logger = Logger(subsystem: "com.thetpine.spatialnav", category: "sonar")

    init(
        provider: any ARSessionProviding,
        meshStore: any MeshStoring,
        cameraAuthorizer: any CameraAuthorizing,
        sonar: SonarSweepUseCase,
        objectDetection: ObjectDetectionUseCase?
    ) {
        self.provider = provider
        self.meshStore = meshStore
        self.cameraAuthorizer = cameraAuthorizer
        self.sonar = sonar
        self.objectDetection = objectDetection
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
    }

    func stop() {
        streamTasks.forEach { $0.cancel() }
        streamTasks.removeAll()
        if let objectDetection {
            Task { await objectDetection.stop() }
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
        let result = await sonar.sweep(frame: snapshot)
        nearestObstacle = result.obstacles.min { $0.distance < $1.distance }
        activeHazards = result.hazards
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
