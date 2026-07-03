//
//  FeaturePrintService.swift
//  SpatialNav
//

import Foundation
import Vision

nonisolated struct FeaturePrintService: FeaturePrinting {
    func featurePrint(for snapshot: PixelBufferSnapshot) async throws -> Data {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: snapshot.buffer, orientation: .right)
        try handler.perform([request])
        guard let observation = request.results?.first as? VNFeaturePrintObservation else {
            throw FeaturePrintError.noObservation
        }
        return try NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
    }

    func distance(between lhs: Data, and rhs: Data) throws -> Float {
        guard
            let first = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: lhs),
            let second = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: rhs)
        else {
            throw FeaturePrintError.invalidData
        }
        var distance: Float = 0
        try first.computeDistance(&distance, to: second)
        return distance
    }
}
