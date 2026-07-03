//
//  YOLODetectionService.swift
//  SpatialNav
//
//  Expects a YOLO model exported with NMS baked in (see scripts/convert_yolo_to_coreml.py)
//  so Vision surfaces results as VNRecognizedObjectObservation. Drop the exported
//  .mlpackage into SpatialNav/Resources/MLModels/ and Xcode compiles it into the bundle.
//

import CoreML
import Foundation
import Vision

nonisolated enum DetectionServiceError: Error {
    case modelNotBundled(String)
}

nonisolated final class YOLODetectionService: ObjectDetecting, @unchecked Sendable {
    /// Immutable after init; Vision requests are created per call.
    private let visionModel: VNCoreMLModel
    private let confidenceThreshold: Float

    init(modelName: String = "yolov8n", confidenceThreshold: Float = 0.35) throws {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw DetectionServiceError.modelNotBundled(modelName)
        }
        let configuration = MLModelConfiguration()
        // Excluding the GPU keeps it free for RealityKit rendering and runs cooler.
        configuration.computeUnits = .cpuAndNeuralEngine
        self.visionModel = try VNCoreMLModel(for: MLModel(contentsOf: url, configuration: configuration))
        self.confidenceThreshold = confidenceThreshold
    }

    func detect(in snapshot: PixelBufferSnapshot) async throws -> [DetectedObject] {
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill
        // .right: the app runs portrait, so the landscape buffer is rotated 90° CW
        // for the model. DetectionGeometry inverts the same rotation.
        let handler = VNImageRequestHandler(cvPixelBuffer: snapshot.buffer, orientation: .right)
        try handler.perform([request])
        let observations = request.results as? [VNRecognizedObjectObservation] ?? []
        return observations.compactMap { observation in
            guard
                let topLabel = observation.labels.first,
                observation.confidence >= confidenceThreshold
            else { return nil }
            return DetectedObject(
                id: UUID(),
                label: topLabel.identifier,
                confidence: observation.confidence,
                boundingBox: observation.boundingBox,
                worldPosition: nil,
                distance: nil,
                direction: nil
            )
        }
    }
}
