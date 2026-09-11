//
//  RonaApp.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import SwiftData
import Combine

@main
@MainActor
struct RonaApp: App {
    let modelContainer: ModelContainer
    @StateObject private var container: AppContainer
    @StateObject private var router: AppRouter

    init() {
        do {
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
            }

            let schema = Schema([
                ScanRecord.self,
                AcneDetectionRecord.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let mc = try ModelContainer(for: schema, configurations: [config])
            self.modelContainer = mc

            let storage = LocalFileImageStorage()
            let repo = SwiftDataScanRepository(modelContext: mc.mainContext, imageStorage: storage)
            let appContainer = AppContainer(
                acneDetector: MockAcneDetector(),
                scoreCalculator: SkinScoreCalculator(),
                insightGenerator: RuleBasedInsightGenerator(),
                imageStorage: storage,
                scanRepository: repo
            )
            _container = StateObject(wrappedValue: appContainer)
            _router = StateObject(wrappedValue: AppRouter())
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(router)
                .task {
                    // Preload initial sample records (matching 13 Aug & 15 Aug from screenshots)
                    await SampleDataSeeder.seedInitialDataIfNeeded(
                        repository: container.scanRepository,
                        imageStorage: container.imageStorage,
                        scoreCalculator: container.scoreCalculator
                    )
                    NotificationCenter.default.post(name: NSNotification.Name("RonaDataDidUpdate"), object: nil)
                }
        }
        .modelContainer(modelContainer)
    }
}
