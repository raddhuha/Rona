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
                            if let current = viewModel.latestRecord, let previous = viewModel.previousRecord {
                                router.presentComparison(record1: previous, record2: current)
                            } else if let current = viewModel.latestRecord {
                                router.navigateToDetail(id: current.id)
                            }
                        }
                    )
                    .padding(.top, 6)
                }

                // Records Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Records")
                        .font(AppTheme.sectionTitleFont)
                        .foregroundColor(AppTheme.textPrimary)

                    NavigationRowCard(title: "Show All Data") {
                        router.navigateToRecords()
                    }
                    .accessibilityIdentifier("summary_show_all_data_button")
                }
                .padding(.top, 10)

                // Report Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report")
                        .font(AppTheme.sectionTitleFont)
                        .foregroundColor(AppTheme.textPrimary)

                    NavigationRowCard(title: "Show Report") {
                        router.navigateToReport()
                    }
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

    // MARK: - Recent Photos View

    @ViewBuilder
    private var recentPhotosSection: some View {
        if let latest = viewModel.latestRecord {
            HStack(spacing: 14) {
                // Left Photo: Previous Record (or placeholder if only 1 record exists)
                if let previous = viewModel.previousRecord {
                    ScanImageCard(
                        image: viewModel.previousFrontImage,
                        dateText: previous.formattedDate,
                        action: {
                            router.navigateToDetail(id: previous.id)
                        }
                    )
                } else {
                    ScanImageCard(
                        image: nil,
                        dateText: "No previous",
                        headerLabel: "Previous"
                    )
                }

                // Right Photo: Latest Record
                ScanImageCard(
                    image: viewModel.latestFrontImage,
                    dateText: latest.formattedDate,
                    headerLabel: "Latest Photo",
                    action: {
                        router.navigateToDetail(id: latest.id)
                    }
                )
            }
            .padding(.top, 4)
        } else {
            // Empty state placeholder cards
            HStack(spacing: 14) {
                ScanImageCard(
                    image: nil,
                    dateText: "No scans yet",
                    headerLabel: "Previous"
                )

                ScanImageCard(
                    image: nil,
                    dateText: "No scans yet",
                    headerLabel: "Latest Photo"
                )
            }
            .padding(.top, 4)
        }
    }
}
