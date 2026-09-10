//
//  SummaryView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Main Home / Summary screen matching the updated reference design.
@MainActor
public struct SummaryView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: SummaryViewModel
    @State private var isSettingsPresented: Bool = false

    public init(viewModel: SummaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header Bar: "Summary" title + Camera & Settings buttons
                headerSection

                // Recent Photos Comparison Preview Cards
                recentPhotosSection

                // Reassuring Subtitle
                Text("Don’t worry if it may look similar - real change usually takes >6 days to show.")
                    .font(.system(size: 13, weight: .regular))
                    .italic()
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, -4)
                    .padding(.bottom, 2)

                // "What we noticed" Card
                WhatWeNoticedCardView(
                    observations: viewModel.observations,
                    showDetailsAction: {
                        openComparisonOrDetail()
                    }
                )
                .accessibilityIdentifier("summary_what_we_noticed_card")

                // "Show All Photos" Card
                NavigationLink(value: AppRouter.Route.records) {
                    HStack {
                        Text("Show All Photos")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .systemGray3))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(uiColor: .systemGray4).opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("summary_show_all_photos_button")
                .padding(.top, 4)

                // "How you've been doing" Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("How you've been doing")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    NavigationLink(value: AppRouter.Route.report) {
                        SummaryProgressCard(
                            headline: viewModel.progressHeadline,
                            currentScore: viewModel.currentSkinScore,
                            points: viewModel.sparklinePoints
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("summary_progress_card")
                }
                .padding(.top, 10)
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.background)
        .sheet(isPresented: $isSettingsPresented) {
            settingsSheetView
        }
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

    // MARK: - Header Bar

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Summary")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            HStack(spacing: 12) {
                // Camera Button
                Button(action: {
                    router.presentScanFlow()
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(uiColor: .systemGray4).opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("summary_camera_button")

                // Settings Button
                Button(action: {
                    isSettingsPresented = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(uiColor: .systemGray4).opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("summary_settings_button")
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Recent Photos View

    @ViewBuilder
    private var recentPhotosSection: some View {
        HStack(spacing: 14) {
            // Left Photo: Previous Record (or mock 12 Aug 2026)
            if let previous = viewModel.previousRecord {
                NavigationLink(value: AppRouter.Route.recordDetail(id: previous.id)) {
                    ScanImageCard(
                        image: viewModel.previousFrontImage,
                        dateText: previous.formattedDate,
                        relativeDateText: viewModel.previousRelativeDate ?? "(7 days ago)"
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    openComparisonOrDetail()
                }) {
                    ScanImageCard(
                        image: viewModel.previousFrontImage,
                        dateText: "12 Aug 2026",
                        relativeDateText: "(7 days ago)"
                    )
                }
                .buttonStyle(.plain)
            }

            // Right Photo: Latest Record (or mock 13 Aug 2026)
            if let latest = viewModel.latestRecord {
                NavigationLink(value: AppRouter.Route.recordDetail(id: latest.id)) {
                    ScanImageCard(
                        image: viewModel.latestFrontImage,
                        dateText: latest.formattedDate,
                        relativeDateText: viewModel.latestRelativeDate ?? "(6 days ago)"
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    router.presentScanFlow()
                }) {
                    ScanImageCard(
                        image: viewModel.latestFrontImage,
                        dateText: "13 Aug 2026",
                        relativeDateText: "(6 days ago)"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
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

    // MARK: - Settings Sheet

    private var settingsSheetView: some View {
        NavigationStack {
            List {
                Section(header: Text("About Rona")) {
                    HStack {
                        Text("Application")
                        Spacer()
                        Text("Rona Acne Tracker")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("ML Detection Engine")
                        Spacer()
                        Text("CoreML Object Detection")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Scanning Preferences")) {
                    HStack {
                        Text("Lighting Detection")
                        Spacer()
                        Text("Enabled")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Face Angle Guidance")
                        Spacer()
                        Text("Front, Left, Right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isSettingsPresented = false
                    }
                }
            }
        }
    }
}
