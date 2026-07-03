//
//  SonarSweepUseCaseTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
import simd
@testable import SpatialNav

struct SonarSweepUseCaseTests {

    private func frame(cameraHeight: Float = 1.5) -> ARFrameSnapshot {
        var transform = matrix_identity_float4x4
        transform.columns.3 = simd_float4(0, cameraHeight, 0, 1)
        return ARFrameSnapshot(
            timestamp: 0,
            cameraTransform: transform,
            trackingQuality: .normal,
            worldMappingStatus: .mapped
        )
    }

    private func horizontalHit(azimuth: Float, distance: Float, height: Float) -> RaycastHit {
        RaycastHit(
            ray: SonarRay(azimuth: azimuth, elevation: 0),
            distance: distance,
            worldPosition: simd_float3(0, height, -distance)
        )
    }

    @Test func mapsHorizontalHitsToObstaclesWithClockBearings() async {
        let provider = MockARSessionProvider()
        provider.scriptedHits = [
            horizontalHit(azimuth: .pi / 6, distance: 2.0, height: 0.9),
            horizontalHit(azimuth: -.pi / 2, distance: 1.0, height: 0.9),
        ]
        let sonar = SonarSweepUseCase(provider: provider, hazardAnalyzer: FloorDiscontinuityDetector())

        let result = await sonar.sweep(frame: frame())

        #expect(result.obstacles.count == 2)
        #expect(result.obstacles[0].direction == .one)
        #expect(result.obstacles[0].distance == 2.0)
        #expect(result.obstacles[1].direction == .nine)
    }

    @Test func filtersHitsBeyondMaxObstacleDistance() async {
        let provider = MockARSessionProvider()
        provider.scriptedHits = [horizontalHit(azimuth: 0, distance: 5.0, height: 0.9)]
        let sonar = SonarSweepUseCase(provider: provider, hazardAnalyzer: FloorDiscontinuityDetector())

        let result = await sonar.sweep(frame: frame())

        #expect(result.obstacles.isEmpty)
    }

    @Test func floorProbeHitsAreNotReportedAsObstacles() async {
        let provider = MockARSessionProvider()
        provider.scriptedHits = [
            RaycastHit(
                ray: SonarConfiguration.nearFloorProbe,
                distance: 1.6,
                worldPosition: simd_float3(0, 0, -0.6)
            )
        ]
        let sonar = SonarSweepUseCase(provider: provider, hazardAnalyzer: FloorDiscontinuityDetector())

        let result = await sonar.sweep(frame: frame())

        #expect(result.obstacles.isEmpty)
    }

    @Test func elevationBandsFollowCameraHeight() {
        // Camera at 1.5 m: hits within 0.4 m below are head, next 0.7 m waist, rest floor.
        #expect(SonarSweepUseCase.elevationBand(hitHeight: 1.4, cameraHeight: 1.5) == .head)
        #expect(SonarSweepUseCase.elevationBand(hitHeight: 1.7, cameraHeight: 1.5) == .head)
        #expect(SonarSweepUseCase.elevationBand(hitHeight: 0.7, cameraHeight: 1.5) == .waist)
        #expect(SonarSweepUseCase.elevationBand(hitHeight: 0.1, cameraHeight: 1.5) == .floor)
    }

    @Test func defaultConfigurationCastsFanPlusFloorProbes() {
        let rays = SonarConfiguration.default.allRays
        #expect(rays.count == 11)
        #expect(rays.contains(SonarConfiguration.nearFloorProbe))
        #expect(rays.contains(SonarConfiguration.farFloorProbe))
    }
}
