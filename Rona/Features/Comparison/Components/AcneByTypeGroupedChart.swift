//
//  AcneByTypeGroupedChart.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Charts

/// Model item for grouped bar chart comparisons.
public struct AcneTypeComparisonItem: Identifiable {
    public var id: String { "\(type.rawValue)_\(isPrevious ? "prev" : "curr")" }
    public let type: AcneType
    public let count: Int
    public let isPrevious: Bool
}

/// Grouped bar chart comparing acne counts by type between two scans, matching Screenshot 2.
public struct AcneByTypeGroupedChart: View {
    private let previousCounts: [AcneType: Int]
    private let currentCounts: [AcneType: Int]
    private let previousDateLabel: String
    private let currentDateLabel: String

    public init(
        previousCounts: [AcneType: Int],
        currentCounts: [AcneType: Int],
        previousDateLabel: String,
        currentDateLabel: String
    ) {
        self.previousCounts = previousCounts
        self.currentCounts = currentCounts
        self.previousDateLabel = previousDateLabel
        self.currentDateLabel = currentDateLabel
    }

    private var maxCount: Int {
        let maxPrev = previousCounts.values.max() ?? 0
        let maxCurr = currentCounts.values.max() ?? 0
        return max(maxPrev, maxCurr, 10)
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 18) {
                ForEach(AcneType.allCases) { type in
                    let prevCount = previousCounts[type, default: 0]
                    let currCount = currentCounts[type, default: 0]

                    VStack(spacing: 8) {
                        // Paired Bars
                        HStack(alignment: .bottom, spacing: 5) {
                            // Left Bar: Previous (Blue)
                            BarColumn(
                                count: prevCount,
                                maxCount: maxCount,
                                color: AppTheme.accentBlue
                            )

                            // Right Bar: Current (Pink)
                            BarColumn(
                                count: currCount,
                                maxCount: maxCount,
                                color: AppTheme.accentPink
                            )
                        }
                        .frame(height: 180, alignment: .bottom)

                        // Category Name
                        Text(type.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                            .frame(width: 58)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
    }
}

/// An individual bar inside the paired comparison chart.
private struct BarColumn: View {
    let count: Int
    let maxCount: Int
    let color: Color

    private var heightRatio: CGFloat {
        guard maxCount > 0 else { return 0.08 }
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return max(ratio, 0.12) // Ensure minimum height to show number badge
    }

    var body: some View {
        GeometryReader { proxy in
            let availableHeight = proxy.size.height
            let barHeight = max(availableHeight * heightRatio, 24)

            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: 22, height: barHeight)

                    // Value label inside bar
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 22)
    }
}

#Preview {
    AcneByTypeGroupedChart(
        previousCounts: [.type1: 10, .type2: 7, .type3: 3],
        currentCounts: [.type1: 7, .type2: 7, .type3: 5],
        previousDateLabel: "12 Aug",
        currentDateLabel: "13 Aug"
    )
    .padding()
}
