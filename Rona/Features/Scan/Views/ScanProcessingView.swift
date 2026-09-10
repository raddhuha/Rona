//
//  ScanProcessingView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Animated loading screen presented while the ML detection pipeline analyzes photos.
public struct ScanProcessingView: View {
    let statusText: String
    @State private var isPulsing: Bool = false

    public init(statusText: String = "Analyzing your skin...") {
        self.statusText = statusText
    }

    public var body: some View {
        VStack(spacing: 28) {
            ZStack {
                // Pulsing outer circle
                Circle()
                    .stroke(AppTheme.accentBlue.opacity(0.2), lineWidth: 4)
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.25 : 0.9)
                    .opacity(isPulsing ? 0.0 : 0.8)

                // Secondary ring
                Circle()
                    .stroke(AppTheme.accentBlue.opacity(0.4), lineWidth: 3)
                    .frame(width: 110, height: 110)
                    .scaleEffect(isPulsing ? 1.1 : 0.95)

                // Core icon container
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)

                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 34))
                    .foregroundColor(AppTheme.accentBlue)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }

            VStack(spacing: 8) {
                Text(statusText)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Our detection model is local and runs completely on your device.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}
