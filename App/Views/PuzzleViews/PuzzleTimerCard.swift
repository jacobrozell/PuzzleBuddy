//
//  PuzzleTimerCard.swift
//  Puzzle Buddy
//

import SwiftUI

struct PuzzleTimerCard: View {
    @Binding var puzzle: Puzzle
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @State private var showResetConfirmation = false

    var body: some View {
        let isRunning = PuzzleTimerSemantics.isRunning(runningSince: puzzle.timerRunningSince, now: Date())

        GroupBox {
            TimelineView(.animation(minimumInterval: 1, paused: !isRunning)) { context in
                let elapsed = PuzzleTimerSemantics.elapsedSeconds(for: puzzle, now: context.date)

                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    Text(PuzzleTimerSemantics.clockLabel(seconds: elapsed))
                        .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .accessibilityHidden(true)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DS.Spacing.s3) {
                            toggleButton(isRunning: isRunning, elapsed: elapsed)
                            resetButton(elapsed: elapsed)
                        }
                        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                            toggleButton(isRunning: isRunning, elapsed: elapsed)
                            resetButton(elapsed: elapsed)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            Text("Timer")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .groupBoxStyle(BrandGroupBoxStyle())
        .accessibilityIdentifier(A11yID.puzzleDetailTimerCard)
        .accessibilityElement(children: .contain)
        .confirmationDialog(
            "Reset timer?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset timer", role: .destructive) {
                run(title: "Could not reset timer") { try ps.resetTimer(id: puzzle.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The timer goes back to 0:00:00. Time you already logged stays.")
        }
    }

    private func toggleButton(isRunning: Bool, elapsed: Int) -> some View {
        Button(isRunning ? "Pause timer" : "Start timer") {
            run(title: isRunning ? "Could not pause timer" : "Could not start timer") {
                if isRunning {
                    try ps.pauseTimer(id: puzzle.id)
                } else {
                    try ps.startTimer(id: puzzle.id)
                }
            }
        }
        .buttonStyle(BrandPrimaryButtonStyle())
        .frame(minHeight: 44)
        .accessibilityIdentifier(A11yID.puzzleDetailTimerToggleButton)
        .accessibilityValue("\(PuzzleTimerSemantics.spokenLabel(seconds: elapsed)), \(isRunning ? "running" : "paused")")
        .accessibilityHint(isRunning ? "Pauses the timer for this puzzle" : "Starts timing this puzzle. Any other running timer pauses.")
    }

    @ViewBuilder
    private func resetButton(elapsed: Int) -> some View {
        if elapsed > 0 {
            Button("Reset timer") {
                showResetConfirmation = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Brand.accentText)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityIdentifier(A11yID.puzzleDetailTimerResetButton)
            .accessibilityHint("Asks before clearing the timer. Logged time is not changed.")
        }
    }

    private func run(title: String, _ action: () throws -> Void) {
        do {
            try action()
            if let refreshed = ps.puzzles.first(where: { $0.id == puzzle.id }) {
                puzzle = refreshed
            }
        } catch {
            eh.handle(title: title, message: error.localizedDescription)
        }
    }
}
