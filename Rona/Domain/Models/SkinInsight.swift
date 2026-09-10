//
//  SkinInsight.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Represents a calm, factual, and non-judgmental insight comparing skin scan records.
public struct SkinInsight: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let body: String
    public let leadingIconName: String
    public let relatedRegion: FacialRegion?
    public let relatedType: AcneType?

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        leadingIconName: String = "lightbulb.fill",
        relatedRegion: FacialRegion? = nil,
        relatedType: AcneType? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.leadingIconName = leadingIconName
        self.relatedRegion = relatedRegion
        self.relatedType = relatedType
    }

    /// Fallback default when no historical comparisons are available yet.
    public static var initialPlaceholder: SkinInsight {
        SkinInsight(
            title: "Welcome to Skin Tracking",
            body: "Perform your first scan to begin tracking changes and receiving personalized skin insights."
        )
    }
}
