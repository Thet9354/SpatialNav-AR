//
//  FeedbackProfile.swift
//  SpatialNav
//

import Foundation

/// User-configured sensory routing. Every `FeedbackEvent` passes through the active
/// profile; no subsystem talks to audio/haptics/speech directly.
nonisolated struct FeedbackProfile: Sendable, Equatable, Codable {
    nonisolated enum Mode: String, Sendable, Codable, CaseIterable {
        case audioDominant
        case hapticDominant
        case hybrid
        /// 100% haptic, richer vibration vocabulary; no audio dependency at all.
        case deafBlind
    }

    nonisolated enum Verbosity: String, Sendable, Codable, CaseIterable {
        case terse
        case normal
        case descriptive
    }

    nonisolated enum DistanceUnit: String, Sendable, Codable, CaseIterable {
        case meters
        case feet
        case steps
    }

    var mode: Mode
    var verbosity: Verbosity
    /// AVSpeechUtterance rate domain, 0...1.
    var speechRate: Float
    /// Obstacles farther than this (meters) produce no alerts.
    var minimumAlertDistance: Float
    var distanceUnit: DistanceUnit
    /// Used to convert meters to steps when `distanceUnit == .steps`.
    var strideLengthMeters: Float

    static let `default` = FeedbackProfile(
        mode: .hybrid,
        verbosity: .normal,
        speechRate: 0.5,
        minimumAlertDistance: 3.0,
        distanceUnit: .meters,
        strideLengthMeters: 0.7
    )
}
