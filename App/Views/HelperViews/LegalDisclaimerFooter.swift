//
//  LegalDisclaimerFooter.swift
//  Puzzle Buddy
//

import SwiftUI

struct LegalDisclaimerFooter: View {
    enum Style {
        case settings
        case form
    }

    let text: String
    var style: Style = .settings
    var accessibilityIdentifier: String?

    var body: some View {
        Text(text)
            .font(style == .settings ? .footnote : .caption)
            .foregroundStyle(Brand.textSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .optionalAccessibilityIdentifier(accessibilityIdentifier)
    }
}
