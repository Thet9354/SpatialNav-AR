//
//  RayMathTests.swift
//  SpatialNavTests
//

import Testing
import simd
@testable import SpatialNav

struct RayMathTests {

    // Identity camera transform: right = +x, up = +y, looking down -z.
    private let identity = matrix_identity_float4x4

    private func approximatelyEqual(
        _ lhs: simd_float3,
        _ rhs: simd_float3,
        tolerance: Float = 1e-5
    ) -> Bool {
        simd_distance(lhs, rhs) < tolerance
    }

    @Test func forwardRayPointsDownNegativeZ() {
        let ray = RayMath.worldRay(cameraTransform: identity, ray: SonarRay(azimuth: 0, elevation: 0))
        #expect(approximatelyEqual(ray.direction, simd_float3(0, 0, -1)))
        #expect(approximatelyEqual(ray.origin, .zero))
    }

    @Test func rightwardAzimuthPointsAlongPositiveX() {
        let ray = RayMath.worldRay(cameraTransform: identity, ray: SonarRay(azimuth: .pi / 2, elevation: 0))
        #expect(approximatelyEqual(ray.direction, simd_float3(1, 0, 0)))
    }

    @Test func leftwardAzimuthPointsAlongNegativeX() {
        let ray = RayMath.worldRay(cameraTransform: identity, ray: SonarRay(azimuth: -.pi / 2, elevation: 0))
        #expect(approximatelyEqual(ray.direction, simd_float3(-1, 0, 0)))
    }

    @Test func upwardElevationPointsAlongPositiveY() {
        let ray = RayMath.worldRay(cameraTransform: identity, ray: SonarRay(azimuth: 0, elevation: .pi / 2))
        #expect(approximatelyEqual(ray.direction, simd_float3(0, 1, 0)))
    }

    @Test func downwardElevationPointsAlongNegativeY() {
        let ray = RayMath.worldRay(cameraTransform: identity, ray: SonarRay(azimuth: 0, elevation: -.pi / 2))
        #expect(approximatelyEqual(ray.direction, simd_float3(0, -1, 0)))
    }

    @Test func originFollowsCameraTranslation() {
        var transform = matrix_identity_float4x4
        transform.columns.3 = simd_float4(1, 2, 3, 1)
        let ray = RayMath.worldRay(cameraTransform: transform, ray: SonarRay(azimuth: 0, elevation: 0))
        #expect(approximatelyEqual(ray.origin, simd_float3(1, 2, 3)))
    }

    @Test func gravityAlignedRayIgnoresCameraPitch() {
        // Camera pitched 45° up (rotation about +x): forward = (0, sin45, -cos45).
        var pitchedUp = matrix_identity_float4x4
        let angle = Float.pi / 4
        pitchedUp.columns.1 = simd_float4(0, cos(angle), sin(angle), 0)
        pitchedUp.columns.2 = simd_float4(0, -sin(angle), cos(angle), 0)

        let probe = SonarRay(azimuth: 0, elevation: -.pi / 4, gravityAligned: true)
        let ray = RayMath.worldRay(cameraTransform: pitchedUp, ray: probe)

        // 45° below the horizon regardless of the camera looking upward.
        let expected = simd_normalize(simd_float3(0, -1, -1))
        #expect(approximatelyEqual(ray.direction, expected))
    }

    @Test func gravityAlignedRayMatchesCameraRelativeWhenLevel() {
        let probe = SonarRay(azimuth: .pi / 6, elevation: -0.5, gravityAligned: true)
        let cameraRelative = SonarRay(azimuth: .pi / 6, elevation: -0.5)
        let gravity = RayMath.worldRay(cameraTransform: identity, ray: probe)
        let relative = RayMath.worldRay(cameraTransform: identity, ray: cameraRelative)
        #expect(approximatelyEqual(gravity.direction, relative.direction))
    }

    @Test func gravityAlignedRayFallsBackWhenCameraPointsStraightDown() {
        // Forward = -y: no horizontal heading; must not produce NaN.
        var straightDown = matrix_identity_float4x4
        straightDown.columns.1 = simd_float4(0, 0, -1, 0) // up → -z
        straightDown.columns.2 = simd_float4(0, 1, 0, 0)  // back → +y, forward → -y

        let probe = SonarRay(azimuth: 0, elevation: -0.5, gravityAligned: true)
        let ray = RayMath.worldRay(cameraTransform: straightDown, ray: probe)
        #expect(ray.direction.x.isFinite && ray.direction.y.isFinite && ray.direction.z.isFinite)
        #expect(abs(simd_length(ray.direction) - 1) < 1e-5)
    }

    @Test func fanIsSymmetricAndOrdered() {
        let arc = Float.pi / 3
        let fan = SonarRay.fan(count: 9, arc: arc)
        #expect(fan.count == 9)
        #expect(abs(fan.first!.azimuth + arc / 2) < 1e-6)
        #expect(abs(fan.last!.azimuth - arc / 2) < 1e-6)
        #expect(abs(fan[4].azimuth) < 1e-6)
    }
}
