//
//  ObjectDetectionUseCase.swift
//  SpatialNav
//

import Foundation
import simd

/// Drives the ML pipeline: consume sampled camera frames, run the detector,
/// locate each detection by raycasting its bounding-box center into the scene,
/// then temporally confirm before publishing.
///
/// Being an actor gives one-in-flight inference for free: frames arriving while
/// `process` runs are dropped by the provider stream (bufferingNewest 1), never queued.
actor ObjectDetectionUseCase {
    private let provider: any ARSessionProviding
    private let detector: any ObjectDetecting
    private var smoother: DetectionSmoother
    private var processingTask: Task<Void, Never>?
    private var continuations: [UUID: AsyncStream<[DetectedObject]>.Continuation] = [:]

    init(
        provider: any ARSessionProviding,
        detector: any ObjectDetecting,
        smoother: DetectionSmoother = DetectionSmoother()
    ) {
        self.provider = provider
        self.detector = detector
        self.smoother = smoother
    }

    func results() -> AsyncStream<[DetectedObject]> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
            continuations[id] = continuation
        }
    }

    func start() {
        guard processingTask == nil else { return }
        let stream = provider.pixelBuffers()
        processingTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self, !Task.isCancelled else { return }
                await self.process(snapshot)
            }
        }
    }

    func stop() {
        processingTask?.cancel()
        processingTask = nil
        smoother.reset()
        for continuation in continuations.values {
            continuation.yield([])
        }
    }

    private func process(_ snapshot: PixelBufferSnapshot) async {
        guard let detections = try? await detector.detect(in: snapshot), !detections.isEmpty else {
            publish(smoother.ingest([], at: snapshot.timestamp))
            return
        }

        let paired: [(detection: DetectedObject, ray: SonarRay)] = detections.map { detection in
            (detection, DetectionGeometry.sonarRay(
                visionBoundingBox: detection.boundingBox,
                intrinsics: snapshot.intrinsics,
                imageResolution: snapshot.imageResolution
            ))
        }
        let hits = await provider.raycast(paired.map(\.ray))
        let hitsByRay = Dictionary(hits.map { ($0.ray, $0) }, uniquingKeysWith: { first, _ in first })

        let located = paired.compactMap { pair -> DetectedObject? in
            guard let hit = hitsByRay[pair.ray] else { return nil }
            return DetectedObject(
                id: pair.detection.id,
                label: pair.detection.label,
                confidence: pair.detection.confidence,
                boundingBox: pair.detection.boundingBox,
                worldPosition: hit.worldPosition,
                distance: hit.distance,
                direction: ClockDirection(bearing: pair.ray.azimuth)
            )
        }

        publish(smoother.ingest(located, at: snapshot.timestamp))
    }

    private func publish(_ objects: [DetectedObject]) {
        for continuation in continuations.values {
            continuation.yield(objects)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }
}
