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

        var warningDescription: String {
            switch self {
            case .dropOff: "Caution — drop-off ahead"
            case .stairsUp: "Stairs going up ahead"
            case .stairsDown: "Caution — stairs going down"
            case .headHeight: "Head-height obstacle ahead"
            case .person: "Person ahead"
            case .obstacle: "Obstacle ahead"
            }
        }
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
