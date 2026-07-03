//
//  SonarRay.swift
//  SpatialNav
//

import Foundation
import simd

/// A ray expressed relative to the camera. Azimuth is radians clockwise-positive
/// (toward the user's right); elevation is radians up-positive.
nonisolated struct SonarRay: Sendable, Hashable {
    let azimuth: Float
    let elevation: Float

    /// A symmetric horizontal fan spanning `arc` radians, centered on forward.
    static func fan(count: Int, arc: Float, elevation: Float = 0) -> [SonarRay] {
        guard count > 1 else { return [SonarRay(azimuth: 0, elevation: elevation)] }
        let step = arc / Float(count - 1)
        return (0..<count).map { index in
            SonarRay(azimuth: -arc / 2 + step * Float(index), elevation: elevation)
        }
    }
}

nonisolated struct RaycastHit: Sendable, Equatable {
    let ray: SonarRay
    let distance: Float
    let worldPosition: simd_float3
}
