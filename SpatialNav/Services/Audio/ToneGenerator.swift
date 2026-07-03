//
//  ToneGenerator.swift
//  SpatialNav
//

import AVFAudio
import Foundation

/// Synthesizes the sonar ping in code — a short sine burst with a fast attack
/// and exponential decay. Mono, because only mono sources get HRTF-spatialized
/// by AVAudioEnvironmentNode.
nonisolated enum ToneGenerator {
    static func pingBuffer(
        frequency: Float,
        duration: Double = 0.12,
        sampleRate: Double = 44_100
    ) -> AVAudioPCMBuffer? {
        guard
            frequency > 0,
            duration > 0,
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        else { return nil }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return nil }

        let totalFrames = Int(frameCount)
        let attackFrames = max(1, min(Int(0.005 * sampleRate), totalFrames))
        for frame in 0..<totalFrames {
            let time = Float(frame) / Float(sampleRate)
            let sine = sin(2 * Float.pi * frequency * time)
            let attack = frame < attackFrames ? Float(frame) / Float(attackFrames) : 1
            let decay = exp(-4 * Float(frame) / Float(totalFrames))
            samples[frame] = sine * attack * decay * 0.8
        }
        return buffer
    }
}
