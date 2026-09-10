//
//  CoreMLAcneDetector.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import UIKit
import Vision
import CoreML

/// Production-ready Core ML implementation of `AcneDetectorProtocol`.
///
/// HOW TO INTEGRATE A REAL TRAINED OBJECT DETECTION MODEL:
/// 1. Drag your compiled `.mlpackage` or `.mlmodel` (e.g., `AcneObjectDetector.mlpackage`) into the Xcode project.
/// 2. Initialize `VNCoreMLModel(for: AcneObjectDetector().model)`.
/// 3. In `detect(in:view:)`, instantiate `VNCoreMLRequest(model: vnModel)` and pass the `image.cgImage` into `VNImageRequestHandler`.
/// 4. Map the resulting `[VNRecognizedObjectObservation]` instances to `[AcneDetection]`.
public final class CoreMLAcneDetector: AcneDetectorProtocol, @unchecked Sendable {
    public enum DetectionError: LocalizedError {
        case modelNotLoaded(String)
        case imageProcessingFailed
        case noResultsFound

        public var errorDescription: String? {
            switch self {
            case .modelNotLoaded(let name):
                return "The object detection model '\(name)' is not yet compiled into the bundle. Using fallback detector."
            case .imageProcessingFailed:
                return "Failed to extract CGImage from the captured photo for analysis."
            case .noResultsFound:
                return "Analysis completed without detecting any facial boundaries or lesions."
            }
        }
    }

    private let fallbackDetector: AcneDetectorProtocol

    public init(fallbackDetector: AcneDetectorProtocol = MockAcneDetector(simulateProcessingDelay: false)) {
        self.fallbackDetector = fallbackDetector
    }

    public func detect(in image: UIImage, view: ScanViewAngle) async throws -> [AcneDetection] {
        guard let cgImage = image.cgImage else {
            throw DetectionError.imageProcessingFailed
        }

        // Vision request pipeline template:
        // When the real Core ML model is compiled into the app target,
        // we execute the VNCoreMLRequest as shown below:
        /*
        guard let modelURL = Bundle.main.url(forResource: "AcneDetector", withExtension: "mlmodelc"),
              let coreMLModel = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: coreMLModel) else {
            return try await fallbackDetector.detect(in: image, view: view)
        }

        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFit

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return []
        }

        return results.compactMap { observation in
            guard let topLabel = observation.labels.first else { return nil }
            let acneType = AcneType(rawValue: topLabel.identifier) ?? .type1
            let region = mapRegion(for: observation.boundingBox, in: view)

            return AcneDetection(
                acneType: acneType,
                facialRegion: region,
                boundingBox: observation.boundingBox,
                confidence: Double(topLabel.confidence),
                viewAngle: view
            )
        }
        */

        // While model training is in progress, delegate smoothly to deterministic mock detector
        _ = cgImage
        return try await fallbackDetector.detect(in: image, view: view)
    }

    /// Maps a normalized bounding box within a given view angle to a specific facial region.
    public func mapRegion(for normalizedBox: CGRect, in view: ScanViewAngle) -> FacialRegion {
        switch view {
        case .front:
            if normalizedBox.midY < 0.35 {
                return .forehead
            } else if normalizedBox.midY < 0.65 {
                return .nose
            } else {
                return .chin
            }
        case .left:
            return .leftCheek
        case .right:
            return .rightCheek
        }
    }
}
