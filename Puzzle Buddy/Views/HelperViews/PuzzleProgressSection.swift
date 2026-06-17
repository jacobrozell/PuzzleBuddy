//
//  PuzzleProgressSection.swift
//  Puzzle Buddy
//

import Charts
import SwiftUI

struct PuzzleProgressSection: View {
    @Binding var progressPercent: Int
    @Binding var status: Puzzle.Status
    var onCommit: (() -> Void)?

    private var clampedProgress: Int {
        PuzzleProgressSemantics.clamped(progressPercent)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            ZStack {
                PuzzleProgressChart(progress: clampedProgress)
                    .frame(width: 148, height: 148)
                    .accessibilityHidden(true)

                VStack(spacing: DS.Spacing.s2) {
                    Text("\(clampedProgress)%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Progress, \(clampedProgress) percent, \(statusLabel)")
            }
            .frame(maxWidth: .infinity)

            Slider(
                value: Binding(
                    get: { Double(clampedProgress) },
                    set: { newValue in
                        applyProgress(Int(newValue.rounded()))
                    }
                ),
                in: 0...100,
                step: 5
            ) {
                Text("Progress")
            } minimumValueLabel: {
                Text("0%")
            } maximumValueLabel: {
                Text("100%")
            }
            .optionalAccessibilityIdentifier(A11yID.puzzleDetailProgressSlider)
            .accessibilityValue(PuzzleProgressSemantics.displayLabel(for: clampedProgress))

            Text(PuzzleProgressSemantics.displayLabel(for: clampedProgress))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, DS.Spacing.s2)
    }

    private var statusLabel: String {
        switch status {
        case .wishlist:
            return "Wishlist"
        case .todo:
            return "Not started"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        }
    }

    private func applyProgress(_ value: Int) {
        let clamped = PuzzleProgressSemantics.clamped(value)
        progressPercent = clamped
        status = PuzzleProgressSemantics.status(for: clamped)
        onCommit?()
    }
}

private struct PuzzleProgressChart: View {
    let progress: Int

    private struct Slice: Identifiable {
        let id: String
        let value: Double
        let style: AnyShapeStyle
    }

    private var slices: [Slice] {
        let complete = Double(progress)
        let remaining = Double(100 - progress)
        return [
            Slice(id: "complete", value: complete, style: AnyShapeStyle(Brand.accent)),
            Slice(id: "remaining", value: remaining, style: AnyShapeStyle(Brand.cardElevated))
        ]
    }

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Amount", slice.value),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .foregroundStyle(slice.style)
        }
        .chartLegend(.hidden)
    }
}
