//
//  SpaceStoring.swift
//  SpatialNav
//

import Foundation

nonisolated enum SpaceStoreError: Error, Equatable {
    case mapDataMissing
}

nonisolated protocol SpaceStoring: Sendable {
    func savedSpaces() async throws -> [SavedSpace]
    /// `worldMapData` is the opaque, compressed ARWorldMap archive.
    func save(_ space: SavedSpace, worldMapData: Data) async throws
    func worldMapData(for space: SavedSpace) async throws -> Data
    func delete(_ space: SavedSpace) async throws
}
