//
//  FeedbackRouter.swift
//  SpatialNav
//

import Foundation

/// The single place that decides which sensory channels carry an event, based
/// on the user's profile. Subsystems emit events; they never choose channels.
nonisolated struct FeedbackRouter: Sendable {
    nonisolated struct Channels: Sendable, Equatable {
        var speech: Bool
        var spatialAudio: Bool
        var haptics: Bool
    }

    func channels(for event: FeedbackEvent, profile: FeedbackProfile) -> Channels {
        var channels: Channels = switch profile.mode {
        case .hybrid:
            Channels(speech: true, spatialAudio: true, haptics: true)
        case .audioDominant:
            // Haptics reserved for the alerts that must never be missed.
            Channels(speech: true, spatialAudio: true, haptics: event.priority >= .critical)
        case .hapticDominant:
            Channels(speech: event.priority >= .high, spatialAudio: false, haptics: true)
        case .deafBlind:
            // Zero audio dependency, richer haptic vocabulary carries everything.
            Channels(speech: false, spatialAudio: false, haptics: true)
        }
        if profile.verbosity == .terse, event.priority <= .low {
            channels.speech = false
        }
        return channels
    }
}
