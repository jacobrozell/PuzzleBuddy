//
//  PuzzleCompletionHistorySection.swift
//  Puzzle Buddy
//

import SwiftUI

struct PuzzleCompletionHistorySection: View {
    @ObservedObject var ps: PuzzleStore
    @Binding var puzzle: Puzzle
    @EnvironmentObject var eh: ErrorHandling

    @State private var editingCompletion: PuzzleCompletion?
    @State private var pendingDelete: PuzzleCompletion?
    @State private var showStatusPrompt = false

    private var sortedCompletions: [PuzzleCompletion] {
        PuzzleCompletionSemantics.sortedNewestFirst(puzzle.completions)
    }

    var body: some View {
        GroupBox {
            if sortedCompletions.isEmpty {
                Text("No completion logs yet.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedCompletions.enumerated()), id: \.element.id) { index, completion in
                        if index > 0 {
                            Divider()
                        }
                        completionRow(completion)
                    }
                }
            }
        } label: {
            HStack {
                Text("Completion history")
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                if puzzle.timesCompleted > 0 {
                    Text("\(puzzle.timesCompleted)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.textOnAccent)
                        .padding(.horizontal, DS.Spacing.s2)
                        .padding(.vertical, 2)
                        .background(Brand.accent)
                        .clipShape(Capsule())
                }
            }
            .accessibilityAddTraits(.isHeader)
        }
        .groupBoxStyle(BrandGroupBoxStyle())
        .accessibilityIdentifier(A11yID.puzzleDetailCompletionHistory)
        .accessibilityElement(children: .contain)
        .sheet(item: $editingCompletion) { completion in
            CompletionEditSheet(
                completion: completion,
                onSave: { updated in
                    saveCompletion(updated)
                }
            )
        }
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: Binding(
                get: { pendingDelete != nil && !showStatusPrompt },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                confirmDelete()
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(deleteDialogMessage)
        }
        .confirmationDialog(
            "Set puzzle status",
            isPresented: $showStatusPrompt,
            titleVisibility: .visible
        ) {
            Button("In progress") {
                performDelete(revertingTo: .inProgress)
            }
            Button("To-Do") {
                performDelete(revertingTo: .todo)
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
                showStatusPrompt = false
            }
        } message: {
            Text("This was your only completion log. Choose a new status for the puzzle.")
        }
    }

    private var deleteDialogTitle: String {
        "Remove completion?"
    }

    private var deleteDialogMessage: String {
        guard let pendingDelete else { return "" }
        let date = pendingDelete.completedAt.formatted(date: .abbreviated, time: .omitted)
        if sortedCompletions.count == 1 {
            return "Remove the finish log from \(date)?"
        }
        return "Remove completion #\(pendingDelete.completionNumber) from \(date)? Other finishes stay in your history."
    }

    @ViewBuilder
    private func completionRow(_ completion: PuzzleCompletion) -> some View {
        Button {
            editingCompletion = completion
        } label: {
            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text("Completion \(completion.completionNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                    Text(completionSummary(completion))
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: DS.Spacing.s2)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
            }
            .padding(.vertical, DS.Spacing.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleDetailCompletionRow(number: completion.completionNumber))
        .accessibilityLabel(completionAccessibilityLabel(completion))
        .accessibilityHint("Opens editor for this completion log")
        .contextMenu {
            Button {
                editingCompletion = completion
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                pendingDelete = completion
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func completionSummary(_ completion: PuzzleCompletion) -> String {
        var parts = [completion.completedAt.formatted(date: .abbreviated, time: .omitted)]
        if let timeLabel = completion.timeSpentLabel {
            parts.append(timeLabel)
        }
        return parts.joined(separator: " · ")
    }

    private func completionAccessibilityLabel(_ completion: PuzzleCompletion) -> String {
        var label = "Completion \(completion.completionNumber), \(completion.completedAt.formatted(date: .abbreviated, time: .omitted))"
        if let timeLabel = completion.timeSpentLabel {
            label += ", \(timeLabel)"
        }
        return label
    }

    private func confirmDelete() {
        guard let pendingDelete else { return }

        let isLast = sortedCompletions.count == 1
        if isLast, puzzle.status == .completed {
            showStatusPrompt = true
            return
        }

        performDelete(revertingTo: nil)
    }

    private func performDelete(revertingTo status: Puzzle.Status?) {
        guard let completion = pendingDelete else { return }
        defer {
            pendingDelete = nil
            showStatusPrompt = false
        }

        do {
            try ps.deleteCompletion(
                puzzleID: puzzle.id,
                completionID: completion.id,
                statusIfRemovingLast: status
            )
            refreshPuzzleFromStore()
            BarcodeScanFeedback.scanAccepted()
        } catch {
            eh.handle(title: "Could not remove completion", message: error.localizedDescription)
        }
    }

    private func saveCompletion(_ updated: PuzzleCompletion) {
        do {
            try ps.updateCompletion(puzzleID: puzzle.id, completion: updated)
            refreshPuzzleFromStore()
            editingCompletion = nil
            BarcodeScanFeedback.scanAccepted()
        } catch {
            eh.handle(title: "Could not save completion", message: error.localizedDescription)
        }
    }

    private func refreshPuzzleFromStore() {
        if let refreshed = ps.puzzles.first(where: { $0.id == puzzle.id }) {
            puzzle = refreshed
        }
    }
}

private struct CompletionEditSheet: View {
    let completion: PuzzleCompletion
    let onSave: (PuzzleCompletion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var completedAt: Date
    @State private var hours: Int
    @State private var minutes: Int
    @State private var tracksTime: Bool

    init(completion: PuzzleCompletion, onSave: @escaping (PuzzleCompletion) -> Void) {
        self.completion = completion
        self.onSave = onSave
        _completedAt = State(initialValue: completion.completedAt)
        let h = completion.timeSpentHours ?? 0
        let m = completion.timeSpentMinutes ?? 0
        _hours = State(initialValue: h)
        _minutes = State(initialValue: m)
        _tracksTime = State(initialValue: h > 0 || m > 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Finished on",
                        selection: $completedAt,
                        displayedComponents: .date
                    )
                }

                Section {
                    Toggle("Log time spent", isOn: $tracksTime)
                    if tracksTime {
                        Stepper(value: $hours, in: 0...999) {
                            Text("\(hours) hr")
                        }
                        Stepper(value: $minutes, in: 0...59) {
                            Text("\(minutes) min")
                        }
                    }
                } footer: {
                    Text("Time spent is stored on this completion log only.")
                }
            }
            .navigationTitle("Edit completion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = completion
                        updated.completedAt = completedAt
                        if tracksTime {
                            updated.timeSpentHours = hours > 0 ? hours : nil
                            updated.timeSpentMinutes = minutes > 0 ? minutes : nil
                            if hours == 0 && minutes == 0 {
                                updated.timeSpentHours = nil
                                updated.timeSpentMinutes = nil
                            }
                        } else {
                            updated.timeSpentHours = nil
                            updated.timeSpentMinutes = nil
                        }
                        onSave(updated)
                        dismiss()
                    }
                    .accessibilityIdentifier(A11yID.puzzleDetailCompletionSaveButton)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
