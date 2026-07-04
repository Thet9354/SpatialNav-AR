//
//  SensoryTutorialView.swift
//  SpatialNav
//

import SwiftUI

/// Step two of onboarding: teach the sensory vocabulary before the first walk.
/// Each row plays its real signal through the user's chosen profile.
struct SensoryTutorialView: View {
    let profile: FeedbackProfile
    let player: SignalPlayer
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Learn the Signals")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("SpatialNav speaks in sounds and vibrations. Tap each one to feel and hear it — you can replay these anytime from Settings.")
                    .font(.body)

                ForEach(SignalCatalog.all) { demo in
                    SignalDemoRow(demo: demo) {
                        player.play(demo.event, profile: profile)
                    }
                }

                // Inside the scroll content, not a floating inset: rows can
                // never sit behind it (contrast-audit finding), and the user
                // scrolls past every signal before starting.
                Button {
                    onFinish()
                } label: {
                    // .title3.bold, not .headline: white-on-blue only meets
                    // the contrast requirement at large text sizes.
                    Text("Start SpatialNav")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .accessibilityHint("Finishes setup and begins guidance")
            }
            .padding(24)
        }
        .onAppear {
            player.prepare()
        }
    }
}
