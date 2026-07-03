//
//  WorldMapCodec.swift
//  SpatialNav
//

import ARKit
import Foundation

/// ARWorldMap ↔ compressed archive. LZFSE roughly halves map size, which matters
/// because relocalization load time scales with file size.
nonisolated enum WorldMapCodec {
    static func encode(_ map: ARWorldMap) throws -> Data {
        let archived = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        return try compress(archived)
    }

    static func decode(_ data: Data) throws -> ARWorldMap {
        let decompressed = try decompress(data)
        guard let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: decompressed) else {
            throw ARSessionError.invalidWorldMapData
        }
        return map
    }

    static func compress(_ data: Data) throws -> Data {
        try (data as NSData).compressed(using: .lzfse) as Data
    }

    static func decompress(_ data: Data) throws -> Data {
        try (data as NSData).decompressed(using: .lzfse) as Data
    }
}
