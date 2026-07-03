//
//  NavigationViewModel.swift
//  SpatialNav
//

import Foundation
import Observation

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
    private(set) var meshAnchorCount = 0

    var lidarAvailable: Bool {
        provider.capabilities.supportsSceneReconstruction
    }

    private let provider: any ARSessionProviding
    private let meshStore: any MeshStoring
    private let cameraAuthorizer: any CameraAuthorizing
    private var streamTasks: [Task<Void, Never>] = []
    private var lastMeshCountRefresh: TimeInterval = 0

    init(
        provider: any ARSessionProviding,
        meshStore: any MeshStoring,
        cameraAuthorizer: any CameraAuthorizing
    ) {
        self.provider = provider
        self.meshStore = meshStore
        self.cameraAuthorizer = cameraAuthorizer
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
    }

    func stop() {
        streamTasks.forEach { $0.cancel() }
        streamTasks.removeAll()
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
    }

    private func handle(_ snapshot: ARFrameSnapshot) async {
        if snapshot.trackingQuality != trackingQuality {
            trackingQuality = snapshot.trackingQuality
        }
        // Mesh count is a coverage indicator for the HUD; 1 Hz is plenty.
        if snapshot.timestamp - lastMeshCountRefresh >= 1.0 {
            lastMeshCountRefresh = snapshot.timestamp
            meshAnchorCount = await meshStore.count()
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
