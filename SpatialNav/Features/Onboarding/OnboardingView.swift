//
//  OnboardingView.swift
//  SpatialNav
//

import SwiftUI

/// First-launch profile choice. Large targets, VoiceOver-first copy; everything
/// here can be changed later in Settings.
struct OnboardingView: View {
    let onComplete: (FeedbackProfile) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to SpatialNav")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("SpatialNav senses the space around you and warns about obstacles and hazards. How should it talk to you? You can change this anytime in Settings.")
                    .font(.body)

                VStack(spacing: 12) {
                    modeButton(
                        mode: .hybrid,
                        title: "Sound and Vibration",
                        description: "Spatial sound pings, spoken alerts, and vibration patterns together."
                    )
                    modeButton(
                        mode: .audioDominant,
                        title: "Mostly Sound",
                        description: "Spatial pings and speech lead. Vibration only for serious hazards."
                    )
                    modeButton(
                        mode: .hapticDominant,
                        title: "Mostly Vibration",
                        description: "Vibration patterns lead. Speech only for serious hazards."
                    )
                    modeButton(
                        mode: .deafBlind,
                        title: "Vibration Only",
                        description: "Everything through distinct vibration patterns. No audio needed."
                    )
                }
            }
            .padding(24)
        }
    }

    private func modeButton(mode: FeedbackProfile.Mode, title: String, description: String) -> some View {
        Button {
            var profile = FeedbackProfile.default
            profile.mode = mode
            onComplete(profile)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                // .primary, not .secondary: on the card fill, secondary text
                // fails the accessibility contrast audit (low-vision users are
                // this app's audience). Hierarchy comes from the font instead.
                Text(description)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Selects this feedback style and starts SpatialNav")
    }
}
