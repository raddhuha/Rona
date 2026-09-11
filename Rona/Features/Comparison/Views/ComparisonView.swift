//
//  ComparisonView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Comparison sheet presenting side-by-side scan evaluation matching design specs.
@MainActor
public struct ComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: ComparisonViewModel
    @State private var showScoreInfoSheet: Bool = false

    public init(viewModel: ComparisonViewModel? = nil) {
        let vm = viewModel ?? ComparisonViewModel.previewInstance
        _viewModel = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Two Side-by-Side Photo Cards
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 14) {
                            ScanImageCard(
                                image: viewModel.previousFrontImage,
                                dateText: viewModel.previousRecord.formattedDate,
                                borderColor: AppTheme.accentBlue,
                                borderWidth: 2.0,
                                action: {
                                    router.dismissComparisonAndNavigateToDetail(id: viewModel.previousRecord.id)
                                }
                            )

                            ScanImageCard(
                                image: viewModel.currentFrontImage,
                                dateText: viewModel.currentRecord.formattedDate,
                                borderColor: AppTheme.accentPink,
                                borderWidth: 2.0,
                                action: {
                                    router.dismissComparisonAndNavigateToDetail(id: viewModel.currentRecord.id)
                                }
                            )
                        }

                        Text("Tap either photo to inspect full detection details")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.leading, 2)
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
                            .buttonStyle(.plain)
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
                        title: "Comparison Insight",
                        showDataAction: {
                            router.dismissComparisonAndNavigateToRecords()
                        }
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

                    // Navigation Shortcuts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("More")
                            .font(AppTheme.sectionTitleFont)
                            .foregroundColor(AppTheme.textPrimary)

                        NavigationRowCard(title: "View All Records") {
                            router.dismissComparisonAndNavigateToRecords()
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .background(AppTheme.background)
            .navigationTitle("Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("comparison_close_button")
                }
                .sharedBackgroundVisibility(.hidden)
            }
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
}

#Preview {
    ComparisonView()
        .environmentObject(AppRouter())
}
