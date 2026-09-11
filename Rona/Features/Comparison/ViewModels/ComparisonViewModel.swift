//
//  ComparisonViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// ViewModel driving the two-date comparison screen.
@MainActor
public final class ComparisonViewModel: ObservableObject {
    public let previousRecord: ScanRecord
    public let currentRecord: ScanRecord

    @Published public var previousFrontImage: UIImage?
    @Published public var currentFrontImage: UIImage?
    @Published public var comparisonInsight: SkinInsight
    @Published public var comparison: ScanComparison

    private let imageStorage: ImageStorageProtocol
    private let insightGenerator: InsightGenerating

    public init(
        previousRecord: ScanRecord,
        currentRecord: ScanRecord,
        imageStorage: ImageStorageProtocol,
        insightGenerator: InsightGenerating
    ) {
        self.previousRecord = previousRecord
        self.currentRecord = currentRecord
        self.imageStorage = imageStorage
        self.insightGenerator = insightGenerator

        let comp = ScanComparison(
            previousDate: previousRecord.date,
            currentDate: currentRecord.date,
            previousScore: previousRecord.skinScore,
            currentScore: currentRecord.skinScore,
            previousTotalAcne: previousRecord.totalAcneCount,
            currentTotalAcne: currentRecord.totalAcneCount,
            previousCountsByType: previousRecord.countsByType,
            currentCountsByType: currentRecord.countsByType,
            previousCountsByRegion: previousRecord.countsByRegion,
            currentCountsByRegion: currentRecord.countsByRegion
        )
        self.comparison = comp
        self.comparisonInsight = insightGenerator.generateInsight(comparison: comp)
    }

    public func loadImages() {
        previousFrontImage = imageStorage.loadImage(fromPath: previousRecord.frontImagePath)
        currentFrontImage = imageStorage.loadImage(fromPath: currentRecord.frontImagePath)
    }

    public static var previewInstance: ComparisonViewModel {
        ComparisonViewModel(
            previousRecord: ScanRecord(calendarDayId: "2026-08-12", skinScore: 68),
            currentRecord: ScanRecord(calendarDayId: "2026-08-13", skinScore: 80),
            imageStorage: AppContainer.preview.imageStorage,
            insightGenerator: AppContainer.preview.insightGenerator
        )
    }
}
