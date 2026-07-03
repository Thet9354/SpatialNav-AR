//
//  SpeechServicing.swift
//  SpatialNav
//

import Foundation

nonisolated protocol SpeechServicing: Sendable {
    /// Higher-priority announcements interrupt lower-priority speech in progress;
    /// equal or lower priority is queued. Critical must never wait.
    func announce(_ message: String, priority: FeedbackPriority) async
    func stopSpeaking() async
}
