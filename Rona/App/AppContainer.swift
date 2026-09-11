//
//  AppContainer.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import SwiftData
import Combine

/// Dependency injection container centralizing services, ML detectors, and repositories.
@MainActor
public final class AppContainer: ObservableObject {
    public let acneDetector: AcneDetectorProtocol
    public let scoreCalculator: SkinScoreCalculating
    public let insightGenerator: InsightGenerating
    public let imageStorage: ImageStorageProtocol
    public let scanRepository: ScanRepositoryProtocol

    public init(
        acneDetector: AcneDetectorProtocol? = nil,
        scoreCalculator: SkinScoreCalculating? = nil,
        insightGenerator: InsightGenerating? = nil,
        imageStorage: ImageStorageProtocol? = nil,
        scanRepository: ScanRepositoryProtocol
    ) {
        let storage = imageStorage ?? LocalFileImageStorage()
        self.imageStorage = storage
        self.acneDetector = acneDetector ?? MockAcneDetector()
        self.scoreCalculator = scoreCalculator ?? SkinScoreCalculator()
        self.insightGenerator = insightGenerator ?? RuleBasedInsightGenerator()
        self.scanRepository = scanRepository
    }

    public static let preview: AppContainer = {
        let schema = Schema([ScanRecord.self, AcneDetectionRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let storage = LocalFileImageStorage()
        let repo = SwiftDataScanRepository(modelContext: container.mainContext, imageStorage: storage)
        return AppContainer(
            acneDetector: MockAcneDetector(simulateProcessingDelay: false),
            scoreCalculator: SkinScoreCalculator(),
            insightGenerator: RuleBasedInsightGenerator(),
            imageStorage: storage,
            scanRepository: repo
        )
    }()
}
