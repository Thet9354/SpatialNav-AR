//
//  DetectedObject.swift
//  SpatialNav
//

import CoreGraphics
import Foundation
import simd

nonisolated struct DetectedObject: Identifiable, Sendable, Equatable {
    let id: UUID
    let label: String
    let confidence: Float
    /// Normalized image coordinates (Vision convention, origin bottom-left).
    let boundingBox: CGRect
    /// Filled once the detection is corroborated by a raycast against the scene mesh.
    let worldPosition: simd_float3?
    /// Camera distance (meters) at the corroborating raycast.
    let distance: Float?
    let direction: ClockDirection?
}
