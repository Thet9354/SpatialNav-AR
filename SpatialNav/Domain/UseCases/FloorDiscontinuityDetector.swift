//
//  FloorDiscontinuityDetector.swift
//  SpatialNav
//

import Foundation
import simd

/// Detects drop-offs and stairs by comparing the two floor probes: if the far
/// probe lands significantly below the near probe (or finds no floor at all),
/// the ground ahead falls away. Stateless and pure per-call.
///
/// Safety bias: a missing far hit may just be unmeshed area, but for a user who
/// cannot see, a false "caution" beats a missed drop-off — we always warn.
nonisolated struct FloorDiscontinuityDetector: HazardAnalyzing {
    var dropThreshold: Float = 0.25
    var riseThreshold: Float = 0.15

    func hazards(from hits: [RaycastHit], frame: ARFrameSnapshot) -> [Hazard] {
        let near = hits.first { $0.ray == SonarConfiguration.nearFloorProbe }
        let far = hits.first { $0.ray == SonarConfiguration.farFloorProbe }

        guard let near else { return [] }

        let camera = frame.cameraTransform.translation

        guard let far else {
            return [Hazard(
                id: UUID(),
                kind: .dropOff,
                distance: horizontalDistance(from: camera, to: near.worldPosition),
                direction: .twelve
            )]
        }

        let heightDelta = far.worldPosition.y - near.worldPosition.y
        let distance = horizontalDistance(from: camera, to: far.worldPosition)

        if heightDelta < -dropThreshold {
            return [Hazard(id: UUID(), kind: .dropOff, distance: distance, direction: .twelve)]
        }
        if heightDelta > riseThreshold {
            return [Hazard(id: UUID(), kind: .stairsUp, distance: distance, direction: .twelve)]
        }
        return []
    }

    private func horizontalDistance(from camera: simd_float3, to point: simd_float3) -> Float {
        simd_length(simd_float2(point.x - camera.x, point.z - camera.z))
    }
}
