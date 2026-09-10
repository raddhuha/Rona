//
//  InsightGenerating.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Protocol for generating calm, factual, non-judgmental skin insights.
public protocol InsightGenerating: Sendable {
    /// Generates an insight based on comparison between current and previous scan data.
    func generateInsight(comparison: ScanComparison) -> SkinInsight

    /// Generates an insight for a single record when no previous comparison is available.
    func generateInitialInsight(for recordDate: Date, skinScore: Double, acneCount: Int) -> SkinInsight
}
