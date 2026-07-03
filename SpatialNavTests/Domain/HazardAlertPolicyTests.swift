//
//  HazardAlertPolicyTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
import simd
@testable import SpatialNav

struct HazardAlertPolicyTests {

    private func hazard(_ kind: Hazard.Kind, distance: Float = 1.5) -> Hazard {
        Hazard(id: UUID(), kind: kind, distance: distance, direction: .twelve)
    }

    private func obstacle(distance: Float) -> Obstacle {
        Obstacle(
            id: UUID(),
            worldPosition: simd_float3(0, 0, -distance),
            distance: distance,
            direction: .one,
            elevation: .waist
        )
    }

    @Test func hazardAnnouncesOnceThenCoolsDown() {
        var policy = HazardAlertPolicy()
        #expect(policy.events(hazards: [hazard(.dropOff)], nearestObstacle: nil, at: 0).count == 1)
        #expect(policy.events(hazards: [hazard(.dropOff)], nearestObstacle: nil, at: 1).isEmpty)
        #expect(policy.events(hazards: [hazard(.dropOff)], nearestObstacle: nil, at: 6).count == 1)
    }

    @Test func approachingHazardReannouncesInsideCooldown() {
        var policy = HazardAlertPolicy()
        _ = policy.events(hazards: [hazard(.dropOff, distance: 2.0)], nearestObstacle: nil, at: 0)
        // 0.6 m closer only 1 s later: announce again, cooldown be damned.
        let events = policy.events(hazards: [hazard(.dropOff, distance: 1.4)], nearestObstacle: nil, at: 1)
        #expect(events.count == 1)
    }

    @Test func highestPriorityHazardWins() {
        var policy = HazardAlertPolicy()
        let events = policy.events(
            hazards: [hazard(.stairsUp, distance: 1.0), hazard(.dropOff, distance: 2.0)],
            nearestObstacle: nil,
            at: 0
        )
        #expect(events.count == 1)
        #expect(events[0].kind == .hazardWarning(.dropOff)) // critical beats high
    }

    @Test func closerHazardWinsPriorityTies() {
        var policy = HazardAlertPolicy()
        let events = policy.events(
            hazards: [hazard(.dropOff, distance: 3.0), hazard(.stairsDown, distance: 1.0)],
            nearestObstacle: nil,
            at: 0
        )
        #expect(events[0].kind == .hazardWarning(.stairsDown))
        #expect(events[0].distance == 1.0)
    }

    @Test func hazardSuppressesObstacleAlert() {
        var policy = HazardAlertPolicy()
        let events = policy.events(
            hazards: [hazard(.dropOff)],
            nearestObstacle: obstacle(distance: 1.0),
            at: 0
        )
        #expect(events.count == 1)
        #expect(events[0].kind == .hazardWarning(.dropOff))
    }

    @Test func obstacleAlertRespectsDistanceAndCooldown() {
        var policy = HazardAlertPolicy()
        // Too far: silent.
        #expect(policy.events(hazards: [], nearestObstacle: obstacle(distance: 3.0), at: 0).isEmpty)
        // In range: announce.
        #expect(policy.events(hazards: [], nearestObstacle: obstacle(distance: 1.5), at: 1).count == 1)
        // Cooldown: silent.
        #expect(policy.events(hazards: [], nearestObstacle: obstacle(distance: 1.4), at: 2).isEmpty)
        // Cooldown elapsed: announce.
        #expect(policy.events(hazards: [], nearestObstacle: obstacle(distance: 1.3), at: 5).count == 1)
    }

    @Test func resetForgetsHistory() {
        var policy = HazardAlertPolicy()
        _ = policy.events(hazards: [hazard(.dropOff)], nearestObstacle: nil, at: 0)
        policy.reset()
        #expect(policy.events(hazards: [hazard(.dropOff)], nearestObstacle: nil, at: 1).count == 1)
    }
}
