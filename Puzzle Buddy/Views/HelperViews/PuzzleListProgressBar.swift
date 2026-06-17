//
//  PuzzleListProgressBar.swift
//  Puzzle Buddy
//

import SwiftUI

/// Compact progress bar for puzzle list rows.
struct PuzzleListProgressBar: View {
    let progress: Int

    private var clamped: Int {
        PuzzleProgressSemantics.clamped(progress)
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Brand.cardElevated)

                    Capsule()
                        .fill(Brand.accent)
                        .frame(width: fillWidth(for: geometry.size.width))
                }
            }
            .frame(height: 6)

            Text("\(clamped)%")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .monospacedDigit()
                .frame(minWidth: 34, alignment: .trailing)
        }
        .accessibilityHidden(true)
        .optionalAccessibilityIdentifier(A11yID.puzzleCellProgress)
    }

    private func fillWidth(for totalWidth: CGFloat) -> CGFloat {
        guard clamped > 0 else { return 0 }
        return max(totalWidth * CGFloat(clamped) / 100, 6)
    }
}
