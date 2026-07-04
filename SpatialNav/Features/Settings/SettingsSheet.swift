//
//  SettingsSheet.swift
//  SpatialNav
//

import SwiftUI

struct SettingsSheet: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        SignalsReferenceView(viewModel: viewModel)
                    } label: {
                        Label("What do the signals mean?", systemImage: "waveform")
                    }
                    .accessibilityHint("Replays each sound and vibration with its meaning")
                }

                Section("Feedback style") {
                    Picker("Mode", selection: $viewModel.profile.mode) {
                        Text("Sound and Vibration").tag(FeedbackProfile.Mode.hybrid)
                        Text("Mostly Sound").tag(FeedbackProfile.Mode.audioDominant)
                        Text("Mostly Vibration").tag(FeedbackProfile.Mode.hapticDominant)
                        Text("Vibration Only").tag(FeedbackProfile.Mode.deafBlind)
                    }
                    Picker("Detail level", selection: $viewModel.profile.verbosity) {
                        Text("Terse").tag(FeedbackProfile.Verbosity.terse)
                        Text("Normal").tag(FeedbackProfile.Verbosity.normal)
                        Text("Descriptive").tag(FeedbackProfile.Verbosity.descriptive)
                    }
                }

                Section("Speech") {
                    VStack(alignment: .leading) {
                        Text("Speaking rate")
                        Slider(value: $viewModel.profile.speechRate, in: 0.3...0.7)
                            .accessibilityLabel("Speaking rate")
                            .accessibilityValue(speechRateDescription)
                    }
                }

                Section("Alerts") {
                    VStack(alignment: .leading) {
                        Text("Alert distance: \(String(format: "%.1f", viewModel.profile.minimumAlertDistance)) m")
                        Slider(value: $viewModel.profile.minimumAlertDistance, in: 1...4, step: 0.5)
                            .accessibilityLabel("Obstacle alert distance")
                            .accessibilityValue("\(String(format: "%.1f", viewModel.profile.minimumAlertDistance)) meters")
                    }
                    Picker("Distances spoken in", selection: $viewModel.profile.distanceUnit) {
                        Text("Meters").tag(FeedbackProfile.DistanceUnit.meters)
                        Text("Feet").tag(FeedbackProfile.DistanceUnit.feet)
                        Text("Steps").tag(FeedbackProfile.DistanceUnit.steps)
                    }
                    if viewModel.profile.distanceUnit == .steps {
                        VStack(alignment: .leading) {
                            Text("Stride length: \(Int(viewModel.profile.strideLengthMeters * 100)) cm")
                            Slider(value: $viewModel.profile.strideLengthMeters, in: 0.4...1.0, step: 0.05)
                                .accessibilityLabel("Stride length")
                                .accessibilityValue("\(Int(viewModel.profile.strideLengthMeters * 100)) centimeters")
                        }
                    }
                }

                Section {
                    Toggle("Show scan overlay", isOn: $viewModel.profile.showScanOverlay)
                        .accessibilityHint("Draws the room scan on screen so a sighted companion can see what SpatialNav senses")
                } footer: {
                    Text("For sighted companions and instructors. Has no effect on audio or vibration guidance.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var speechRateDescription: String {
        switch viewModel.profile.speechRate {
        case ..<0.42: "Slow"
        case ..<0.55: "Normal"
        default: "Fast"
        }
    }
}
