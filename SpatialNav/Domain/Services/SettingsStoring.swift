//
//  SettingsStoring.swift
//  SpatialNav
//

import Foundation

nonisolated protocol SettingsStoring: Sendable {
    func loadProfile() -> FeedbackProfile
    func save(_ profile: FeedbackProfile)
}
