//
//  RelocalizationWatchdogTests.swift
//  SpatialNavTests
//
//  Note: ingest(quality:at:) is mutating and the #expect macro captures values
//  immutably, so results are bound to lets before asserting.
//

import Foundation
import Testing
@testable import SpatialNav

struct RelocalizationWatchdogTests {

    @Test func doesNotFireBeforeTimeout() {
        var watchdog = RelocalizationWatchdog(timeout: 10)
        let atStart = watchdog.ingest(quality: .limited(.relocalizing), at: 0)
        let midway = watchdog.ingest(quality: .limited(.relocalizing), at: 5)
        let justBefore = watchdog.ingest(quality: .limited(.relocalizing), at: 9.9)
        #expect(!atStart)
        #expect(!midway)
        #expect(!justBefore)
    }

    @Test func firesOncePastTimeoutThenRearms() {
        var watchdog = RelocalizationWatchdog(timeout: 10)
        _ = watchdog.ingest(quality: .limited(.relocalizing), at: 0)
        let fired = watchdog.ingest(quality: .limited(.relocalizing), at: 10.5)
        let immediatelyAfter = watchdog.ingest(quality: .limited(.relocalizing), at: 11)
        let secondEpisode = watchdog.ingest(quality: .limited(.relocalizing), at: 21.5)
        #expect(fired)
        #expect(!immediatelyAfter) // fired once; next episode has its own timer
        #expect(secondEpisode)
    }

    @Test func recoveryResetsTheTimer() {
        var watchdog = RelocalizationWatchdog(timeout: 10)
        _ = watchdog.ingest(quality: .limited(.relocalizing), at: 0)
        _ = watchdog.ingest(quality: .normal, at: 5) // relocalized fine
        _ = watchdog.ingest(quality: .limited(.relocalizing), at: 100)
        let tooSoon = watchdog.ingest(quality: .limited(.relocalizing), at: 105)
        let pastTimeout = watchdog.ingest(quality: .limited(.relocalizing), at: 110.5)
        #expect(!tooSoon) // must not inherit the old episode's start time
        #expect(pastTimeout)
    }

    @Test func otherLimitedStatesDoNotCount() {
        var watchdog = RelocalizationWatchdog(timeout: 10)
        _ = watchdog.ingest(quality: .limited(.excessiveMotion), at: 0)
        let much = watchdog.ingest(quality: .limited(.excessiveMotion), at: 50)
        #expect(!much)
    }
}
