//
//  SpacesSheet.swift
//  SpatialNav
//

import SwiftUI

struct SpacesSheet: View {
    @State private var viewModel: SpacesViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SpacesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Save this space") {
                    TextField("Space name (e.g. Living Room)", text: $viewModel.newSpaceName)
                        .accessibilityLabel("Name for the current space")
                    Button {
                        Task { await viewModel.saveCurrentSpace() }
                    } label: {
                        Label("Save Current Space", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.isBusy)
                }

                Section("Saved spaces") {
                    if viewModel.spaces.isEmpty {
                        Text("No saved spaces yet. Scan a room, then save it to return later.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.spaces) { space in
                        Button {
                            Task {
                                await viewModel.load(space)
                                dismiss()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(space.name)
                                    .font(.headline)
                                Text(space.createdAt, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(viewModel.isBusy)
                        .accessibilityHint("Loads this space and finds your position in it")
                    }
                    .onDelete { offsets in
                        Task { await viewModel.delete(at: offsets) }
                    }
                }

                if let message = viewModel.message {
                    Section {
                        Text(message)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Saved Spaces")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.refresh() }
        }
    }
}
