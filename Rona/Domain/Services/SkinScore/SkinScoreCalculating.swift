//
//  SkinScoreCalculating.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Protocol for calculating skin/acne scores from detected lesions.
///
/// Separating this logic into a dedicated service allows the scoring formula
/// to be modified, fine-tuned, or swapped without touching views or ViewModels.
public protocol SkinScoreCalculating: Sendable {
    /// Computes an objective skin score between 0.0 and 100.0 from detected lesions.
    ///
    /// - Parameter detections: The list of acne lesions detected across all captured view angles.
    /// - Returns: A normalized score from 0.0 (high lesion density/severity) to 100.0 (clear skin).
    func calculateScore(detections: [AcneDetection]) -> Double

    /// Calculates a score directly from counts by acne type.
    func calculateScore(countsByType: [AcneType: Int]) -> Double
}
