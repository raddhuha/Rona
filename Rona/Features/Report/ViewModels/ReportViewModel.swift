//
//  ReportViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// ViewModel managing period filters, date range navigation, and chart series for the progress report.
@MainActor
public final class ReportViewModel: ObservableObject {
    @Published public var selectedPeriod: TimePeriod = .month
    @Published public var chartMode: SkinProgressChart.Mode = .skinScore
    @Published public var rangeOffset: Int = 0
    @Published public var dateRangeLabel: String = ""
    @Published public var progressPoints: [ProgressPoint] = []
    @Published public var insight: SkinInsight = SkinInsight.initialPlaceholder
    @Published public var comparisonPair: (ScanRecord, ScanRecord)? = nil

    private let scanRepository: ScanRepositoryProtocol
    private let insightGenerator: InsightGenerating

    private let dayTickFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private let monthTickFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    public init(scanRepository: ScanRepositoryProtocol, insightGenerator: InsightGenerating) {
        self.scanRepository = scanRepository
        self.insightGenerator = insightGenerator
    }

    public func loadData() async {
        do {
            let all = try await scanRepository.fetchAll()
            computePeriodData(allRecords: all)
        } catch {
            print("Failed to load report data: \(error)")
        }
    }

    public func previousPeriod() {
        rangeOffset -= 1
        Task { await loadData() }
    }

    public func nextPeriod() {
        if rangeOffset < 0 {
            rangeOffset += 1
            Task { await loadData() }
        }
    }

    private func computePeriodData(allRecords: [ScanRecord]) {
        let calendar = Calendar.current
        let now = Date()

        let (startDate, endDate) = calculateDateInterval(for: selectedPeriod, offset: rangeOffset, baseDate: now, calendar: calendar)

        // Format date range label: e.g. "20 Jul 2026 - 19 Aug 2026"
        let startStr = CalendarDayHelper.formatDisplayDate(startDate)
        let endStr = CalendarDayHelper.formatDisplayDate(endDate)
        dateRangeLabel = "\(startStr) - \(endStr)"

        // Filter records within range
        let filtered = allRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date < $1.date }

        progressPoints = filtered.map { record in
            let label: String
            switch selectedPeriod {
            case .week, .month:
                label = dayTickFormatter.string(from: record.date)
            case .year:
                label = monthTickFormatter.string(from: record.date)
            }

            return ProgressPoint(
                dayId: record.calendarDayId,
                date: record.date,
                label: label,
                skinScore: record.skinScore,
                totalAcneCount: record.totalAcneCount,
                countsByType: record.countsByType
            )
        }

        // Generate insight between earliest and latest in this period
        if filtered.count >= 2, let first = filtered.first, let last = filtered.last {
            comparisonPair = (first, last)
            let comp = ScanComparison(
                previousDate: first.date,
                currentDate: last.date,
                previousScore: first.skinScore,
                currentScore: last.skinScore,
                previousTotalAcne: first.totalAcneCount,
                currentTotalAcne: last.totalAcneCount,
                previousCountsByType: first.countsByType,
                currentCountsByType: last.countsByType,
                previousCountsByRegion: first.countsByRegion,
                currentCountsByRegion: last.countsByRegion
            )
            insight = insightGenerator.generateInsight(comparison: comp)
        } else if let only = filtered.first {
            comparisonPair = nil
            insight = insightGenerator.generateInitialInsight(
                for: only.date,
                skinScore: only.skinScore,
                acneCount: only.totalAcneCount
            )
        } else {
            comparisonPair = nil
            insight = SkinInsight(
                title: "No Data in Range",
                body: "No skin scans recorded for this time range. Try navigating to an earlier period or taking a scan today."
            )
        }
    }

    private func calculateDateInterval(for period: TimePeriod, offset: Int, baseDate: Date, calendar: Calendar) -> (Date, Date) {
        let referenceDate: Date
        switch period {
        case .week:
            referenceDate = calendar.date(byAdding: .weekOfYear, value: offset, to: baseDate) ?? baseDate
            let start = calendar.date(byAdding: .day, value: -6, to: referenceDate) ?? referenceDate
            return (calendar.startOfDay(for: start), referenceDate)
        case .month:
            referenceDate = calendar.date(byAdding: .month, value: offset, to: baseDate) ?? baseDate
            let start = calendar.date(byAdding: .day, value: -29, to: referenceDate) ?? referenceDate
            return (calendar.startOfDay(for: start), referenceDate)
        case .year:
            referenceDate = calendar.date(byAdding: .year, value: offset, to: baseDate) ?? baseDate
            let start = calendar.date(byAdding: .year, value: -1, to: referenceDate) ?? referenceDate
            return (calendar.startOfDay(for: start), referenceDate)
        }
    }
}
