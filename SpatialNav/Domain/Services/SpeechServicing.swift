//
//  SpeechServicing.swift
//  SpatialNav
//

import Foundation

nonisolated protocol SpeechServicing: Sendable {
    /// Warms the synthesizer so the first real announcement doesn't pay the
    /// engine's cold-start cost (hundreds of ms) at the worst possible moment.
    func prepare() async
    /// Higher-priority announcements interrupt lower-priority speech in progress;
    /// equal or lower priority is queued. Critical must never wait.
    func announce(_ message: String, priority: FeedbackPriority) async
    func stopSpeaking() async
    /// AVSpeechUtterance rate domain, from the user's profile.
    func setRate(_ rate: Float) async
}
