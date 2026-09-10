//
//  NavigationRowCard.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Pill-shaped navigation row card for sections like "Show All Data" and "Show Report".
public struct NavigationRowCard: View {
    private let title: String
    private let action: (() -> Void)?

    public init(title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        if let action = action {
            Button(action: action) {
                cardContent
            }
            .buttonStyle(.plain)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .contentShape(Capsule())
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
}
