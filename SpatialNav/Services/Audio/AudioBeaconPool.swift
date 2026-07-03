//
//  AudioBeaconPool.swift
//  SpatialNav
//

import AVFAudio

/// Fixed pool of mono player nodes, attached once at engine setup and reused
/// round-robin — allocating nodes per ping rebuilds the audio graph and
/// glitches. Not Sendable by design: owned and confined by SpatialAudioEngine.
nonisolated final class AudioBeaconPool {
    private let players: [AVAudioPlayerNode]
    private var nextIndex = 0

    init(engine: AVAudioEngine, environment: AVAudioEnvironmentNode, nodeCount: Int, format: AVAudioFormat) {
        players = (0..<nodeCount).map { _ in
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: environment, format: format)
            player.renderingAlgorithm = .HRTFHQ
            return player
        }
    }

    func play(buffer: AVAudioPCMBuffer, at position: AVAudio3DPoint) {
        let player = players[nextIndex]
        nextIndex = (nextIndex + 1) % players.count
        if player.isPlaying {
            player.stop()
        }
        player.position = position
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func stopAll() {
        for player in players {
            player.stop()
        }
    }
}
