//
//  PerformanceGoverning.swift
//  SpatialNav
//

import Foundation

nonisolated protocol PerformanceGoverning: Sendable {
    var currentTier: ProcessingTier { get async }
    /// Emits on every tier change; implementations must apply hysteresis so
    /// subsystems don't oscillate between tiers.
    func tiers() -> AsyncStream<ProcessingTier>
}
