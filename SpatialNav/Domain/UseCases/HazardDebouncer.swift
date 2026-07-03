//
//  HazardDebouncer.swift
//  SpatialNav
//

import Foundation

/// A hazard kind must appear in `requiredStreak` consecutive sweeps before it is
/// reported, so a single noisy raycast can't flash a warning. At the 10 Hz sweep
/// rate the added latency is ~0.3 s, which is acceptable against walking speed.
/// A kind missing from one sweep resets its streak.
nonisolated struct HazardDebouncer: Sendable {
    var requiredStreak: Int

    private var streaks: [Hazard.Kind: Int] = [:]

    init(requiredStreak: Int = 3) {
        self.requiredStreak = requiredStreak
    }

    mutating func ingest(_ hazards: [Hazard]) -> [Hazard] {
        var confirmed: [Hazard] = []
        var nextStreaks: [Hazard.Kind: Int] = [:]
        for hazard in hazards {
            let streak = (streaks[hazard.kind] ?? 0) + 1
            nextStreaks[hazard.kind] = streak
            if streak >= requiredStreak {
                confirmed.append(hazard)
            }
        }
        streaks = nextStreaks
        return confirmed
    }

    mutating func reset() {
        streaks.removeAll()
    }
}
