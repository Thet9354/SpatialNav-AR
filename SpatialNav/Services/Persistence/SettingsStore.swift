//
//  SettingsStore.swift
//  SpatialNav
//

import Foundation

/// UserDefaults-backed profile storage. UserDefaults is documented thread-safe,
/// which is what the @unchecked Sendable relies on.
nonisolated struct SettingsStore: SettingsStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let profileKey = "com.thetpine.spatialnav.feedback-profile"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSavedProfile: Bool {
        defaults.data(forKey: profileKey) != nil
    }

    func loadProfile() -> FeedbackProfile {
        guard
            let data = defaults.data(forKey: profileKey),
            let profile = try? JSONDecoder().decode(FeedbackProfile.self, from: data)
        else {
            return .default
        }
        return profile
    }

    func save(_ profile: FeedbackProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }
}
