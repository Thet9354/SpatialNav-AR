//
//  ObjectDetectionUseCaseTests.swift
//  SpatialNavTests
//
//  Pipeline-level test: scripted frames → mock detector → raycast located →
//  temporal confirmation → published results.
//

import CoreGraphics
import Foundation
import Testing
import simd
@testable import SpatialNav

private final class MockObjectDetector: ObjectDetecting, @unchecked Sendable {
    var scripted: [DetectedObject] = []
    func detect(in snapshot: PixelBufferSnapshot) async throws -> [DetectedObject] { scripted }
}

struct ObjectDetectionUseCaseTests {

    private let boundingBox = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)

    private func detection() -> DetectedObject {
        DetectedObject(
            id: UUID(),
            label: "chair",
            confidence: 0.9,
            boundingBox: boundingBox,
            worldPosition: nil,
            distance: nil,
            direction: nil
        )
    }

    /// The ray the use case will compute for our bounding box — the mock's
    /// scripted hit must carry the identical ray to be matched back.
    private var expectedRay: SonarRay {
        DetectionGeometry.sonarRay(
            visionBoundingBox: boundingBox,
            intrinsics: matrix_identity_float3x3,
            imageResolution: CGSize(width: 64, height: 64)
        )
    }

    @Test func locatesAndConfirmsAfterRepeatedSightings() async {
        let provider = MockARSessionProvider()
        let detector = MockObjectDetector()
        detector.scripted = [detection()]
        provider.scriptedHits = [RaycastHit(
            ray: expectedRay,
            distance: 2.0,
            worldPosition: simd_float3(0, 0, -2)
        )]

        let useCase = ObjectDetectionUseCase(
            provider: provider,
            detector: detector,
            smoother: DetectionSmoother(requiredHits: 2)
        )
        let results = await useCase.results()
        var iterator = results.makeAsyncIterator()
        await useCase.start()

        provider.pixelContinuation?.yield(TestFixtures.pixelSnapshot(timestamp: 0))
        let afterFirst = await iterator.next()
        #expect(afterFirst == []) // seen once, not yet confirmed

        provider.pixelContinuation?.yield(TestFixtures.pixelSnapshot(timestamp: 0.2))
        let afterSecond = await iterator.next()
        #expect(afterSecond?.count == 1)
        #expect(afterSecond?.first?.worldPosition == simd_float3(0, 0, -2))
        #expect(afterSecond?.first?.distance == 2.0)
        #expect(afterSecond?.first?.direction != nil)

        await useCase.stop()
    }

    @Test func detectionsWithoutARaycastHitAreNeverPublished() async {
        let provider = MockARSessionProvider()
        let detector = MockObjectDetector()
        detector.scripted = [detection()]
        provider.scriptedHits = [] // camera sees something, but no scene geometry behind it

        let useCase = ObjectDetectionUseCase(
            provider: provider,
            detector: detector,
            smoother: DetectionSmoother(requiredHits: 1)
        )
        let results = await useCase.results()
        var iterator = results.makeAsyncIterator()
        await useCase.start()

        provider.pixelContinuation?.yield(TestFixtures.pixelSnapshot(timestamp: 0))
        #expect(await iterator.next() == [])

        await useCase.stop()
    }
}
