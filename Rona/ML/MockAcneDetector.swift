//
//  MockAcneDetector.swift
//  Rona
//
//  ============================================================================
//  MOCK / DEVELOPMENT ONLY
//  ============================================================================
//  This implementation provides deterministic synthetic acne detections
//  for development and testing prior to training and deploying the Core ML model.
//

import UIKit

/// Mock implementation of `AcneDetectorProtocol` generating deterministic acne detections.
public final class MockAcneDetector: AcneDetectorProtocol, @unchecked Sendable {
    public let simulateProcessingDelay: Bool

    public init(simulateProcessingDelay: Bool = true) {
        self.simulateProcessingDelay = simulateProcessingDelay
    }

    public func detect(in image: UIImage, view: ScanViewAngle) async throws -> [AcneDetection] {
        if simulateProcessingDelay {
            // Realistic simulated inference time
            try await Task.sleep(nanoseconds: 600_000_000)
        }

        // Return deterministic mock detections based strictly on the view perspective
        switch view {
        case .front:
            return generateFrontDetections()
        case .left:
            return generateLeftCheekDetections()
        case .right:
            return generateRightCheekDetections()
        }
    }

    // MARK: - Deterministic Generators

    private func generateFrontDetections() -> [AcneDetection] {
        [
            // Forehead lesions (normalized: upper third of face, centered)
            AcneDetection(
                acneType: .type1, // Whitehead
                facialRegion: .forehead,
                boundingBox: CGRect(x: 0.38, y: 0.22, width: 0.05, height: 0.04),
                confidence: 0.94,
                viewAngle: .front
            ),
            AcneDetection(
                acneType: .type1, // Whitehead
                facialRegion: .forehead,
                boundingBox: CGRect(x: 0.48, y: 0.19, width: 0.04, height: 0.035),
                confidence: 0.91,
                viewAngle: .front
            ),
            AcneDetection(
                acneType: .type3, // Papules
                facialRegion: .forehead,
                boundingBox: CGRect(x: 0.58, y: 0.24, width: 0.05, height: 0.045),
                confidence: 0.89,
                viewAngle: .front
            ),

            // Nose lesion (normalized: middle center)
            AcneDetection(
                acneType: .type2, // Blackhead
                facialRegion: .nose,
                boundingBox: CGRect(x: 0.47, y: 0.48, width: 0.035, height: 0.03),
                confidence: 0.86,
                viewAngle: .front
            ),

            // Chin lesions (normalized: lower third)
            AcneDetection(
                acneType: .type1, // Whitehead
                facialRegion: .chin,
                boundingBox: CGRect(x: 0.44, y: 0.72, width: 0.04, height: 0.035),
                confidence: 0.92,
                viewAngle: .front
            ),
            AcneDetection(
                acneType: .type4, // Pustules
                facialRegion: .chin,
                boundingBox: CGRect(x: 0.52, y: 0.76, width: 0.05, height: 0.045),
                confidence: 0.88,
                viewAngle: .front
            )
        ]
    }

    private func generateLeftCheekDetections() -> [AcneDetection] {
        [
            AcneDetection(
                acneType: .type1, // Whitehead
                facialRegion: .leftCheek,
                boundingBox: CGRect(x: 0.42, y: 0.45, width: 0.045, height: 0.04),
                confidence: 0.93,
                viewAngle: .left
            ),
            AcneDetection(
                acneType: .type2, // Blackhead
                facialRegion: .leftCheek,
                boundingBox: CGRect(x: 0.50, y: 0.52, width: 0.04, height: 0.035),
                confidence: 0.90,
                viewAngle: .left
            ),
            AcneDetection(
                acneType: .type3, // Papules
                facialRegion: .leftCheek,
                boundingBox: CGRect(x: 0.58, y: 0.48, width: 0.05, height: 0.045),
                confidence: 0.87,
                viewAngle: .left
            )
        ]
    }

    private func generateRightCheekDetections() -> [AcneDetection] {
        [
            AcneDetection(
                acneType: .type1, // Whitehead
                facialRegion: .rightCheek,
                boundingBox: CGRect(x: 0.40, y: 0.44, width: 0.045, height: 0.04),
                confidence: 0.92,
                viewAngle: .right
            ),
            AcneDetection(
                acneType: .type3, // Papules
                facialRegion: .rightCheek,
                boundingBox: CGRect(x: 0.52, y: 0.50, width: 0.05, height: 0.045),
                confidence: 0.89,
                viewAngle: .right
            )
        ]
    }
}
