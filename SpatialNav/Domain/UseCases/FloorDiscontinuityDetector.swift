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
/// cannot see, a false "caution" beats a missed drop-off — we warn, and rely on
/// the floor-plausibility gate plus the ViewModel's debouncer to keep false
/// positives down (field finding: near probe landing on a chair seat used to
/// read as a drop-off).
nonisolated struct FloorDiscontinuityDetector: HazardAnalyzing {
    var dropThreshold: Float = 0.25
    var riseThreshold: Float = 0.15
    /// Rises beyond a plausible stair step (~2 steps over the probe span) are
    /// furniture/walls, which the horizontal fan already reports.
    var maxRiseThreshold: Float = 0.4
    /// The near hit must be at least this far below the camera to count as a
    /// floor reference; anything higher is furniture, and no judgment is made.
    var minFloorReferenceDepth: Float = 1.0
    /// A surface counts as walkable (floor/tread) only if its normal points
    /// up at least this much (~45°). A drawer front 30 cm up produces the same
    /// hit point as a stair tread 30 cm up; the normal is what tells them apart.
    var minUpFacingNormalY: Float = 0.7

    func hazards(from hits: [RaycastHit], frame: ARFrameSnapshot) -> [Hazard] {
        let near = hits.first { $0.ray == SonarConfiguration.nearFloorProbe }
        let far = hits.first { $0.ray == SonarConfiguration.farFloorProbe }

        guard let near else { return [] }

        let camera = frame.cameraTransform.translation
        guard camera.y - near.worldPosition.y >= minFloorReferenceDepth, isWalkableSurface(near) else {
            return []
        }

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
            // Deliberately not gated on the far surface normal: descending
            // stairs often present a riser face, and missing a drop-off is
            // worse than a rare extra caution.
            return [Hazard(id: UUID(), kind: .dropOff, distance: distance, direction: .twelve)]
        }
        if heightDelta > riseThreshold, heightDelta <= maxRiseThreshold, isWalkableSurface(far) {
            return [Hazard(id: UUID(), kind: .stairsUp, distance: distance, direction: .twelve)]
        }
        return []
    }

    /// Hits without a normal (older data, test fixtures) are treated as
    /// walkable so the absence of metadata never disables a safety warning.
    private func isWalkableSurface(_ hit: RaycastHit) -> Bool {
        hit.surfaceNormal.map { $0.y >= minUpFacingNormalY } ?? true
    }

    private func horizontalDistance(from camera: simd_float3, to point: simd_float3) -> Float {
        simd_length(simd_float2(point.x - camera.x, point.z - camera.z))
    }
}
