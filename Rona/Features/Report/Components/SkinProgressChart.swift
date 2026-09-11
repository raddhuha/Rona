//
//  SkinProgressChart.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Charts

/// Chart data point representing daily progress.
public struct ProgressPoint: Identifiable {
    public var id: String { dayId }
    public let dayId: String
    public let date: Date
    public let label: String
    public let skinScore: Double
    public let totalAcneCount: Int
    public let countsByType: [AcneType: Int]
}

/// Swift Charts component visualizing score or acne counts over time, matching Screenshot 5.
public struct SkinProgressChart: View {
    public enum Mode {
        case skinScore
        case acneType
    }

    private let points: [ProgressPoint]
    private let mode: Mode

    public init(points: [ProgressPoint] = [], mode: Mode = .skinScore) {
        self.points = points
        self.mode = mode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if points.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Not enough data yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                chartContent
                    .frame(height: 220)
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if mode == .skinScore {
            Chart {
                // Dashed horizontal threshold guides at 25, 50, 75, 100
                ForEach([25.0, 50.0, 75.0, 100.0], id: \.self) { val in
                    RuleMark(y: .value("Guide", val))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color(uiColor: .systemGray5))
                }

                ForEach(points) { point in
                    LineMark(
                        x: .value("Date", point.label),
                        y: .value("Skin Score", point.skinScore)
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.label),
                        y: .value("Skin Score", point.skinScore)
                    )
                    .foregroundStyle(AppTheme.textPrimary)
                    .symbolSize(36)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        } else {
            // Acne Type breakdown bar chart over time
            Chart {
                ForEach(points) { point in
                    ForEach(AcneType.allCases) { type in
                        let count = point.countsByType[type, default: 0]
                        BarMark(
                            x: .value("Date", point.label),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(by: .value("Type", type.displayName))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    SkinProgressChart()
}
