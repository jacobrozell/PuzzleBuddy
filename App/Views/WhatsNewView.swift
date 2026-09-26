//
//  WhatsNewView.swift
//  Puzzle Buddy
//

import SwiftUI

struct WhatsNewView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s5) {
                    VStack(spacing: DS.Spacing.s3) {
                        PuzzleHeroView(size: 88)
                        Text(WhatsNewCopy.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .accessibilityAddTraits(.isHeader)
                        Text(WhatsNewCopy.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                        ForEach(WhatsNewCopy.items) { item in
                            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                                Image(systemName: item.symbolName)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Brand.accent)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(Brand.textPrimary)
                                    Text(item.message)
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }

                    Button(WhatsNewCopy.dismissTitle, action: onDismiss)
                        .buttonStyle(BrandPrimaryButtonStyle(expandHorizontally: true))
                        .accessibilityIdentifier(A11yID.whatsNewDismissButton)
                        .accessibilityHint("Closes the 1.1 update notes")
                }
                .padding(DS.Spacing.s5)
            }
            .readableBrandScreenChrome()
            .navigationTitle(WhatsNewCopy.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityIdentifier(A11yID.whatsNewSheet)
        .onAppear {
            AppLog.shared.info(.ui, eventName: "whats_new_shown", message: "Showed 1.1 What's New notes.")
        }
    }
}

#Preview {
    WhatsNewView(onDismiss: {})
}
