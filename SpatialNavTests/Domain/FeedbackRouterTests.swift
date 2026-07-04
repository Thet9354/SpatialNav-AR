//
//  FeedbackRouterTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct FeedbackRouterTests {

    private let router = FeedbackRouter()

    private func event(kind: FeedbackEvent.Kind = .obstacleProximity, priority: FeedbackPriority) -> FeedbackEvent {
        FeedbackEvent(kind: kind, priority: priority, direction: nil, distance: nil, message: "test")
    }

    private func profile(mode: FeedbackProfile.Mode, verbosity: FeedbackProfile.Verbosity = .normal) -> FeedbackProfile {
        var profile = FeedbackProfile.default
        profile.mode = mode
        profile.verbosity = verbosity
        return profile
    }

    @Test func hybridUsesEveryChannel() {
        let channels = router.channels(for: event(priority: .normal), profile: profile(mode: .hybrid))
        #expect(channels == FeedbackRouter.Channels(speech: true, spatialAudio: true, haptics: true))
    }

    @Test func deafBlindNeverUsesAudio() {
        for priority in [FeedbackPriority.low, .normal, .high, .critical] {
            let channels = router.channels(for: event(priority: priority), profile: profile(mode: .deafBlind))
            #expect(!channels.speech)
            #expect(!channels.spatialAudio)
            #expect(channels.haptics)
        }
    }

    @Test func audioDominantReservesHapticsForCritical() {
        let normal = router.channels(for: event(priority: .normal), profile: profile(mode: .audioDominant))
        #expect(normal.speech && normal.spatialAudio && !normal.haptics)

        let critical = router.channels(for: event(priority: .critical), profile: profile(mode: .audioDominant))
        #expect(critical.haptics)
    }

    @Test func hapticDominantSpeaksOnlySeriousAlerts() {
        let normal = router.channels(for: event(priority: .normal), profile: profile(mode: .hapticDominant))
        #expect(!normal.speech && !normal.spatialAudio && normal.haptics)

        let high = router.channels(for: event(priority: .high), profile: profile(mode: .hapticDominant))
        #expect(high.speech && high.haptics)
    }

    @Test func terseVerbositySilencesLowPriorityChatter() {
        let channels = router.channels(
            for: event(kind: .status, priority: .low),
            profile: profile(mode: .hybrid, verbosity: .terse)
        )
        #expect(!channels.speech)
        // Critical is never silenced by verbosity.
        let critical = router.channels(
            for: event(kind: .hazardWarning(.dropOff), priority: .critical),
            profile: profile(mode: .hybrid, verbosity: .terse)
        )
        #expect(critical.speech)
    }
}
