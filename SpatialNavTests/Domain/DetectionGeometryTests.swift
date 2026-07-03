//
//  DetectionGeometryTests.swift
//  SpatialNavTests
//

import CoreGraphics
import Foundation
import Testing
import simd
@testable import SpatialNav

struct DetectionGeometryTests {

    // fx = fy = 1000, principal point at image center of a 1920×1080 buffer.
    private let intrinsics = simd_float3x3(columns: (
        simd_float3(1000, 0, 0),
        simd_float3(0, 1000, 0),
        simd_float3(960, 540, 1)
    ))
    private let resolution = CGSize(width: 1920, height: 1080)

    @Test func imageCenterMapsToImageCenter() {
        let box = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2) // centered box
        let point = DetectionGeometry.bufferPoint(visionBoundingBox: box)
        #expect(abs(point.x - 0.5) < 1e-9)
        #expect(abs(point.y - 0.5) < 1e-9)
    }

    @Test func portraitTopMapsToBufferLeft() {
        // Box near the visual top of the portrait image (Vision origin is bottom-left,
        // so high midY). Rotating 90° CW put the buffer's left column at the visual top.
        let box = CGRect(x: 0.4, y: 0.85, width: 0.2, height: 0.1) // midY(bl) = 0.9
        let point = DetectionGeometry.bufferPoint(visionBoundingBox: box)
        #expect(abs(point.x - 0.1) < 1e-6) // 1 - 0.9 → near buffer left
        #expect(abs(point.y - 0.5) < 1e-6)
    }

    @Test func centerPixelRayIsStraightAhead() {
        let ray = DetectionGeometry.sonarRay(
            bufferPoint: CGPoint(x: 0.5, y: 0.5),
            intrinsics: intrinsics,
            imageResolution: resolution
        )
        #expect(abs(ray.azimuth) < 1e-6)
        #expect(abs(ray.elevation) < 1e-6)
    }

    @Test func pixelOneFocalLengthRightIs45DegreesAzimuth() {
        // px = cx + fx → camera-space direction (1, 0, -1) → azimuth π/4.
        let point = CGPoint(x: Double(960 + 1000) / 1920, y: 0.5)
        let ray = DetectionGeometry.sonarRay(
            bufferPoint: point,
            intrinsics: intrinsics,
            imageResolution: resolution
        )
        #expect(abs(ray.azimuth - .pi / 4) < 1e-5)
        #expect(abs(ray.elevation) < 1e-5)
    }

    @Test func pixelAboveCenterHasPositiveElevation() {
        // Buffer y grows downward, so a pixel above center must look upward.
        let point = CGPoint(x: 0.5, y: 0.25) // py = 270, 270 px above cy
        let ray = DetectionGeometry.sonarRay(
            bufferPoint: point,
            intrinsics: intrinsics,
            imageResolution: resolution
        )
        #expect(ray.elevation > 0)
        #expect(abs(ray.azimuth) < 1e-5)
    }
}
