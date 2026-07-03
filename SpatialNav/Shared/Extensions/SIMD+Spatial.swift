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
    /// Converts a SonarRay into a world-space ray.
    /// Elevation is applied about the right axis first, then azimuth about the
    /// up axis (negated: azimuth is clockwise-positive, right-hand rotation
    /// about up is counterclockwise). Camera-relative rays use the camera's
    /// axes; gravity-aligned rays use the world up axis and the camera's
    /// heading projected onto the horizontal plane, so device pitch/roll
    /// cannot tilt them.
    static func worldRay(
        cameraTransform: simd_float4x4,
        ray: SonarRay
    ) -> (origin: simd_float3, direction: simd_float3) {
        let forward: simd_float3
        let up: simd_float3
        let right: simd_float3

        gravity: if ray.gravityAligned {
            // ARKit world alignment is .gravity, so world +Y is up.
            let worldUp = simd_float3(0, 1, 0)
            let cameraForward = cameraTransform.forwardVector
            let horizontal = cameraForward - worldUp * simd_dot(cameraForward, worldUp)
            let length = simd_length(horizontal)
            // Camera pointing near straight up/down: heading is undefined,
            // fall back to camera-relative axes.
            guard length > 1e-4 else { break gravity }
            forward = horizontal / length
            up = worldUp
            right = simd_normalize(simd_cross(forward, worldUp))
            return compose(origin: cameraTransform.translation, forward: forward, up: up, right: right, ray: ray)
        }

        return compose(
            origin: cameraTransform.translation,
            forward: cameraTransform.forwardVector,
            up: cameraTransform.upVector,
            right: cameraTransform.rightVector,
            ray: ray
        )
    }

    private static func compose(
        origin: simd_float3,
        forward: simd_float3,
        up: simd_float3,
        right: simd_float3,
        ray: SonarRay
    ) -> (origin: simd_float3, direction: simd_float3) {
        let azimuthRotation = simd_quatf(angle: -ray.azimuth, axis: up)
        let elevationRotation = simd_quatf(angle: ray.elevation, axis: right)
        let direction = simd_normalize(azimuthRotation.act(elevationRotation.act(forward)))
        return (origin, direction)
    }
}
