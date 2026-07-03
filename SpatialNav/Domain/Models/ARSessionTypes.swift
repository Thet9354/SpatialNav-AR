//
//  ARSessionTypes.swift
//  SpatialNav
//

import Foundation

nonisolated enum ARSessionEvent: Sendable, Equatable {
    case interrupted
    case interruptionEnded
    case failed(String)
}

nonisolated enum ARSessionError: Error, Equatable {
    case worldTrackingUnsupported
    case worldMapUnavailable
    case invalidWorldMapData
}

nonisolated struct ARCapabilities: Sendable, Equatable {
    let supportsWorldTracking: Bool
    /// True only on LiDAR devices; gates Sonar Mode and mesh-based hazards.
    let supportsSceneReconstruction: Bool
    let supportsSceneDepth: Bool
}
