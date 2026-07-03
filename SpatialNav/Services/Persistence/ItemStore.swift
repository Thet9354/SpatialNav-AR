//
//  ItemStore.swift
//  SpatialNav
//

import Foundation

/// File-backed store for registered personal items (items.json). Positions are
/// world coordinates of the space the item was saved in; the feature-print blob
/// rides along for future visual re-acquisition.
actor ItemStore: ItemStoring {
    private let directory: URL
    private var cache: [SavedItem]?

    init(directory: URL) {
        self.directory = directory
    }

    static func defaultDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("Items", isDirectory: true)
    }

    func items() throws -> [SavedItem] {
        try load()
    }

    func save(_ item: SavedItem) throws {
        var items = try load()
        if let existing = items.firstIndex(where: { $0.id == item.id }) {
            items[existing] = item
        } else {
            items.append(item)
        }
        try write(items)
    }

    func delete(_ item: SavedItem) throws {
        var items = try load()
        items.removeAll { $0.id == item.id }
        try write(items)
    }

    // MARK: Private

    private var fileURL: URL {
        directory.appendingPathComponent("items.json")
    }

    private func load() throws -> [SavedItem] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let items = try JSONDecoder().decode([SavedItem].self, from: data)
        cache = items
        return items
    }

    private func write(_ items: [SavedItem]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(items)
        try data.write(to: fileURL, options: .atomic)
        cache = items
    }
}
