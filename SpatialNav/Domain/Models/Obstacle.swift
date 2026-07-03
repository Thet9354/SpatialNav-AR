//
//  Obstacle.swift
//  SpatialNav
//

import Foundation
import simd

nonisolated struct Obstacle: Identifiable, Sendable, Equatable {
    /// Height band relative to the user; head-height obstacles are the ones
    /// canes and guide dogs cannot warn about.
    nonisolated enum Elevation: Sendable, Equatable {
        case floor
        case waist
        case head
    }

    let id: UUID
    let worldPosition: simd_float3
    let distance: Float
    let direction: ClockDirection
    let elevation: Elevation
}
