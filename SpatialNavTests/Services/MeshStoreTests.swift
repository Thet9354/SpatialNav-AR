//
//  MeshStoreTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
import simd
@testable import SpatialNav

struct MeshStoreTests {

    @Test func applyingSnapshotsInsertsThem() async {
        let store = MeshStore()
        let snapshots = [
            MeshAnchorSnapshot(id: UUID(), transform: matrix_identity_float4x4, updatedAt: 1),
            MeshAnchorSnapshot(id: UUID(), transform: matrix_identity_float4x4, updatedAt: 1),
        ]
        await store.apply(snapshots)
        #expect(await store.count() == 2)
    }

    @Test func applyingSameAnchorIdCoalescesToLatest() async {
        let store = MeshStore()
        let id = UUID()
        await store.apply([MeshAnchorSnapshot(id: id, transform: matrix_identity_float4x4, updatedAt: 1)])
        await store.apply([MeshAnchorSnapshot(id: id, transform: matrix_identity_float4x4, updatedAt: 2)])
        #expect(await store.count() == 1)
        #expect(await store.snapshot(for: id)?.updatedAt == 2)
    }

    @Test func removingAnchorsDeletesThem() async {
        let store = MeshStore()
        let keep = UUID()
        let drop = UUID()
        await store.apply([
            MeshAnchorSnapshot(id: keep, transform: matrix_identity_float4x4, updatedAt: 1),
            MeshAnchorSnapshot(id: drop, transform: matrix_identity_float4x4, updatedAt: 1),
        ])
        await store.remove(ids: [drop])
        #expect(await store.count() == 1)
        #expect(await store.snapshot(for: keep) != nil)
        #expect(await store.snapshot(for: drop) == nil)
    }
}
