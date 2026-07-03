//
//  SpeechQueuePolicy.swift
//  SpatialNav
//

import Foundation

/// Pure arbitration for the speech queue: a higher-priority announcement
/// interrupts speech in progress; equal or lower priority waits its turn in
/// priority order. "Chair at 2 o'clock" must never talk over "DROP-OFF AHEAD".
nonisolated struct SpeechQueuePolicy: Sendable {
    nonisolated enum Action: Equatable {
        case speakNow(interruptCurrent: Bool)
        case enqueue(at: Int)
        case drop
    }

    /// Older low-priority chatter is dropped rather than queued forever.
    var maxQueueDepth: Int = 4

    func action(
        newPriority: FeedbackPriority,
        current: FeedbackPriority?,
        pendingPriorities: [FeedbackPriority]
    ) -> Action {
        guard let current else {
            return .speakNow(interruptCurrent: false)
        }
        if newPriority > current {
            return .speakNow(interruptCurrent: true)
        }
        if pendingPriorities.count >= maxQueueDepth,
           let lowest = pendingPriorities.min(),
           newPriority <= lowest {
            return .drop
        }
        let index = pendingPriorities.firstIndex { $0 < newPriority } ?? pendingPriorities.count
        return .enqueue(at: index)
    }
}
