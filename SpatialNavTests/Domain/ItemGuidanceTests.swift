//
//  ItemGuidanceTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
import simd
@testable import SpatialNav

struct ItemGuidanceTests {

    // Identity camera: at origin, facing -z, world up +y.
    private let identity = matrix_identity_float4x4

    @Test func itemStraightAheadIsTwelveOClock() {
        let guidance = ItemGuidance.toward(simd_float3(0, 0, -2), from: identity)
        #expect(guidance.direction == .twelve)
        #expect(abs(guidance.distance - 2) < 1e-5)
        #expect(abs(guidance.heightDelta) < 1e-5)
    }

    @Test func itemToTheRightIsThreeOClock() {
        let guidance = ItemGuidance.toward(simd_float3(2, 0, 0), from: identity)
        #expect(guidance.direction == .three)
    }

    @Test func itemBehindIsSixOClock() {
        let guidance = ItemGuidance.toward(simd_float3(0, 0, 2), from: identity)
        #expect(guidance.direction == .six)
    }

    @Test func itemThirtyDegreesRightIsOneOClock() {
        let guidance = ItemGuidance.toward(simd_float3(1, 0, -sqrt(3)), from: identity)
        #expect(guidance.direction == .one)
    }

    @Test func bearingIgnoresCameraPitch() {
        // Camera pitched 45° up; item straight ahead horizontally must stay 12 o'clock.
        var pitchedUp = matrix_identity_float4x4
        let angle = Float.pi / 4
        pitchedUp.columns.1 = simd_float4(0, cos(angle), sin(angle), 0)
        pitchedUp.columns.2 = simd_float4(0, -sin(angle), cos(angle), 0)
        let guidance = ItemGuidance.toward(simd_float3(0, 0, -2), from: pitchedUp)
        #expect(guidance.direction == .twelve)
    }

    @Test func heightDeltaReportsShelfItems() {
        var transform = matrix_identity_float4x4
        transform.columns.3 = simd_float4(0, 1.5, 0, 1)
        let guidance = ItemGuidance.toward(simd_float3(0, 2.0, -1), from: transform)
        #expect(abs(guidance.heightDelta - 0.5) < 1e-5)
    }

    @Test func itemDirectlyOverheadFallsBackGracefully() {
        let guidance = ItemGuidance.toward(simd_float3(0, 3, 0), from: identity)
        #expect(guidance.direction == .twelve)
        #expect(abs(guidance.distance - 3) < 1e-5)
    }
}
