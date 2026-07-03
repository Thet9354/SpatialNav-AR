//
//  MeshStoring.swift
//  SpatialNav
//

import Foundation

nonisolated protocol MeshStoring: Sendable {
    func apply(_ snapshots: [MeshAnchorSnapshot]) async
    func remove(ids: [UUID]) async
    func count() async -> Int
}
