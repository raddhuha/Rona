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
            let sampleImage1 = createSyntheticScanImage(label: "12 Aug 2026")
            let sampleImage2 = createSyntheticScanImage(label: "13 Aug 2026")
            _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-12_front.jpg")
            _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-12_left.jpg")
            _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-12_right.jpg")
            _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-13_front.jpg")
            _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-13_left.jpg")
            _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-13_right.jpg")

            let hasAug12 = existing.contains { $0.calendarDayId == "2026-08-12" }
            let hasAug13 = existing.contains { $0.calendarDayId == "2026-08-13" }
            guard !hasAug12 || !hasAug13 || existing.isEmpty else { return }

            let calendar = Calendar.current

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
        } catch {
            print("Failed to seed initial data: \(error)")
        }
    }

    private static func createSyntheticScanImage(label: String) -> UIImage {
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
