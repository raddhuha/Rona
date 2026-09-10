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
}
