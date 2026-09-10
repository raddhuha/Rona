//
//  RecordsGridView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// 3-column historical records grid screen matching Screenshot 3 reference design.
@MainActor
public struct RecordsGridView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecordsViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    public init(viewModel: RecordsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Header
            NavigationHeader(
                title: "Records",
                actionType: .back,
                onLeadingAction: {
                    dismiss()
                },
                trailing: {
                    PrimaryPillButton(
                        title: viewModel.isSelectionMode ? "Cancel" : "Compare",
                        style: viewModel.isSelectionMode ? .filled : .bordered,
                        action: {
                            viewModel.toggleSelectionMode()
                        }
                    )
                }
            )

            ZStack(alignment: .bottom) {
                if viewModel.records.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "photo.stack",
                        title: "No Records Available",
                        message: "Complete a skin scan to see your daily photos organized here.",
                        actionTitle: "Scan Now"
                    ) {
                        router.presentScanFlow()
                    }
                    .padding(24)
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(viewModel.records) { record in
                                let isSelected = viewModel.selectedRecordIds.contains(record.id)
                                let image = viewModel.imageStorage.loadImage(fromPath: record.frontImagePath)

                                ScanImageCard(
                                    image: image,
                                    dateText: record.formattedDate,
                                    isSelected: isSelected,
                                    isSelectionMode: viewModel.isSelectionMode,
                                    action: {
                                        if viewModel.isSelectionMode {
                                            viewModel.toggleRecordSelection(record)
                                        } else {
                                            router.navigateToDetail(id: record.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, viewModel.isSelectionMode ? 90 : 30)
                    }
                }

                // Floating Compare Action Button when 2 records are picked
                if viewModel.isSelectionMode {
                    VStack {
                        Spacer()
                        if let pair = viewModel.selectedRecordsPair {
                            Button(action: {
                                router.presentComparison(record1: pair.0, record2: pair.1)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left.and.right")
                                    Text("Compare Selected (2)")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(AppTheme.textPrimary)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                            }
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            Text("Select 2 records to compare")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppTheme.cardBackground)
                                .clipShape(Capsule())
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadRecords()
        }
    }
}
