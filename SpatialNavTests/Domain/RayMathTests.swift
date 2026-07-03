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

    @Test func fanIsSymmetricAndOrdered() {
        let arc = Float.pi / 3
        let fan = SonarRay.fan(count: 9, arc: arc)
        #expect(fan.count == 9)
        #expect(abs(fan.first!.azimuth + arc / 2) < 1e-6)
        #expect(abs(fan.last!.azimuth - arc / 2) < 1e-6)
        #expect(abs(fan[4].azimuth) < 1e-6)
    }
}
