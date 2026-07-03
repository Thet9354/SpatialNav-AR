//
//  SpaceStore.swift
//  SpatialNav
//

import Foundation

/// File-backed store: `index.json` holds the `[SavedSpace]` metadata sidecar;
/// each world map blob lives in `<uuid>.armap` beside it. Metadata survives
/// even if a map file must be rebuilt.
actor SpaceStore: SpaceStoring {
    private let directory: URL
    private var cachedIndex: [SavedSpace]?

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
        return base.appendingPathComponent("Spaces", isDirectory: true)
    }

    func savedSpaces() throws -> [SavedSpace] {
        try loadIndex()
    }

    func save(_ space: SavedSpace, worldMapData: Data) throws {
        try ensureDirectory()
        try worldMapData.write(to: mapURL(for: space.id), options: .atomic)
        var index = try loadIndex()
        if let existing = index.firstIndex(where: { $0.id == space.id }) {
            index[existing] = space
        } else {
            index.append(space)
        }
        try writeIndex(index)
    }

    func worldMapData(for space: SavedSpace) throws -> Data {
        let url = mapURL(for: space.id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SpaceStoreError.mapDataMissing
        }
        return try Data(contentsOf: url)
    }

    func delete(_ space: SavedSpace) throws {
        try? FileManager.default.removeItem(at: mapURL(for: space.id))
        var index = try loadIndex()
        index.removeAll { $0.id == space.id }
        try writeIndex(index)
    }

    // MARK: Private

    private var indexURL: URL {
        directory.appendingPathComponent("index.json")
    }

    private func mapURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).armap")
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func loadIndex() throws -> [SavedSpace] {
        if let cachedIndex { return cachedIndex }
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            cachedIndex = []
            return []
        }
        let data = try Data(contentsOf: indexURL)
        let spaces = try JSONDecoder().decode([SavedSpace].self, from: data)
        cachedIndex = spaces
        return spaces
    }

    private func writeIndex(_ spaces: [SavedSpace]) throws {
        try ensureDirectory()
        let data = try JSONEncoder().encode(spaces)
        try data.write(to: indexURL, options: .atomic)
        cachedIndex = spaces
    }
}
