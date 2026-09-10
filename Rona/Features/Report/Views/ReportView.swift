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
    @StateObject private var viewModel: ReportViewModel

    public init(viewModel: ReportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Navigation Header
            NavigationHeader(
                title: "Report",
                actionType: .back,
                onLeadingAction: {
                    dismiss()
                }
            )

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
                        title: "Insight"
                    )
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadData()
        }
    }
}
