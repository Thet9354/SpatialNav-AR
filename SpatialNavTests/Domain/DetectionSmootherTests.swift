//
//  DetectionSmootherTests.swift
//  SpatialNavTests
//

import CoreGraphics
import Foundation
import Testing
import simd
@testable import SpatialNav

struct DetectionSmootherTests {

    private func detection(
        label: String = "chair",
        position: simd_float3? = simd_float3(0, 0, -2)
    ) -> DetectedObject {
        DetectedObject(
            id: UUID(),
            label: label,
            confidence: 0.8,
            boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
            worldPosition: position,
            distance: 2.0,
            direction: .twelve
        )
    }

    @Test func objectIsConfirmedOnlyAfterRequiredHits() {
        var smoother = DetectionSmoother(requiredHits: 3)
        #expect(smoother.ingest([detection()], at: 0).isEmpty)
        #expect(smoother.ingest([detection()], at: 0.2).isEmpty)
        let confirmed = smoother.ingest([detection()], at: 0.4)
        #expect(confirmed.count == 1)
        #expect(confirmed[0].label == "chair")
    }

    @Test func confirmedObjectKeepsStableIdentityAcrossSightings() {
        var smoother = DetectionSmoother(requiredHits: 2)
        _ = smoother.ingest([detection()], at: 0)
        let first = smoother.ingest([detection()], at: 0.2)
        let second = smoother.ingest([detection()], at: 0.4)
        #expect(first.count == 1)
        #expect(second.count == 1)
        #expect(first[0].id == second[0].id)
    }

    @Test func differentLabelsDoNotMatchEachOther() {
        var smoother = DetectionSmoother(requiredHits: 2)
        _ = smoother.ingest([detection(label: "chair")], at: 0)
        let confirmed = smoother.ingest([detection(label: "person")], at: 0.2)
        #expect(confirmed.isEmpty)
    }

    @Test func sameLabelFarApartIsASeparateCandidate() {
        var smoother = DetectionSmoother(requiredHits: 2, matchRadius: 0.5)
        _ = smoother.ingest([detection(position: simd_float3(0, 0, -2))], at: 0)
        let confirmed = smoother.ingest([detection(position: simd_float3(3, 0, -2))], at: 0.2)
        #expect(confirmed.isEmpty)
    }

    @Test func unseenObjectsExpireAfterStaleInterval() {
        var smoother = DetectionSmoother(requiredHits: 2, staleInterval: 1.0)
        _ = smoother.ingest([detection()], at: 0)
        #expect(smoother.ingest([detection()], at: 0.2).count == 1)
        #expect(smoother.ingest([], at: 5.0).isEmpty)
        // A later sighting starts confirmation over.
        #expect(smoother.ingest([detection()], at: 5.1).isEmpty)
    }

    @Test func detectionsWithoutWorldPositionAreIgnored() {
        var smoother = DetectionSmoother(requiredHits: 1)
        let confirmed = smoother.ingest([detection(position: nil)], at: 0)
        #expect(confirmed.isEmpty)
    }
}
