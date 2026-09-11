//
//  RecordDetailView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Detailed record screen matching designer mockup with horizontal region photo carousel
/// and synchronized Acne by Type breakdown.
@MainActor
public struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecordDetailViewModel
    @State private var showScoreInfoSheet: Bool = false
    @State private var selectedPagePosition: DetailPageKind? = .fullFace

    public init(viewModel: RecordDetailViewModel? = nil) {
        let vm = viewModel ?? RecordDetailViewModel(
            recordId: UUID(),
            scanRepository: AppContainer.preview.scanRepository,
            imageStorage: AppContainer.preview.imageStorage,
            record: ScanRecord(
                calendarDayId: "2026-08-13",
                date: Date(),
                skinScore: 20.0,
                totalAcneCount: 90,
                detections: [
                    AcneDetectionRecord(
                        from: AcneDetection(
                            acneType: .type1,
                            facialRegion: .forehead,
                            boundingBox: CGRect(x: 0.45, y: 0.20, width: 0.08, height: 0.08),
                            confidence: 0.95
                        )
                    ),
                    AcneDetectionRecord(
                        from: AcneDetection(
                            acneType: .type1,
                            facialRegion: .rightCheek,
                            boundingBox: CGRect(x: 0.60, y: 0.45, width: 0.08, height: 0.08),
                            confidence: 0.92
                        )
                    )
                ]
            )
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        Group {
            if let record = viewModel.record {
                mainScrollContent(record: record)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(viewModel.record?.formattedFullDate ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                deleteButton
            }
        }
        .task {
            await viewModel.loadRecord()
        }
        .confirmationDialog(
            "Delete Record",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Scan Record", role: .destructive) {
                Task {
                    await viewModel.deleteRecord()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this scan? This will remove the photos and analysis for this day.")
        }
        .alert("About Skin Score", isPresented: $showScoreInfoSheet) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The skin score is an estimate based on detected lesions and does not represent medical diagnosis.")
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
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
        .accessibilityIdentifier("record_detail_back_button")
    }

    private var deleteButton: some View {
        Button(action: {
            viewModel.showDeleteConfirmation = true
        }) {
            HStack(spacing: 5) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                Text("Delete")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(AppTheme.accentRed)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("record_detail_delete_button")
    }

    private func mainScrollContent(record: ScanRecord) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                carouselSection(record: record)
                    .padding(.top, 12)

                bottomDetailsSection(record: record)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -40 {
                        navigateToNextPage()
                    } else if value.translation.width > 40 {
                        navigateToPreviousPage()
                    }
                }
        )
    }

    private func bottomDetailsSection(record: ScanRecord) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.selectedPage.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .id("title_\(viewModel.selectedPage.id)")

            if viewModel.selectedPage == .fullFace {
                skinScoreSection(record: record)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Acne by Type")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                acneBreakdownTable(for: viewModel.selectedPage, record: record)
                    .id("table_\(viewModel.selectedPage.id)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private func skinScoreSection(record: ScanRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text("Skin Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Button(action: {
                    showScoreInfoSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Text("\(Int(record.skinScore))%")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
        }
        .transition(.opacity)
    }

    // MARK: - Carousel Section

    private func carouselSection(record: ScanRecord) -> some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let cardWidth: CGFloat = 230
            let cardHeight: CGFloat = 310
            let sidePadding = max(0, (screenWidth - cardWidth) / 2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(DetailPageKind.allCases) { page in
                        photoCard(for: page, width: cardWidth, height: cardHeight)
                            .id(page)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                                    selectedPagePosition = page
                                    viewModel.selectedPage = page
                                }
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, sidePadding)
            .scrollPosition(id: $selectedPagePosition)
            .onChange(of: selectedPagePosition) { _, newPage in
                if let newPage = newPage, newPage != viewModel.selectedPage {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        viewModel.selectedPage = newPage
                    }
                }
            }
        }
        .frame(height: 316)
    }

    private func photoCard(for page: DetailPageKind, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if let image = viewModel.image(for: page) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Page Switching Handlers

    private func navigateToNextPage() {
        let all = DetailPageKind.allCases
        guard let idx = all.firstIndex(of: viewModel.selectedPage), idx < all.count - 1 else { return }
        let next = all[idx + 1]
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            selectedPagePosition = next
            viewModel.selectedPage = next
        }
    }

    private func navigateToPreviousPage() {
        let all = DetailPageKind.allCases
        guard let idx = all.firstIndex(of: viewModel.selectedPage), idx > 0 else { return }
        let prev = all[idx - 1]
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            selectedPagePosition = prev
            viewModel.selectedPage = prev
        }
    }

    // MARK: - Acne by Type Table

    private func acneBreakdownTable(for page: DetailPageKind, record: ScanRecord) -> some View {
        let counts = viewModel.countsByType(for: page)
        let total = viewModel.totalAcneCount(for: page)

        return VStack(spacing: 0) {
            ForEach(AcneType.allCases) { type in
                let count = counts[type, default: 0]
                let label = type.displayName == "Cystic" ? "Cystics" : type.displayName

                HStack {
                    Text(label)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text("\(count)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.vertical, 9)

                Divider()
                    .background(Color(uiColor: .systemGray5))
            }

            // Total Row
            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(total)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.vertical, 11)
        }
    }
}

#Preview {
    NavigationStack {
        RecordDetailView()
            .environmentObject(AppRouter())
    }
}
