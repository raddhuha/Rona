//
//  ReportView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Progress report screen matching Screenshot 5 reference design.
@MainActor
public struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: ReportViewModel

    public init(viewModel: ReportViewModel? = nil) {
        let vm = viewModel ?? ReportViewModel(
            scanRepository: AppContainer.preview.scanRepository,
            insightGenerator: AppContainer.preview.insightGenerator
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                    // Period Selector Dropdown (Weekly / Monthly / Yearly)
                    Menu {
                        ForEach(TimePeriod.allCases) { period in
                            Button(period.displayName) {
                                viewModel.selectedPeriod = period
                                viewModel.rangeOffset = 0
                                Task { await viewModel.loadData() }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.selectedPeriod.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(.top, 4)

                    // Date Range Navigator Pill: <  20 Jul 2026 - 19 Aug 2026  >
                    HStack {
                        Button(action: {
                            viewModel.previousPeriod()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 28, height: 28)
                        }

                        Spacer()

                        Text(viewModel.dateRangeLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Button(action: {
                            viewModel.nextPeriod()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(viewModel.rangeOffset < 0 ? AppTheme.textPrimary : AppTheme.textMuted)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(viewModel.rangeOffset >= 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.borderSubtle, lineWidth: 1)
                    )

                    // Segmented Switch Pill: Skin Score | Acne Type
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.chartMode = .skinScore
                            }
                        }) {
                            Text("Skin Score")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(viewModel.chartMode == .skinScore ? AppTheme.textPrimary : Color(uiColor: .systemGray))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(viewModel.chartMode == .skinScore ? Color.white : Color.clear)
                                .clipShape(Capsule())
                                .shadow(color: viewModel.chartMode == .skinScore ? Color.black.opacity(0.06) : Color.clear, radius: 4, x: 0, y: 1)
                        }

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.chartMode = .acneType
                            }
                        }) {
                            Text("Acne Type")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(viewModel.chartMode == .acneType ? AppTheme.textPrimary : Color(uiColor: .systemGray))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(viewModel.chartMode == .acneType ? Color.white : Color.clear)
                                .clipShape(Capsule())
                                .shadow(color: viewModel.chartMode == .acneType ? Color.black.opacity(0.06) : Color.clear, radius: 4, x: 0, y: 1)
                        }
                    }
                    .padding(3)
                    .background(Color(uiColor: .systemGray5))
                    .clipShape(Capsule())

                    // Swift Charts Progression Graph
                    SkinProgressChart(
                        points: viewModel.progressPoints,
                        mode: viewModel.chartMode
                    )
                    .padding(.vertical, 8)

                    // Bottom Insight Card
                    InsightCardView(
                        insight: viewModel.insight,
                        title: "Insight",
                        showDataAction: {
                            router.navigateToRecords()
                        }
                    )

                    // Quick Comparison for period if at least 2 records exist
                    if let pair = viewModel.comparisonPair {
                        Button(action: {
                            router.presentComparison(record1: pair.0, record2: pair.1)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.and.right")
                                Text("Compare Start & End of Period")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(Capsule())
                        }
                    }

                    // Navigation Shortcuts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("More")
                            .font(AppTheme.sectionTitleFont)
                            .foregroundColor(AppTheme.textPrimary)

                        NavigationRowCard(title: "View All Records") {
                            router.navigateToRecords()
                        }

                        PrimaryPillButton(
                            title: "Scan Now",
                            style: .bordered,
                            action: {
                                router.presentScanFlow()
                            }
                        )
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.background)
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("report_back_button")
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    ReportView()
        .environmentObject(AppRouter())
}
