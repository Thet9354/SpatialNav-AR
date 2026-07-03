//
//  ProcessingTier.swift
//  SpatialNav
//

import Foundation

/// Published by the performance governor from thermal/battery state.
/// Every expensive subsystem (ML sampling, mesh reconstruction, sonar rays)
/// subscribes and degrades gracefully rather than letting the OS throttle us.
nonisolated enum ProcessingTier: Int, Sendable, Comparable, Equatable {
    case essential
    case reduced
    case full

    static func < (lhs: ProcessingTier, rhs: ProcessingTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var mlFramesPerSecond: Double {
        switch self {
        case .full: 10
        case .reduced: 4
        case .essential: 0
        }
    }

    var sonarRayCount: Int {
        switch self {
        case .full: 9
        case .reduced: 5
        case .essential: 3
        }
    }

    var meshReconstructionEnabled: Bool {
        self != .essential
    }
}
