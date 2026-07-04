//
//  SpokenDistanceTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct SpokenDistanceTests {

    @Test func metersFormatWithOneDecimal() {
        #expect(SpokenDistance.description(meters: 1.84, unit: .meters, strideLengthMeters: 0.7) == "1.8 meters")
    }

    @Test func feetConvertAndRound() {
        // 2 m = 6.56 ft → "7 feet"
        #expect(SpokenDistance.description(meters: 2.0, unit: .feet, strideLengthMeters: 0.7) == "7 feet")
    }

    @Test func stepsUseStrideLength() {
        // 2.1 m at 0.7 m stride = 3 steps
        #expect(SpokenDistance.description(meters: 2.1, unit: .steps, strideLengthMeters: 0.7) == "3 steps")
    }

    @Test func stepsNeverReportZero() {
        #expect(SpokenDistance.description(meters: 0.2, unit: .steps, strideLengthMeters: 0.7) == "1 steps")
    }

    @Test func degenerateStrideLengthDoesNotDivideByZero() {
        let result = SpokenDistance.description(meters: 1.0, unit: .steps, strideLengthMeters: 0)
        #expect(!result.isEmpty)
    }
}
