//
//  SignalDemoRow.swift
//  SpatialNav
//

import SwiftUI

/// One tappable signal in the tutorial and the Settings reference:
/// the whole row plays the signal, so the target is as large as possible.
struct SignalDemoRow: View {
    let demo: SignalDemo
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(demo.title)
                        .font(.headline)
                    Text(demo.explanation)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(demo.title). \(demo.explanation)")
        .accessibilityHint("Plays this signal so you can learn it")
    }
}
