//
//  HapticVocabulary.swift
//  SpatialNav
//

import Foundation

/// One beat of a haptic pattern. `duration` 0 means a transient tap;
/// otherwise a continuous rumble.
nonisolated struct HapticPulse: Sendable, Equatable {
    let time: TimeInterval
    let intensity: Float
    let sharpness: Float
    let duration: TimeInterval

    init(time: TimeInterval, intensity: Float, sharpness: Float, duration: TimeInterval = 0) {
        self.time = time
        self.intensity = intensity
        self.sharpness = sharpness
        self.duration = duration
    }
}

/// The haptic language: each event kind has a distinct, recognizable pattern
/// so a deaf-blind user can tell a drop-off from a person from an item beacon
/// by feel alone. Defined as pure values; the engine converts them to CoreHaptics.
nonisolated enum HapticVocabulary {

    static func pattern(for event: FeedbackEvent) -> [HapticPulse] {
        switch event.kind {
        case .hazardWarning(.dropOff), .hazardWarning(.stairsDown):
            // Two heavy thuds then a rumble: unmistakably "STOP".
            [
                HapticPulse(time: 0, intensity: 1.0, sharpness: 0.7),
                HapticPulse(time: 0.12, intensity: 1.0, sharpness: 0.7),
                HapticPulse(time: 0.26, intensity: 0.8, sharpness: 0.3, duration: 0.4),
            ]
        case .hazardWarning:
            // Triple sharp tap: attention, but not stop-dead.
            [
                HapticPulse(time: 0, intensity: 0.8, sharpness: 0.9),
                HapticPulse(time: 0.1, intensity: 0.8, sharpness: 0.9),
                HapticPulse(time: 0.2, intensity: 0.8, sharpness: 0.9),
            ]
        case .obstacleProximity:
            [HapticPulse(time: 0, intensity: proximityIntensity(forDistance: event.distance), sharpness: 0.6)]
        case .itemPing:
            // Light double tick, like a heartbeat: the beacon signature.
            [
                HapticPulse(time: 0, intensity: 0.5, sharpness: 0.9),
                HapticPulse(time: 0.08, intensity: 0.5, sharpness: 0.9),
            ]
        case .navigationCue, .status:
            [HapticPulse(time: 0, intensity: 0.4, sharpness: 0.3)]
        }
    }

    /// Closer obstacles thump harder: 1.0 at touching distance, 0.3 at range.
    static func proximityIntensity(forDistance distance: Float?) -> Float {
        guard let distance else { return 0.5 }
        let t = min(max((distance - 0.3) / (4.0 - 0.3), 0), 1)
        return 1.0 - 0.7 * t
    }
}
