//
//  ToneGeneratorTests.swift
//  SpatialNavTests
//

import AVFAudio
import Foundation
import Testing
@testable import SpatialNav

struct ToneGeneratorTests {

    @Test func producesMonoBufferOfRequestedLength() throws {
        let buffer = try #require(ToneGenerator.pingBuffer(frequency: 880, duration: 0.12, sampleRate: 44_100))
        #expect(buffer.format.channelCount == 1)
        #expect(buffer.frameLength == AVAudioFrameCount(0.12 * 44_100))
    }

    @Test func signalIsAudibleAndWithinUnitRange() throws {
        let buffer = try #require(ToneGenerator.pingBuffer(frequency: 880))
        let samples = try #require(buffer.floatChannelData?[0])
        var peak: Float = 0
        for frame in 0..<Int(buffer.frameLength) {
            peak = max(peak, abs(samples[frame]))
        }
        #expect(peak > 0.1)  // not silence
        #expect(peak <= 1.0) // no clipping
    }

    @Test func envelopeStartsAndEndsQuiet() throws {
        // Attack from zero and exponential decay: no click at either end.
        let buffer = try #require(ToneGenerator.pingBuffer(frequency: 880))
        let samples = try #require(buffer.floatChannelData?[0])
        let last = Int(buffer.frameLength) - 1
        #expect(abs(samples[0]) < 0.01)
        #expect(abs(samples[last]) < 0.1)
    }

    @Test func invalidParametersReturnNil() {
        #expect(ToneGenerator.pingBuffer(frequency: 0) == nil)
        #expect(ToneGenerator.pingBuffer(frequency: 880, duration: 0) == nil)
    }
}
