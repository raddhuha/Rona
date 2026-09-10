//
//  RecordsViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// ViewModel managing the 3-column records grid and comparison selection.
@MainActor
public final class RecordsViewModel: ObservableObject {
    @Published public var records: [ScanRecord] = []
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
        } catch {
            print("Failed to fetch records: \(error)")
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
