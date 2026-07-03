//
//  HapticServicing.swift
//  SpatialNav
//

import Foundation

nonisolated protocol HapticServicing: Sendable {
    var supportsHaptics: Bool { get }
    func play(_ event: FeedbackEvent) async
}
