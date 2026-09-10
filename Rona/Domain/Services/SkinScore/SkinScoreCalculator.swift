//
//  SkinScoreCalculator.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Production implementation of `SkinScoreCalculating`.
///
/// SCORING FORMULA DESIGN:
/// - Base baseline: 100.0 (represents clear skin with 0 detected lesions).
/// - Deductions: Each lesion incurs a penalty proportional to its clinical severity weight:
///     - Whitehead (type1): 1.0 pt
///     - Blackhead (type2): 1.0 pt
///     - Papules (type3): 2.0 pts
///     - Pustules (type4): 2.5 pts
///     - Nodules (type5): 4.0 pts
///     - Cystic (type6): 5.0 pts
/// - The total penalty is scaled by a sensitivity factor (default 1.5) and clamped between 0 and 100.
///
/// HOW TO CHANGE THE SCORING FORMULA LATER:
/// Simply adjust `baselineScore`, `sensitivityFactor`, or the formula in `calculateScore(countsByType:)`,
/// or replace this class with an alternate implementation conforming to `SkinScoreCalculating`.
public final class SkinScoreCalculator: SkinScoreCalculating {
    public let baselineScore: Double
    public let sensitivityFactor: Double

    public init(baselineScore: Double = 100.0, sensitivityFactor: Double = 1.5) {
        self.baselineScore = baselineScore
        self.sensitivityFactor = sensitivityFactor
    }

    public func calculateScore(detections: [AcneDetection]) -> Double {
        if detections.isEmpty {
            return baselineScore
        }

        var weightedPenaltySum: Double = 0.0
        for detection in detections {
            weightedPenaltySum += detection.acneType.severityWeight
        }

        let penalty = weightedPenaltySum * sensitivityFactor
        let score = max(0.0, min(baselineScore, baselineScore - penalty))
        return (score * 10).rounded() / 10 // Round to 1 decimal place
    }

    public func calculateScore(countsByType: [AcneType: Int]) -> Double {
        var weightedPenaltySum: Double = 0.0
        for (type, count) in countsByType {
            weightedPenaltySum += Double(count) * type.severityWeight
        }

        let penalty = weightedPenaltySum * sensitivityFactor
        let score = max(0.0, min(baselineScore, baselineScore - penalty))
        return (score * 10).rounded() / 10
    }
}
