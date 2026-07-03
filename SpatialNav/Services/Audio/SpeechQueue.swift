//
//  SpeechQueue.swift
//  SpatialNav
//

import AVFAudio
import Foundation
import UIKit

/// Priority-arbitrated speech. When VoiceOver is running, announcements are
/// posted through UIAccessibility so VoiceOver arbitrates against its own
/// speech; otherwise a private AVSpeechSynthesizer is used with
/// SpeechQueuePolicy deciding who interrupts whom.
actor SpeechQueue: SpeechServicing {
    private let synthesizer = AVSpeechSynthesizer()
    private let bridge = DelegateBridge()
    private let policy = SpeechQueuePolicy()
    private var pending: [(message: String, priority: FeedbackPriority)] = []
    private var currentPriority: FeedbackPriority?
    var speechRate: Float

    init(speechRate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        self.speechRate = speechRate
        synthesizer.delegate = bridge
        bridge.onUtteranceEnded = { [weak self] in
            Task { await self?.advance() }
        }
    }

    func announce(_ message: String, priority: FeedbackPriority) async {
        let voiceOverRunning = await MainActor.run { UIAccessibility.isVoiceOverRunning }
        if voiceOverRunning {
            await MainActor.run {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
            return
        }

        switch policy.action(
            newPriority: priority,
            current: currentPriority,
            pendingPriorities: pending.map(\.priority)
        ) {
        case .speakNow(interruptCurrent: false):
            speak(message, priority: priority)
        case .speakNow(interruptCurrent: true):
            // Queue ours at the front; the cancel callback speaks it next.
            // If nothing was actually speaking (finish raced us), advance directly.
            pending.insert((message, priority), at: 0)
            if !synthesizer.stopSpeaking(at: .immediate) {
                advance()
            }
        case .enqueue(let index):
            pending.insert((message, priority), at: index)
        case .drop:
            break
        }
    }

    func stopSpeaking() {
        pending.removeAll()
        currentPriority = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func setRate(_ rate: Float) {
        speechRate = rate
    }

    // MARK: Private

    private func speak(_ message: String, priority: FeedbackPriority) {
        currentPriority = priority
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = speechRate
        synthesizer.speak(utterance)
    }

    private func advance() {
        currentPriority = nil
        guard !pending.isEmpty else { return }
        let next = pending.removeFirst()
        speak(next.message, priority: next.priority)
    }

    /// AVSpeechSynthesizer delegates arrive on an arbitrary queue; this bridge
    /// hops back into the actor. Finish and cancel both mean "slot is free".
    private final class DelegateBridge: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
        var onUtteranceEnded: (@Sendable () -> Void)?

        nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            onUtteranceEnded?()
        }

        nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            onUtteranceEnded?()
        }
    }
}
