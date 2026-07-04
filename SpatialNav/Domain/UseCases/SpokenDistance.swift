//
//  SpokenDistance.swift
//  SpatialNav
//

import Foundation

/// Distances in the user's preferred unit. "Steps" uses the profile's stride
/// length — O&M practice often thinks in paces, not meters.
nonisolated enum SpokenDistance {
    static func description(
        meters: Float,
        unit: FeedbackProfile.DistanceUnit,
        strideLengthMeters: Float
    ) -> String {
        switch unit {
        case .meters:
            String(format: "%.1f meters", meters)
        case .feet:
            String(format: "%.0f feet", meters * 3.28084)
        case .steps:
            "\(max(1, Int((meters / max(strideLengthMeters, 0.1)).rounded()))) steps"
        }
    }
}
