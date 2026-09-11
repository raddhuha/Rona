//
//  AppDesignSystem.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Design tokens matching the clean, calm, Apple-native visual design.
public enum AppTheme {
    // MARK: - Colors

    public static let background = Color.white
    public static let cardBackground = Color(red: 0.965, green: 0.968, blue: 0.975)
    public static let pillBackground = Color.white
    public static let borderSubtle = Color(red: 0.90, green: 0.91, blue: 0.93)

    public static let textPrimary = Color(red: 0.08, green: 0.08, blue: 0.10)
    public static let textSecondary = Color(red: 0.48, green: 0.50, blue: 0.55)
    public static let textMuted = Color(red: 0.65, green: 0.67, blue: 0.72)

    // Visual Accent Colors (from reference screenshots)
    public static let primary = Color(red: 0.23, green: 0.48, blue: 0.96)
    public static let accentBlue = primary
    public static let accentPink = Color(red: 0.98, green: 0.22, blue: 0.65)
    public static let accentGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    public static let accentDestructive = Color(red: 0.92, green: 0.24, blue: 0.24)
    public static let accentRed = accentDestructive

    // MARK: - Dimensions & Radii

    public static let cardCornerRadius: CGFloat = 18.0
    public static let pillCornerRadius: CGFloat = 28.0
    public static let buttonCornerRadius: CGFloat = 24.0

    // MARK: - Typography Presets

    public static let largeTitleFont: Font = .system(size: 34, weight: .bold, design: .default)
    public static let sectionTitleFont: Font = .system(size: 24, weight: .bold, design: .default)
    public static let cardTitleFont: Font = .system(size: 17, weight: .semibold, design: .default)
    public static let bodyFont: Font = .system(size: 15, weight: .regular, design: .default)
    public static let captionFont: Font = .system(size: 13, weight: .medium, design: .default)
    public static let footnoteFont: Font = .system(size: 12, weight: .regular, design: .default)
}
