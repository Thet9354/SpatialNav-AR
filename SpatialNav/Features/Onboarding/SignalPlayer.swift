//
//  SignalPlayer.swift
//  SpatialNav
//

import Foundation

/// Plays a signal demo through the same engines and profile routing the live
/// app uses, so what the user learns is exactly what they'll feel and hear.
@MainActor
final class SignalPlayer {
    private let audio: any SpatialAudioServicing
    private let haptics: any HapticServicing
    private let router = FeedbackRouter()

    init(audio: any SpatialAudioServicing, haptics: any HapticServicing) {
        self.audio = audio
        self.haptics = haptics
    }

    /// Warms the audio engine so the first demo doesn't stutter.
    func prepare() {
        let audio = audio
        Task { try? await audio.startEngine() }
    }

    func play(_ event: FeedbackEvent, profile: FeedbackProfile) {
        let channels = router.channels(for: event, profile: profile)
        let audio = audio
        let haptics = haptics
        Task {
            if channels.spatialAudio {
                await audio.play(event, at: nil)
            }
            if channels.haptics {
                await haptics.play(event)
            }
        }
    }
}
