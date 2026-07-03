//
//  ItemStoreTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
import simd
@testable import SpatialNav

struct ItemStoreTests {

    private func makeStore() -> ItemStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ItemStoreTests-\(UUID().uuidString)", isDirectory: true)
        return ItemStore(directory: directory)
    }

    private func makeItem(name: String) -> SavedItem {
        SavedItem(
            id: UUID(),
            name: name,
            lastKnownPosition: simd_float3(1, 0.8, -2),
            featurePrintData: Data("print".utf8)
        )
    }

    @Test func startsEmpty() async throws {
        let store = makeStore()
        #expect(try await store.items().isEmpty)
    }

    @Test func saveAndReloadRoundTrips() async throws {
        let store = makeStore()
        let item = makeItem(name: "Keys")
        try await store.save(item)
        let items = try await store.items()
        #expect(items == [item])
    }

    @Test func savingSameIdUpdates() async throws {
        let store = makeStore()
        var item = makeItem(name: "Wallet")
        try await store.save(item)
        item.name = "Brown Wallet"
        try await store.save(item)
        let items = try await store.items()
        #expect(items.count == 1)
        #expect(items[0].name == "Brown Wallet")
    }

    @Test func deleteRemovesItem() async throws {
        let store = makeStore()
        let keep = makeItem(name: "Keys")
        let drop = makeItem(name: "Mug")
        try await store.save(keep)
        try await store.save(drop)
        try await store.delete(drop)
        #expect(try await store.items() == [keep])
    }
}
