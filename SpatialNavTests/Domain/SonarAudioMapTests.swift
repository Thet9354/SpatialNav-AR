//
//  SonarAudioMapTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct SonarAudioMapTests {

    private let map = SonarAudioMap()

    @Test func nearObstaclePingsHighAndFast() {
        #expect(map.frequency(forDistance: 0.3) == 1200)
        #expect(map.pulseInterval(forDistance: 0.3) == 0.15)
    }

    @Test func farObstaclePingsLowAndSlow() {
        #expect(map.frequency(forDistance: 4.0) == 440)
        #expect(map.pulseInterval(forDistance: 4.0) == 1.0)
    }

    @Test func valuesClampOutsideRange() {
        #expect(map.frequency(forDistance: 0.05) == 1200)
        #expect(map.frequency(forDistance: 10) == 440)
        #expect(map.pulseInterval(forDistance: 0.05) == 0.15)
        #expect(map.pulseInterval(forDistance: 10) == 1.0)
    }

    @Test func frequencyFallsMonotonicallyWithDistance() {
        let distances: [Float] = [0.3, 1.0, 2.0, 3.0, 4.0]
        let frequencies = distances.map { map.frequency(forDistance: $0) }
        for pair in zip(frequencies, frequencies.dropFirst()) {
            #expect(pair.0 > pair.1)
        }
    }

    @Test func midpointInterpolatesLinearly() {
        let mid = (0.3 + 4.0) / 2
        #expect(abs(map.frequency(forDistance: Float(mid)) - (1200 + 440) / 2) < 1)
    }
}
