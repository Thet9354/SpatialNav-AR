//
//  ClockDirectionTests.swift
//  SpatialNavTests
//

import Testing
@testable import SpatialNav

struct ClockDirectionTests {

    @Test func straightAheadIsTwelveOClock() {
        #expect(ClockDirection(bearing: 0) == .twelve)
    }

    @Test func thirtyDegreesRightIsOneOClock() {
        #expect(ClockDirection(bearing: .pi / 6) == .one)
    }

    @Test func ninetyDegreesRightIsThreeOClock() {
        #expect(ClockDirection(bearing: .pi / 2) == .three)
    }

    @Test func ninetyDegreesLeftIsNineOClock() {
        #expect(ClockDirection(bearing: -.pi / 2) == .nine)
    }

    @Test func directlyBehindIsSixOClock() {
        #expect(ClockDirection(bearing: .pi) == .six)
        #expect(ClockDirection(bearing: -.pi) == .six)
    }

    @Test func bearingsWrapBeyondFullRotation() {
        #expect(ClockDirection(bearing: 2 * .pi) == .twelve)
        #expect(ClockDirection(bearing: 2 * .pi + .pi / 6) == .one)
    }

    @Test func bearingsRoundToNearestHour() {
        let fortyDegrees = Float(40) * .pi / 180
        let fiftyDegrees = Float(50) * .pi / 180
        #expect(ClockDirection(bearing: fortyDegrees) == .one)
        #expect(ClockDirection(bearing: fiftyDegrees) == .two)
    }

    @Test func spokenDescriptionUsesClockConvention() {
        #expect(ClockDirection.three.spokenDescription == "3 o'clock")
        #expect(ClockDirection.twelve.spokenDescription == "12 o'clock")
    }
}
