//
//  QuickAddPuzzleSheet.swift
//  Puzzle Buddy
//

import SwiftUI

struct QuickAddPuzzleSheet: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @Environment(\.dismiss) private var dismiss

    let barcode: String
    let metadata: BarcodeProductMetadata?

    @StateObject private var formVm = PuzzleFormViewModel()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                if let metadata, metadata.suggestedName != nil || metadata.brand != nil {
                    Section {
                        if let brand = metadata.brand {
                            LabeledContent("Brand", value: brand)
                        }
                        if metadata.suggestedName == nil {
                            Text("No product title found for this barcode. Enter a name below.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    } header: {
                        Text("From barcode lookup")
                    } footer: {
                        Text("Product databases don't always know puzzles. Confirm the details before saving.")
                    }
                }

                Section {
                    TextField("Name", text: $formVm.puzzle.name, prompt: Text("Puzzle Name"))
                        .optionalAccessibilityIdentifier(A11yID.puzzleFormNameField)

                    PuzzlePiecesField(pieces: $formVm.puzzle.pieces)

                    Picker("Status", selection: $formVm.puzzle.status) {
                        ForEach(Puzzle.Status.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .onChange(of: formVm.puzzle.status) { _, newStatus in
                        formVm.puzzle.progressPercent = PuzzleProgressSemantics.progress(
                            for: newStatus,
                            current: formVm.puzzle.progressPercent
                        )
                    }

                    LabeledContent("Barcode", value: barcode)
                } header: {
                    Text("Quick add")
                }
            }
            .navigationTitle("Add from scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePuzzle()
                    }
                    .disabled(formVm.puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .optionalAccessibilityIdentifier(A11yID.quickAddPuzzleSheet)
            .onAppear {
                applyScannedValues()
            }
        }
    }

    private func applyScannedValues() {
        formVm.puzzle.barcode = barcode
        if let metadata {
            if let name = metadata.suggestedName {
                formVm.puzzle.name = name
            }
            if let pieces = metadata.suggestedPieces {
                formVm.puzzle.pieces = pieces
            }
            if formVm.puzzle.source == nil, let brand = metadata.brand {
                formVm.puzzle.source = brand
            }
        }
    }

    private func savePuzzle() {
        isSaving = true
        do {
            try ps.add(puzzle: formVm.puzzle)
            dismiss()
        } catch {
            isSaving = false
            eh.handle(title: "Could not save puzzle", message: error.localizedDescription)
        }
    }
}
