//
//  ScanRepositoryProtocol.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Repository protocol abstracting persistence operations for scan records.
@MainActor
public protocol ScanRepositoryProtocol {
    /// Fetches all stored scan records sorted chronologically (newest first).
    func fetchAll() async throws -> [ScanRecord]

    /// Fetches a scan record matching a specific calendar day identifier (e.g. "2026-08-13").
    func fetchByDayId(_ dayId: String) async throws -> ScanRecord?

    /// Fetches a scan record matching a specific UUID.
    func fetchById(_ id: UUID) async throws -> ScanRecord?

    /// Saves or updates a daily scan record, enforcing exactly one record per calendar day.
    func saveOrUpdate(
        date: Date,
        frontImagePath: String,
        leftImagePath: String,
        rightImagePath: String,
        skinScore: Double,
        detections: [AcneDetection]
    ) async throws -> ScanRecord

    /// Deletes a scan record by ID.
    func delete(id: UUID) async throws

    /// Retrieves the most recent scan record strictly prior to the specified date.
    func getPreviousRecord(before date: Date) async throws -> ScanRecord?
}
