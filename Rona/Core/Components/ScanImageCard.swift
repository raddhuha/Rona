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
    private let headerLabel: String?
    private let borderColor: Color?
    private let borderWidth: CGFloat
    private let isSelected: Bool
    private let isSelectionMode: Bool
    private let action: (() -> Void)?

    public init(
        image: UIImage? = nil,
        dateText: String,
        relativeDateText: String? = nil,
        headerLabel: String? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1.8,
        isSelected: Bool = false,
        isSelectionMode: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.image = image
        self.dateText = dateText
        self.relativeDateText = relativeDateText
        self.headerLabel = headerLabel
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

            // Dark gradient overlay for bottom text contrast (only when image is present)
            if image != nil {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }

            // Header label (e.g. "Latest Photo")
            if let headerLabel = headerLabel {
                Text(headerLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .padding(10)
            }

            // Selection indicator badge
            if isSelectionMode {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .background(isSelected ? AppTheme.accentBlue : Color.black.opacity(0.3))
                            .clipShape(Circle())

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(10)
                }
            }

            // Bottom Date and Relative Date Text (Left-aligned)
            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                if let relative = relativeDateText {
                    Text(relative)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(image != nil ? Color.white.opacity(0.85) : Color(uiColor: .secondaryLabel))
                }
                Text(dateText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(image != nil ? Color.white : AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 160)
        .aspectRatio(0.78, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? borderWidth : 0)
        )
    }
}
