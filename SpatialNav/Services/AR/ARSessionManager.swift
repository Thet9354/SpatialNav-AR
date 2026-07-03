//
//  ARSessionManager.swift
//  SpatialNav
//

import ARKit
import Foundation

/// Owns the ARSession; the only type in the app that calls ARKit session APIs.
///
/// Thread-safety invariant for `@unchecked Sendable`: every mutable property is
/// confined to `delegateQueue`. ARKit delivers all delegate callbacks on that
/// queue (`session.delegateQueue`), and external entry points (`raycast`,
/// stream registration) hop onto it before touching state. ARFrame and other
/// ARKit objects never escape this type — only Sendable snapshots do.
nonisolated final class ARSessionManager: NSObject, ARSessionProviding, ARSessionDelegate, @unchecked Sendable {

    /// Exposed solely so the render layer (ARViewContainer) can attach an ARView.
    let session = ARSession()

    private let delegateQueue = DispatchQueue(label: "com.thetpine.spatialnav.ar-session")
    private let meshStore: any MeshStoring
    private let snapshotInterval: TimeInterval
    /// didUpdate-anchor bursts are time-gated; adds/removes always pass through.
    private let meshForwardInterval: TimeInterval = 0.2

    // MARK: State confined to delegateQueue

    private var latestCameraTransform: simd_float4x4?
    private var latestTrackingQuality: TrackingQuality = .notAvailable
    private var lastSnapshotTimestamp: TimeInterval = 0
    private var lastMeshForwardTime: TimeInterval = 0
    private var frameContinuations: [UUID: AsyncStream<ARFrameSnapshot>.Continuation] = [:]
    private var eventContinuations: [UUID: AsyncStream<ARSessionEvent>.Continuation] = [:]

    init(meshStore: any MeshStoring, snapshotsPerSecond: Double = 10) {
        self.meshStore = meshStore
        self.snapshotInterval = 1.0 / snapshotsPerSecond
        super.init()
        session.delegate = self
        session.delegateQueue = delegateQueue
    }

    // MARK: ARSessionProviding

    var capabilities: ARCapabilities {
        ARCapabilities(
            supportsWorldTracking: ARWorldTrackingConfiguration.isSupported,
            supportsSceneReconstruction: ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
            supportsSceneDepth: ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        )
    }

    func start() throws {
        guard ARWorldTrackingConfiguration.isSupported else {
            throw ARSessionError.worldTrackingUnsupported
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .none
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }

    func frames() -> AsyncStream<ARFrameSnapshot> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.delegateQueue.async { self.frameContinuations[id] = nil }
            }
            delegateQueue.async { self.frameContinuations[id] = continuation }
        }
    }

    func events() -> AsyncStream<ARSessionEvent> {
        AsyncStream { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.delegateQueue.async { self.eventContinuations[id] = nil }
            }
            delegateQueue.async { self.eventContinuations[id] = continuation }
        }
    }

    func raycast(_ rays: [SonarRay]) async -> [RaycastHit] {
        await withCheckedContinuation { continuation in
            delegateQueue.async {
                guard let cameraTransform = self.latestCameraTransform else {
                    continuation.resume(returning: [])
                    return
                }
                let hits = rays.compactMap { ray -> RaycastHit? in
                    let worldRay = RayMath.worldRay(cameraTransform: cameraTransform, ray: ray)
                    let query = ARRaycastQuery(
                        origin: worldRay.origin,
                        direction: worldRay.direction,
                        allowing: .estimatedPlane,
                        alignment: .any
                    )
                    guard let result = self.session.raycast(query).first else { return nil }
                    let position = result.worldTransform.translation
                    return RaycastHit(
                        ray: ray,
                        distance: simd_distance(position, worldRay.origin),
                        worldPosition: position
                    )
                }
                continuation.resume(returning: hits)
            }
        }
    }

    // MARK: ARSessionDelegate (delivered on delegateQueue)

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        latestCameraTransform = frame.camera.transform
        guard frame.timestamp - lastSnapshotTimestamp >= snapshotInterval else { return }
        lastSnapshotTimestamp = frame.timestamp
        let snapshot = ARFrameSnapshot(
            timestamp: frame.timestamp,
            cameraTransform: frame.camera.transform,
            trackingQuality: latestTrackingQuality
        )
        for continuation in frameContinuations.values {
            continuation.yield(snapshot)
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        latestTrackingQuality = TrackingQuality(camera.trackingState)
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        forwardMeshAnchors(anchors, force: true)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        forwardMeshAnchors(anchors, force: false)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        let ids = anchors.compactMap { ($0 as? ARMeshAnchor)?.identifier }
        guard !ids.isEmpty else { return }
        let store = meshStore
        Task { await store.remove(ids: ids) }
    }

    // MARK: ARSessionObserver (delivered on delegateQueue)

    func sessionWasInterrupted(_ session: ARSession) {
        yieldEvent(.interrupted)
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        yieldEvent(.interruptionEnded)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        yieldEvent(.failed(error.localizedDescription))
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        true
    }

    // MARK: Private

    private func yieldEvent(_ event: ARSessionEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }

    private func forwardMeshAnchors(_ anchors: [ARAnchor], force: Bool) {
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
        guard !meshAnchors.isEmpty else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if !force, now - lastMeshForwardTime < meshForwardInterval { return }
        lastMeshForwardTime = now
        let snapshots = meshAnchors.map {
            MeshAnchorSnapshot(id: $0.identifier, transform: $0.transform, updatedAt: now)
        }
        let store = meshStore
        Task { await store.apply(snapshots) }
    }
}

extension TrackingQuality {
    fileprivate nonisolated init(_ state: ARCamera.TrackingState) {
        switch state {
        case .normal:
            self = .normal
        case .notAvailable:
            self = .notAvailable
        case .limited(let reason):
            switch reason {
            case .initializing: self = .limited(.initializing)
            case .excessiveMotion: self = .limited(.excessiveMotion)
            case .insufficientFeatures: self = .limited(.insufficientFeatures)
            case .relocalizing: self = .limited(.relocalizing)
            @unknown default: self = .limited(.initializing)
            }
        }
    }
}
