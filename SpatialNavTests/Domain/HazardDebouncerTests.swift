//
//  HazardDebouncerTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct HazardDebouncerTests {

    private func dropOff() -> Hazard {
        Hazard(id: UUID(), kind: .dropOff, distance: 1.5, direction: .twelve)
    }

    @Test func hazardIsSuppressedUntilStreakReached() {
        var debouncer = HazardDebouncer(requiredStreak: 3)
        #expect(debouncer.ingest([dropOff()]).isEmpty)
        #expect(debouncer.ingest([dropOff()]).isEmpty)
        #expect(debouncer.ingest([dropOff()]).count == 1)
    }

    @Test func confirmedHazardStaysWhilePresent() {
        var debouncer = HazardDebouncer(requiredStreak: 2)
        _ = debouncer.ingest([dropOff()])
        #expect(debouncer.ingest([dropOff()]).count == 1)
        #expect(debouncer.ingest([dropOff()]).count == 1)
    }

    @Test func oneMissedSweepResetsTheStreak() {
        var debouncer = HazardDebouncer(requiredStreak: 3)
        _ = debouncer.ingest([dropOff()])
        _ = debouncer.ingest([dropOff()])
        _ = debouncer.ingest([]) // hazard vanished for one sweep
        #expect(debouncer.ingest([dropOff()]).isEmpty) // streak starts over
    }

    @Test func kindsAreTrackedIndependently() {
        var debouncer = HazardDebouncer(requiredStreak: 2)
        let stairs = Hazard(id: UUID(), kind: .stairsUp, distance: 2, direction: .twelve)
        _ = debouncer.ingest([dropOff()])
        let confirmed = debouncer.ingest([dropOff(), stairs])
        #expect(confirmed.count == 1)
        #expect(confirmed[0].kind == .dropOff)
    }

    @Test func resetClearsAllStreaks() {
        var debouncer = HazardDebouncer(requiredStreak: 2)
        _ = debouncer.ingest([dropOff()])
        debouncer.reset()
        #expect(debouncer.ingest([dropOff()]).isEmpty)
    }
}
