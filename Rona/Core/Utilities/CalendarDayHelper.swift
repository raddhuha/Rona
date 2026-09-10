//
//  CalendarDayHelper.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import Foundation

/// Utility helper for standardizing calendar dates and day identifiers.
public enum CalendarDayHelper {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let fullDisplayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Produces a unique calendar day identifier (e.g., "2026-08-13") for a date.
    public static func calendarDayId(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let startOfDay = calendar.startOfDay(for: date)
        return dayFormatter.string(from: startOfDay)
    }

    /// Returns the start of the calendar day for a given date.
    public static func startOfDay(for date: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Formats a date in "13 Aug 2026" style as seen in reference screenshots.
    public static func formatDisplayDate(_ date: Date) -> String {
        displayDateFormatter.string(from: date)
    }

    /// Formats a date in "13 August 2026" style for detailed views.
    public static func formatFullDisplayDate(_ date: Date) -> String {
        fullDisplayDateFormatter.string(from: date)
    }

    /// Parses a calendarDayId back to Date if needed.
    public static func date(fromDayId dayId: String) -> Date? {
        dayFormatter.date(from: dayId)
    }
}
