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

    @Test func nearProbeOnFurnitureIsNotAFloorReference() {
        // Near probe lands on a chair seat 0.6 m below the camera (< 1.0 m gate):
        // no judgment, even though the far probe is missing entirely.
        let chairSeat = RaycastHit(
            ray: SonarConfiguration.nearFloorProbe,
            distance: 1.0,
            worldPosition: simd_float3(0, 0.9, -0.6)
        )
        let hazards = detector.hazards(from: [chairSeat], frame: frame)
        #expect(hazards.isEmpty)
    }

    @Test func farProbeOnFurnitureIsNotStairs() {
        // Far probe hits a desk 0.6 m above the floor: beyond a plausible stair
        // rise, so the fan reports it as an obstacle instead of stairs.
        let hazards = detector.hazards(from: [nearHit(), farHit(floorHeight: 0.6)], frame: frame)
        #expect(hazards.isEmpty)
    }

    // Field regression: a wardrobe drawer front 0.3 m up produced the same hit
    // point as a stair tread and fired "Stairs going up ahead".

    @Test func verticalSurfaceAtStepHeightIsNotStairs() {
        let floor = RaycastHit(
            ray: SonarConfiguration.nearFloorProbe,
            distance: 1.6,
            worldPosition: simd_float3(0, 0, -0.6),
            surfaceNormal: simd_float3(0, 1, 0)
        )
        let drawerFront = RaycastHit(
            ray: SonarConfiguration.farFloorProbe,
            distance: 1.8,
            worldPosition: simd_float3(0, 0.3, -1.4),
            surfaceNormal: simd_float3(0, 0, 1) // faces the user, not up
        )
        let hazards = detector.hazards(from: [floor, drawerFront], frame: frame)
        #expect(hazards.isEmpty)
    }

    @Test func upFacingSurfaceAtStepHeightIsStairs() {
        let floor = RaycastHit(
            ray: SonarConfiguration.nearFloorProbe,
            distance: 1.6,
            worldPosition: simd_float3(0, 0, -0.6),
            surfaceNormal: simd_float3(0, 1, 0)
        )
        let tread = RaycastHit(
            ray: SonarConfiguration.farFloorProbe,
            distance: 2.0,
            worldPosition: simd_float3(0, 0.3, -1.4),
            surfaceNormal: simd_float3(0, 1, 0)
        )
        let hazards = detector.hazards(from: [floor, tread], frame: frame)
        #expect(hazards.count == 1)
        #expect(hazards[0].kind == .stairsUp)
    }

    @Test func nearProbeOnVerticalSurfaceIsNoFloorReference() {
        // Near probe deep enough below the camera but on a vertical surface
        // (e.g. grazing a wall base): not a floor reference, no judgment.
        let wallGraze = RaycastHit(
            ray: SonarConfiguration.nearFloorProbe,
            distance: 1.6,
            worldPosition: simd_float3(0, 0.2, -0.6),
            surfaceNormal: simd_float3(0, 0, 1)
        )
        let hazards = detector.hazards(from: [wallGraze], frame: frame)
        #expect(hazards.isEmpty)
    }

    @Test func dropOffIsNotGatedOnFarSurfaceNormal() {
        // Descending stairs can present a riser face to the probe; the warning
        // must still fire.
        let floor = RaycastHit(
            ray: SonarConfiguration.nearFloorProbe,
            distance: 1.6,
            worldPosition: simd_float3(0, 0, -0.6),
            surfaceNormal: simd_float3(0, 1, 0)
        )
        let riser = RaycastHit(
            ray: SonarConfiguration.farFloorProbe,
            distance: 2.4,
            worldPosition: simd_float3(0, -0.4, -1.8),
            surfaceNormal: simd_float3(0, 0, 1)
        )
        let hazards = detector.hazards(from: [floor, riser], frame: frame)
        #expect(hazards.count == 1)
        #expect(hazards[0].kind == .dropOff)
    }
}
