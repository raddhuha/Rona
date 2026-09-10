//
//  AcneType.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation
import SwiftUI

/// Represents the classification of acne lesions detected by the ML model.
///
/// NOTE: The acne class names are configurable here in one single place.
/// To rename or adjust classes in the future, simply update the raw values or `displayName`
/// without modifying any view or service logic.
public enum AcneType: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case type1 = "type1"
    case type2 = "type2"
    case type3 = "type3"
    case type4 = "type4"
    case type5 = "type5"
    case type6 = "type6"

    public var id: String { rawValue }

    /// Human-readable label displayed across all views, tables, and charts.
    public var displayName: String {
        switch self {
        case .type1: return "Whitehead"
        case .type2: return "Blackhead"
        case .type3: return "Papules"
        case .type4: return "Pustules"
        case .type5: return "Nodules"
        case .type6: return "Cystic"
        }
    }

    /// Associated theme color for visualizations and bounding boxes.
    public var visualColor: Color {
        switch self {
        case .type1: return Color(red: 0.95, green: 0.70, blue: 0.30) // Warm amber
        case .type2: return Color(red: 0.35, green: 0.40, blue: 0.50) // Slate gray
        case .type3: return Color(red: 0.95, green: 0.45, blue: 0.35) // Coral red
        case .type4: return Color(red: 0.90, green: 0.25, blue: 0.45) // Deep rose
        case .type5: return Color(red: 0.70, green: 0.20, blue: 0.60) // Purple
        case .type6: return Color(red: 0.85, green: 0.15, blue: 0.20) // Crimson
        }
    }

    /// Weight assigned when computing the skin score penalty.
    /// Non-inflammatory lesions have lower weights; inflammatory lesions have higher weights.
    public var severityWeight: Double {
        switch self {
        case .type1: return 1.0  // Whitehead
        case .type2: return 1.0  // Blackhead
        case .type3: return 2.0  // Papules
        case .type4: return 2.5  // Pustules
        case .type5: return 4.0  // Nodules
        case .type6: return 5.0  // Cystic
        }
    }
}
