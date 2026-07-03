//
//  SonarSweepUseCase.swift
//  SpatialNav
//

import Foundation
import simd

nonisolated struct SonarConfiguration: Sendable {
    var rayCount: Int = 9
    /// Total horizontal sweep, centered on forward.
    var horizontalArc: Float = .pi / 3
    /// Hits beyond this are ignored for obstacle alerts.
    var maxObstacleDistance: Float = 4.0

    /// Floor probes for discontinuity (drop-off/stairs) detection.
    /// At eye height (~1.5 m) the near probe lands ~0.6 m ahead, the far probe ~1.6 m.
    /// Gravity-aligned: angles are below the horizon, not below the camera axis,
    /// so tilting the phone up at a shelf can't swing them onto furniture.
    static let nearFloorProbe = SonarRay(azimuth: 0, elevation: -1.2, gravityAligned: true)
    static let farFloorProbe = SonarRay(azimuth: 0, elevation: -0.75, gravityAligned: true)

    static let `default` = SonarConfiguration()

    var allRays: [SonarRay] {
        SonarRay.fan(count: rayCount, arc: horizontalArc) + [Self.nearFloorProbe, Self.farFloorProbe]
    }
}

nonisolated struct SonarSweepResult: Sendable, Equatable {
    let obstacles: [Obstacle]
    let hazards: [Hazard]
}

/// One sonar cycle: cast the ray fan + floor probes, convert horizontal hits into
/// obstacles (distance, clock bearing, height band), and hand all hits to the
/// hazard analyzer. Pure except for the injected raycast — fully testable.
nonisolated final class SonarSweepUseCase: Sendable {
    private let provider: any ARSessionProviding
    private let hazardAnalyzer: any HazardAnalyzing
    private let configuration: SonarConfiguration

    init(
        provider: any ARSessionProviding,
        hazardAnalyzer: any HazardAnalyzing,
        configuration: SonarConfiguration = .default
    ) {
        self.provider = provider
        self.hazardAnalyzer = hazardAnalyzer
        self.configuration = configuration
    }

    /// `rayCount` lets the performance governor thin the fan under thermal
    /// pressure; floor probes are safety-critical and always cast.
    func sweep(frame: ARFrameSnapshot, rayCount: Int? = nil) async -> SonarSweepResult {
        let count = rayCount ?? configuration.rayCount
        let rays = SonarRay.fan(count: count, arc: configuration.horizontalArc)
            + [SonarConfiguration.nearFloorProbe, SonarConfiguration.farFloorProbe]
        let hits = await provider.raycast(rays)
        return SonarSweepResult(
            obstacles: Self.obstacles(from: hits, frame: frame, configuration: configuration),
            hazards: hazardAnalyzer.hazards(from: hits, frame: frame)
        )
    }

    static func obstacles(
        from hits: [RaycastHit],
        frame: ARFrameSnapshot,
        configuration: SonarConfiguration
    ) -> [Obstacle] {
        let cameraHeight = frame.cameraTransform.translation.y
        return hits
            .filter { $0.ray.elevation == 0 && $0.distance <= configuration.maxObstacleDistance }
            .map { hit in
                Obstacle(
                    id: UUID(),
                    worldPosition: hit.worldPosition,
                    distance: hit.distance,
                    direction: ClockDirection(bearing: hit.ray.azimuth),
                    elevation: elevationBand(hitHeight: hit.worldPosition.y, cameraHeight: cameraHeight)
                )
            }
    }

    /// Height bands relative to the camera (held near eye/chest height):
    /// within 0.4 m of the camera or above = head, next 0.7 m down = waist, below = floor.
    static func elevationBand(hitHeight: Float, cameraHeight: Float) -> Obstacle.Elevation {
        let depthBelowCamera = cameraHeight - hitHeight
        if depthBelowCamera < 0.4 { return .head }
        if depthBelowCamera < 1.1 { return .waist }
        return .floor
    }
}
