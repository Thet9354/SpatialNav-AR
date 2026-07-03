//
//  SpacesViewModel.swift
//  SpatialNav
//

import Foundation
import Observation

@MainActor
@Observable
final class SpacesViewModel {
    private(set) var spaces: [SavedSpace] = []
    private(set) var isBusy = false
    private(set) var message: String?
    var newSpaceName = ""

    private let store: any SpaceStoring
    private let provider: any ARSessionProviding

    init(store: any SpaceStoring, provider: any ARSessionProviding) {
        self.store = store
        self.provider = provider
    }

    func refresh() async {
        do {
            spaces = try await store.savedSpaces()
        } catch {
            message = "Couldn't load saved spaces: \(error.localizedDescription)"
        }
    }

    func saveCurrentSpace() async {
        let name = newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            message = "Give this space a name first."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let mapData = try await provider.captureWorldMapData()
            let space = SavedSpace(id: UUID(), name: name, createdAt: .now, waypoints: [], items: [])
            try await store.save(space, worldMapData: mapData)
            newSpaceName = ""
            message = "Saved “\(name)”."
            await refresh()
        } catch {
            // Most common cause: the room isn't sufficiently mapped yet.
            message = "Couldn't save this space yet — keep scanning the room, then try again."
        }
    }

    func load(_ space: SavedSpace) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let mapData = try await store.worldMapData(for: space)
            try provider.restoreWorldMap(from: mapData)
            message = "Loading “\(space.name)” — look around slowly so I can find your position."
        } catch {
            message = "Couldn't load “\(space.name)”: \(error.localizedDescription)"
        }
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets where spaces.indices.contains(index) {
            try? await store.delete(spaces[index])
        }
        await refresh()
    }
}
