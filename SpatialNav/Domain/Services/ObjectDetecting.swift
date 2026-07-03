//
//  ObjectDetecting.swift
//  SpatialNav
//

import CoreVideo
import Foundation
import simd

/// Transfer wrapper for a camera frame handed to the ML pipeline.
/// Invariant (audited): exactly one consumer receives each snapshot, and the
/// buffer is released as soon as inference completes — never queued. This is
/// what makes `@unchecked Sendable` sound and keeps ARKit's buffer pool healthy.
nonisolated struct PixelBufferSnapshot: @unchecked Sendable {
    let buffer: CVPixelBuffer
    let timestamp: TimeInterval
    let cameraTransform: simd_float4x4
    /// Camera intrinsics for the buffer in its native (landscape) orientation.
    let intrinsics: simd_float3x3
    let imageResolution: CGSize
}

nonisolated protocol ObjectDetecting: Sendable {
    func detect(in snapshot: PixelBufferSnapshot) async throws -> [DetectedObject]
}
