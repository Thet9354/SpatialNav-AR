//
//  WorldMapCodecTests.swift
//  SpatialNavTests
//
//  ARWorldMap instances can only be produced by a live AR session on device,
//  so the archive path is exercised in on-device testing; the compression
//  layer is verified here.
//

import Foundation
import Testing
@testable import SpatialNav

struct WorldMapCodecTests {

    @Test func compressionRoundTripsLosslessly() throws {
        let original = Data((0..<50_000).map { _ in UInt8.random(in: 0...255) })
        let compressed = try WorldMapCodec.compress(original)
        let restored = try WorldMapCodec.decompress(compressed)
        #expect(restored == original)
    }

    @Test func compressibleDataActuallyShrinks() throws {
        let repetitive = Data(repeating: 42, count: 100_000)
        let compressed = try WorldMapCodec.compress(repetitive)
        #expect(compressed.count < repetitive.count / 10)
    }

    @Test func decodingGarbageThrows() {
        #expect(throws: Error.self) {
            _ = try WorldMapCodec.decode(Data("not a world map".utf8))
        }
    }
}
