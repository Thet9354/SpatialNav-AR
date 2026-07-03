//
//  FindItemUseCase.swift
//  SpatialNav
//

import Foundation
import simd

nonisolated enum FindItemError: Error, Equatable {
    case noCameraFrame
    case itemHasNoPosition
}

/// Registers personal items (visual fingerprint + world position at the screen
/// center) and provides live guidance back to them. Positions are valid within
/// the session they were saved in, or after relocalizing into the same space.
///
/// Live re-acquisition via feature-print matching (for items that moved) is the
/// planned extension; the fingerprint is captured now so saved items already
/// carry what that will need.
actor FindItemUseCase {
    private let provider: any ARSessionProviding
    private let featurePrinter: any FeaturePrinting
    private let itemStore: any ItemStoring

    init(
        provider: any ARSessionProviding,
        featurePrinter: any FeaturePrinting,
        itemStore: any ItemStoring
    ) {
        self.provider = provider
        self.featurePrinter = featurePrinter
        self.itemStore = itemStore
    }

    func items() async throws -> [SavedItem] {
        try await itemStore.items()
    }

    /// Registers whatever is at the center of the camera view.
    func registerItem(named name: String) async throws -> SavedItem {
        guard let snapshot = await provider.captureNextPixelBuffer() else {
            throw FindItemError.noCameraFrame
        }
        let fingerprint = try await featurePrinter.featurePrint(for: snapshot)
        let hits = await provider.raycast([SonarRay(azimuth: 0, elevation: 0)])
        let item = SavedItem(
            id: UUID(),
            name: name,
            lastKnownPosition: hits.first?.worldPosition,
            featurePrintData: fingerprint
        )
        try await itemStore.save(item)
        return item
    }

    func delete(_ item: SavedItem) async throws {
        try await itemStore.delete(item)
    }

    nonisolated static func guidance(
        to item: SavedItem,
        from cameraTransform: simd_float4x4
    ) -> ItemGuidance? {
        guard let position = item.lastKnownPosition else { return nil }
        return ItemGuidance.toward(position, from: cameraTransform)
    }
}
