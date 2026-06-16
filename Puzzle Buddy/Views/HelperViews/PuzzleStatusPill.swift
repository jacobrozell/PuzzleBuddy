//
//  PuzzleStatusPill.swift
//  Puzzle Buddy
//

import SwiftUI

// MARK: - PuzzleStatusPill

struct PuzzleStatusPill: View {
    let status: Puzzle.Status

    var body: some View {
        Text(PuzzleDateSemantics.statusPillLabel(for: status))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DS.Spacing.s2)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }

    private var foregroundColor: Color {
        switch status {
        case .todo:
            return Brand.textSecondary
        case .inProgress:
            return Brand.textOnAccent
        case .completed:
            return Brand.accent
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .todo:
            return Brand.cardElevated
        case .inProgress:
            return Brand.accent
        case .completed:
            return Brand.accent.opacity(0.15)
        }
    }
}
