//
//  PuzzleForm.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import Photos
import PhotosUI
import SwiftUI

class PuzzleFormViewModel: ObservableObject {
    @Published var puzzle: Puzzle
    @Published var image: UIImage = UIImage() {
        didSet {
            puzzle.image = image
        }
    }

    init() {
        self.puzzle = .fixture()
    }

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.image = puzzle.image ?? UIImage()
    }
}

// MARK: - PuzzleForm
struct PuzzleForm: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @Binding var isPresented: Bool

    @StateObject var formVm: PuzzleFormViewModel

    /// Detail Init
    init(puzzle: Puzzle, ps: PuzzleStore) {
        self._ps = ObservedObject(wrappedValue: ps)
        self._isPresented = .constant(false)
        self._formVm = StateObject(wrappedValue: PuzzleFormViewModel(puzzle: puzzle))
    }

    /// Normal Path Init
    init(isPresented: Binding<Bool>, ps: PuzzleStore) {
        self._ps = ObservedObject(wrappedValue: ps)
        self._isPresented = isPresented
        self._formVm = StateObject(wrappedValue: PuzzleFormViewModel())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PuzzleFormInternal(formVm: formVm)
                SubmitAddButton(ps: ps, formVm: formVm, isPresented: $isPresented)
            }
            .brandScreenChrome()
            .navigationTitle("Add Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Closes the add puzzle form without saving")
                }
            }
        }
    }
}

// MARK: - PuzzleFormInternal
struct PuzzleFormInternal: View {
    @ObservedObject var formVm: PuzzleFormViewModel

    var body: some View {
        Form {
            ImagePickerView(image: $formVm.image)
                .frame(maxWidth: .infinity, maxHeight: 300, alignment: .center)

            Section {
                TextField("Name", text: $formVm.puzzle.name, prompt: Text("Puzzle Name"))
                    .keyboardType(.namePhonePad)
                    .disableAutocorrection(true)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormNameField)
                    .accessibilityLabel("Puzzle name")

                PuzzlePiecesField(pieces: $formVm.puzzle.pieces)

                Picker("Status", selection: $formVm.puzzle.status) {
                    ForEach(Puzzle.Status.allCases) { status in
                        Text(status.rawValue)
                            .id(status)
                            .tag(status)
                    }
                }
                .accessibilityValue(formVm.puzzle.status.accessibilityDescription)
                .onChange(of: formVm.puzzle.status) { _, newStatus in
                    formVm.puzzle.progressPercent = PuzzleProgressSemantics.progress(
                        for: newStatus,
                        current: formVm.puzzle.progressPercent
                    )
                }
            } header: {
                Text("Puzzle Info")
            }

            Section {
                TextField(
                    "Source",
                    text: sourceBinding,
                    prompt: Text("Gift from Mom, Amazon, Goodwill…")
                )
                .optionalAccessibilityIdentifier(A11yID.puzzleFormSourceField)
                .accessibilityLabel("Where you got this puzzle")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s2) {
                        ForEach(PuzzleSourcePreset.allCases) { preset in
                            Button(preset.label) {
                                formVm.puzzle.source = preset.suggestedText
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityLabel("Set source to \(preset.label)")
                        }
                    }
                    .padding(.vertical, DS.Spacing.s2)
                }
            } header: {
                Text("Where did you get it?")
            } footer: {
                Text("Great for gifts from family — add a name after tapping a preset.")
            }

            Section {
                TextField(
                    "Barcode",
                    text: barcodeBinding,
                    prompt: Text("UPC / EAN from box")
                )
                .keyboardType(.numberPad)
                .optionalAccessibilityIdentifier(A11yID.puzzleFormBarcodeField)
                .accessibilityLabel("Barcode")
                .accessibilityHint("Optional UPC or EAN number from the puzzle box")
            } header: {
                Text("Barcode")
            } footer: {
                Text("Used to check for duplicates when shopping. Enter 6 to 14 digits.")
            }

            Section {
                PuzzleProgressSection(
                    progressPercent: $formVm.puzzle.progressPercent,
                    status: $formVm.puzzle.status
                )
            } header: {
                Text("Progress")
            } footer: {
                Text("Slide to track how far along you are, like Goodreads for puzzles.")
            }

            Section {
                LabeledContent("Rating") {
                    RatingsView(rating: $formVm.puzzle.rating)
                        .optionalAccessibilityIdentifier(A11yID.puzzleFormRatingControl)
                }

                Picker("Difficulty", selection: $formVm.puzzle.difficulty) {
                    ForEach(Puzzle.Difficulty.allCases) { difficulty in
                        Group {
                            if difficulty == .none {
                                Text("N/A")
                            } else {
                                Text("\(difficulty.rawValue)")
                            }
                        }
                        .id(difficulty)
                        .tag(difficulty)
                    }
                }
                .accessibilityValue(formVm.puzzle.difficulty.accessibilityDescription)
            } header: {
                Text("How did you like it?")
            }

            Section {
                TextField("Hours", value: Binding(
                    get: { formVm.puzzle.estimatedTimeSpent?.hours },
                    set: { new in
                        if formVm.puzzle.estimatedTimeSpent == nil {
                            formVm.puzzle.estimatedTimeSpent = Puzzle.PuzzleTime()
                        }
                        formVm.puzzle.estimatedTimeSpent?.hours = new
                    }
                ), format: .number, prompt: Text("0"))
                .keyboardType(.numberPad)
                .accessibilityLabel("Estimated hours spent")

                TextField("Minutes", value: Binding(
                    get: { formVm.puzzle.estimatedTimeSpent?.minutes },
                    set: { new in
                        if formVm.puzzle.estimatedTimeSpent == nil {
                            formVm.puzzle.estimatedTimeSpent = Puzzle.PuzzleTime()
                        }
                        formVm.puzzle.estimatedTimeSpent?.minutes = new
                    }
                ), format: .number, prompt: Text("0"))
                .keyboardType(.numberPad)
                .accessibilityLabel("Estimated minutes spent")
            } header: {
                Text("How long did it take?")
            }

            // Completion Section
            Section {
                DatePicker(
                    PuzzleDateSemantics.detailDateLabel(for: formVm.puzzle.status),
                    selection: $formVm.puzzle.completionDate
                )
                    .datePickerStyle(.graphical)
                    .accessibilityLabel(PuzzleDateSemantics.detailDateLabel(for: formVm.puzzle.status))
            } header: {
                Text(PuzzleDateSemantics.formDateSectionTitle(
                    for: formVm.puzzle.status,
                    puzzleName: formVm.puzzle.name
                ))
            }

            // Condition Section
            Section {
                Toggle("Missing pieces", isOn: $formVm.puzzle.hasMissingPieces)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormMissingPiecesToggle)
                    .accessibilityLabel("Missing pieces")
                    .accessibilityValue(formVm.puzzle.hasMissingPieces ? "On" : "Off")

                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text("Notes")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)

                    TextEditor(text: notesBinding)
                        .frame(minHeight: 88, maxHeight: 160)
                        .optionalAccessibilityIdentifier(A11yID.puzzleFormNotesField)
                        .accessibilityLabel("Notes")
                        .accessibilityHint("Optional notes about condition, missing pieces, or storage")
                }
            } header: {
                Text("Condition")
            }
        }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { formVm.puzzle.notes ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                formVm.puzzle.notes = trimmed.isEmpty ? nil : String(newValue.prefix(2_000))
            }
        )
    }

    private var sourceBinding: Binding<String> {
        Binding(
            get: { formVm.puzzle.source ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                formVm.puzzle.source = trimmed.isEmpty ? nil : String(trimmed.prefix(200))
            }
        )
    }

    private var barcodeBinding: Binding<String> {
        Binding(
            get: { formVm.puzzle.barcode ?? "" },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                formVm.puzzle.barcode = digits.isEmpty
                    ? nil
                    : String(digits.prefix(BarcodeNormalizer.maxLength))
            }
        )
    }
}

// MARK: - SubmitAddButton
struct SubmitAddButton: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var formVm: PuzzleFormViewModel
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            do {
                try ps.add(puzzle: formVm.puzzle)
                isPresented = false
            } catch {
                eh.handle(title: "Error Adding Puzzle!", message: "\(error.localizedDescription)")
            }
        } label: {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(BrandPrimaryButtonStyle())
        .optionalAccessibilityIdentifier(A11yID.puzzleFormSubmitButton)
        .accessibilityLabel("Save puzzle")
        .accessibilityHint(formVm.puzzle.name.isEmpty ? "Enter a puzzle name to enable saving" : "Saves this puzzle to your collection")
        .padding()
        .disabled(formVm.puzzle.name.isEmpty)
        .opacity(formVm.puzzle.name.isEmpty ? 0.6 : 1.0)
    }
}

// MARK: - Preview
struct PuzzleForm_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            PuzzleForm(isPresented: .constant(false), ps: PreviewSupport.puzzleStore)
        }
    }
}
