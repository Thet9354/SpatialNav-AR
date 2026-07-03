//
//  ItemStoring.swift
//  SpatialNav
//

import Foundation

nonisolated protocol ItemStoring: Sendable {
    func items() async throws -> [SavedItem]
    func save(_ item: SavedItem) async throws
    func delete(_ item: SavedItem) async throws
}
