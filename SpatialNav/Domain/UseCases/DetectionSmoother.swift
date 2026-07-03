//
//  DetectionSmoother.swift
//  SpatialNav
//

import Foundation
import simd

/// Temporal confirmation: an object must be seen `requiredHits` times near the
/// same world position before it is reported, which suppresses single-frame
/// false positives. Confirmed objects keep a stable identity while re-observed
/// and expire after `staleInterval` without a sighting.
nonisolated struct DetectionSmoother: Sendable {
    var requiredHits: Int
    var matchRadius: Float
    var staleInterval: TimeInterval

    private struct Candidate {
        var object: DetectedObject
        var hits: Int
        var lastSeen: TimeInterval
    }

    private var candidates: [Candidate] = []

    init(requiredHits: Int = 3, matchRadius: Float = 0.5, staleInterval: TimeInterval = 2.0) {
        self.requiredHits = requiredHits
        self.matchRadius = matchRadius
        self.staleInterval = staleInterval
    }

    /// Feeds one frame's located detections; returns currently confirmed objects.
    /// Detections without a world position cannot be matched and are ignored.
    mutating func ingest(_ detections: [DetectedObject], at time: TimeInterval) -> [DetectedObject] {
        for detection in detections {
            guard let position = detection.worldPosition else { continue }
            if let index = candidates.firstIndex(where: { candidate in
                candidate.object.label == detection.label &&
                candidate.object.worldPosition.map { simd_distance($0, position) < matchRadius } == true
            }) {
                candidates[index].object = DetectedObject(
                    id: candidates[index].object.id,
                    label: detection.label,
                    confidence: detection.confidence,
                    boundingBox: detection.boundingBox,
                    worldPosition: detection.worldPosition,
                    distance: detection.distance,
                    direction: detection.direction
                )
                candidates[index].hits += 1
                candidates[index].lastSeen = time
            } else {
                candidates.append(Candidate(object: detection, hits: 1, lastSeen: time))
            }
        }
        candidates.removeAll { time - $0.lastSeen > staleInterval }
        return candidates.filter { $0.hits >= requiredHits }.map(\.object)
    }

    mutating func reset() {
        candidates.removeAll()
    }
}
