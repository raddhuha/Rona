//
//  SkinScanSession.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import UIKit

/// In-memory representation of a 3-view scan session during capture and analysis.
public struct SkinScanSession {
    public var date: Date
    public var frontImage: UIImage?
    public var leftImage: UIImage?
    public var rightImage: UIImage?
    public var detections: [AcneDetection]
    public var skinScore: Double

    public init(
        date: Date = Date(),
        frontImage: UIImage? = nil,
        leftImage: UIImage? = nil,
        rightImage: UIImage? = nil,
        detections: [AcneDetection] = [],
        skinScore: Double = 100.0
    ) {
        self.date = date
        self.frontImage = frontImage
        self.leftImage = leftImage
        self.rightImage = rightImage
        self.detections = detections
        self.skinScore = skinScore
    }

    public var totalAcneCount: Int {
        detections.count
    }

    public var countsByType: [AcneType: Int] {
        var counts: [AcneType: Int] = [:]
        for type in AcneType.allCases {
            counts[type] = 0
        }
        for detection in detections {
            counts[detection.acneType, default: 0] += 1
        }
        return counts
    }

    public var countsByRegion: [FacialRegion: Int] {
        var counts: [FacialRegion: Int] = [:]
        for region in FacialRegion.allCases {
            counts[region] = 0
        }
        for detection in detections {
            counts[detection.facialRegion, default: 0] += 1
        }
        return counts
    }
}
