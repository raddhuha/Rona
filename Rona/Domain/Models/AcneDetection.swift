//
//  AcneDetection.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation
import CoreGraphics

/// An individual acne lesion detected by the ML detection pipeline.
public struct AcneDetection: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let acneType: AcneType
    public let facialRegion: FacialRegion
    public let boundingBox: CGRect // Normalized [0, 1] relative coordinates: (x, y, width, height)
    public let confidence: Double
    public let viewAngle: ScanViewAngle

    public init(
        id: UUID = UUID(),
        acneType: AcneType,
        facialRegion: FacialRegion = .forehead,
        boundingBox: CGRect,
        confidence: Double = 0.9,
        viewAngle: ScanViewAngle = .front
    ) {
        self.id = id
        self.acneType = acneType
        self.facialRegion = facialRegion
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.viewAngle = viewAngle
    }
}
