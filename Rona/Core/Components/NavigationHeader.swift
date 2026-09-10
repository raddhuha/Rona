//
//  NavigationHeader.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Standard navigation header with circular navigation button, centered title, and optional trailing button.
public struct NavigationHeader<TrailingContent: View>: View {
    public enum NavigationActionType {
        case back
        case close
        case none

        var iconName: String {
            switch self {
            case .back: return "chevron.left"
            case .close: return "xmark"
            case .none: return ""
            }
        }
    }

    private let title: String
    private let actionType: NavigationActionType
    private let onLeadingAction: (() -> Void)?
    private let trailingContent: TrailingContent

    public init(
        title: String,
        actionType: NavigationActionType = .back,
        onLeadingAction: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> TrailingContent
    ) {
        self.title = title
        self.actionType = actionType
        self.onLeadingAction = onLeadingAction
        self.trailingContent = trailing()
    }

    public var body: some View {
        HStack(alignment: .center) {
            if actionType != .none {
                Button(action: {
                    onLeadingAction?()
                }) {
                    Image(systemName: actionType.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(Circle())
                }
                .accessibilityLabel(actionType == .back ? "Back" : "Close")
            } else {
                Spacer().frame(width: 40)
            }

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            trailingContent
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

extension NavigationHeader where TrailingContent == EmptyView {
    public init(
        title: String,
        actionType: NavigationActionType = .back,
        onLeadingAction: (() -> Void)? = nil
    ) {
        self.init(title: title, actionType: actionType, onLeadingAction: onLeadingAction) {
            EmptyView()
        }
    }
}
