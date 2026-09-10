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
            if let first = existing.first, imageStorage.loadImage(fromPath: first.frontImagePath) == nil {
                // Re-create image files for existing records if missing
                let sampleImage1 = createSyntheticScanImage(label: "13 Aug 2026")
                let sampleImage2 = createSyntheticScanImage(label: "15 Aug 2026")
                _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-13_front.jpg")
                _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-13_left.jpg")
                _ = try? imageStorage.saveImage(sampleImage1, named: "2026-08-13_right.jpg")
                _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-15_front.jpg")
                _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-15_left.jpg")
                _ = try? imageStorage.saveImage(sampleImage2, named: "2026-08-15_right.jpg")
            }
            guard existing.isEmpty else { return }

            let calendar = Calendar.current

            // 1. Seed Record 1: 13 Aug 2026 (Score ~20%, matching Screenshot 1, 2, 4)
            var dateComponents1 = DateComponents()
            dateComponents1.year = 2026
            dateComponents1.month = 8
            dateComponents1.day = 13
            let date1 = calendar.date(from: dateComponents1) ?? Date()
            let dayId1 = CalendarDayHelper.calendarDayId(for: date1)

            let sampleImage1 = createSyntheticScanImage(label: "13 Aug 2026")
            let path1Front = try imageStorage.saveImage(sampleImage1, named: "\(dayId1)_front.jpg")
            let path1Left = try imageStorage.saveImage(sampleImage1, named: "\(dayId1)_left.jpg")
            let path1Right = try imageStorage.saveImage(sampleImage1, named: "\(dayId1)_right.jpg")

            // Create initial detections (e.g. 6 forehead lesions, 3 left cheek, 3 right cheek, etc.)
            var detections1: [AcneDetection] = []
            // 6 Forehead lesions (to support "decreased from 6 to 3" insight)
            for i in 0..<6 {
                detections1.append(AcneDetection(
                    acneType: .type1, // Whitehead
                    facialRegion: .forehead,
                    boundingBox: CGRect(x: 0.30 + Double(i) * 0.06, y: 0.20 + Double(i % 2) * 0.04, width: 0.04, height: 0.035),
                    confidence: 0.92,
                    viewAngle: .front
                ))
            }
            // Cheeks and nose lesions to match Screenshot 2 grouped bar chart counts
            for i in 0..<4 {
                detections1.append(AcneDetection(
                    acneType: .type2, // Blackhead
                    facialRegion: .nose,
                    boundingBox: CGRect(x: 0.46, y: 0.44 + Double(i) * 0.03, width: 0.035, height: 0.03),
                    confidence: 0.88,
                    viewAngle: .front
                ))
            }
            for i in 0..<6 {
                detections1.append(AcneDetection(
                    acneType: .type3, // Papules
                    facialRegion: .leftCheek,
                    boundingBox: CGRect(x: 0.40 + Double(i % 3) * 0.06, y: 0.46 + Double(i / 3) * 0.05, width: 0.045, height: 0.04),
                    confidence: 0.90,
                    viewAngle: .left
                ))
            }
            for i in 0..<5 {
                detections1.append(AcneDetection(
                    acneType: .type4, // Pustules
                    facialRegion: .rightCheek,
                    boundingBox: CGRect(x: 0.42 + Double(i % 3) * 0.06, y: 0.48 + Double(i / 3) * 0.05, width: 0.045, height: 0.04),
                    confidence: 0.89,
                    viewAngle: .right
                ))
            }

            _ = try await repository.saveOrUpdate(
                date: date1,
                frontImagePath: path1Front,
                leftImagePath: path1Left,
                rightImagePath: path1Right,
                skinScore: 20.0, // Matches 20% in Screenshot 2 & 20/100 in Screenshot 4
                detections: detections1
            )

            // 2. Seed Record 2: 15 Aug 2026 (Score 45%, Forehead improved from 6 to 3)
            var dateComponents2 = DateComponents()
            dateComponents2.year = 2026
            dateComponents2.month = 8
            dateComponents2.day = 15
            let date2 = calendar.date(from: dateComponents2) ?? Date()
            let dayId2 = CalendarDayHelper.calendarDayId(for: date2)

            let sampleImage2 = createSyntheticScanImage(label: "15 Aug 2026")
            let path2Front = try imageStorage.saveImage(sampleImage2, named: "\(dayId2)_front.jpg")
            let path2Left = try imageStorage.saveImage(sampleImage2, named: "\(dayId2)_left.jpg")
            let path2Right = try imageStorage.saveImage(sampleImage2, named: "\(dayId2)_right.jpg")

            var detections2: [AcneDetection] = []
            // Forehead reduced from 6 to 3
            for i in 0..<3 {
                detections2.append(AcneDetection(
                    acneType: .type1, // Whitehead
                    facialRegion: .forehead,
                    boundingBox: CGRect(x: 0.35 + Double(i) * 0.08, y: 0.22, width: 0.04, height: 0.035),
                    confidence: 0.94,
                    viewAngle: .front
                ))
            }
            // Reduced other regions
            detections2.append(AcneDetection(
                acneType: .type2,
                facialRegion: .nose,
                boundingBox: CGRect(x: 0.48, y: 0.48, width: 0.035, height: 0.03),
                confidence: 0.89,
                viewAngle: .front
            ))
            for i in 0..<3 {
                detections2.append(AcneDetection(
                    acneType: .type3,
                    facialRegion: .leftCheek,
                    boundingBox: CGRect(x: 0.44 + Double(i) * 0.06, y: 0.48, width: 0.045, height: 0.04),
                    confidence: 0.91,
                    viewAngle: .left
                ))
            }
            for i in 0..<2 {
                detections2.append(AcneDetection(
                    acneType: .type4,
                    facialRegion: .rightCheek,
                    boundingBox: CGRect(x: 0.45 + Double(i) * 0.07, y: 0.50, width: 0.045, height: 0.04),
                    confidence: 0.90,
                    viewAngle: .right
                ))
            }

            _ = try await repository.saveOrUpdate(
                date: date2,
                frontImagePath: path2Front,
                leftImagePath: path2Left,
                rightImagePath: path2Right,
                skinScore: 45.0, // Matches 45% in Screenshot 2
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
