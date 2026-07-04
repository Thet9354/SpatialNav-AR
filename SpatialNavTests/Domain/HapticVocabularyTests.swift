//
//  HapticVocabularyTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct HapticVocabularyTests {

    private func event(kind: FeedbackEvent.Kind, distance: Float? = nil) -> FeedbackEvent {
        FeedbackEvent(kind: kind, priority: .normal, direction: nil, distance: distance, message: nil)
    }

    @Test func everyEventKindHasAPattern() {
        let kinds: [FeedbackEvent.Kind] = [
            .hazardWarning(.dropOff), .hazardWarning(.stairsUp), .hazardWarning(.person),
            .obstacleProximity, .itemPing, .navigationCue, .status,
        ]
        for kind in kinds {
            #expect(!HapticVocabulary.pattern(for: event(kind: kind)).isEmpty)
        }
    }

    @Test func dropOffIsTheStrongestAndLongestSignature() {
        let dropOff = HapticVocabulary.pattern(for: event(kind: .hazardWarning(.dropOff)))
        let status = HapticVocabulary.pattern(for: event(kind: .status))
        #expect(dropOff.count > status.count)
        #expect(dropOff.contains { $0.intensity == 1.0 })
        #expect(dropOff.contains { $0.duration > 0 }) // ends in a rumble
    }

    @Test func signaturesAreDistinguishableByFeel() {
        // A deaf-blind user must be able to tell these apart: distinct pulse counts.
        let dropOff = HapticVocabulary.pattern(for: event(kind: .hazardWarning(.dropOff)))
        let hazard = HapticVocabulary.pattern(for: event(kind: .hazardWarning(.person)))
        let item = HapticVocabulary.pattern(for: event(kind: .itemPing))
        let obstacle = HapticVocabulary.pattern(for: event(kind: .obstacleProximity))
        #expect(hazard.count == 3)
        #expect(item.count == 2)
        #expect(obstacle.count == 1)
        #expect(dropOff != hazard)
        #expect(item != obstacle)
    }

    @Test func obstacleIntensityScalesWithProximity() {
        let near = HapticVocabulary.proximityIntensity(forDistance: 0.3)
        let mid = HapticVocabulary.proximityIntensity(forDistance: 2.0)
        let far = HapticVocabulary.proximityIntensity(forDistance: 4.0)
        #expect(near == 1.0)
        #expect(near > mid)
        #expect(mid > far)
        #expect(abs(far - 0.3) < 1e-5)
    }

    @Test func unknownDistanceGetsMediumIntensity() {
        #expect(HapticVocabulary.proximityIntensity(forDistance: nil) == 0.5)
    }
}
