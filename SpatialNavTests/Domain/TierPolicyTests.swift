//
//  TierPolicyTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct TierPolicyTests {

    private let policy = TierPolicy()

    @Test func coolDeviceRunsFull() {
        #expect(policy.target(thermal: .nominal, isLowPowerMode: false, batteryLevel: 0.8) == .full)
        #expect(policy.target(thermal: .fair, isLowPowerMode: false, batteryLevel: 0.8) == .full)
    }

    @Test func thermalPressureDowngrades() {
        #expect(policy.target(thermal: .serious, isLowPowerMode: false, batteryLevel: 0.8) == .reduced)
        #expect(policy.target(thermal: .critical, isLowPowerMode: false, batteryLevel: 0.8) == .essential)
    }

    @Test func lowPowerModeCapsAtReduced() {
        #expect(policy.target(thermal: .nominal, isLowPowerMode: true, batteryLevel: 0.8) == .reduced)
        // Thermal critical still wins.
        #expect(policy.target(thermal: .critical, isLowPowerMode: true, batteryLevel: 0.8) == .essential)
    }

    @Test func batteryThresholdsCapTiers() {
        #expect(policy.target(thermal: .nominal, isLowPowerMode: false, batteryLevel: 0.15) == .reduced)
        #expect(policy.target(thermal: .nominal, isLowPowerMode: false, batteryLevel: 0.05) == .essential)
    }

    @Test func unknownBatteryIsIgnored() {
        // Simulator reports -1.
        #expect(policy.target(thermal: .nominal, isLowPowerMode: false, batteryLevel: -1) == .full)
        #expect(policy.target(thermal: .nominal, isLowPowerMode: false, batteryLevel: nil) == .full)
    }
}

struct TierArbiterTests {

    @Test func downgradeAppliesImmediately() {
        var arbiter = TierArbiter(initial: .full, upgradeDelay: 30)
        #expect(arbiter.ingest(target: .essential, at: 0) == .essential)
    }

    @Test func upgradeWaitsForSustainedImprovement() {
        var arbiter = TierArbiter(initial: .full, upgradeDelay: 30)
        _ = arbiter.ingest(target: .reduced, at: 0)
        #expect(arbiter.ingest(target: .full, at: 5) == .reduced)   // pending
        #expect(arbiter.ingest(target: .full, at: 20) == .reduced)  // still pending
        #expect(arbiter.ingest(target: .full, at: 36) == .full)     // sustained past delay
    }

    @Test func relapseCancelsPendingUpgrade() {
        var arbiter = TierArbiter(initial: .full, upgradeDelay: 30)
        _ = arbiter.ingest(target: .reduced, at: 0)
        _ = arbiter.ingest(target: .full, at: 5)      // pending upgrade
        _ = arbiter.ingest(target: .reduced, at: 10)  // heats up again
        // A fresh improvement must wait the full delay from its own start.
        #expect(arbiter.ingest(target: .full, at: 20) == .reduced)
        #expect(arbiter.ingest(target: .full, at: 45) == .reduced)
        #expect(arbiter.ingest(target: .full, at: 51) == .full)
    }
}
