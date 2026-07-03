//
//  MeshAnchorSnapshot.swift
//  SpatialNav
//

import Foundation
import simd

/// Value snapshot of an ARMeshAnchor. Geometry extraction (vertices, classification)
/// is added in the hazard-analysis phase; identity + transform is enough for
/// session bring-up and coverage metrics.
nonisolated struct MeshAnchorSnapshot: Sendable, Equatable {
    let id: UUID
    let transform: simd_float4x4
    let updatedAt: TimeInterval
}
