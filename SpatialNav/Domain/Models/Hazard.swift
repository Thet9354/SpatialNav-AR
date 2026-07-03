//
//  Hazard.swift
//  SpatialNav
//

import Foundation

nonisolated struct Hazard: Identifiable, Sendable, Equatable {
    nonisolated enum Kind: Sendable, Equatable {
        case dropOff
        case stairsUp
        case stairsDown
        case headHeight
        case person
        case obstacle
    }

    let id: UUID
    let kind: Kind
    let distance: Float
    let direction: ClockDirection

    var priority: FeedbackPriority {
        switch kind {
        case .dropOff, .stairsDown: .critical
        case .headHeight, .person, .stairsUp: .high
        case .obstacle: .normal
        }
    }
}
