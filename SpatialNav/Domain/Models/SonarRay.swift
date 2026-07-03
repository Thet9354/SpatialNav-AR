//
//  SonarRay.swift
//  SpatialNav
//

import Foundation
import simd

/// A ray expressed relative to the camera. Azimuth is radians clockwise-positive
/// (toward the user's right); elevation is radians up-positive.
///
/// `gravityAligned` rays measure elevation from the world horizon instead of the
/// camera's pitch (azimuth still follows the camera's heading). Floor probes use
/// this so tilting the phone up at a shelf doesn't swing them onto furniture.
nonisolated struct SonarRay: Sendable, Hashable {
    let azimuth: Float
    let elevation: Float
    var gravityAligned: Bool = false

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
    /// Unit normal of the struck surface, when the platform provides one.
    /// Distinguishes a stair tread (faces up) from a furniture front (faces
    /// sideways) at the same hit point — position alone cannot.
    let surfaceNormal: simd_float3?

    init(ray: SonarRay, distance: Float, worldPosition: simd_float3, surfaceNormal: simd_float3? = nil) {
        self.ray = ray
        self.distance = distance
        self.worldPosition = worldPosition
        self.surfaceNormal = surfaceNormal
    }
}
