//
//  MockARSessionProvider.swift
//  SpatialNavTests
//

import Foundation
@testable import SpatialNav

/// Test double confined to single-threaded test usage.
final class MockARSessionProvider: ARSessionProviding, @unchecked Sendable {
    var capabilities = ARCapabilities(
        supportsWorldTracking: true,
        supportsSceneReconstruction: true,
        supportsSceneDepth: true
    )
    var scriptedHits: [RaycastHit] = []
    var scriptedWorldMapData = Data()
    var scriptedPixelBuffer: PixelBufferSnapshot?
    var startError: Error?
    private(set) var started = false
    private(set) var raycastCallCount = 0
    private(set) var restoredWorldMapData: Data?
    private(set) var mlSampleRates: [Double] = []

    func frames() -> AsyncStream<ARFrameSnapshot> {
        AsyncStream { $0.finish() }
    }

    func events() -> AsyncStream<ARSessionEvent> {
        AsyncStream { $0.finish() }
    }

    func pixelBuffers() -> AsyncStream<PixelBufferSnapshot> {
        AsyncStream { $0.finish() }
    }

    func captureNextPixelBuffer() async -> PixelBufferSnapshot? {
        scriptedPixelBuffer
    }

    func setMLSampleRate(framesPerSecond: Double) {
        mlSampleRates.append(framesPerSecond)
    }

    func start() throws {
        if let startError { throw startError }
        started = true
    }

    func stop() {
        started = false
    }

    func raycast(_ rays: [SonarRay]) async -> [RaycastHit] {
        raycastCallCount += 1
        return scriptedHits
    }

    func captureWorldMapData() async throws -> Data {
        scriptedWorldMapData
    }

    func restoreWorldMap(from data: Data) throws {
        restoredWorldMapData = data
    }
}
