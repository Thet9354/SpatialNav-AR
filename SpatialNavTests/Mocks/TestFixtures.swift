//
//  TestFixtures.swift
//  SpatialNavTests
//

import CoreVideo
import Foundation
import simd
@testable import SpatialNav

enum TestFixtures {
    static func pixelSnapshot(timestamp: TimeInterval = 0) -> PixelBufferSnapshot {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_32BGRA, nil, &buffer)
        return PixelBufferSnapshot(
            buffer: buffer!,
            timestamp: timestamp,
            cameraTransform: matrix_identity_float4x4,
            intrinsics: matrix_identity_float3x3,
            imageResolution: CGSize(width: 64, height: 64)
        )
    }
}
