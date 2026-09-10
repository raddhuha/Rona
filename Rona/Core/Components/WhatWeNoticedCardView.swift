//
//  WhatWeNoticedCardView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Card displaying calm, factual regional acne progression observations matching the reference design.
public struct WhatWeNoticedCardView: View {
    private let observations: [SkinObservationItem]
    private let showDetailsAction: () -> Void

    public init(
        observations: [SkinObservationItem],
        showDetailsAction: @escaping () -> Void
    ) {
        self.observations = observations
        self.showDetailsAction = showDetailsAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Lightbulb Icon + Title
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(width: 28, height: 28)

                Text("What we noticed")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }

            Divider()
                .background(Color(uiColor: .systemGray3).opacity(0.6))

            // Observation rows
            ForEach(Array(observations.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .center, spacing: 14) {
                    trendIcon(for: item.trend)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(item.subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                Divider()
                    .background(Color(uiColor: .systemGray3).opacity(0.6))
            }

            // Centered "Show details" Button
            Button(action: showDetailsAction) {
                Text("Show details")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .systemGray5).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func trendIcon(for trend: SkinObservationItem.Trend) -> some View {
        switch trend {
        case .improvement:
            Image(systemName: "arrow.up")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.28, green: 0.78, blue: 0.38))
        case .attention:
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.94, green: 0.45, blue: 0.45))
        case .neutral:
            Image(systemName: "minus")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}
