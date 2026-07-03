//
//  ItemGuidance.swift
//  SpatialNav
//

import Foundation
import simd

/// Live guidance toward a saved item's world position, expressed in the same
/// clock-face terms as everything else the user hears.
nonisolated struct ItemGuidance: Sendable, Equatable {
    let distance: Float
    let direction: ClockDirection
    /// Positive when the item is above the camera (e.g. on a shelf).
    let heightDelta: Float

    /// Pure bearing math: azimuth is the signed horizontal angle from the
    /// camera's heading to the target, clockwise-positive. Pitch is ignored so
    /// looking down at the phone doesn't change the reported direction.
    static func toward(_ target: simd_float3, from cameraTransform: simd_float4x4) -> ItemGuidance {
        let camera = cameraTransform.translation
        let delta = target - camera
        let distance = simd_length(delta)
        let heightDelta = delta.y

        let worldUp = simd_float3(0, 1, 0)
        let forward = cameraTransform.forwardVector
        let forwardHorizontal = forward - worldUp * simd_dot(forward, worldUp)
        let deltaHorizontal = simd_float3(delta.x, 0, delta.z)

        guard simd_length(forwardHorizontal) > 1e-4, simd_length(deltaHorizontal) > 1e-4 else {
            return ItemGuidance(distance: distance, direction: .twelve, heightDelta: heightDelta)
        }

        let f = simd_normalize(forwardHorizontal)
        let d = simd_normalize(deltaHorizontal)
        // Counterclockwise angle about world up, negated for clockwise-positive bearings.
        let bearing = -atan2(simd_dot(simd_cross(f, d), worldUp), simd_dot(f, d))
        return ItemGuidance(
            distance: distance,
            direction: ClockDirection(bearing: bearing),
            heightDelta: heightDelta
        )
    }
}
