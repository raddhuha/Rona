//
//  InsightCardView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Rounded card displaying calm, supportive insights with an SF Symbol icon.
public struct InsightCardView: View {
    private let title: String
    private let bodyHeadline: String
    private let bodyDetail: String
    private let iconName: String
    private let showDataAction: (() -> Void)?

    public init(
        title: String = "Comparison Insight",
        bodyHeadline: String,
        bodyDetail: String,
        iconName: String = "lightbulb.fill",
        showDataAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.bodyHeadline = bodyHeadline
        self.bodyDetail = bodyDetail
        self.iconName = iconName
        self.showDataAction = showDataAction
    }

    public init(insight: SkinInsight, title: String = "Comparison Insight", showDataAction: (() -> Void)? = nil) {
        self.title = title
        self.bodyHeadline = insight.title
        self.bodyDetail = insight.body
        self.iconName = insight.leadingIconName
        self.showDataAction = showDataAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.textPrimary)

                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bodyHeadline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(bodyDetail)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let showDataAction = showDataAction {
                Button(action: showDataAction) {
                    Text("Show data")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
}

#Preview {
    InsightCardView(
        insight: SkinInsight(
            title: "Your forehead improved the most",
            body: "Acne detected on your forehead decreased from 6 to 3."
        )
    )
    .padding()
}
