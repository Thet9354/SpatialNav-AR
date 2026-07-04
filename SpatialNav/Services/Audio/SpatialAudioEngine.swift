//
//  SpatialAudioEngine.swift
//  SpatialNav
//

import AVFAudio
import Foundation
import simd

nonisolated enum SpatialAudioError: Error {
    case monoFormatUnavailable
}

/// HRTF-spatialized audio: the listener tracks the camera pose, so a ping
/// played at an obstacle's world position genuinely sounds like it comes from
/// there. Graph is built once at start (environment node + beacon pool);
/// engine stalls from route changes/interruptions are recovered, never rebuilt.
actor SpatialAudioEngine: SpatialAudioServicing {
    private let engine = AVAudioEngine()
    private let environment = AVAudioEnvironmentNode()
    private var pool: AudioBeaconPool?
    private let audioMap = SonarAudioMap()
    private var bufferCache: [Int: AVAudioPCMBuffer] = [:]
    private var observers: [NSObjectProtocol] = []
    private var started = false

    func startEngine() throws {
        guard !started else { return }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try session.setActive(true)

        engine.attach(environment)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)
        guard let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
            throw SpatialAudioError.monoFormatUnavailable
        }
        if pool == nil {
            pool = AudioBeaconPool(engine: engine, environment: environment, nodeCount: 8, format: monoFormat)
        }
        try engine.start()
        started = true
        observeEngineHealth()

        // Pre-synthesize the ping range so no first-use synthesis cost lands
        // mid-alert (~16 short mono buffers; negligible memory).
        for frequency in stride(from: 400, through: 1250, by: 50) {
            _ = buffer(for: Float(frequency))
        }
        _ = buffer(for: 990) // item beacon
        _ = buffer(for: 660) // hazard tone
    }

    func stopEngine() {
        guard started else { return }
        started = false
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        pool?.stopAll()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func updateListener(transform: simd_float4x4) {
        guard started else { return }
        let position = transform.translation
        environment.listenerPosition = AVAudio3DPoint(x: position.x, y: position.y, z: position.z)
        let forward = transform.forwardVector
        let up = transform.upVector
        environment.listenerVectorOrientation = AVAudio3DVectorOrientation(
            forward: AVAudio3DVector(x: forward.x, y: forward.y, z: forward.z),
            up: AVAudio3DVector(x: up.x, y: up.y, z: up.z)
        )
    }

    func play(_ event: FeedbackEvent, at position: simd_float3?) {
        guard started, let pool else { return }
        let frequency: Float = switch event.kind {
        case .itemPing: 990 // distinct identity from obstacle pings
        case .hazardWarning: 660
        default: audioMap.frequency(forDistance: event.distance ?? audioMap.maxDistance)
        }
        guard let buffer = buffer(for: frequency) else { return }
        // Non-spatial events play at the listener, i.e. centered.
        let point = position.map { AVAudio3DPoint(x: $0.x, y: $0.y, z: $0.z) } ?? environment.listenerPosition
        pool.play(buffer: buffer, at: point)
    }

    // MARK: Private

    private func buffer(for frequency: Float) -> AVAudioPCMBuffer? {
        // Quantize to 50 Hz steps so the cache stays small.
        let key = Int((frequency / 50).rounded()) * 50
        if let cached = bufferCache[key] { return cached }
        let buffer = ToneGenerator.pingBuffer(frequency: Float(key))
        bufferCache[key] = buffer
        return buffer
    }

    /// Route changes (headphones in/out) and interruptions (calls, Siri) stop
    /// the engine; state is recovered rather than the graph rebuilt.
    private func observeEngineHealth() {
        let names: [Notification.Name] = [
            .AVAudioEngineConfigurationChange,
            AVAudioSession.interruptionNotification,
        ]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                Task { await self?.recoverIfNeeded() }
            }
        }
    }

    private func recoverIfNeeded() {
        guard started, !engine.isRunning else { return }
        try? engine.start()
    }
}
