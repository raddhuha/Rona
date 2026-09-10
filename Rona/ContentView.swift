//
//  ContentView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Main container coordinating root navigation and presentations.
@MainActor
public struct ContentView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer

    public var body: some View {
        NavigationStack(path: $router.path) {
            SummaryView(
                viewModel: SummaryViewModel(
                    scanRepository: container.scanRepository,
                    insightGenerator: container.insightGenerator,
                    imageStorage: container.imageStorage
                )
            )
            .navigationDestination(for: AppRouter.Route.self) { route in
                switch route {
                case .records:
                    RecordsGridView(
                        viewModel: RecordsViewModel(
                            scanRepository: container.scanRepository,
                            imageStorage: container.imageStorage
                        )
                    )
                case .report:
                    ReportView(
                        viewModel: ReportViewModel(
                            scanRepository: container.scanRepository,
                            insightGenerator: container.insightGenerator
                        )
                    )
                case .recordDetail(let id):
                    RecordDetailView(
                        viewModel: RecordDetailViewModel(
                            recordId: id,
                            scanRepository: container.scanRepository,
                            imageStorage: container.imageStorage
                        )
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $router.isScanningPresented) {
            ScanCoordinatorView(
                viewModel: ScanViewModel(
                    acneDetector: container.acneDetector,
                    scoreCalculator: container.scoreCalculator,
                    insightGenerator: container.insightGenerator,
                    scanRepository: container.scanRepository,
                    imageStorage: container.imageStorage
                )
            )
            .environmentObject(router)
            .environmentObject(container)
        }
        .sheet(item: $router.activeComparison) { comparison in
            ComparisonView(
                viewModel: ComparisonViewModel(
                    previousRecord: comparison.previousRecord,
                    currentRecord: comparison.currentRecord,
                    imageStorage: container.imageStorage,
                    insightGenerator: container.insightGenerator
                )
            )
            .environmentObject(router)
            .environmentObject(container)
        }
        .preferredColorScheme(.light)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-testScanResult") || ProcessInfo.processInfo.arguments.contains("-testScan") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    router.presentScanFlow()
                }
            }
            #endif
        }
    }
}
