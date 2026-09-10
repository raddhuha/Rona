//
//  ComparisonView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Comparison sheet presenting side-by-side scan evaluation matching Screenshot 2.
@MainActor
public struct ComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ComparisonViewModel
    @State private var showScoreInfoSheet: Bool = false

    public init(viewModel: ComparisonViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Sheet Grabber Handle
            Capsule()
                .fill(Color(uiColor: .systemGray4))
                .frame(width: 38, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // Top Header: Close button and Title
            NavigationHeader(
                title: "Comparison",
                actionType: .close,
                onLeadingAction: {
                    dismiss()
                }
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Two Side-by-Side Photo Cards
                    HStack(spacing: 14) {
                        ScanImageCard(
                            image: viewModel.previousFrontImage,
                            dateText: viewModel.previousRecord.formattedDate,
                            borderColor: AppTheme.accentBlue,
                            borderWidth: 2.0
                        )

                        ScanImageCard(
                            image: viewModel.currentFrontImage,
                            dateText: viewModel.currentRecord.formattedDate,
                            borderColor: AppTheme.accentPink,
                            borderWidth: 2.0
                        )
                    }

                    // "Full Face" Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Face")
                            .font(AppTheme.sectionTitleFont)
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(spacing: 4) {
                            Text("Skin Score")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            Button(action: {
                                showScoreInfoSheet = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }

                    // Side-by-Side Large Scores
                    HStack {
                        ScoreBadgeView(
                            score: viewModel.previousRecord.skinScore,
                            mode: .percentage,
                            color: AppTheme.accentBlue
                        )
                        .frame(maxWidth: .infinity, alignment: .center)

                        ScoreBadgeView(
                            score: viewModel.currentRecord.skinScore,
                            mode: .percentage,
                            color: AppTheme.accentPink
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 4)

                    // Comparison Insight Card
                    InsightCardView(
                        insight: viewModel.comparisonInsight,
                        title: "Comparison Insight"
                    )

                    // "Acne by Type" Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Acne by Type")
                            .font(AppTheme.sectionTitleFont)
                            .foregroundColor(AppTheme.textPrimary)

                        AcneByTypeGroupedChart(
                            previousCounts: viewModel.previousRecord.countsByType,
                            currentCounts: viewModel.currentRecord.countsByType,
                            previousDateLabel: viewModel.previousRecord.formattedDate,
                            currentDateLabel: viewModel.currentRecord.formattedDate
                        )
                    }
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadImages()
        }
        .alert("About Skin Score", isPresented: $showScoreInfoSheet) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("The skin score is an estimate (0–100%) calculated by assessing lesion severity, density, and distribution across all scanned facial views. This application is a monitoring tool and does not provide medical diagnosis.")
        }
    }
}
