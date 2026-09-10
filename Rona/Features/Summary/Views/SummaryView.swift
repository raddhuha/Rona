//
//  SummaryView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Main Home / Summary screen matching Screenshot 1 reference design.
@MainActor
public struct SummaryView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: SummaryViewModel

    public init(viewModel: SummaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Large Header Title
                Text("Summary")
                    .font(AppTheme.largeTitleFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.top, 8)

                // Check-in Reminder
                Text(viewModel.checkInMessage)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // "Scan Now" Button
                PrimaryPillButton(
                    title: "Scan Now",
                    style: .bordered,
                    action: {
                        router.presentScanFlow()
                    }
                )
                .accessibilityIdentifier("summary_scan_now_button")
                .padding(.top, 4)

                // Recent Photos Section
                recentPhotosSection

                // Comparison Insight Card
                if let insight = viewModel.comparisonInsight {
                    InsightCardView(
                        insight: insight,
                        title: "Comparison Insight",
                        showDataAction: {
                            openComparisonOrDetail()
                        }
                    )
                    .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                    .onTapGesture {
                        openComparisonOrDetail()
                    }
                    .padding(.top, 6)
                }

                // Records Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Records")
                        .font(AppTheme.sectionTitleFont)
                        .foregroundColor(AppTheme.textPrimary)

                    NavigationLink(value: AppRouter.Route.records) {
                        NavigationRowCard(title: "Show All Data")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("summary_show_all_data_button")
                }
                .padding(.top, 10)

                // Report Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report")
                        .font(AppTheme.sectionTitleFont)
                        .foregroundColor(AppTheme.textPrimary)

                    NavigationLink(value: AppRouter.Route.report) {
                        NavigationRowCard(title: "Show Report")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("summary_show_report_button")
                }
                .padding(.top, 6)
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.background)
        .task {
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RonaDataDidUpdate"))) { _ in
            Task {
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
    }

    private func openComparisonOrDetail() {
        if let current = viewModel.latestRecord, let previous = viewModel.previousRecord {
            router.presentComparison(record1: previous, record2: current)
        } else if let current = viewModel.latestRecord {
            router.navigateToDetail(id: current.id)
        } else {
            router.presentScanFlow()
        }
    }

    // MARK: - Recent Photos View

    @ViewBuilder
    private var recentPhotosSection: some View {
        if let latest = viewModel.latestRecord {
            HStack(spacing: 14) {
                // Left Photo: Previous Record (or placeholder if only 1 record exists)
                if let previous = viewModel.previousRecord {
                    NavigationLink(value: AppRouter.Route.recordDetail(id: previous.id)) {
                        ScanImageCard(
                            image: viewModel.previousFrontImage,
                            dateText: previous.formattedDate
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        router.presentScanFlow()
                    }) {
                        ScanImageCard(
                            image: nil,
                            dateText: "Scan to add",
                            headerLabel: "Previous"
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Right Photo: Latest Record
                NavigationLink(value: AppRouter.Route.recordDetail(id: latest.id)) {
                    ScanImageCard(
                        image: viewModel.latestFrontImage,
                        dateText: latest.formattedDate,
                        headerLabel: "Latest Photo"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        } else {
            // Empty state placeholder cards - tapping opens scan flow
            HStack(spacing: 14) {
                Button(action: {
                    router.presentScanFlow()
                }) {
                    ScanImageCard(
                        image: nil,
                        dateText: "Tap to scan",
                        headerLabel: "Previous"
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    router.presentScanFlow()
                }) {
                    ScanImageCard(
                        image: nil,
                        dateText: "Tap to scan",
                        headerLabel: "Latest Photo"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
}
