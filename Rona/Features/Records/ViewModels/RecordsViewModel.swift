//
//  RecordsViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Model representing a group of historical scan records for a single calendar month.
public struct MonthRecordGroup: Identifiable {
    public var id: String { monthYearString }
    public let monthYearString: String
    public let monthDate: Date
    public let records: [ScanRecord]

    public init(monthYearString: String, monthDate: Date, records: [ScanRecord]) {
        self.monthYearString = monthYearString
        self.monthDate = monthDate
        self.records = records
    }
}

/// ViewModel managing the 3-column records grid grouped by month, expansion toggling, and comparison selection.
@MainActor
public final class RecordsViewModel: ObservableObject {
    @Published public var records: [ScanRecord] = []
    @Published public var monthGroups: [MonthRecordGroup] = []
    @Published public var expandedMonthIds: Set<String> = []
    @Published public var isSelectionMode: Bool = false
    @Published public var selectedRecordIds: Set<UUID> = []
    @Published public var isLoading: Bool = false

    private let scanRepository: ScanRepositoryProtocol
    public let imageStorage: ImageStorageProtocol

    public init(scanRepository: ScanRepositoryProtocol, imageStorage: ImageStorageProtocol) {
        self.scanRepository = scanRepository
        self.imageStorage = imageStorage
    }

    public func loadRecords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            records = try await scanRepository.fetchAll()
            updateMonthGroups()
        } catch {
            print("Failed to fetch records: \(error)")
        }
    }

    private func updateMonthGroups() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record -> Date in
            CalendarDayHelper.startOfMonth(for: record.date, calendar: calendar)
        }

        let sortedMonthDates = grouped.keys.sorted(by: >)
        self.monthGroups = sortedMonthDates.map { monthDate in
            let sortedRecords = (grouped[monthDate] ?? []).sorted { $0.date > $1.date }
            let title = CalendarDayHelper.formatMonthYear(monthDate)
            return MonthRecordGroup(
                monthYearString: title,
                monthDate: monthDate,
                records: sortedRecords
            )
        }

        // Automatically expand the latest (first) month by default; all others stay collapsed
        if let latestMonth = monthGroups.first, expandedMonthIds.isEmpty {
            expandedMonthIds.insert(latestMonth.id)
        }
    }

    public func toggleMonthExpansion(_ monthId: String) {
        if expandedMonthIds.contains(monthId) {
            expandedMonthIds.remove(monthId)
        } else {
            expandedMonthIds.insert(monthId)
        }
    }

    public func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedRecordIds.removeAll()
        }
    }

    public func toggleRecordSelection(_ record: ScanRecord) {
        if selectedRecordIds.contains(record.id) {
            selectedRecordIds.remove(record.id)
        } else {
            if selectedRecordIds.count < 2 {
                selectedRecordIds.insert(record.id)
            } else {
                // Keep at most 2 selected for comparison
                selectedRecordIds.removeAll()
                selectedRecordIds.insert(record.id)
            }
        }
    }

    public var selectedRecordsPair: (ScanRecord, ScanRecord)? {
        guard selectedRecordIds.count == 2 else { return nil }
        let selectedList = records.filter { selectedRecordIds.contains($0.id) }
        guard selectedList.count == 2 else { return nil }
        // Ensure chronological ordering: older first, newer second
        let sorted = selectedList.sorted { $0.date < $1.date }
        return (sorted[0], sorted[1])
    }
}
