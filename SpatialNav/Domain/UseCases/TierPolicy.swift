//
//  TierPolicy.swift
//  SpatialNav
//

import Foundation

/// Domain mirror of ProcessInfo.ThermalState so the policy stays framework-free.
nonisolated enum ThermalLevel: Sendable, Equatable {
    case nominal
    case fair
    case serious
    case critical
}

/// Maps device conditions to a target processing tier. The most constrained
/// input wins, so a cool phone in Low Power Mode still runs reduced.
nonisolated struct TierPolicy: Sendable {
    /// Below this battery fraction, cap at .reduced.
    var lowBatteryThreshold: Float = 0.2
    /// Below this battery fraction, cap at .essential.
    var criticalBatteryThreshold: Float = 0.1

    func target(
        thermal: ThermalLevel,
        isLowPowerMode: Bool,
        batteryLevel: Float?
    ) -> ProcessingTier {
        var tier: ProcessingTier = switch thermal {
        case .nominal, .fair: .full
        case .serious: .reduced
        case .critical: .essential
        }
        if isLowPowerMode {
            tier = min(tier, .reduced)
        }
        // Battery reports -1 when unknown (e.g. simulator); ignore those.
        if let batteryLevel, batteryLevel >= 0 {
            if batteryLevel < criticalBatteryThreshold {
                tier = min(tier, .essential)
            } else if batteryLevel < lowBatteryThreshold {
                tier = min(tier, .reduced)
            }
        }
        return tier
    }
}

/// Hysteresis between target and applied tier: downgrades apply immediately
/// (protect the device), upgrades only after the better target has been
/// sustained for `upgradeDelay`, so tiers can't oscillate at a thermal boundary.
nonisolated struct TierArbiter: Sendable {
    var upgradeDelay: TimeInterval

    private(set) var current: ProcessingTier
    private var pendingUpgrade: (tier: ProcessingTier, since: TimeInterval)?

    init(initial: ProcessingTier = .full, upgradeDelay: TimeInterval = 30) {
        self.current = initial
        self.upgradeDelay = upgradeDelay
    }

    mutating func ingest(target: ProcessingTier, at time: TimeInterval) -> ProcessingTier {
        if target < current {
            current = target
            pendingUpgrade = nil
        } else if target == current {
            pendingUpgrade = nil
        } else if let pending = pendingUpgrade, pending.tier == target {
            if time - pending.since >= upgradeDelay {
                current = target
                pendingUpgrade = nil
            }
        } else {
            pendingUpgrade = (target, time)
        }
        return current
    }
}
