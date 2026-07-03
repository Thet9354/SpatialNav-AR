//
//  FindItemUseCaseTests.swift
//  SpatialNavTests
//

import CoreVideo
import Foundation
import Testing
import simd
@testable import SpatialNav

private final class MockFeaturePrinter: FeaturePrinting, @unchecked Sendable {
    var scriptedPrint = Data("fingerprint".utf8)
    func featurePrint(for snapshot: PixelBufferSnapshot) async throws -> Data { scriptedPrint }
    func distance(between lhs: Data, and rhs: Data) throws -> Float { lhs == rhs ? 0 : 1 }
}

private final class MockItemStore: ItemStoring, @unchecked Sendable {
    private(set) var saved: [SavedItem] = []
    func items() async throws -> [SavedItem] { saved }
    func save(_ item: SavedItem) async throws { saved.append(item) }
    func delete(_ item: SavedItem) async throws { saved.removeAll { $0.id == item.id } }
}

private func makePixelSnapshot() -> PixelBufferSnapshot {
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_32BGRA, nil, &buffer)
    return PixelBufferSnapshot(
        buffer: buffer!,
        timestamp: 0,
        cameraTransform: matrix_identity_float4x4,
        intrinsics: matrix_identity_float3x3,
        imageResolution: CGSize(width: 64, height: 64)
    )
}

struct FindItemUseCaseTests {

    @Test func registerCapturesPrintAndPositionAndPersists() async throws {
        let provider = MockARSessionProvider()
        provider.scriptedPixelBuffer = makePixelSnapshot()
        provider.scriptedHits = [RaycastHit(
            ray: SonarRay(azimuth: 0, elevation: 0),
            distance: 1.2,
            worldPosition: simd_float3(0, 0.8, -1.2)
        )]
        let store = MockItemStore()
        let useCase = FindItemUseCase(
            provider: provider,
            featurePrinter: MockFeaturePrinter(),
            itemStore: store
        )

        let item = try await useCase.registerItem(named: "Keys")

        #expect(item.name == "Keys")
        #expect(item.lastKnownPosition == simd_float3(0, 0.8, -1.2))
        #expect(item.featurePrintData == Data("fingerprint".utf8))
        #expect(store.saved.count == 1)
    }

    @Test func registerWithoutCameraFrameThrows() async {
        let provider = MockARSessionProvider()
        provider.scriptedPixelBuffer = nil
        let useCase = FindItemUseCase(
            provider: provider,
            featurePrinter: MockFeaturePrinter(),
            itemStore: MockItemStore()
        )

        await #expect(throws: FindItemError.noCameraFrame) {
            _ = try await useCase.registerItem(named: "Keys")
        }
    }

    @Test func registerWithNoRaycastHitStillSavesWithoutPosition() async throws {
        let provider = MockARSessionProvider()
        provider.scriptedPixelBuffer = makePixelSnapshot()
        provider.scriptedHits = []
        let store = MockItemStore()
        let useCase = FindItemUseCase(
            provider: provider,
            featurePrinter: MockFeaturePrinter(),
            itemStore: store
        )

        let item = try await useCase.registerItem(named: "Mug")

        #expect(item.lastKnownPosition == nil)
        #expect(store.saved.count == 1)
    }

    @Test func guidanceRequiresAPosition() {
        let noPosition = SavedItem(id: UUID(), name: "Ghost", lastKnownPosition: nil, featurePrintData: nil)
        #expect(FindItemUseCase.guidance(to: noPosition, from: matrix_identity_float4x4) == nil)

        let placed = SavedItem(id: UUID(), name: "Keys", lastKnownPosition: simd_float3(0, 0, -2), featurePrintData: nil)
        #expect(FindItemUseCase.guidance(to: placed, from: matrix_identity_float4x4)?.direction == .twelve)
    }
}
