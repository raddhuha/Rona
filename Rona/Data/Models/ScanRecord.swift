//
//  ScanRecord.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation
import SwiftData

/// SwiftData entity representing a daily skin scan record.
///
/// NOTE: Each calendar day has at most ONE saved record.
/// The `calendarDayId` property is uniquely constrained so re-scanning on the same day
/// updates the record rather than creating a duplicate.
@Model
public final class ScanRecord {
    @Attribute(.unique)
    public var calendarDayId: String = ""

    public var id: UUID = UUID()
    public var date: Date = Date()
    public var frontImagePath: String = ""
    public var leftImagePath: String = ""
    public var rightImagePath: String = ""
    public var skinScore: Double = 100.0
    public var totalAcneCount: Int = 0

    @Relationship(deleteRule: .cascade)
    public var detections: [AcneDetectionRecord] = []

    public init(
        calendarDayId: String,
        id: UUID = UUID(),
        date: Date = Date(),
        frontImagePath: String = "",
        leftImagePath: String = "",
        rightImagePath: String = "",
        skinScore: Double = 100.0,
        totalAcneCount: Int = 0,
        detections: [AcneDetectionRecord] = []
    ) {
        self.calendarDayId = calendarDayId
        self.id = id
        self.date = date
        self.frontImagePath = frontImagePath
        self.leftImagePath = leftImagePath
        self.rightImagePath = rightImagePath
        self.skinScore = skinScore
        self.totalAcneCount = totalAcneCount
        self.detections = detections
    }

    // MARK: - Computed Properties & Aggregations

    public var formattedDate: String {
        CalendarDayHelper.formatDisplayDate(date)
    }

    public var formattedFullDate: String {
        CalendarDayHelper.formatFullDisplayDate(date)
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

    public func detections(for angle: ScanViewAngle) -> [AcneDetectionRecord] {
        detections.filter { $0.viewAngle == angle }
    }

    public func toDomainDetections() -> [AcneDetection] {
        detections.map { $0.toDomain() }
    }
}
