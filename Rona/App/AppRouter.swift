//
//  AppRouter.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Wrapper struct for record comparison to support Identifiable sheet presentation and Equatable state.
public struct ComparisonSelection: Identifiable, Equatable {
    public let id: String
    public let previousRecord: ScanRecord
    public let currentRecord: ScanRecord

    public init(previousRecord: ScanRecord, currentRecord: ScanRecord) {
        self.id = "\(previousRecord.calendarDayId)_\(currentRecord.calendarDayId)_\(UUID().uuidString)"
        self.previousRecord = previousRecord
        self.currentRecord = currentRecord
    }

    public static func == (lhs: ComparisonSelection, rhs: ComparisonSelection) -> Bool {
        lhs.id == rhs.id
    }
}

/// App navigation router managing NavigationStack paths and modal presentations.
@MainActor
public final class AppRouter: ObservableObject {
    public enum Route: Hashable {
        case records
        case report
        case recordDetail(id: UUID)
    }

    @Published public var path = NavigationPath()
    @Published public var isScanningPresented: Bool = false
    @Published public var activeComparison: ComparisonSelection? = nil

    public init() {}

    public func navigateToRecords() {
        path.append(Route.records)
    }

    public func navigateToReport() {
        path.append(Route.report)
    }

    public func navigateToDetail(id: UUID) {
        path.append(Route.recordDetail(id: id))
    }

    public func presentScanFlow() {
        isScanningPresented = true
    }

    public func presentComparison(record1: ScanRecord, record2: ScanRecord) {
        activeComparison = ComparisonSelection(previousRecord: record1, currentRecord: record2)
    }

    public func dismissScanFlow() {
        isScanningPresented = false
    }

    public func dismissScanAndNavigateToDetail(id: UUID) {
        isScanningPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.navigateToDetail(id: id)
        }
    }

    public func dismissScanAndPresentComparison(record1: ScanRecord, record2: ScanRecord) {
        isScanningPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.presentComparison(record1: record1, record2: record2)
        }
    }

    public func dismissScanAndNavigateToRecords() {
        isScanningPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.navigateToRecords()
        }
    }

    public func dismissComparisonAndNavigateToDetail(id: UUID) {
        activeComparison = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.navigateToDetail(id: id)
        }
    }

    public func dismissComparisonAndNavigateToRecords() {
        activeComparison = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.navigateToRecords()
        }
    }

    public func popToRoot() {
        path.removeLast(path.count)
    }
}
