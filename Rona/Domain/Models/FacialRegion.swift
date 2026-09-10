//
//  FacialRegion.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Represents the facial regions where acne lesions can occur.
public enum FacialRegion: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case forehead = "forehead"
    case leftCheek = "leftCheek"
    case rightCheek = "rightCheek"
    case nose = "nose"
    case chin = "chin"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .forehead: return "Forehead"
        case .leftCheek: return "Left Cheek"
        case .rightCheek: return "Right Cheek"
        case .nose: return "Nose"
        case .chin: return "Chin"
        }
    }
}
