//
//  ScanComparison.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Encapsulates the quantitative delta between two skin scan records.
public struct ScanComparison: Identifiable, Sendable {
    public let id: UUID
    public let previousDate: Date
    public let currentDate: Date
    public let previousScore: Double
    public let currentScore: Double
    public let scoreDelta: Double // Positive means score increased (improvement)
    public let previousTotalAcne: Int
    public let currentTotalAcne: Int
    public let totalAcneDelta: Int // Negative means acne decreased (improvement)

    public let countsByTypeDelta: [AcneType: (previous: Int, current: Int, delta: Int)]
    public let countsByRegionDelta: [FacialRegion: (previous: Int, current: Int, delta: Int)]

    public init(
        id: UUID = UUID(),
        previousDate: Date,
        currentDate: Date,
        previousScore: Double,
        currentScore: Double,
        previousTotalAcne: Int,
        currentTotalAcne: Int,
        previousCountsByType: [AcneType: Int],
        currentCountsByType: [AcneType: Int],
        previousCountsByRegion: [FacialRegion: Int],
        currentCountsByRegion: [FacialRegion: Int]
    ) {
        self.id = id
        self.previousDate = previousDate
        self.currentDate = currentDate
        self.previousScore = previousScore
        self.currentScore = currentScore
        self.scoreDelta = currentScore - previousScore
        self.previousTotalAcne = previousTotalAcne
        self.currentTotalAcne = currentTotalAcne
        self.totalAcneDelta = currentTotalAcne - previousTotalAcne

        var typeDeltas: [AcneType: (previous: Int, current: Int, delta: Int)] = [:]
        for type in AcneType.allCases {
            let prev = previousCountsByType[type, default: 0]
            let curr = currentCountsByType[type, default: 0]
            typeDeltas[type] = (previous: prev, current: curr, delta: curr - prev)
        }
        self.countsByTypeDelta = typeDeltas

        var regionDeltas: [FacialRegion: (previous: Int, current: Int, delta: Int)] = [:]
        for region in FacialRegion.allCases {
            let prev = previousCountsByRegion[region, default: 0]
            let curr = currentCountsByRegion[region, default: 0]
            regionDeltas[region] = (previous: prev, current: curr, delta: curr - prev)
        }
        self.countsByRegionDelta = regionDeltas
    }

    /// Identifies the facial region that experienced the greatest reduction in acne count.
    public var mostImprovedRegion: (region: FacialRegion, decrease: Int, from: Int, to: Int)? {
        var best: (region: FacialRegion, decrease: Int, from: Int, to: Int)? = nil

        for (region, data) in countsByRegionDelta {
            let decrease = data.previous - data.current
            if decrease > 0 {
                if best == nil || decrease > best!.decrease {
                    best = (region: region, decrease: decrease, from: data.previous, to: data.current)
                }
            }
        }
        return best
    }

    /// Identifies the facial region that experienced the largest increase in acne count.
    public var mostIncreasedRegion: (region: FacialRegion, increase: Int, from: Int, to: Int)? {
        var highest: (region: FacialRegion, increase: Int, from: Int, to: Int)? = nil

        for (region, data) in countsByRegionDelta {
            let increase = data.current - data.previous
            if increase > 0 {
                if highest == nil || increase > highest!.increase {
                    highest = (region: region, increase: increase, from: data.previous, to: data.current)
                }
            }
        }
        return highest
    }
}
