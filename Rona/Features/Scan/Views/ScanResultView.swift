//
//  ScanResultView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Review screen presented after analysis completion, allowing the user to review and save the record.
@MainActor
public struct ScanResultView: View {
    @ObservedObject var viewModel: ScanViewModel
    let onSaveCompleted: () -> Void
    @State private var isSaving: Bool = false

    public init(viewModel: ScanViewModel, onSaveCompleted: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSaveCompleted = onSaveCompleted
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Scan Complete")
                    .font(AppTheme.largeTitleFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.top, 12)

                Text("Your skin scan has been analyzed. Review your score and detected lesions below before saving.")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)

                // Front Photo Preview with Bounding Boxes
                if let front = viewModel.frontImage, let session = viewModel.sessionResult {
                    ZStack {
                        Image(uiImage: front)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()

                        let frontDetections = session.detections.filter { $0.viewAngle == .front }
                        AcneBoundingBoxOverlay(detections: frontDetections)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                // Skin Score Section
                if let session = viewModel.sessionResult {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated Skin Score")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)

                            ScoreBadgeView(
                                score: session.skinScore,
                                mode: .fraction
                            )
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Lesions")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)

                            Text("\(session.totalAcneCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(20)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                }

                // Comparison Insight Card
                if let insight = viewModel.comparisonInsight {
                    InsightCardView(
                        insight: insight,
                        title: "Scan Insight"
                    )
                }

                // Action Buttons: Save Record & Retake
                VStack(spacing: 12) {
                    Button(action: {
                        isSaving = true
                        Task {
                            let success = await viewModel.saveRecord()
                            isSaving = false
                            if success {
                                onSaveCompleted()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving Record..." : "Save Record")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.textPrimary)
                        .clipShape(Capsule())
                    }
                    .disabled(isSaving)

                    Button(action: {
                        viewModel.retakeCurrent()
                    }) {
                        Text("Retake Photos")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.background)
    }
}
