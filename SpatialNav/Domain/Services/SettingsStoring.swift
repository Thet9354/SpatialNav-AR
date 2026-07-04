//
//  SettingsStoring.swift
//  SpatialNav
//

import Foundation

nonisolated protocol SettingsStoring: Sendable {
    /// False until the user has completed onboarding and a profile was saved.
    var hasSavedProfile: Bool { get }
    func loadProfile() -> FeedbackProfile
    func save(_ profile: FeedbackProfile)
}
