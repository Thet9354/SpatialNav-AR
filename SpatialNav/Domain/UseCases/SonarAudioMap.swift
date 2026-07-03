//
//  SonarAudioMap.swift
//  SpatialNav
//

import Foundation

/// Distance → sound mapping for Sonar Mode: closer obstacles ping higher and
/// faster, like a parking sensor. Linear interpolation, clamped to the range.
nonisolated struct SonarAudioMap: Sendable {
    var minDistance: Float = 0.3
    var maxDistance: Float = 4.0
    var nearFrequency: Float = 1200
    var farFrequency: Float = 440
    var nearPulseInterval: TimeInterval = 0.15
    var farPulseInterval: TimeInterval = 1.0

    func frequency(forDistance distance: Float) -> Float {
        nearFrequency + (farFrequency - nearFrequency) * normalized(distance)
    }

    func pulseInterval(forDistance distance: Float) -> TimeInterval {
        nearPulseInterval + (farPulseInterval - nearPulseInterval) * TimeInterval(normalized(distance))
    }

    private func normalized(_ distance: Float) -> Float {
        let t = (distance - minDistance) / (maxDistance - minDistance)
        return Swift.min(Swift.max(t, 0), 1)
    }
}
