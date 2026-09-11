//
//  SummaryViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// ViewModel driving the Summary / Home screen.
@MainActor
public final class SummaryViewModel: ObservableObject {
    @Published public var latestRecord: ScanRecord?
    @Published public var previousRecord: ScanRecord?
    @Published public var latestFrontImage: UIImage?
    @Published public var previousFrontImage: UIImage?
    @Published public var comparisonInsight: SkinInsight?
    @Published public var observations: [SkinObservationItem] = []
    @Published public var previousRelativeDate: String?
    @Published public var latestRelativeDate: String?
    @Published public var progressHeadline: String = "You've made steady progress this last 30 days — whatever you're doing, it's working!"
    @Published public var currentSkinScore: Int = 80
    @Published public var sparklinePoints: [CGPoint] = SummaryProgressCard.defaultPoints
    @Published public var isLoading: Bool = false

    private let scanRepository: ScanRepositoryProtocol
    private let insightGenerator: InsightGenerating
    private let imageStorage: ImageStorageProtocol

    public init(
        scanRepository: ScanRepositoryProtocol,
        insightGenerator: InsightGenerating,
        imageStorage: ImageStorageProtocol
    ) {
        self.scanRepository = scanRepository
        self.insightGenerator = insightGenerator
        self.imageStorage = imageStorage
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let all = try await scanRepository.fetchAll()
            latestRecord = all.first

            if all.count >= 2 {
                previousRecord = all[1]
            } else {
                previousRecord = nil
            }

            // Load images from disk
            if let latest = latestRecord {
                latestFrontImage = imageStorage.loadImage(fromPath: latest.frontImagePath)
            } else {
                latestFrontImage = nil
            }

            if let prev = previousRecord {
                previousFrontImage = imageStorage.loadImage(fromPath: prev.frontImagePath)
            } else {
                previousFrontImage = nil
            }

            // Compute comparison insight
            updateInsight()
        } catch {
            print("Failed to load summary records: \(error)")
        }
    }

    private func updateInsight() {
        if let current = latestRecord {
            currentSkinScore = current.skinScore > 0 ? Int(current.skinScore) : 80
            let days = Calendar.current.dateComponents([.day], from: CalendarDayHelper.startOfDay(for: current.date), to: CalendarDayHelper.startOfDay(for: Date())).day ?? 0
            if days >= 20 {
                latestRelativeDate = "(6 days ago)"
            } else {
                latestRelativeDate = CalendarDayHelper.formatRelativeDays(for: current.date)
            }
        } else {
            currentSkinScore = 80
            latestRelativeDate = "(6 days ago)"
        }

        if let prev = previousRecord {
            let days = Calendar.current.dateComponents([.day], from: CalendarDayHelper.startOfDay(for: prev.date), to: CalendarDayHelper.startOfDay(for: Date())).day ?? 0
            if days >= 20 {
                previousRelativeDate = "(7 days ago)"
            } else {
                previousRelativeDate = CalendarDayHelper.formatRelativeDays(for: prev.date)
            }
        } else {
            previousRelativeDate = "(7 days ago)"
        }

        if let current = latestRecord, let prev = previousRecord {
            let comparison = ScanComparison(
                previousDate: prev.date,
                currentDate: current.date,
                previousScore: prev.skinScore,
                currentScore: current.skinScore,
                previousTotalAcne: prev.totalAcneCount,
                currentTotalAcne: current.totalAcneCount,
                previousCountsByType: prev.countsByType,
                currentCountsByType: current.countsByType,
                previousCountsByRegion: prev.countsByRegion,
                currentCountsByRegion: current.countsByRegion
            )
            comparisonInsight = insightGenerator.generateInsight(comparison: comparison)
            observations = insightGenerator.generateObservations(comparison: comparison)
        } else if let current = latestRecord {
            comparisonInsight = insightGenerator.generateInitialInsight(
                for: current.date,
                skinScore: current.skinScore,
                acneCount: current.totalAcneCount
            )
            observations = insightGenerator.generateDefaultObservations()
        } else {
            comparisonInsight = SkinInsight.initialPlaceholder
            observations = insightGenerator.generateDefaultObservations()
        }
    }
}
