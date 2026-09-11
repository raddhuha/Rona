//
//  SampleDataSeeder.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import UIKit
import SwiftData

/// Seeds realistic initial records matching the reference screenshots (13 Aug 2026 & 15 Aug 2026)
/// so that charts, comparisons, and image cards are immediately populated.
@MainActor
public enum SampleDataSeeder {
    public static func seedInitialDataIfNeeded(
        repository: ScanRepositoryProtocol,
        imageStorage: ImageStorageProtocol,
        scoreCalculator: SkinScoreCalculating
    ) async {
        do {
            let existing = try await repository.fetchAll()

            // Remove legacy 15 Aug record if present to maintain 12-13 Aug reference pairing
            for record in existing where record.calendarDayId == "2026-08-15" {
                try? await repository.delete(id: record.id)
            }

            // Ensure images exist on disk for 12 Aug and 13 Aug
            let sampleImage1 = createSyntheticScanImage()
            let sampleImage2 = createSyntheticScanImage()
            _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-12_front.jpg")
            _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-12_left.jpg")
            _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-12_right.jpg")
            _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-13_front.jpg")
            _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-13_left.jpg")
            _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-13_right.jpg")

            let hasAug12 = existing.contains { $0.calendarDayId == "2026-08-12" }
            let hasAug13 = existing.contains { $0.calendarDayId == "2026-08-13" }

            let calendar = Calendar.current

            if !hasAug12 || !hasAug13 || existing.isEmpty {
                // 1. Seed Record 1: 12 Aug 2026 (7 days ago)
                var dateComponents1 = DateComponents()
                dateComponents1.year = 2026
                dateComponents1.month = 8
                dateComponents1.day = 12
                let date1 = calendar.date(from: dateComponents1) ?? Date()
                let dayId1 = CalendarDayHelper.calendarDayId(for: date1)

                let path1Front = try imageStorage.saveImage(sampleImage1, named: "\(dayId1)_front.jpg")
                let path1Left = try imageStorage.saveImage(sampleImage1, named: "\(dayId1)_left.jpg")
                let path1Right = try imageStorage.saveImage(sampleImage1, named: "\(dayId1)_right.jpg")

                var detections1: [AcneDetection] = []
                // Right cheek: 6 lesions (for decrease from 6 to 3)
                for i in 0..<6 {
                    detections1.append(AcneDetection(
                        acneType: .type1,
                        facialRegion: .rightCheek,
                        boundingBox: CGRect(x: 0.42 + Double(i % 3) * 0.06, y: 0.48 + Double(i / 3) * 0.05, width: 0.045, height: 0.04),
                        confidence: 0.92,
                        viewAngle: .right
                    ))
                }
                // Chin: 2 lesions (for increase from 2 to 5)
                for i in 0..<2 {
                    detections1.append(AcneDetection(
                        acneType: .type3,
                        facialRegion: .chin,
                        boundingBox: CGRect(x: 0.46 + Double(i) * 0.06, y: 0.72, width: 0.04, height: 0.035),
                        confidence: 0.90,
                        viewAngle: .front
                    ))
                }
                // Forehead: 3 lesions
                for i in 0..<3 {
                    detections1.append(AcneDetection(
                        acneType: .type2,
                        facialRegion: .forehead,
                        boundingBox: CGRect(x: 0.38 + Double(i) * 0.06, y: 0.22, width: 0.04, height: 0.035),
                        confidence: 0.88,
                        viewAngle: .front
                    ))
                }

                _ = try await repository.saveOrUpdate(
                    date: date1,
                    frontImagePath: path1Front,
                    leftImagePath: path1Left,
                    rightImagePath: path1Right,
                    skinScore: 68.0,
                    detections: detections1
                )

                // 2. Seed Record 2: 13 Aug 2026 (6 days ago)
                var dateComponents2 = DateComponents()
                dateComponents2.year = 2026
                dateComponents2.month = 8
                dateComponents2.day = 13
                let date2 = calendar.date(from: dateComponents2) ?? Date()
                let dayId2 = CalendarDayHelper.calendarDayId(for: date2)

                let path2Front = try imageStorage.saveImage(sampleImage2, named: "\(dayId2)_front.jpg")
                let path2Left = try imageStorage.saveImage(sampleImage2, named: "\(dayId2)_left.jpg")
                let path2Right = try imageStorage.saveImage(sampleImage2, named: "\(dayId2)_right.jpg")

                var detections2: [AcneDetection] = []
                // Right cheek: 3 lesions (decreased from 6 to 3!)
                for i in 0..<3 {
                    detections2.append(AcneDetection(
                        acneType: .type1,
                        facialRegion: .rightCheek,
                        boundingBox: CGRect(x: 0.44 + Double(i) * 0.06, y: 0.50, width: 0.045, height: 0.04),
                        confidence: 0.93,
                        viewAngle: .right
                    ))
                }
                // Chin: 5 lesions (increased from 2 to 5!)
                for i in 0..<5 {
                    detections2.append(AcneDetection(
                        acneType: .type3,
                        facialRegion: .chin,
                        boundingBox: CGRect(x: 0.42 + Double(i % 3) * 0.06, y: 0.70 + Double(i / 3) * 0.04, width: 0.04, height: 0.035),
                        confidence: 0.91,
                        viewAngle: .front
                    ))
                }
                // Forehead: 2 lesions
                for i in 0..<2 {
                    detections2.append(AcneDetection(
                        acneType: .type2,
                        facialRegion: .forehead,
                        boundingBox: CGRect(x: 0.40 + Double(i) * 0.08, y: 0.22, width: 0.04, height: 0.035),
                        confidence: 0.89,
                        viewAngle: .front
                    ))
                }

                _ = try await repository.saveOrUpdate(
                    date: date2,
                    frontImagePath: path2Front,
                    leftImagePath: path2Left,
                    rightImagePath: path2Right,
                    skinScore: 80.0, // Matches 80 in screenshot
                    detections: detections2
                )
            }

            // 3. Seed historical records for previous months (August, July, June) if not already present
            let hasJuly = existing.contains { $0.calendarDayId.starts(with: "2026-07") }
            if !hasJuly {
                let historicalDates: [(year: Int, month: Int, day: Int, score: Double)] = [
                    // Additional August records (for 6 cards in August 2026 matching mockup)
                    (2026, 8, 10, 76.0),
                    (2026, 8, 8, 74.0),
                    (2026, 8, 5, 72.0),
                    (2026, 8, 2, 70.0),
                    // July records (5 cards matching mockup)
                    (2026, 7, 28, 68.0),
                    (2026, 7, 24, 66.0),
                    (2026, 7, 19, 65.0),
                    (2026, 7, 14, 62.0),
                    (2026, 7, 8, 60.0),
                    // June records (2 cards matching mockup)
                    (2026, 6, 25, 58.0),
                    (2026, 6, 18, 55.0)
                ]

                for item in historicalDates {
                    var comps = DateComponents()
                    comps.year = item.year
                    comps.month = item.month
                    comps.day = item.day
                    if let d = calendar.date(from: comps) {
                        let dayId = CalendarDayHelper.calendarDayId(for: d)
                        let fPath = try imageStorage.saveImage(sampleImage2, named: "\(dayId)_front.jpg")
                        let lPath = try imageStorage.saveImage(sampleImage2, named: "\(dayId)_left.jpg")
                        let rPath = try imageStorage.saveImage(sampleImage2, named: "\(dayId)_right.jpg")

                        let detections = [
                            AcneDetection(acneType: .type1, facialRegion: .rightCheek, boundingBox: CGRect(x: 0.45, y: 0.50, width: 0.04, height: 0.04), confidence: 0.9, viewAngle: .right),
                            AcneDetection(acneType: .type2, facialRegion: .forehead, boundingBox: CGRect(x: 0.40, y: 0.22, width: 0.04, height: 0.035), confidence: 0.88, viewAngle: .front)
                        ]

                        _ = try await repository.saveOrUpdate(
                            date: d,
                            frontImagePath: fPath,
                            leftImagePath: lPath,
                            rightImagePath: rPath,
                            skinScore: item.score,
                            detections: detections
                        )
                    }
                }
            }
        } catch {
            print("Failed to seed initial data: \(error)")
        }
    }

    private static func createSyntheticScanImage() -> UIImage {
        let size = CGSize(width: 480, height: 640)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Clean neutral skin tone background
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.95, green: 0.90, blue: 0.86, alpha: 1.0).setFill()
            ctx.fill(rect)

            // Face oval outline
            let faceOval = CGRect(x: 80, y: 90, width: 320, height: 440)
            UIColor(red: 0.98, green: 0.93, blue: 0.89, alpha: 1.0).setFill()
            ctx.cgContext.fillEllipse(in: faceOval)

            UIColor(red: 0.88, green: 0.80, blue: 0.75, alpha: 0.6).setStroke()
            ctx.cgContext.setLineWidth(2.0)
            ctx.cgContext.strokeEllipse(in: faceOval)
        }
    }
}
