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
    private let signalPlayer: SignalPlayer
    private let onChange: (FeedbackProfile) -> Void

    init(
        store: any SettingsStoring,
        signalPlayer: SignalPlayer,
        onChange: @escaping (FeedbackProfile) -> Void
    ) {
        self.profile = store.loadProfile()
        self.store = store
        self.signalPlayer = signalPlayer
        self.onChange = onChange
    }

    func play(_ demo: SignalDemo) {
        signalPlayer.prepare()
        signalPlayer.play(demo.event, profile: profile)
    }
}
