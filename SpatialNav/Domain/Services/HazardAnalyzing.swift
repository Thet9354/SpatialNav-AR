//
//  HazardAnalyzing.swift
//  SpatialNav
//

import Foundation

nonisolated protocol HazardAnalyzing: Sendable {
    /// Pure classification of raycast results into hazards; no side effects,
    /// so implementations are trivially unit-testable.
    func hazards(from hits: [RaycastHit], frame: ARFrameSnapshot) -> [Hazard]
}
