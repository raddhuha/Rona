//
//  PrimaryPillButton.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Pill-shaped action button styled according to the reference designs.
public struct PrimaryPillButton: View {
    public enum Style {
        case bordered
        case filled
        case destructive
    }

    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        style: Style = .bordered,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: style == .bordered ? 1.2 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .bordered:
            return AppTheme.textPrimary
        case .filled:
            return .white
        case .destructive:
            return AppTheme.accentDestructive
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .bordered:
            return .clear
        case .filled:
            return AppTheme.textPrimary
        case .destructive:
            return Color(red: 1.0, green: 0.94, blue: 0.94)
        }
    }

    private var borderColor: Color {
        switch style {
        case .bordered:
            return AppTheme.textPrimary
        case .filled, .destructive:
            return .clear
        }
    }
}
