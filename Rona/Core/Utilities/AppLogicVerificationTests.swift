//
//  AppLogicVerificationTests.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation
import SwiftData
import CoreGraphics

/// Self-contained test suite validating core business logic, persistence invariants,
/// scoring calculations, and insight generation.
@MainActor
public enum AppLogicVerificationTests {
    public static func runAllTests() async -> (passed: Int, failed: Int, errors: [String]) {
        var passed = 0
        var failed = 0
        var errors: [String] = []

        func assertCondition(_ condition: Bool, _ testName: String) {
            if condition {
                passed += 1
                print("✅ [TEST PASSED]: \(testName)")
            } else {
                failed += 1
                let msg = "❌ [TEST FAILED]: \(testName)"
                errors.append(msg)
                print(msg)
            }
        }

        print("🚀 Starting AppLogicVerificationTests...")

        // -------------------------------------------------------------
        // TEST 1: Skin Score Calculator
        // -------------------------------------------------------------
        let calculator = SkinScoreCalculator(baselineScore: 100.0, sensitivityFactor: 1.5)

        // 1a: Zero lesions = 100.0
        let zeroScore = calculator.calculateScore(detections: [])
        assertCondition(zeroScore == 100.0, "SkinScoreCalculator: Zero lesions yields 100.0 score")

        // 1b: Higher severity lesions reduce score more than mild ones
        let mildDetections = [
            AcneDetection(acneType: .type1, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front)
        ]
        let severeDetections = [
            AcneDetection(acneType: .type6, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front)
        ]
        let mildScore = calculator.calculateScore(detections: mildDetections)
        let severeScore = calculator.calculateScore(detections: severeDetections)
        assertCondition(mildScore > severeScore, "SkinScoreCalculator: Severe lesion penalizes more than mild lesion")

        // 1c: Score is clamped above 0.0
        var manyDetections: [AcneDetection] = []
        for _ in 0..<100 {
            manyDetections.append(AcneDetection(acneType: .type6, facialRegion: .chin, boundingBox: .zero, confidence: 0.9, viewAngle: .front))
        }
        let clampedScore = calculator.calculateScore(detections: manyDetections)
        assertCondition(clampedScore >= 0.0 && clampedScore <= 100.0, "SkinScoreCalculator: Score remains within [0, 100] bounds")

        // -------------------------------------------------------------
        // TEST 2: Acne Counting & Regional Aggregations
        // -------------------------------------------------------------
        let testDetections = [
            AcneDetection(acneType: .type1, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front),
            AcneDetection(acneType: .type1, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front),
            AcneDetection(acneType: .type2, facialRegion: .nose, boundingBox: .zero, confidence: 0.9, viewAngle: .front),
            AcneDetection(acneType: .type3, facialRegion: .leftCheek, boundingBox: .zero, confidence: 0.9, viewAngle: .left),
            AcneDetection(acneType: .type3, facialRegion: .leftCheek, boundingBox: .zero, confidence: 0.9, viewAngle: .left),
            AcneDetection(acneType: .type3, facialRegion: .leftCheek, boundingBox: .zero, confidence: 0.9, viewAngle: .left)
        ]

        let testSession = SkinScanSession(detections: testDetections)
        assertCondition(testSession.totalAcneCount == 6, "AcneCounting: Total count is exactly 6")
        assertCondition(testSession.countsByType[.type1] == 2, "AcneCounting: Whitehead count is 2")
        assertCondition(testSession.countsByType[.type2] == 1, "AcneCounting: Blackhead count is 1")
        assertCondition(testSession.countsByType[.type3] == 3, "AcneCounting: Papules count is 3")
        assertCondition(testSession.countsByRegion[.forehead] == 2, "RegionAggregation: Forehead count is 2")
        assertCondition(testSession.countsByRegion[.leftCheek] == 3, "RegionAggregation: Left cheek count is 3")
        assertCondition(testSession.countsByRegion[.nose] == 1, "RegionAggregation: Nose count is 1")
        assertCondition(testSession.countsByRegion[.chin] == 0, "RegionAggregation: Chin count is 0")

        // -------------------------------------------------------------
        // TEST 3: Same-Day Scan Replacement Behavior
        // -------------------------------------------------------------
        do {
            let schema = Schema([ScanRecord.self, AcneDetectionRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let testContainer = try ModelContainer(for: schema, configurations: [config])
            let storage = LocalFileImageStorage()
            let testRepo = SwiftDataScanRepository(modelContext: testContainer.mainContext, imageStorage: storage)

            let testDate = Date()
            let dayId = CalendarDayHelper.calendarDayId(for: testDate)

            // Save Scan 1 on testDate
            _ = try await testRepo.saveOrUpdate(
                date: testDate,
                frontImagePath: "path1.jpg",
                leftImagePath: "path1_left.jpg",
                rightImagePath: "path1_right.jpg",
                skinScore: 20.0,
                detections: [
                    AcneDetection(acneType: .type1, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front)
                ]
            )

            let recordsAfterScan1 = try await testRepo.fetchAll()
            assertCondition(recordsAfterScan1.count == 1, "DateReplacement: Exactly 1 record exists after scan 1")
            assertCondition(recordsAfterScan1.first?.skinScore == 20.0, "DateReplacement: Scan 1 skin score is 20.0")

            // Later on the SAME calendar day: Save Scan 2
            let laterSameDay = testDate.addingTimeInterval(3600 * 4) // 4 hours later
            _ = try await testRepo.saveOrUpdate(
                date: laterSameDay,
                frontImagePath: "path2.jpg",
                leftImagePath: "path2_left.jpg",
                rightImagePath: "path2_right.jpg",
                skinScore: 45.0,
                detections: [
                    AcneDetection(acneType: .type1, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front),
                    AcneDetection(acneType: .type1, facialRegion: .forehead, boundingBox: .zero, confidence: 0.9, viewAngle: .front)
                ]
            )

            let recordsAfterScan2 = try await testRepo.fetchAll()
            assertCondition(recordsAfterScan2.count == 1, "DateReplacement: Still exactly 1 record after rescan on same day (NO duplicate created)")
            assertCondition(recordsAfterScan2.first?.calendarDayId == dayId, "DateReplacement: Record calendarDayId matches original day")
            assertCondition(recordsAfterScan2.first?.skinScore == 45.0, "DateReplacement: Previous record fields were successfully replaced")
            assertCondition(recordsAfterScan2.first?.totalAcneCount == 2, "DateReplacement: Total acne count updated to 2")

            // Save Scan 3 on a DIFFERENT day
            let nextDay = testDate.addingTimeInterval(86400 * 2) // 2 days later
            _ = try await testRepo.saveOrUpdate(
                date: nextDay,
                frontImagePath: "path3.jpg",
                leftImagePath: "path3_left.jpg",
                rightImagePath: "path3_right.jpg",
                skinScore: 60.0,
                detections: []
            )

            let recordsAfterDay2 = try await testRepo.fetchAll()
            assertCondition(recordsAfterDay2.count == 2, "DateReplacement: A new record is created when scanning on a different calendar day")

        } catch {
            assertCondition(false, "DateReplacement: Exception thrown: \(error)")
        }

        // -------------------------------------------------------------
        // TEST 4: Comparison & Insight Generator
        // -------------------------------------------------------------
        let prevCountsByRegion: [FacialRegion: Int] = [.forehead: 6, .leftCheek: 5, .rightCheek: 3, .nose: 2, .chin: 1]
        let currCountsByRegion: [FacialRegion: Int] = [.forehead: 3, .leftCheek: 5, .rightCheek: 3, .nose: 2, .chin: 1]

        let comparison = ScanComparison(
            previousDate: Date().addingTimeInterval(-86400 * 2),
            currentDate: Date(),
            previousScore: 20.0,
            currentScore: 45.0,
            previousTotalAcne: 17,
            currentTotalAcne: 14,
            previousCountsByType: [.type1: 10, .type2: 7],
            currentCountsByType: [.type1: 7, .type2: 7],
            previousCountsByRegion: prevCountsByRegion,
            currentCountsByRegion: currCountsByRegion
        )

        // 4a: Identifies most improved region
        assertCondition(comparison.mostImprovedRegion?.region == .forehead, "Comparison: Forehead correctly identified as most improved region")
        assertCondition(comparison.mostImprovedRegion?.decrease == 3, "Comparison: Forehead decrease calculated as 3")
        assertCondition(comparison.mostImprovedRegion?.from == 6, "Comparison: Forehead from value is 6")
        assertCondition(comparison.mostImprovedRegion?.to == 3, "Comparison: Forehead to value is 3")

        // 4b: Generates calm, supportive insight
        let insightGen = RuleBasedInsightGenerator()
        let insight = insightGen.generateInsight(comparison: comparison)
        assertCondition(insight.title == "Your forehead improved the most", "InsightGenerator: Title matches expected region improvement")
        assertCondition(insight.body.contains("decreased from 6 to 3"), "InsightGenerator: Body text explains decrease factually")

        print("🏁 Finished AppLogicVerificationTests: \(passed) passed, \(failed) failed.")
        return (passed, failed, errors)
    }
}
