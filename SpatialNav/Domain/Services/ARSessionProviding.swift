//
//  ARSessionProviding.swift
//  SpatialNav
//

import Foundation

/// Abstraction over the ARKit session. ViewModels and use cases depend on this,
/// never on ARKit types, so all AR-driven logic is unit-testable with scripted streams.
nonisolated protocol ARSessionProviding: Sendable {
    var capabilities: ARCapabilities { get }

    /// Each call returns an independent stream; safe for one consumer per call,
    /// including across stop/start cycles.
    func frames() -> AsyncStream<ARFrameSnapshot>
    func events() -> AsyncStream<ARSessionEvent>

    func start() throws
    func stop()

    /// Casts camera-relative rays against the reconstructed scene.
    /// Rays that hit nothing are omitted from the result.
    func raycast(_ rays: [SonarRay]) async -> [RaycastHit]
}
