//
//  ScoreBadgeView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Component for displaying skin scores as percentages or normalized 0-100 scores.
public struct ScoreBadgeView: View {
    public enum DisplayMode {
        case percentage
        case fraction
    }

    private let score: Double
    private let mode: DisplayMode
    private let color: Color

    public init(
        score: Double,
        mode: DisplayMode = .percentage,
        color: Color = AppTheme.textPrimary
    ) {
        self.score = score
        self.mode = mode
        self.color = color
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(Int(score))")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(color)

            if mode == .percentage {
                Text("%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            } else {
                Text("/100")
                    .font(.system(size: 22, weight: .medium, design: .default))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
    }
}
