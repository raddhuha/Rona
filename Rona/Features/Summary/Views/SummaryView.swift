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
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("summary_camera_button")

                // Settings Button
                Button(action: {
                    isSettingsPresented = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
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

// MARK: - Subcomponents

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

/// Smooth cubic sparkline curve drawing progress across time.
public struct SmoothSparklineShape: Shape {
    public let normalizedPoints: [CGPoint] // x: 0...1, y: 0...1 (0 = bottom, 1 = top)

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard normalizedPoints.count > 1 else { return path }

        // Convert normalized coordinates to rect coordinates (inverted Y for SwiftUI)
        let points = normalizedPoints.map { pt in
            CGPoint(
                x: rect.minX + pt.x * rect.width,
                y: rect.maxY - pt.y * rect.height
            )
        }

        path.move(to: points[0])

        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : p2

            // Catmull-Rom to Cubic Bézier conversion
            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }

        return path
    }
}

/// "How you've been doing" progress card with smooth 30-day sparkline and score indicator matching the reference design.
public struct SummaryProgressCard: View {
    public let headline: String
    public let currentScore: Int
    public let points: [CGPoint]

    public init(
        headline: String = "You've made steady progress this last 30 days — whatever you're doing, it's working!",
        currentScore: Int = 80,
        points: [CGPoint] = Self.defaultPoints
    ) {
        self.headline = headline
        self.currentScore = currentScore
        self.points = points.isEmpty ? Self.defaultPoints : points
    }

    public static var defaultPoints: [CGPoint] {
        // Progression curve matching reference screenshot:
        [
            CGPoint(x: 0.08, y: 0.22),
            CGPoint(x: 0.16, y: 0.26),
            CGPoint(x: 0.23, y: 0.44),
            CGPoint(x: 0.30, y: 0.65),
            CGPoint(x: 0.37, y: 0.60),
            CGPoint(x: 0.45, y: 0.40),
            CGPoint(x: 0.52, y: 0.46),
            CGPoint(x: 0.58, y: 0.24),
            CGPoint(x: 0.65, y: 0.32),
            CGPoint(x: 0.72, y: 0.21),
            CGPoint(x: 0.80, y: 0.30),
            CGPoint(x: 0.88, y: 0.18),
            CGPoint(x: 0.95, y: 0.58),
            CGPoint(x: 0.98, y: 0.82)
        ]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Top row: headline + chevron
            HStack(alignment: .top, spacing: 12) {
                Text(headline)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: .systemGray3))
                    .padding(.top, 2)
            }

            // Chart area
            VStack(spacing: 8) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack(alignment: .topLeading) {
                        // Smooth sparkline curve
                        SmoothSparklineShape(normalizedPoints: points)
                            .stroke(
                                Color(uiColor: .systemGray).opacity(0.85),
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                            )

                        // Score label floating right above the curve's endpoint
                        if let lastPoint = points.last {
                            let endX = lastPoint.x * w
                            let endY = (1.0 - lastPoint.y) * h

                            Text("\(currentScore)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(uiColor: .darkGray))
                                .position(x: endX - 4, y: max(endY - 14, 8))
                        }
                    }
                }
                .frame(height: 90)
                .padding(.top, 6)

                // Baseline horizontal axis
                Rectangle()
                    .fill(Color(uiColor: .systemGray4).opacity(0.8))
                    .frame(height: 1)

                // X-Axis Labels: "30 days ago" and "Today"
                HStack {
                    Text("30 days ago")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Spacer()

                    Text("Today")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(uiColor: .systemGray4).opacity(0.5), lineWidth: 1)
        )
    }
}
