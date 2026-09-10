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
    @Published public var checkInMessage: String = ""
    @Published public var isLoading: Bool = false

    private let scanRepository: ScanRepositoryProtocol
    private let insightGenerator: InsightGenerating
    private let imageStorage: ImageStorageProtocol
    private let checkInIntervalDays: Int = 7

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

            // Compute next check-in message
            updateCheckInMessage()

        } catch {
            print("Failed to load summary records: \(error)")
        }
    }

    private func updateInsight() {
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
        } else if let current = latestRecord {
            comparisonInsight = insightGenerator.generateInitialInsight(
                for: current.date,
                skinScore: current.skinScore,
                acneCount: current.totalAcneCount
            )
        } else {
            comparisonInsight = SkinInsight.initialPlaceholder
        }
    }

    private func updateCheckInMessage() {
        guard let latest = latestRecord else {
            checkInMessage = "You have not recorded any skin scans yet. Take your first scan to start tracking your skin progression."
            return
        }

        let calendar = Calendar.current
        let nextCheckInDate = calendar.date(byAdding: .day, value: checkInIntervalDays, to: latest.date) ?? latest.date
        let today = Date()

        let daysLeft = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: nextCheckInDate)).day ?? 0
        let formattedDate = CalendarDayHelper.formatDisplayDate(nextCheckInDate)

        if daysLeft > 0 {
            checkInMessage = "Your next regular check-in is on \(formattedDate) (\(daysLeft) days left)\nYou're free to scan today too, if you'd like to see how your skin's doing right now."
        } else if daysLeft == 0 {
            checkInMessage = "Your regular check-in is scheduled for today (\(formattedDate)).\nTake a few moments to scan your skin and log your progress."
        } else {
            let overdue = abs(daysLeft)
            checkInMessage = "Your regular check-in was due \(overdue) day\(overdue == 1 ? "" : "s") ago on \(formattedDate).\nScan today to keep your progress chart up to date."
        }
    }
}
