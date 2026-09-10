//
//  ScanViewAngle.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// The three camera perspectives captured during a complete skin scan session.
public enum ScanViewAngle: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case front = "front"
    case left = "left"
    case right = "right"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .front: return "Scan Front"
        case .left: return "Scan Left"
        case .right: return "Scan Right"
        }
    }

    public var instruction: String {
        switch self {
        case .front: return "Position your face inside the guide and look straight ahead."
        case .left: return "Turn your head slightly to your left to capture your cheek."
        case .right: return "Turn your head slightly to your right to capture your cheek."
        }
    }

    /// Configurable mapping between the capture view angle and the facial regions expected in that view.
    public var associatedRegions: [FacialRegion] {
        switch self {
        case .front:
            return [.forehead, .nose, .chin]
        case .left:
            return [.leftCheek]
        case .right:
            return [.rightCheek]
        }
    }
}
