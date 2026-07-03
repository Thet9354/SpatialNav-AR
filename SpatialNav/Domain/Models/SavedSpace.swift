//
//  SavedSpace.swift
//  SpatialNav
//

import Foundation
import simd

/// Metadata for a persisted indoor environment. The ARWorldMap blob itself is
/// stored as an opaque compressed file next to this record; anchor metadata lives
/// here in a sidecar so it survives even if the map must be rebuilt.
nonisolated struct SavedSpace: Identifiable, Sendable, Equatable, Codable {
    let id: UUID
    var name: String
    let createdAt: Date
    var waypoints: [Waypoint]
    var items: [SavedItem]
}

nonisolated struct Waypoint: Identifiable, Sendable, Equatable, Codable {
    let id: UUID
    var name: String
    var position: simd_float3
}

nonisolated struct SavedItem: Identifiable, Sendable, Equatable, Codable {
    let id: UUID
    var name: String
    var lastKnownPosition: simd_float3?
    /// Serialized VNFeaturePrintObservation data for re-acquisition when the item moved.
    var featurePrintData: Data?
}
