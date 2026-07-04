//
//  SettingsViewModel.swift
//  SpatialNav
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var profile: FeedbackProfile {
        didSet {
            guard profile != oldValue else { return }
            store.save(profile)
            onChange(profile)
        }
    }

    private let store: any SettingsStoring
    private let onChange: (FeedbackProfile) -> Void

    init(store: any SettingsStoring, onChange: @escaping (FeedbackProfile) -> Void) {
        self.profile = store.loadProfile()
        self.store = store
        self.onChange = onChange
    }
}
