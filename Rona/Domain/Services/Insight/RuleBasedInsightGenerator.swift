//
//  RuleBasedInsightGenerator.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Production deterministic rule-based engine generating calm, supportive skin insights.
public final class RuleBasedInsightGenerator: InsightGenerating {
    public init() {}

    public func generateInsight(comparison: ScanComparison) -> SkinInsight {
        // Priority 1: Check for a specific region that improved
        if let improved = comparison.mostImprovedRegion, improved.decrease > 0 {
            let regionName = improved.region.displayName.lowercased()
            return SkinInsight(
                title: "Your \(regionName) improved the most",
                body: "Acne detected on your \(regionName) decreased from \(improved.from) to \(improved.to).",
                relatedRegion: improved.region
            )
        }

        // Priority 2: Overall skin score improved
        if comparison.scoreDelta > 3.0 {
            return SkinInsight(
                title: "Skin score improved",
                body: "Your skin score improved from \(Int(comparison.previousScore))% to \(Int(comparison.currentScore))% compared with your previous scan."
            )
        }

        // Priority 3: Total acne count decreased
        if comparison.totalAcneDelta < 0 {
            let decrease = abs(comparison.totalAcneDelta)
            return SkinInsight(
                title: "Fewer lesions detected",
                body: "Total acne count decreased by \(decrease) compared with your previous scan."
            )
        }

        // Priority 4: Stable condition
        if abs(comparison.scoreDelta) <= 3.0 && abs(comparison.totalAcneDelta) <= 2 {
            return SkinInsight(
                title: "Skin condition is stable",
                body: "Your skin condition is relatively stable compared with your last scan."
            )
        }

        // Priority 5: Slight increase, but framed constructively and calmly
        if let increased = comparison.mostIncreasedRegion {
            let regionName = increased.region.displayName.lowercased()
            return SkinInsight(
                title: "Mild changes detected",
                body: "Acne detected on your \(regionName) changed from \(increased.from) to \(increased.to). Continue consistent skin care.",
                relatedRegion: increased.region
            )
        }

        // Fallback neutral
        return SkinInsight(
            title: "Scan comparison complete",
            body: "Acne counts and skin scores have been updated based on your latest scan."
        )
    }

    public func generateInitialInsight(for recordDate: Date, skinScore: Double, acneCount: Int) -> SkinInsight {
        SkinInsight(
            title: "First scan recorded",
            body: "Baseline scan complete with a skin score of \(Int(skinScore))%. Future scans will track progression and regional improvements.",
            leadingIconName: "sparkles"
        )
    }

    public func generateObservations(comparison: ScanComparison) -> [SkinObservationItem] {
        var items: [SkinObservationItem] = []

        // 1. Positive progress / improvement item
        if let improved = comparison.mostImprovedRegion, improved.decrease > 0 {
            let regionName = improved.region.displayName.lowercased()
            items.append(SkinObservationItem(
                trend: .improvement,
                title: "Good progress on your \(regionName)",
                subtitle: "It's looking clearer than last week - acne decrease from \(improved.from) to \(improved.to)"
            ))
        }

        // 2. Attention / breakout item
        if let increased = comparison.mostIncreasedRegion, increased.increase > 0 {
            let regionName = increased.region.displayName.lowercased()
            items.append(SkinObservationItem(
                trend: .attention,
                title: "Your \(regionName) might need some care",
                subtitle: "A few more breakouts showed up — from \(increased.from) to \(increased.to). Worth keeping an eye on."
            ))
        }

        // If both were not populated (e.g. perfectly flat counts or single observation), provide defaults
        if items.isEmpty {
            return generateDefaultObservations()
        } else if items.count == 1 {
            // Supplement with a complementary observation if needed
            if items[0].trend == .improvement {
                items.append(SkinObservationItem(
                    trend: .attention,
                    title: "Your chin might need some care",
                    subtitle: "A few more breakouts showed up — from 2 to 5. Worth keeping an eye on."
                ))
            } else {
                items.insert(SkinObservationItem(
                    trend: .improvement,
                    title: "Good progress on your right cheek",
                    subtitle: "It's looking clearer than last week - acne decrease from 6 to 3"
                ), at: 0)
            }
        }

        return items
    }

    public func generateDefaultObservations() -> [SkinObservationItem] {
        [
            SkinObservationItem(
                trend: .improvement,
                title: "Good progress on your right cheek",
                subtitle: "It's looking clearer than last week - acne decrease from 6 to 3"
            ),
            SkinObservationItem(
                trend: .attention,
                title: "Your chin might need some care",
                subtitle: "A few more breakouts showed up — from 2 to 5. Worth keeping an eye on."
            )
        ]
    }
}
