//
//  FeaturePrinting.swift
//  SpatialNav
//

import Foundation

nonisolated enum FeaturePrintError: Error, Equatable {
    case noObservation
    case invalidData
}

/// Visual fingerprinting for saved items: a compact vector describing what the
/// camera saw, comparable across sightings. Data blobs are opaque archives.
nonisolated protocol FeaturePrinting: Sendable {
    func featurePrint(for snapshot: PixelBufferSnapshot) async throws -> Data
    /// Lower is more similar.
    func distance(between lhs: Data, and rhs: Data) throws -> Float
}
