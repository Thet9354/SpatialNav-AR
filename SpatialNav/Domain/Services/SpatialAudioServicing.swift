//
//  SpatialAudioServicing.swift
//  SpatialNav
//

import Foundation
import simd

nonisolated protocol SpatialAudioServicing: Sendable {
    func startEngine() async throws
    func stopEngine() async
    /// Listener pose must track the camera so HRTF panning matches the real room.
    func updateListener(transform: simd_float4x4) async
    /// Position nil means non-spatial (interface) feedback.
    func play(_ event: FeedbackEvent, at position: simd_float3?) async
}
