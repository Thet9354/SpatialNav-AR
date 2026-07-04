//
//  HazardAlertPolicy.swift
//  SpatialNav
//

import Foundation

/// Decides which single alert (if any) to announce this sweep. Hazards outrank
/// obstacle proximity; among hazards, highest priority wins, then closest.
/// Cooldowns stop the same warning from repeating every sweep, but a hazard
/// that got meaningfully closer re-announces immediately — approach matters
/// more than the cooldown.
nonisolated struct HazardAlertPolicy: Sendable {
    var hazardCooldown: TimeInterval = 5
    /// Re-announce inside the cooldown if the hazard closed by this much (m).
    var hazardApproachDelta: Float = 0.5
    var obstacleCooldown: TimeInterval = 3
    var obstacleAlertDistance: Float = 2.0
    /// Spoken-distance preferences from the user's profile.
    var distanceUnit: FeedbackProfile.DistanceUnit = .meters
    var strideLengthMeters: Float = 0.7

    private struct Announcement {
        var time: TimeInterval
        var distance: Float
    }

    private var hazardHistory: [Hazard.Kind: Announcement] = [:]
    private var lastObstacleTime: TimeInterval = -.infinity

    mutating func events(
        hazards: [Hazard],
        nearestObstacle: Obstacle?,
        at time: TimeInterval
    ) -> [FeedbackEvent] {
        let topHazard = hazards.max { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.distance > rhs.distance // closer wins ties
        }
        if let hazard = topHazard, shouldAnnounce(hazard, at: time) {
            hazardHistory[hazard.kind] = Announcement(time: time, distance: hazard.distance)
            return [FeedbackEvent(
                kind: .hazardWarning(hazard.kind),
                priority: hazard.priority,
                direction: hazard.direction,
                distance: hazard.distance,
                message: hazard.kind.warningDescription
            )]
        }

        if let obstacle = nearestObstacle,
           obstacle.distance <= obstacleAlertDistance,
           time - lastObstacleTime >= obstacleCooldown {
            lastObstacleTime = time
            let spokenDistance = SpokenDistance.description(
                meters: obstacle.distance,
                unit: distanceUnit,
                strideLengthMeters: strideLengthMeters
            )
            let message = "Obstacle \(spokenDistance) at \(obstacle.direction.spokenDescription)"
            return [FeedbackEvent(
                kind: .obstacleProximity,
                priority: .normal,
                direction: obstacle.direction,
                distance: obstacle.distance,
                message: message
            )]
        }
        return []
    }

    mutating func reset() {
        hazardHistory.removeAll()
        lastObstacleTime = -.infinity
    }

    private func shouldAnnounce(_ hazard: Hazard, at time: TimeInterval) -> Bool {
        guard let last = hazardHistory[hazard.kind] else { return true }
        if time - last.time >= hazardCooldown { return true }
        return last.distance - hazard.distance >= hazardApproachDelta
    }
}
