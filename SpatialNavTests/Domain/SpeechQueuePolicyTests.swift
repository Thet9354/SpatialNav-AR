//
//  SpeechQueuePolicyTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct SpeechQueuePolicyTests {

    private let policy = SpeechQueuePolicy()

    @Test func idleQueueSpeaksImmediately() {
        let action = policy.action(newPriority: .low, current: nil, pendingPriorities: [])
        #expect(action == .speakNow(interruptCurrent: false))
    }

    @Test func higherPriorityInterruptsCurrentSpeech() {
        let action = policy.action(newPriority: .critical, current: .normal, pendingPriorities: [])
        #expect(action == .speakNow(interruptCurrent: true))
    }

    @Test func equalPriorityWaitsItsTurn() {
        let action = policy.action(newPriority: .normal, current: .normal, pendingPriorities: [])
        #expect(action == .enqueue(at: 0))
    }

    @Test func lowerPrioritySlotsBehindHigherPending() {
        let action = policy.action(
            newPriority: .normal,
            current: .critical,
            pendingPriorities: [.high, .normal, .low]
        )
        #expect(action == .enqueue(at: 2)) // after .high and the existing .normal
    }

    @Test func criticalNeverWaits() {
        let action = policy.action(
            newPriority: .critical,
            current: .high,
            pendingPriorities: [.high, .normal]
        )
        #expect(action == .speakNow(interruptCurrent: true))
    }

    @Test func fullQueueDropsLowPriorityChatter() {
        let action = policy.action(
            newPriority: .low,
            current: .normal,
            pendingPriorities: [.normal, .normal, .low, .low]
        )
        #expect(action == .drop)
    }

    @Test func fullQueueStillAcceptsHigherPriority() {
        let action = policy.action(
            newPriority: .high,
            current: .critical,
            pendingPriorities: [.normal, .normal, .low, .low]
        )
        #expect(action == .enqueue(at: 0))
    }
}
