//
//  ItemsSheet.swift
//  SpatialNav
//

import SwiftUI

struct ItemsSheet: View {
    @State private var viewModel: ItemsViewModel
    private let onGuide: (SavedItem) -> Void
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ItemsViewModel, onGuide: @escaping (SavedItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onGuide = onGuide
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Register an item") {
                    TextField("Item name (e.g. Keys)", text: $viewModel.newItemName)
                        .accessibilityLabel("Name for the item at the center of your view")
                    Button {
                        Task { await viewModel.registerItem() }
                    } label: {
                        Label("Save What I'm Pointing At", systemImage: "viewfinder")
                    }
                    .disabled(viewModel.isBusy)
                    .accessibilityHint("Saves the item at the center of the camera view with your position")
                }

                Section("Saved items") {
                    if viewModel.items.isEmpty {
                        Text("No saved items yet. Point the camera at something you misplace often and save it.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.items) { item in
                        Button {
                            onGuide(item)
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                if item.lastKnownPosition == nil {
                                    Text("No position")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(item.lastKnownPosition == nil)
                        .accessibilityHint("Starts guiding you toward this item")
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
            .navigationTitle("My Items")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.refresh() }
        }
    }
}
