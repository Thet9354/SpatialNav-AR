//
//  SceneDescriber.swift
//  SpatialNav
//

import Foundation

/// On-demand verbal snapshot of the surroundings, composed entirely from
/// already-tracked state — no extra sensing, works offline, instant.
nonisolated enum SceneDescriber {
    static func describe(
        objects: [DetectedObject],
        nearestObstacle: Obstacle?,
        hazards: [Hazard],
        unit: FeedbackProfile.DistanceUnit,
        strideLengthMeters: Float
    ) -> String {
        var parts: [String] = []

        if let hazard = hazards.max(by: { $0.priority < $1.priority }) {
            parts.append(hazard.kind.warningDescription + ".")
        }

        let describedObjects = objects.prefix(3).compactMap { object -> String? in
            guard let distance = object.distance, let direction = object.direction else { return nil }
            let spoken = SpokenDistance.description(meters: distance, unit: unit, strideLengthMeters: strideLengthMeters)
            return "\(object.label), \(spoken) at \(direction.spokenDescription)"
        }
        if describedObjects.isEmpty {
            parts.append("No objects recognized.")
        } else {
            parts.append(describedObjects.joined(separator: ". ") + ".")
        }

        if let nearest = nearestObstacle {
            let spoken = SpokenDistance.description(meters: nearest.distance, unit: unit, strideLengthMeters: strideLengthMeters)
            parts.append("Nearest obstacle \(spoken) at \(nearest.direction.spokenDescription).")
        } else {
            parts.append("Path clear ahead.")
        }

        return parts.joined(separator: " ")
    }
}
