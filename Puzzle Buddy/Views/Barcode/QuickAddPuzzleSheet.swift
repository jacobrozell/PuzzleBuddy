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

    private var hasSuggestedDetails: Bool {
        metadata?.suggestedName != nil || metadata?.brand != nil
    }

    private var sourcePuzzle: Puzzle? {
        guard let sourceID = metadata?.sourcePuzzleID else { return nil }
        return ps.puzzles.first { $0.id == sourceID }
    }

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
                if hasSuggestedDetails, let metadata {
                    Section {
                        if let label = metadata.lookupSourceLabel {
                            Label(label, systemImage: "internaldrive")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textSecondary)
                        }

                        if let sourcePuzzle {
                            HStack(spacing: DS.Spacing.s3) {
                                sourceThumbnail(for: sourcePuzzle)
                                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                                    Text(sourcePuzzle.name)
                                        .font(.subheadline.weight(.semibold))
                                    if let pieces = sourcePuzzle.pieces {
                                        Text("\(pieces) pieces")
                                            .font(.caption)
                                            .foregroundStyle(Brand.textSecondary)
                                    }
                                }
                            }
                        }

                        if let brand = metadata.brand {
                            LabeledContent("Brand", value: brand)
                        }
                        if let suggestedName = metadata.suggestedName {
                            LabeledContent("Suggested name", value: suggestedName)
                        }
                    } header: {
                        Text("Suggested details")
                    } footer: {
                        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                            LegalDisclaimerFooter(
                                text: LegalCopy.barcodeScanDisclaimer,
                                style: .form
                            )
                            if metadata.brand != nil {
                                LegalDisclaimerFooter(
                                    text: LegalCopy.brandTrademarkDisclaimer,
                                    style: .form
                                )
                            }
                        }
                    }
                } else {
                    Section {
                        Text("First time scanning this barcode. Enter the details below.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.textPrimary)
                        Text("Next time you scan it, Puzzle Buddy can suggest what you saved on this device.")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    } header: {
                        Text("New barcode")
                    } footer: {
                        LegalDisclaimerFooter(
                            text: LegalCopy.barcodeScanDisclaimer,
                            style: .form
                        )
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
                    .onChange(of: formVm.puzzle.status) { previousStatus, newStatus in
                        formVm.puzzle.noteStatusChanged(from: previousStatus, to: newStatus)
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

    @ViewBuilder
    private func sourceThumbnail(for puzzle: Puzzle) -> some View {
        Group {
            if let image = puzzle.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.body)
                    .foregroundStyle(Brand.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.cardElevated)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        .accessibilityHidden(true)
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
            try ps.add(puzzle: formVm.puzzle, source: .barcode)
            dismiss()
        } catch {
            isSaving = false
            eh.handle(title: "Could not save puzzle", message: error.localizedDescription)
        }
    }
}
