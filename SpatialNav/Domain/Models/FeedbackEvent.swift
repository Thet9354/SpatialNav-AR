//
//  FeedbackEvent.swift
//  SpatialNav
//

import Foundation

nonisolated enum FeedbackPriority: Int, Comparable, Sendable, Codable {
    case low, normal, high, critical

    static func < (lhs: FeedbackPriority, rhs: FeedbackPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The single event type every subsystem emits. Audio, haptic, and speech services
/// consume these; routing between them is decided by the active `FeedbackProfile`,
/// never by the emitting subsystem.
nonisolated struct FeedbackEvent: Sendable, Equatable {
    nonisolated enum Kind: Sendable, Equatable {
        case obstacleProximity
        case hazardWarning(Hazard.Kind)
        case navigationCue
        case itemPing
        case status
    }

    let kind: Kind
    let priority: FeedbackPriority
    let direction: ClockDirection?
    let distance: Float?
    let message: String?
}
