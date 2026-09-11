//
//  ScanResultView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Review screen presented after capture and analysis, matching the reference design:
/// Horizontal 3-photo carousel, Full Face, Skin Score, Acne by Type table, and Save/Discard actions.
@MainActor
public struct ScanResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @ObservedObject var viewModel: ScanViewModel
    let onSaveCompleted: () -> Void

    @State private var isSaving: Bool = false
    @State private var showDiscardAlert: Bool = false
    @State private var showScoreInfoSheet: Bool = false

    public init(viewModel: ScanViewModel? = nil, onSaveCompleted: @escaping () -> Void = {}) {
        self.viewModel = viewModel ?? ScanViewModel.previewInstance
        self.onSaveCompleted = onSaveCompleted
    }

    private var displayDateText: String {
        guard let session = viewModel.sessionResult else {
            return CalendarDayHelper.formatFullDisplayDate(Date())
        }
        return CalendarDayHelper.formatFullDisplayDate(session.date)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar: Circular Back Button `<` + Centered Date
            topNavigationBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // 3-Photo Horizontal Carousel (Front, Left, Right)
                    photoCarouselSection

                    // "Full Face" Section
                    Text("Full Face")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 2)

                    // "Skin Score" Section
                    skinScoreSection
                        .padding(.horizontal, 20)

                    // "Acne by Type" Breakdown Table
                    acneByTypeSection
                        .padding(.horizontal, 20)

                    // Save Button
                    saveButton
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                }
            }
        }
        .background(AppTheme.background)
        .alert("Discard Scan?", isPresented: $showDiscardAlert) {
            Button("Discard and Delete", role: .destructive) {
                viewModel.discardScan()
                router.dismissScanFlow()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("This will delete the current scan session and its results.")
        }
        .sheet(isPresented: $showScoreInfoSheet) {
            scoreInfoSheet
        }
    }

    // MARK: - Navigation Bar

    private var topNavigationBar: some View {
        ZStack {
            // Centered Date
            Text(displayDateText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            // Leading Circular Back Button
            HStack {
                Button(action: {
                    showDiscardAlert = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scan_result_back_button")

                Spacer()
            }
        }
    }

    // MARK: - 3-Photo Horizontal Carousel

    private var photoCarouselSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // Card 1: Front
                carouselCard(image: viewModel.frontImage)

                // Card 2: Right
                carouselCard(image: viewModel.rightImage)

                // Card 3: Left
                carouselCard(image: viewModel.leftImage)
            }
            .padding(.horizontal, 20)
        }
    }

    private func carouselCard(image: UIImage?) -> some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 270)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 220, height: 270)
            }
        }
        .frame(width: 220, height: 270)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(uiColor: .systemGray5), lineWidth: 1)
        )
    }

    // MARK: - Skin Score Section

    private var skinScoreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text("Skin Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Button(action: {
                    showScoreInfoSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .buttonStyle(.plain)
            }

            let score = Int(viewModel.sessionResult?.skinScore ?? 20.0)
            Text("\(score)%")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    // MARK: - Acne by Type Section

    private var acneByTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acne by Type")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            let counts = viewModel.sessionResult?.countsByType ?? [:]
            let total = viewModel.sessionResult?.totalAcneCount ?? 90

            VStack(spacing: 0) {
                acneTypeRow(title: "Whitehead", count: counts[.type1, default: 90])
                acneTypeRow(title: "Blackhead", count: counts[.type2, default: 0])
                acneTypeRow(title: "Papules", count: counts[.type3, default: 0])
                acneTypeRow(title: "Pustules", count: counts[.type4, default: 0])
                acneTypeRow(title: "Nodules", count: counts[.type5, default: 0])
                acneTypeRow(title: "Cystics", count: counts[.type6, default: 0])

                // Total Row
                HStack {
                    Text("Total")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Text("\(total)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.vertical, 9)

                Divider()
                    .background(Color(uiColor: .systemGray4).opacity(0.4))
            }
        }
    }

    private func acneTypeRow(title: String, count: Int) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.vertical, 7)

            Divider()
                .background(Color(uiColor: .systemGray4).opacity(0.4))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            isSaving = true
            Task {
                let success = await viewModel.saveRecord()
                isSaving = false
                if success {
                    onSaveCompleted()
                    router.dismissScanFlow()
                }
            }
        }) {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(AppTheme.textPrimary)
                        .padding(.trailing, 4)
                }
                Text(isSaving ? "Saving..." : "Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(uiColor: .systemGray4).opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityIdentifier("scan_result_save_button")
    }

    // MARK: - Score Info Sheet

    private var scoreInfoSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("How Skin Score is Calculated")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Skin Score is calculated on a scale from 0% to 100%. Higher scores reflect clearer skin with fewer inflammatory lesions. Each detected lesion contributes a weighted factor based on its severity (Whiteheads & Blackheads have low weight; Papules, Pustules, Nodules, and Cystics have higher weight).")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(4)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Skin Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showScoreInfoSheet = false
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ScanResultView()
        .environmentObject(AppRouter())
}

