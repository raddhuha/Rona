//
//  TimePeriod.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Supported reporting and chart time windows.
public enum TimePeriod: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case week = "Weekly"
    case month = "Monthly"
    case year = "Yearly"

    public var id: String { rawValue }

    public var displayName: String { rawValue }
}
