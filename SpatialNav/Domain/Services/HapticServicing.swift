//
//  HapticServicing.swift
//  SpatialNav
//

import Foundation

nonisolated protocol HapticServicing: Sendable {
    var supportsHaptics: Bool { get }
    /// Starts the engine eagerly so the first hazard pattern fires with no
    /// engine-start latency.
    func prepare() async
    func play(_ event: FeedbackEvent) async
}
