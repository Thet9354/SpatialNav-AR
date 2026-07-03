//
//  PerformanceGoverning.swift
//  SpatialNav
//

import Foundation

nonisolated protocol PerformanceGoverning: Sendable {
    var currentTier: ProcessingTier { get async }
    /// Emits the current tier on subscription, then on every change;
    /// implementations must apply hysteresis so subsystems don't oscillate.
    func tiers() async -> AsyncStream<ProcessingTier>
    func start() async
    func stop() async
}
