//
//  AcneDetectionRecord.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation
import SwiftData
import CoreGraphics

/// SwiftData persisted entity for an individual detected acne lesion.
@Model
public final class AcneDetectionRecord {
    public var id: UUID = UUID()
    public var acneTypeRaw: String = "type1"
    public var regionRaw: String = "forehead"
    public var confidence: Double = 0.9
    public var x: Double = 0.0
    public var y: Double = 0.0
    public var width: Double = 0.0
    public var height: Double = 0.0
    public var viewAngleRaw: String = "front"

    @Relationship(inverse: \ScanRecord.detections)
    public var scanRecord: ScanRecord?

    public init(
        id: UUID = UUID(),
        acneTypeRaw: String,
        regionRaw: String,
        confidence: Double,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        viewAngleRaw: String
    ) {
        self.id = id
        self.acneTypeRaw = acneTypeRaw
        self.regionRaw = regionRaw
        self.confidence = confidence
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.viewAngleRaw = viewAngleRaw
    }

    public convenience init(from detection: AcneDetection) {
        self.init(
            id: detection.id,
            acneTypeRaw: detection.acneType.rawValue,
            regionRaw: detection.facialRegion.rawValue,
            confidence: detection.confidence,
            x: Double(detection.boundingBox.origin.x),
            y: Double(detection.boundingBox.origin.y),
            width: Double(detection.boundingBox.size.width),
            height: Double(detection.boundingBox.size.height),
            viewAngleRaw: detection.viewAngle.rawValue
        )
    }

    // MARK: - Domain Mapping

    public var acneType: AcneType {
        AcneType(rawValue: acneTypeRaw) ?? .type1
    }

    public var facialRegion: FacialRegion {
        FacialRegion(rawValue: regionRaw) ?? .forehead
    }

    public var viewAngle: ScanViewAngle {
        ScanViewAngle(rawValue: viewAngleRaw) ?? .front
    }

    public var boundingBox: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    public func toDomain() -> AcneDetection {
        AcneDetection(
            id: id,
            acneType: acneType,
            facialRegion: facialRegion,
            boundingBox: boundingBox,
            confidence: confidence,
            viewAngle: viewAngle
        )
    }
}
