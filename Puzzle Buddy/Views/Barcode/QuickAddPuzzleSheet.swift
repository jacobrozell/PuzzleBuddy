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
    let lookupNotice: String?

    @StateObject private var formVm = PuzzleFormViewModel()
    @State private var isSaving = false

    private var similarMatches: [Puzzle] {
        PuzzleSimilarMatchFinder.findSimilar(
            name: formVm.puzzle.name,
            source: formVm.puzzle.source,
            pieces: formVm.puzzle.pieces,
            barcode: barcode,
            excludingID: nil,
            in: ps.puzzles
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let lookupNotice {
                    Section {
                        Label(lookupNotice, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.accentWarm)
                            .accessibilityIdentifier(A11yID.quickAddLookupNotice)
                    }
                }

                if let metadata, metadata.suggestedName != nil || metadata.brand != nil || metadata.lookupSourceLabel != nil {
                    Section {
                        if let label = metadata.lookupSourceLabel {
                            Label(label, systemImage: metadata.source == "local_cache" ? "internaldrive" : "globe")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        if let brand = metadata.brand {
                            LabeledContent("Brand", value: brand)
                        }
                        if let suggestedName = metadata.suggestedName {
                            LabeledContent("Suggested name", value: suggestedName)
                        }
                        if metadata.suggestedName == nil, metadata.brand == nil {
                            Text("No product details found for this barcode. Enter a name below.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    } header: {
                        Text("Suggested details")
                    } footer: {
                        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                            Text("Confirm everything before saving — especially piece count and title.")
                            if metadata.brand != nil {
                                LegalDisclaimerFooter(
                                    text: LegalCopy.brandTrademarkDisclaimer,
                                    style: .form
                                )
                            }
                        }
                    }
                }

                if !similarMatches.isEmpty {
                    Section {
                        ForEach(similarMatches, id: \.id) { puzzle in
                            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                                Text(puzzle.name)
                                    .font(.subheadline.weight(.semibold))
                                if let pieces = puzzle.pieces {
                                    Text("\(pieces) pieces")
                                        .font(.caption)
                                        .foregroundStyle(Brand.textSecondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(similarMatchAccessibilityLabel(for: puzzle))
                        }
                    } header: {
                        Text("Looks similar")
                    } footer: {
                        Text("You may already own a puzzle with a matching name, brand, or piece count.")
                    }
                    .accessibilityIdentifier(A11yID.quickAddSimilarSection)
                }

                Section {
                    TextField("Name", text: $formVm.puzzle.name, prompt: Text("Puzzle Name"))
                        .optionalAccessibilityIdentifier(A11yID.puzzleFormNameField)
                        .accessibilityLabel("Puzzle name")

                    PuzzlePiecesField(pieces: $formVm.puzzle.pieces)

                    Picker("Status", selection: $formVm.puzzle.status) {
                        ForEach(Puzzle.Status.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .accessibilityLabel("Status")
                    .onChange(of: formVm.puzzle.status) { _, newStatus in
                        formVm.puzzle.progressPercent = PuzzleProgressSemantics.progress(
                            for: newStatus,
                            current: formVm.puzzle.progressPercent
                        )
                    }

                    LabeledContent("Barcode", value: barcode)
                        .accessibilityLabel("Barcode, \(barcode)")
                } header: {
                    Text("Quick add")
                }
            }
            .adaptiveScrollChrome()
            .navigationTitle("Add from scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel quick add")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePuzzle()
                    }
                    .disabled(formVm.puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .optionalAccessibilityIdentifier(A11yID.quickAddSaveButton)
                    .accessibilityLabel("Save puzzle")
                    .accessibilityHint("Adds this puzzle to your collection")
                }
            }
            .optionalAccessibilityIdentifier(A11yID.quickAddPuzzleSheet)
            .accessibilityElement(children: .contain)
            .onAppear {
                applyScannedValues()
            }
        }
    }

    private func similarMatchAccessibilityLabel(for puzzle: Puzzle) -> String {
        var parts = ["Looks similar", puzzle.name]
        if let pieces = puzzle.pieces {
            parts.append("\(pieces) pieces")
        }
        if let source = puzzle.source, !source.isEmpty {
            parts.append(source)
        }
        return parts.joined(separator: ", ")
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
