//
//  HapticEngineService.swift
//  SpatialNav
//

import CoreHaptics
import Foundation

/// Plays the HapticVocabulary through CoreHaptics. CHHapticEngine dies silently
/// on audio route changes (connecting AirPods!) and interruptions, so the
/// engine is health-checked before every pattern and rebuilt via the
/// reset/stopped handlers rather than assumed alive.
actor HapticEngineService: HapticServicing {
    nonisolated let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var engineRunning = false

    func play(_ event: FeedbackEvent) {
        guard supportsHaptics else { return }
        let pulses = HapticVocabulary.pattern(for: event)
        guard !pulses.isEmpty, let engine = runningEngine() else { return }
        do {
            let pattern = try CHHapticPattern(events: pulses.map(Self.hapticEvent(from:)), parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // One retry with a fresh engine; a second failure drops the pulse
            // (haptics are best-effort, alerts also travel on other channels).
            engineRunning = false
            self.engine = nil
            if let retryEngine = runningEngine(),
               let pattern = try? CHHapticPattern(events: pulses.map(Self.hapticEvent(from:)), parameters: []),
               let player = try? retryEngine.makePlayer(with: pattern) {
                try? player.start(atTime: CHHapticTimeImmediate)
            }
        }
    }

    // MARK: Private

    private func runningEngine() -> CHHapticEngine? {
        if let engine, engineRunning {
            return engine
        }
        do {
            let engine = try self.engine ?? makeEngine()
            try engine.start()
            self.engine = engine
            engineRunning = true
            return engine
        } catch {
            engineRunning = false
            return nil
        }
    }

    private func makeEngine() throws -> CHHapticEngine {
        let engine = try CHHapticEngine()
        engine.resetHandler = { [weak self] in
            Task { await self?.markStopped() }
        }
        engine.stoppedHandler = { [weak self] _ in
            Task { await self?.markStopped() }
        }
        return engine
    }

    private func markStopped() {
        engineRunning = false
    }

    private static nonisolated func hapticEvent(from pulse: HapticPulse) -> CHHapticEvent {
        let parameters = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: pulse.intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: pulse.sharpness),
        ]
        if pulse.duration > 0 {
            return CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: parameters,
                relativeTime: pulse.time,
                duration: pulse.duration
            )
        }
        return CHHapticEvent(eventType: .hapticTransient, parameters: parameters, relativeTime: pulse.time)
    }
}
