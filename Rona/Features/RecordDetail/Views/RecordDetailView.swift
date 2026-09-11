//
//  RecordDetailView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Detailed record screen matching Screenshot 4 reference design.
@MainActor
public struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecordDetailViewModel
    @State private var showScoreInfoSheet: Bool = false

    public init(viewModel: RecordDetailViewModel? = nil) {
        let vm = viewModel ?? RecordDetailViewModel(
            recordId: UUID(),
            scanRepository: AppContainer.preview.scanRepository,
            imageStorage: AppContainer.preview.imageStorage,
            record: ScanRecord(
                calendarDayId: "2026-08-13",
                date: Date(),
                skinScore: 80.0,
                totalAcneCount: 1,
                detections: [
                    AcneDetectionRecord(
                        from: AcneDetection(
                            acneType: .type1,
                            boundingBox: CGRect(x: 0.45, y: 0.35, width: 0.08, height: 0.08),
                            confidence: 0.92
                        )
                    )
                ]
            )
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let record = viewModel.record {
                // Navigation Header
                NavigationHeader(
                    title: record.formattedFullDate,
                    actionType: .back,
                    onLeadingAction: {
                        dismiss()
                    },
                    trailing: {
                        PrimaryPillButton(
                            title: "Delete",
                            icon: "trash",
                            style: .destructive,
                            action: {
                                viewModel.showDeleteConfirmation = true
                            }
                        )
                    }
                )

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Angle Selector (Front / Left / Right)
                        HStack(spacing: 8) {
                            ForEach(ScanViewAngle.allCases) { angle in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedAngle = angle
                                    }
                                }) {
                                    Text(angle.rawValue.capitalized)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(viewModel.selectedAngle == angle ? .white : AppTheme.textPrimary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(viewModel.selectedAngle == angle ? AppTheme.textPrimary : Color(uiColor: .systemGray6))
                                        .clipShape(Capsule())
                                }
                            }

                            Spacer()

                            // Bounding Box Toggle
                            Button(action: {
                                viewModel.showBoundingBoxes.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.showBoundingBoxes ? "viewfinder.circle.fill" : "viewfinder.circle")
                                    Text("Detections")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(viewModel.showBoundingBoxes ? AppTheme.accentBlue : AppTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(uiColor: .systemGray6))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 4)

                        // Photo with optional Bounding Box Overlay
                        ZStack {
                            let currentImage = viewModel.currentImage(for: viewModel.selectedAngle)
                            let detections = viewModel.currentDetections(for: viewModel.selectedAngle)

                            if let image = currentImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color(uiColor: .systemGray6))
                                    .frame(height: 280)
                                    .overlay(
                                        Image(systemName: "person.crop.rectangle")
                                            .font(.system(size: 48))
                                            .foregroundColor(Color(uiColor: .systemGray4))
                                    )
                            }

                            if viewModel.showBoundingBoxes {
                                AcneBoundingBoxOverlay(detections: detections)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

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

                        // Score 20/100 Display
                        ScoreBadgeView(
                            score: record.skinScore,
                            mode: .fraction
                        )

                        // Quick Navigation: Compare with previous scan if available
                        if let previous = viewModel.previousRecord {
                            Button(action: {
                                router.presentComparison(record1: previous, record2: record)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left.and.right")
                                    Text("Compare with \(previous.formattedDate)")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .systemGray6))
                                .clipShape(Capsule())
                            }
                        }

                        // "Acne by Type" Breakdown Table (matching Screenshot 4)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acne by Type")
                                .font(AppTheme.sectionTitleFont)
                                .foregroundColor(AppTheme.textPrimary)

                            VStack(spacing: 0) {
                                ForEach(AcneType.allCases) { type in
                                    let count = record.countsByType[type, default: 0]
                                    HStack {
                                        Text(type.displayName)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Text("\(count)")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    .padding(.vertical, 10)

                                    Divider()
                                }

                                // Total Row
                                HStack {
                                    Text("Total")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text("\(record.totalAcneCount)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .padding(.vertical, 12)
                            }
                        }

                        // "Acne by Region" Breakdown Table
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acne by Region")
                                .font(AppTheme.sectionTitleFont)
                                .foregroundColor(AppTheme.textPrimary)

                            VStack(spacing: 0) {
                                ForEach(FacialRegion.allCases) { region in
                                    let count = record.countsByRegion[region, default: 0]
                                    HStack {
                                        Text(region.displayName)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Text("\(count)")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    .padding(.vertical, 10)

                                    Divider()
                                }
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

                            NavigationRowCard(title: "View Progress Report") {
                                router.navigateToReport()
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 36)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden(true)
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
}

#Preview {
    RecordDetailView()
        .environmentObject(AppRouter())
}

