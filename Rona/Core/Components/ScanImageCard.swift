//
//  ScanImageCard.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Rounded card displaying a facial scan photo thumbnail with a date stamp and optional colored border.
public struct ScanImageCard: View {
    private let image: UIImage?
    private let dateText: String
    private let relativeDateText: String?
    private let borderColor: Color?
    private let borderWidth: CGFloat
    private let isSelected: Bool
    private let isSelectionMode: Bool
    private let action: (() -> Void)?

    public init(
        image: UIImage? = nil,
        dateText: String,
        relativeDateText: String? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1.8,
        isSelected: Bool = false,
        isSelectionMode: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.image = image
        self.dateText = dateText
        self.relativeDateText = relativeDateText
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.isSelected = isSelected
        self.isSelectionMode = isSelectionMode
        self.action = action
    }

    public var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        ZStack(alignment: .topLeading) {
            // Photo or placeholder background
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(uiColor: .systemGray6))
            }

            // Selection indicator badge matching designer mockup
            if isSelectionMode {
                HStack {
                    Spacer()
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(AppTheme.textPrimary)
                                .frame(width: 20, height: 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .stroke(Color(uiColor: .systemGray3), lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                                .background(Color.white.opacity(0.3).clipShape(Circle()))
                        }
                    }
                    .padding(8)
                }
            }

            // Bottom Date and Relative Date Text (Left-aligned)
            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                if let relative = relativeDateText {
                    Text(relative)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                Text(dateText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .aspectRatio(0.74, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? borderWidth : 0)
        )
    }
}

#Preview {
    ScanImageCard(
        dateText: "13 Aug 2026",
        relativeDateText: "(6 days ago)"
    )
    .frame(width: 170)
    .padding()
}
