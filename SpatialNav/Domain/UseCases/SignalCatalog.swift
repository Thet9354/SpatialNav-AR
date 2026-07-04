//
//  SignalCatalog.swift
//  SpatialNav
//

import Foundation

/// One teachable signal: what it's called, what it means, and the event that
/// reproduces it on demand.
nonisolated struct SignalDemo: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let explanation: String
    let event: FeedbackEvent
}

/// The app's sensory language, in teaching order. Shown in the onboarding
/// tutorial and the Settings reference so the vocabulary is never a mystery.
nonisolated enum SignalCatalog {
    static let all: [SignalDemo] = [
        SignalDemo(
            id: "drop-off",
            title: "Drop-off warning",
            explanation: "Two heavy thuds and a rumble. The ground ahead falls away — stop.",
            event: FeedbackEvent(
                kind: .hazardWarning(.dropOff),
                priority: .critical,
                direction: .twelve,
                distance: 1.5,
                message: Hazard.Kind.dropOff.warningDescription
            )
        ),
        SignalDemo(
            id: "hazard",
            title: "Hazard alert",
            explanation: "Three sharp taps. Something needs attention, like stairs or a person ahead.",
            event: FeedbackEvent(
                kind: .hazardWarning(.stairsUp),
                priority: .high,
                direction: .twelve,
                distance: 1.5,
                message: Hazard.Kind.stairsUp.warningDescription
            )
        ),
        SignalDemo(
            id: "obstacle-near",
            title: "Obstacle very close",
            explanation: "A high, fast ping and a strong tap. Something is within arm's reach.",
            event: FeedbackEvent(
                kind: .obstacleProximity,
                priority: .normal,
                direction: .twelve,
                distance: 0.5,
                message: nil
            )
        ),
        SignalDemo(
            id: "obstacle-far",
            title: "Obstacle farther away",
            explanation: "A lower, slower ping and a soft tap. Something ahead, but not close yet.",
            event: FeedbackEvent(
                kind: .obstacleProximity,
                priority: .normal,
                direction: .twelve,
                distance: 3.5,
                message: nil
            )
        ),
        SignalDemo(
            id: "item-beacon",
            title: "Item beacon",
            explanation: "A light double tick, like a heartbeat. A saved item is calling from its location.",
            event: FeedbackEvent(
                kind: .itemPing,
                priority: .normal,
                direction: .twelve,
                distance: 1.5,
                message: nil
            )
        ),
        SignalDemo(
            id: "status",
            title: "Status update",
            explanation: "One gentle tap. SpatialNav is telling you something routine.",
            event: FeedbackEvent(
                kind: .status,
                priority: .low,
                direction: nil,
                distance: nil,
                message: nil
            )
        ),
    ]
}
