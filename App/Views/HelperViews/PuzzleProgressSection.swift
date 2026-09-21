//
//  PuzzleProgressSection.swift
//  Puzzle Buddy
//

import SwiftUI

struct PuzzleProgressSection: View {
    @Binding var progressPercent: Int
    @Binding var status: Puzzle.Status
    var onCommit: (() -> Void)?
    var onPuzzleAgain: (() -> Void)?
    var onMarkReturned: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDraggingSlider = false

    private var clampedProgress: Int {
        PuzzleProgressSemantics.clamped(progressPercent)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            ZStack {
                PuzzleProgressRing(progress: clampedProgress)
                    .frame(width: 148, height: 148)
                    .accessibilityHidden(true)

                VStack(spacing: DS.Spacing.s2) {
                    Text("\(clampedProgress)%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                        .contentTransition(.numericText(value: Double(clampedProgress)))
                        .animation(labelAnimation, value: clampedProgress)
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .contentTransition(.opacity)
                        .animation(labelAnimation, value: status)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Progress, \(clampedProgress) percent, \(statusLabel)")
            }
            .frame(maxWidth: .infinity)

            Slider(
                value: Binding(
                    get: { Double(clampedProgress) },
                    set: { newValue in
                        applyProgress(Int(newValue.rounded()), commit: false)
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
            } onEditingChanged: { editing in
                isDraggingSlider = editing
                if !editing {
                    onCommit?()
                }
            }
            // Do not put .animation on Slider ancestors — it fights the thumb and can block 0%/100%.
            .tint(Brand.accent)
            .optionalAccessibilityIdentifier(A11yID.puzzleDetailProgressSlider)
            .accessibilityValue(PuzzleProgressSemantics.displayLabel(for: clampedProgress))

            Text(PuzzleProgressSemantics.displayLabel(for: clampedProgress))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentTransition(.numericText(value: Double(clampedProgress)))
                .animation(labelAnimation, value: clampedProgress)

            if status == .completed, let onPuzzleAgain {
                Button("Puzzle again") {
                    onPuzzleAgain()
                }
                .buttonStyle(BrandSecondaryButtonStyle(expandHorizontally: true))
                .optionalAccessibilityIdentifier(A11yID.puzzleDetailRedoButton)
                .accessibilityHint("Starts a new attempt and keeps your completion history")
            }

            if let onMarkReturned {
                Button("Mark returned") {
                    onMarkReturned()
                }
                .buttonStyle(BrandSecondaryButtonStyle(expandHorizontally: true))
                .optionalAccessibilityIdentifier(A11yID.puzzleDetailMarkReturnedButton)
                .accessibilityHint("Clears on-loan status for this puzzle")
            }
        }
        .padding(.vertical, DS.Spacing.s2)
    }

    private var labelAnimation: Animation? {
        if isDraggingSlider { return nil }
        return reduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.42, dampingFraction: 0.82)
    }

    private var statusLabel: String {
        switch status {
        case .wishlist:
            return "On wishlist"
        case .todo:
            return "Not started"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .abandoned:
            return "Abandoned, will not finish"
        }
    }

    private func applyProgress(_ value: Int, commit: Bool) {
        let clamped = PuzzleProgressSemantics.clamped(value)
        // Update bindings without an animation transaction so Slider can settle on 0 / 100.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            progressPercent = clamped
            status = PuzzleProgressSemantics.status(for: clamped)
        }
        if commit {
            onCommit?()
        }
    }
}

/// Trimmed-circle ring — animates via local state only (never animates the Slider binding).
private struct PuzzleProgressRing: View {
    let progress: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedFraction: CGFloat = 0
    @State private var didAnimateIn = false

    private var targetFraction: CGFloat {
        CGFloat(PuzzleProgressSemantics.clamped(progress)) / 100
    }

    private let lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.cardElevated, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: max(displayedFraction, 0.0001))
                .stroke(
                    Brand.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                // Hide residual round-cap “dot” at true zero.
                .opacity(displayedFraction > 0.001 ? 1 : 0)
        }
        .padding(lineWidth / 2)
        .onAppear {
            animateToTarget(preferIntro: !didAnimateIn)
            didAnimateIn = true
        }
        .onChange(of: progress) { _, _ in
            animateToTarget(preferIntro: false)
        }
    }

    private func animateToTarget(preferIntro: Bool) {
        let next = targetFraction
        if reduceMotion {
            displayedFraction = next
            return
        }
        if preferIntro, next > 0, abs(displayedFraction - next) > 0.001 {
            displayedFraction = 0
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                displayedFraction = next
            }
            return
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            displayedFraction = next
        }
    }
}
