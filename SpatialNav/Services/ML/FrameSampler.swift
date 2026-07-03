//
//  FrameSampler.swift
//  SpatialNav
//

import Foundation

/// Decides which camera frames reach the ML pipeline. ARKit delivers 60 fps;
/// inference is perceptually sufficient at a few fps and running per-frame
/// would cook the device. First frame always passes.
nonisolated struct FrameSampler: Sendable {
    private(set) var interval: TimeInterval
    private var lastEmission: TimeInterval = -.infinity

    init(framesPerSecond: Double) {
        self.interval = framesPerSecond > 0 ? 1.0 / framesPerSecond : .infinity
    }

    mutating func setRate(framesPerSecond: Double) {
        interval = framesPerSecond > 0 ? 1.0 / framesPerSecond : .infinity
    }

    mutating func shouldEmit(at timestamp: TimeInterval) -> Bool {
        // An infinite interval means "disabled" — without this guard the first
        // frame would slip through because (t - -inf) >= inf is true.
        guard interval.isFinite else { return false }
        guard timestamp - lastEmission >= interval else { return false }
        lastEmission = timestamp
        return true
    }
}
