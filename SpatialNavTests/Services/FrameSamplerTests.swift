//
//  FrameSamplerTests.swift
//  SpatialNavTests
//
//  Note: shouldEmit(at:) is mutating, and the #expect macro captures values
//  immutably, so results are bound to lets before asserting.
//

import Foundation
import Testing
@testable import SpatialNav

struct FrameSamplerTests {

    @Test func firstFrameAlwaysPasses() {
        var sampler = FrameSampler(framesPerSecond: 5)
        let emitted = sampler.shouldEmit(at: 123.456)
        #expect(emitted)
    }

    @Test func gatesToConfiguredRate() {
        // 0.125 s steps are exact in binary, so the arithmetic is deterministic:
        // at 4 fps (0.25 s interval) exactly every other frame passes.
        var sampler = FrameSampler(framesPerSecond: 4)
        var emitted = 0
        for step in 0...8 {
            if sampler.shouldEmit(at: Double(step) * 0.125) {
                emitted += 1
            }
        }
        #expect(emitted == 5) // t = 0, 0.25, 0.5, 0.75, 1.0
    }

    @Test func framesDuringCooldownAreRejected() {
        var sampler = FrameSampler(framesPerSecond: 5)
        let first = sampler.shouldEmit(at: 0)
        let tooSoon = sampler.shouldEmit(at: 0.05)
        let stillTooSoon = sampler.shouldEmit(at: 0.1)
        let afterCooldown = sampler.shouldEmit(at: 0.25)
        #expect(first)
        #expect(!tooSoon)
        #expect(!stillTooSoon)
        #expect(afterCooldown)
    }

    @Test func zeroRateNeverEmits() {
        var sampler = FrameSampler(framesPerSecond: 0)
        let atZero = sampler.shouldEmit(at: 0)
        let muchLater = sampler.shouldEmit(at: 100)
        #expect(!atZero)
        #expect(!muchLater)
    }

    @Test func rateCanBeRetuned() {
        var sampler = FrameSampler(framesPerSecond: 0)
        let whileDisabled = sampler.shouldEmit(at: 0)
        sampler.setRate(framesPerSecond: 10)
        let afterEnabling = sampler.shouldEmit(at: 0.1)
        #expect(!whileDisabled)
        #expect(afterEnabling)
    }
}
