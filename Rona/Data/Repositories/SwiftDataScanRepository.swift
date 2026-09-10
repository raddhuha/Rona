//
//  SwiftDataScanRepository.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation
import SwiftData

/// SwiftData implementation of `ScanRepositoryProtocol`.
///
/// Ensures the invariant: EXACTLY ONE record per calendar day.
/// Re-scanning on the same day replaces the previous record and cleans up obsolete photos.
@MainActor
public final class SwiftDataScanRepository: ScanRepositoryProtocol {
    private let modelContext: ModelContext
    private let imageStorage: ImageStorageProtocol

    public init(modelContext: ModelContext, imageStorage: ImageStorageProtocol) {
        self.modelContext = modelContext
        self.imageStorage = imageStorage
    }

    public func fetchAll() async throws -> [ScanRecord] {
        var descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    public func fetchByDayId(_ dayId: String) async throws -> ScanRecord? {
        var descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate { $0.calendarDayId == dayId }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func fetchById(_ id: UUID) async throws -> ScanRecord? {
        var descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func saveOrUpdate(
        date: Date,
        frontImagePath: String,
        leftImagePath: String,
        rightImagePath: String,
        skinScore: Double,
        detections: [AcneDetection]
    ) async throws -> ScanRecord {
        let dayId = CalendarDayHelper.calendarDayId(for: date)

        // Convert domain detections into persistent records
        let detectionRecords = detections.map { AcneDetectionRecord(from: $0) }

        if let existing = try await fetchByDayId(dayId) {
            // Replace existing record for this calendar day
            // 1. Delete old images from disk if paths changed
            if existing.frontImagePath != frontImagePath {
                imageStorage.deleteImage(atPath: existing.frontImagePath)
            }
            if existing.leftImagePath != leftImagePath {
                imageStorage.deleteImage(atPath: existing.leftImagePath)
            }
            if existing.rightImagePath != rightImagePath {
                imageStorage.deleteImage(atPath: existing.rightImagePath)
            }

            // 2. Clear out old detections from context
            for oldDetection in existing.detections {
                modelContext.delete(oldDetection)
            }

            // 3. Update fields
            existing.date = date
            existing.frontImagePath = frontImagePath
            existing.leftImagePath = leftImagePath
            existing.rightImagePath = rightImagePath
            existing.skinScore = skinScore
            existing.totalAcneCount = detections.count
            existing.detections = detectionRecords

            for record in detectionRecords {
                record.scanRecord = existing
            }

            try modelContext.save()
            return existing
        } else {
            // Create brand new daily record
            let newRecord = ScanRecord(
                calendarDayId: dayId,
                id: UUID(),
                date: date,
                frontImagePath: frontImagePath,
                leftImagePath: leftImagePath,
                rightImagePath: rightImagePath,
                skinScore: skinScore,
                totalAcneCount: detections.count,
                detections: detectionRecords
            )

            for record in detectionRecords {
                record.scanRecord = newRecord
            }

            modelContext.insert(newRecord)
            try modelContext.save()
            return newRecord
        }
    }

    public func delete(id: UUID) async throws {
        if let record = try await fetchById(id) {
            // Delete associated images
            imageStorage.deleteImage(atPath: record.frontImagePath)
            imageStorage.deleteImage(atPath: record.leftImagePath)
            imageStorage.deleteImage(atPath: record.rightImagePath)

            modelContext.delete(record)
            try modelContext.save()
        }
    }

    public func getPreviousRecord(before date: Date) async throws -> ScanRecord? {
        let all = try await fetchAll()
        let dayIdOfTarget = CalendarDayHelper.calendarDayId(for: date)

        // Find the most recent record that is strictly before this calendar day
        return all.first { record in
            record.calendarDayId != dayIdOfTarget && record.date < date
        }
    }
}
