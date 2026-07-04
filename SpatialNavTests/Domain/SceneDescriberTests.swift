//
//  SceneDescriberTests.swift
//  SpatialNavTests
//

import CoreGraphics
import Foundation
import Testing
import simd
@testable import SpatialNav

struct SceneDescriberTests {

    private func object(label: String, distance: Float, direction: ClockDirection) -> DetectedObject {
        DetectedObject(
            id: UUID(),
            label: label,
            confidence: 0.9,
            boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
            worldPosition: simd_float3(0, 0, -distance),
            distance: distance,
            direction: direction
        )
    }

    private func obstacle(distance: Float, direction: ClockDirection) -> Obstacle {
        Obstacle(
            id: UUID(),
            worldPosition: simd_float3(0, 0, -distance),
            distance: distance,
            direction: direction,
            elevation: .waist
        )
    }

    @Test func describesObjectsObstacleAndClearPath() {
        let text = SceneDescriber.describe(
            objects: [object(label: "chair", distance: 2.0, direction: .eleven)],
            nearestObstacle: obstacle(distance: 1.4, direction: .one),
            hazards: [],
            unit: .meters,
            strideLengthMeters: 0.7
        )
        #expect(text == "chair, 2.0 meters at 11 o'clock. Nearest obstacle 1.4 meters at 1 o'clock.")
    }

    @Test func hazardLeadsTheDescription() {
        let text = SceneDescriber.describe(
            objects: [],
            nearestObstacle: nil,
            hazards: [Hazard(id: UUID(), kind: .dropOff, distance: 1.5, direction: .twelve)],
            unit: .meters,
            strideLengthMeters: 0.7
        )
        #expect(text.hasPrefix("Caution — drop-off ahead."))
        #expect(text.hasSuffix("Path clear ahead."))
    }

    @Test func emptySceneIsHonest() {
        let text = SceneDescriber.describe(
            objects: [],
            nearestObstacle: nil,
            hazards: [],
            unit: .meters,
            strideLengthMeters: 0.7
        )
        #expect(text == "No objects recognized. Path clear ahead.")
    }

    @Test func onlyTopThreeObjectsAreSpoken() {
        let objects = (1...5).map { object(label: "thing\($0)", distance: Float($0), direction: .twelve) }
        let text = SceneDescriber.describe(
            objects: objects,
            nearestObstacle: nil,
            hazards: [],
            unit: .meters,
            strideLengthMeters: 0.7
        )
        #expect(text.contains("thing3"))
        #expect(!text.contains("thing4"))
    }

    @Test func respectsDistanceUnits() {
        let text = SceneDescriber.describe(
            objects: [object(label: "chair", distance: 2.1, direction: .twelve)],
            nearestObstacle: nil,
            hazards: [],
            unit: .steps,
            strideLengthMeters: 0.7
        )
        #expect(text.contains("3 steps"))
    }
}
