//
//  OnboardingFlowView.swift
//  SpatialNav
//

import SwiftUI

/// Two-step first launch: choose a feedback style, then learn the signals.
struct OnboardingFlowView: View {
    let signalPlayer: SignalPlayer
    let onComplete: (FeedbackProfile) -> Void

    @State private var chosenProfile: FeedbackProfile?

    var body: some View {
        if let profile = chosenProfile {
            SensoryTutorialView(profile: profile, player: signalPlayer) {
                onComplete(profile)
            }
        } else {
            OnboardingView { profile in
                chosenProfile = profile
            }
        }
    }
}
