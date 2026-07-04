//
//  SignalsReferenceView.swift
//  SpatialNav
//

import SwiftUI

/// The signal vocabulary, replayable anytime — the tutorial's permanent home.
struct SignalsReferenceView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(SignalCatalog.all) { demo in
                    SignalDemoRow(demo: demo) {
                        viewModel.play(demo)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Signals")
        .navigationBarTitleDisplayMode(.inline)
    }
}
