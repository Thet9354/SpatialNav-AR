//
//  RelocalizationWatchdog.swift
//  SpatialNav
//

import Foundation

/// A blind user cannot "point the phone at a distinctive area" to help a stuck
/// relocalization. If the session stays in relocalizing past the timeout, we
/// give up honestly: announce it and start fresh instead of guiding on stale
/// data. Fires once per stuck episode.
nonisolated struct RelocalizationWatchdog: Sendable {
    var timeout: TimeInterval

    private var relocalizingSince: TimeInterval?

    init(timeout: TimeInterval = 10) {
        self.timeout = timeout
    }

    /// Returns true exactly when the caller should abandon relocalization.
    mutating func ingest(quality: TrackingQuality, at time: TimeInterval) -> Bool {
        guard case .limited(.relocalizing) = quality else {
            relocalizingSince = nil
            return false
        }
        guard let since = relocalizingSince else {
            relocalizingSince = time
            return false
        }
        if time - since >= timeout {
            relocalizingSince = nil // reset so a new episode starts a new timer
            return true
        }
        return false
    }
}
