//
//  CopyableDetailRow.swift
//  Puzzle Buddy
//

import SwiftUI

struct CopyableDetailRow: View {
    let label: String
    let value: String
    var copiedAnnouncement: String?
    var accessibilityIdentifier: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var didCopy = false

    var body: some View {
        Group {
            if usesStackedLayout {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text("\(label):")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                    valueRow
                }
            } else {
                HStack {
                    Text("\(label):")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                    Spacer()
                    valueRow
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
        .accessibilityHint("Double tap to copy")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            copyValue()
        }
        .optionalAccessibilityIdentifier(accessibilityIdentifier)
    }

    private var usesStackedLayout: Bool {
        AdaptiveLayout.usesStackedRowLayout(
            dynamicType: dynamicTypeSize,
            verticalSizeClass: verticalSizeClass
        )
    }

    private var valueRow: some View {
        HStack(spacing: DS.Spacing.s2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Brand.textPrimary)
                .textSelection(.enabled)

            Image(systemName: didCopy ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.caption)
                .foregroundStyle(didCopy ? Brand.accent : Brand.textSecondary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            copyValue()
        }
    }

    private func copyValue() {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.15)) {
            didCopy = true
        }
        let announcement = copiedAnnouncement ?? "\(label) copied"
        UIAccessibility.post(notification: .announcement, argument: announcement)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                didCopy = false
            }
        }
    }
}
