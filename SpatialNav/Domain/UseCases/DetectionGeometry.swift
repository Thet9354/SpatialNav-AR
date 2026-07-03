//
//  DetectionGeometry.swift
//  SpatialNav
//

import CoreGraphics
import Foundation
import simd

/// Converts Vision detection coordinates into camera-relative sonar rays so
/// detections can be located with the same raycast machinery as obstacles.
///
/// Coordinate chain (app is portrait; Vision is handed the buffer with
/// orientation `.right`, i.e. the portrait image is the buffer rotated 90° CW):
/// Vision bbox (normalized, bottom-left origin, portrait) → normalized buffer
/// point (top-left origin, landscape) → pixel → intrinsics ray.
nonisolated enum DetectionGeometry {

    /// Center of a Vision bounding box, mapped into normalized buffer
    /// coordinates (top-left origin). Inverse of the 90° CW view rotation:
    /// bufferX = portraitY(top-left), bufferY = 1 - portraitX.
    static func bufferPoint(visionBoundingBox box: CGRect) -> CGPoint {
        let portraitXTopLeft = box.midX
        let portraitYTopLeft = 1 - box.midY
        return CGPoint(x: portraitYTopLeft, y: 1 - portraitXTopLeft)
    }

    /// Camera-relative ray through a normalized buffer point. Buffer y grows
    /// downward while camera-space y grows upward, hence the sign flip.
    static func sonarRay(
        bufferPoint point: CGPoint,
        intrinsics: simd_float3x3,
        imageResolution: CGSize
    ) -> SonarRay {
        let pixelX = Float(point.x) * Float(imageResolution.width)
        let pixelY = Float(point.y) * Float(imageResolution.height)
        let fx = intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y
        let direction = simd_normalize(simd_float3(
            (pixelX - cx) / fx,
            -(pixelY - cy) / fy,
            -1
        ))
        return SonarRay(
            azimuth: atan2(direction.x, -direction.z),
            elevation: asin(direction.y)
        )
    }

    static func sonarRay(
        visionBoundingBox box: CGRect,
        intrinsics: simd_float3x3,
        imageResolution: CGSize
    ) -> SonarRay {
        sonarRay(
            bufferPoint: bufferPoint(visionBoundingBox: box),
            intrinsics: intrinsics,
            imageResolution: imageResolution
        )
    }
}
