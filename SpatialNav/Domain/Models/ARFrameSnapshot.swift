//
//  ARFrameSnapshot.swift
//  SpatialNav
//

import Foundation
import simd

/// Sendable value snapshot extracted from an ARFrame at the delegate boundary.
/// ARKit framework objects (ARFrame, ARCamera) never cross an isolation boundary;
/// only these snapshots do.
nonisolated struct ARFrameSnapshot: Sendable {
    let timestamp: TimeInterval
    let cameraTransform: simd_float4x4
    let trackingQuality: TrackingQuality
}

nonisolated enum TrackingQuality: Sendable, Equatable {
    nonisolated enum LimitedReason: Sendable, Equatable {
        case initializing
        case excessiveMotion
        case insufficientFeatures
        case relocalizing
    }

    case notAvailable
    case limited(LimitedReason)
    case normal

    var statusDescription: String {
        switch self {
        case .normal: "Tracking normal"
        case .notAvailable: "Tracking unavailable"
        case .limited(.initializing): "Starting up — move your phone slowly"
        case .limited(.excessiveMotion): "Moving too fast — slow down"
        case .limited(.insufficientFeatures): "Not enough visual detail here"
        case .limited(.relocalizing): "Finding your position"
        }
    }
}
