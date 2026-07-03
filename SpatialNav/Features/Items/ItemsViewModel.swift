//
//  ItemsViewModel.swift
//  SpatialNav
//

import Foundation
import Observation

@MainActor
@Observable
final class ItemsViewModel {
    private(set) var items: [SavedItem] = []
    private(set) var isBusy = false
    private(set) var message: String?
    var newItemName = ""

    private let findItem: FindItemUseCase

    init(findItem: FindItemUseCase) {
        self.findItem = findItem
    }

    func refresh() async {
        do {
            items = try await findItem.items()
        } catch {
            message = "Couldn't load saved items: \(error.localizedDescription)"
        }
    }

    func registerItem() async {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            message = "Give the item a name first."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let item = try await findItem.registerItem(named: name)
            newItemName = ""
            message = item.lastKnownPosition == nil
                ? "Saved “\(name)”, but I couldn't pin its position — try again facing the item straight on."
                : "Saved “\(name)” at the center of your view."
            await refresh()
        } catch {
            message = "Couldn't save the item — make sure the camera is running and pointed at it."
        }
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets where items.indices.contains(index) {
            try? await findItem.delete(items[index])
        }
        await refresh()
    }
}
