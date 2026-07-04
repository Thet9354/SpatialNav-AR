//
//  SettingsStoreTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct SettingsStoreTests {

    private func makeStore() -> SettingsStore {
        let suiteName = "SettingsStoreTests-\(UUID().uuidString)"
        return SettingsStore(defaults: UserDefaults(suiteName: suiteName)!)
    }

    @Test func startsWithNoSavedProfileAndReturnsDefault() {
        let store = makeStore()
        #expect(!store.hasSavedProfile)
        #expect(store.loadProfile() == .default)
    }

    @Test func savedProfileRoundTrips() {
        let store = makeStore()
        var profile = FeedbackProfile.default
        profile.mode = .deafBlind
        profile.verbosity = .terse
        profile.speechRate = 0.62
        profile.minimumAlertDistance = 1.5
        profile.distanceUnit = .steps
        profile.strideLengthMeters = 0.65

        store.save(profile)

        #expect(store.hasSavedProfile)
        #expect(store.loadProfile() == profile)
    }

    @Test func savingAgainOverwrites() {
        let store = makeStore()
        var profile = FeedbackProfile.default
        profile.mode = .audioDominant
        store.save(profile)
        profile.mode = .hapticDominant
        store.save(profile)
        #expect(store.loadProfile().mode == .hapticDominant)
    }
}
