//
//  FloorDiscontinuityDetectorTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
import simd
@testable import SpatialNav

struct FloorDiscontinuityDetectorTests {

    private let detector = FloorDiscontinuityDetector()

    private var frame: ARFrameSnapshot {
        var transform = matrix_identity_float4x4
        transform.columns.3 = simd_float4(0, 1.5, 0, 1)
        return ARFrameSnapshot(
            timestamp: 0,
            cameraTransform: transform,
            trackingQuality: .normal,
            worldMappingStatus: .mapped
        )
    }

    private func nearHit(floorHeight: Float = 0) -> RaycastHit {
        RaycastHit(
            ray: SonarConfiguration.nearFloorProbe,
            distance: 1.6,
            worldPosition: simd_float3(0, floorHeight, -0.6)
        )
    }

    private func farHit(floorHeight: Float) -> RaycastHit {
        RaycastHit(
            ray: SonarConfiguration.farFloorProbe,
            distance: 2.2,
            worldPosition: simd_float3(0, floorHeight, -1.6)
        )
    }

    @Test func flatFloorProducesNoHazard() {
        let hazards = detector.hazards(from: [nearHit(), farHit(floorHeight: 0.05)], frame: frame)
        #expect(hazards.isEmpty)
    }

    @Test func farProbeBelowNearProbeIsDropOff() {
        let hazards = detector.hazards(from: [nearHit(), farHit(floorHeight: -0.4)], frame: frame)
        #expect(hazards.count == 1)
        #expect(hazards[0].kind == .dropOff)
        #expect(hazards[0].direction == .twelve)
        #expect(abs(hazards[0].distance - 1.6) < 1e-5)
    }

    @Test func missingFarProbeIsDropOff() {
        let hazards = detector.hazards(from: [nearHit()], frame: frame)
        #expect(hazards.count == 1)
        #expect(hazards[0].kind == .dropOff)
    }

    @Test func farProbeAboveNearProbeIsRisingStairs() {
        let hazards = detector.hazards(from: [nearHit(), farHit(floorHeight: 0.2)], frame: frame)
        #expect(hazards.count == 1)
        #expect(hazards[0].kind == .stairsUp)
    }

    @Test func noProbesMeansNoJudgment() {
        let hazards = detector.hazards(from: [], frame: frame)
        #expect(hazards.isEmpty)
    }
}
