//
//  RecordsGridView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// 3-column historical records grid screen grouped by month with collapsible sections and comparison mode.
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

    public init(viewModel: RecordsViewModel? = nil) {
        let vm = viewModel ?? RecordsViewModel(
            scanRepository: AppContainer.preview.scanRepository,
            imageStorage: AppContainer.preview.imageStorage
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

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
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.monthGroups) { group in
                            monthSectionView(for: group)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
            }
        }
        .navigationTitle(viewModel.isSelectionMode ? "" : "Records")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if viewModel.isSelectionMode {
                // Compare Mode Toolbar (Right side)
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        // "Compare (0/2)" Action Pill
                        Button(action: {
                            if let pair = viewModel.selectedRecordsPair {
                                router.presentComparison(record1: pair.0, record2: pair.1)
                            }
                        }) {
                            Text("Compare (\(viewModel.selectedRecordIds.count)/2)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(viewModel.selectedRecordIds.count == 2 ? .white : Color(uiColor: .secondaryLabel))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedRecordIds.count == 2 ? AppTheme.textPrimary : Color(uiColor: .systemGray5))
                                .clipShape(Capsule())
                        }
                        .disabled(viewModel.selectedRecordIds.count != 2)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("records_compare_action_button")

                        // Close "X" Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                viewModel.toggleSelectionMode()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("records_close_compare_button")
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                // Normal Mode Toolbar (Leading back button & Trailing compare pill)
                ToolbarItem(placement: .topBarLeading) {
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
                    .accessibilityIdentifier("records_back_button")
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            viewModel.toggleSelectionMode()
                        }
                    }) {
                        Text("Compare")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color(uiColor: .systemGray4).opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("records_compare_button")
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .task {
            await viewModel.loadRecords()
        }
    }

    // MARK: - Month Section View

    @ViewBuilder
    private func monthSectionView(for group: MonthRecordGroup) -> some View {
        let isExpanded = viewModel.expandedMonthIds.contains(group.id)

        VStack(alignment: .leading, spacing: 0) {
            // Header Row (Tap to expand/collapse naturally)
            Button(action: {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                    viewModel.toggleMonthExpansion(group.id)
                }
            }) {
                HStack {
                    Text(group.monthYearString)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                // 3-Column Card Grid expands naturally in place
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(group.records) { record in
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
                .transition(.opacity)
                .padding(.top, 6)
                .padding(.bottom, 20)
            } else {
                // Divider line below collapsed month
                Rectangle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 1)
                    .padding(.bottom, 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordsGridView()
            .environmentObject(AppRouter())
    }
}
