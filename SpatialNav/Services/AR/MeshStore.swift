//
//  MeshStore.swift
//  SpatialNav
//

import Foundation

/// Thread-safe cache of the reconstructed scene, keyed by anchor identity.
/// Applying a snapshot for an existing id overwrites it (keep-latest coalescing).
actor MeshStore: MeshStoring {
    private var anchors: [UUID: MeshAnchorSnapshot] = [:]

    func apply(_ snapshots: [MeshAnchorSnapshot]) {
        for snapshot in snapshots {
            anchors[snapshot.id] = snapshot
        }
    }

    func remove(ids: [UUID]) {
        for id in ids {
            anchors[id] = nil
        }
    }

    func count() -> Int {
        anchors.count
    }

    func snapshot(for id: UUID) -> MeshAnchorSnapshot? {
        anchors[id]
    }

    func removeAll() {
        anchors.removeAll()
    }
}
