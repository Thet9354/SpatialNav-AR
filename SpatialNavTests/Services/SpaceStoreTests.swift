//
//  SpaceStoreTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct SpaceStoreTests {

    private func makeStore() -> SpaceStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpaceStoreTests-\(UUID().uuidString)", isDirectory: true)
        return SpaceStore(directory: directory)
    }

    private func makeSpace(name: String) -> SavedSpace {
        SavedSpace(id: UUID(), name: name, createdAt: .now, waypoints: [], items: [])
    }

    @Test func savedSpacesIsEmptyInitially() async throws {
        let store = makeStore()
        #expect(try await store.savedSpaces().isEmpty)
    }

    @Test func saveThenLoadRoundTripsMetadataAndMapData() async throws {
        let store = makeStore()
        let space = makeSpace(name: "Living Room")
        let mapData = Data("fake-world-map".utf8)

        try await store.save(space, worldMapData: mapData)

        let spaces = try await store.savedSpaces()
        #expect(spaces == [space])
        #expect(try await store.worldMapData(for: space) == mapData)
    }

    @Test func savingSameSpaceIdUpdatesInsteadOfDuplicating() async throws {
        let store = makeStore()
        var space = makeSpace(name: "Kitchen")
        try await store.save(space, worldMapData: Data("v1".utf8))
        space.name = "Kitchen (rescanned)"
        try await store.save(space, worldMapData: Data("v2".utf8))

        let spaces = try await store.savedSpaces()
        #expect(spaces.count == 1)
        #expect(spaces[0].name == "Kitchen (rescanned)")
        #expect(try await store.worldMapData(for: space) == Data("v2".utf8))
    }

    @Test func deleteRemovesMetadataAndMapData() async throws {
        let store = makeStore()
        let space = makeSpace(name: "Bedroom")
        try await store.save(space, worldMapData: Data("map".utf8))

        try await store.delete(space)

        #expect(try await store.savedSpaces().isEmpty)
        await #expect(throws: SpaceStoreError.mapDataMissing) {
            try await store.worldMapData(for: space)
        }
    }

    @Test func missingMapDataThrows() async throws {
        let store = makeStore()
        await #expect(throws: SpaceStoreError.mapDataMissing) {
            try await store.worldMapData(for: makeSpace(name: "Ghost"))
        }
    }
}
