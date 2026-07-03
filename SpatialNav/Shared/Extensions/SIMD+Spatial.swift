//
//  SIMD+Spatial.swift
//  SpatialNav
//

import Foundation
import simd

extension simd_float4x4 {
    nonisolated var translation: simd_float3 {
        simd_float3(columns.3.x, columns.3.y, columns.3.z)
    }

    // ARKit camera space: +x right, +y up, camera looks down -z.
    nonisolated var rightVector: simd_float3 {
        simd_normalize(simd_float3(columns.0.x, columns.0.y, columns.0.z))
    }

    nonisolated var upVector: simd_float3 {
        simd_normalize(simd_float3(columns.1.x, columns.1.y, columns.1.z))
    }

    nonisolated var forwardVector: simd_float3 {
        simd_normalize(-simd_float3(columns.2.x, columns.2.y, columns.2.z))
    }
}

nonisolated enum RayMath {
    /// Converts a camera-relative SonarRay into a world-space ray.
    /// Elevation is applied about the camera's right axis first, then azimuth
    /// about the camera's up axis (negated: azimuth is clockwise-positive,
    /// right-hand rotation about up is counterclockwise).
    static func worldRay(
        cameraTransform: simd_float4x4,
        ray: SonarRay
    ) -> (origin: simd_float3, direction: simd_float3) {
        let azimuthRotation = simd_quatf(angle: -ray.azimuth, axis: cameraTransform.upVector)
        let elevationRotation = simd_quatf(angle: ray.elevation, axis: cameraTransform.rightVector)
        let direction = simd_normalize(azimuthRotation.act(elevationRotation.act(cameraTransform.forwardVector)))
        return (cameraTransform.translation, direction)
    }
}
