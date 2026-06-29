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

    init() {
        self.puzzle = .fixture()
    }

    init(puzzle: Puzzle) {
        var puzzle = puzzle
        if puzzle.photos.isEmpty, let image = puzzle.image {
            puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: image)]
        }
        self.puzzle = puzzle
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
                PuzzleFormInternal(formVm: formVm, allPuzzles: ps.puzzles)
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
    var allPuzzles: [Puzzle] = []
    @State private var showBarcodeScanner = false

    private var barcodeDuplicate: Puzzle? {
        PuzzleDuplicateChecker.findDuplicate(
            barcode: formVm.puzzle.barcode,
            excludingID: formVm.puzzle.id,
            in: allPuzzles
        )
    }

    var body: some View {
        Form {
            Section {
                PuzzlePhotoGalleryEditor(photos: $formVm.puzzle.photos)
            } header: {
                Text("Photos")
            } footer: {
                Text("Add up to \(PuzzlePhotoLimits.maxCount) photos — box art, progress, or finished puzzle. The first photo is the cover.")
            }

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
                .onChange(of: formVm.puzzle.status) { previousStatus, newStatus in
                    formVm.puzzle.noteStatusChanged(from: previousStatus, to: newStatus)
                }
            } header: {
                Text("Puzzle Info")
            }

            Section {
                TextField(
                    "Brand",
                    text: sourceBinding,
                    prompt: Text("Ravensburger, Galison, Buffalo Games…")
                )
                .optionalAccessibilityIdentifier(A11yID.puzzleFormSourceField)
                .accessibilityLabel("Puzzle brand or manufacturer")
            } header: {
                Text("Brand")
            }

            Section {
                TextField(
                    "Store or source",
                    text: purchaseLocationBinding,
                    prompt: Text("Amazon, Goodwill, puzzle swap…")
                )
                .optionalAccessibilityIdentifier(A11yID.puzzleFormPurchaseLocationField)
                .accessibilityLabel("Where you bought this puzzle")

                TextField(
                    "Purchase price",
                    text: purchasePriceBinding,
                    prompt: Text("Optional")
                )
                .keyboardType(.decimalPad)
                .accessibilityLabel("Purchase price")

                Picker("Release year", selection: releaseYearBinding) {
                    Text("Unknown").tag(Optional<Int>.none)
                    ForEach(releaseYearOptions, id: \.self) { year in
                        Text(String(year)).tag(Optional(year))
                    }
                }
                .accessibilityLabel("Release year")

                Picker("Puzzle type", selection: $formVm.puzzle.puzzleType) {
                    ForEach(PuzzleType.allCases) { type in
                        Text(type.displayLabel).tag(type)
                    }
                }
                .accessibilityValue(formVm.puzzle.puzzleType.accessibilityDescription)

                Picker("Material", selection: $formVm.puzzle.material) {
                    ForEach(PuzzleMaterial.allCases) { material in
                        Text(material.displayLabel).tag(material)
                    }
                }
                .accessibilityValue(formVm.puzzle.material.accessibilityDescription)

                Picker("Shape", selection: $formVm.puzzle.puzzleShape) {
                    ForEach(PuzzleShape.allCases) { shape in
                        Text(shape.displayLabel).tag(shape)
                    }
                }
                .accessibilityValue(formVm.puzzle.puzzleShape.accessibilityDescription)

                Picker("Cut type", selection: $formVm.puzzle.cutType) {
                    ForEach(PuzzleCutType.allCases) { cutType in
                        Text(cutType.displayLabel).tag(cutType)
                    }
                }
                .accessibilityValue(formVm.puzzle.cutType.accessibilityDescription)

                TextField(
                    "Dimensions",
                    text: dimensionsBinding,
                    prompt: Text("e.g. 68 × 49 cm")
                )
                .accessibilityLabel("Finished puzzle dimensions")
            } header: {
                Text("About this puzzle")
            }

            Section {
                PuzzleTagsField(
                    tags: $formVm.puzzle.tags,
                    catalog: PuzzleTagIndex.allTagNames(from: allPuzzles)
                )
            } header: {
                Text("Tags")
            } footer: {
                Text("Organize your collection with custom labels. Type to search existing tags or add a new one.")
            }

            Section {
                HStack(spacing: DS.Spacing.s2) {
                    TextField(
                        "Barcode",
                        text: barcodeBinding,
                        prompt: Text("UPC / EAN from box")
                    )
                    .keyboardType(.numberPad)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormBarcodeField)
                    .accessibilityLabel("Barcode")
                    .accessibilityHint("Optional UPC or EAN number from the puzzle box")

                    if ProductService.isBarcodeScanEnabled {
                        Button {
                            showBarcodeScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Scan barcode")
                        .accessibilityHint("Opens the camera to scan the puzzle box barcode")
                        .optionalAccessibilityIdentifier(A11yID.puzzleFormScanBarcodeButton)
                    }
                }

                if let duplicate = barcodeDuplicate {
                    Label {
                        Text("Matches \(duplicate.name) in your collection.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(Brand.accentWarm)
                    .accessibilityLabel("This barcode matches \(duplicate.name) in your collection")
                }
            } header: {
                Text("Barcode")
            } footer: {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text("Used to check for duplicates when shopping. Enter 6 to 14 digits, or scan from the box.")
                    LegalDisclaimerFooter(
                        text: LegalCopy.barcodeScanDisclaimer,
                        style: .form
                    )
                }
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
                HStack(alignment: .top, spacing: DS.Spacing.s4) {
                    timeComponentField(
                        title: "Hours",
                        unit: "hr",
                        value: timeHoursBinding,
                        accessibilityLabel: "Hours spent on puzzle"
                    )

                    timeComponentField(
                        title: "Minutes",
                        unit: "min",
                        value: timeMinutesBinding,
                        accessibilityLabel: "Minutes spent on puzzle"
                    )
                }

                if let preview = formVm.puzzle.estimatedTimeSpent?.displayLabel {
                    Label(preview, systemImage: "clock")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.accent)
                        .accessibilityLabel("Total time: \(preview)")
                }
            } header: {
                Text("How long did it take?")
            } footer: {
                Text("Optional. Enter hours and minutes separately — for example, 3 hr and 45 min. Minutes roll over at 60.")
            }

            // Completion Section
            Section {
                DatePicker(
                    PuzzleDateSemantics.detailDateLabel(for: formVm.puzzle.status),
                    selection: $formVm.puzzle.completionDate,
                    displayedComponents: .date
                )
                    .datePickerStyle(.graphical)
                    .accessibilityLabel(PuzzleDateSemantics.detailDateLabel(for: formVm.puzzle.status))
            } header: {
                Text(PuzzleDateSemantics.formDateSectionTitle(
                    for: formVm.puzzle.status,
                    puzzleName: formVm.puzzle.name
                ))
            }

            if PuzzleDateSemantics.showsStartDatePicker(for: formVm.puzzle.status) {
                Section {
                    DatePicker(
                        "Started on",
                        selection: startDateBinding,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormStartDateField)
                    .accessibilityLabel("Started on")
                } footer: {
                    Text("Used for days puzzling on the detail screen.")
                }
            }

            if formVm.puzzle.status == .completed {
                Section {
                    Picker("After finishing", selection: $formVm.puzzle.disposition) {
                        ForEach(PuzzleDisposition.allCases) { disposition in
                            Text(disposition.displayLabel).tag(disposition)
                        }
                    }
                    .accessibilityLabel("What happened to this puzzle after finishing")
                    .accessibilityValue(formVm.puzzle.disposition.accessibilityDescription)
                } header: {
                    Text("After finishing")
                }
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
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerSheet { raw in
                if let normalized = BarcodeNormalizer.normalize(raw) {
                    formVm.puzzle.barcode = normalized
                } else {
                    let digits = raw.filter(\.isNumber)
                    formVm.puzzle.barcode = digits.isEmpty ? nil : digits
                }
            }
        }
    }

    private var timeHoursBinding: Binding<Int?> {
        Binding(
            get: { formVm.puzzle.estimatedTimeSpent?.hours },
            set: { new in
                if formVm.puzzle.estimatedTimeSpent == nil {
                    formVm.puzzle.estimatedTimeSpent = Puzzle.PuzzleTime()
                }
                formVm.puzzle.estimatedTimeSpent?.hours = new.map { max($0, 0) }
            }
        )
    }

    private var timeMinutesBinding: Binding<Int?> {
        Binding(
            get: { formVm.puzzle.estimatedTimeSpent?.minutes },
            set: { new in
                if formVm.puzzle.estimatedTimeSpent == nil {
                    formVm.puzzle.estimatedTimeSpent = Puzzle.PuzzleTime()
                }
                formVm.puzzle.estimatedTimeSpent?.minutes = new.map { max($0, 0) }
                formVm.puzzle.estimatedTimeSpent?.normalizeComponents()
            }
        )
    }

    @ViewBuilder
    private func timeComponentField(
        title: String,
        unit: String,
        value: Binding<Int?>,
        accessibilityLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Brand.textSecondary)

            HStack(spacing: DS.Spacing.s2) {
                TextField("0", value: value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel(accessibilityLabel)

                Text(unit)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        }
        .frame(maxWidth: .infinity)
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

    private var releaseYearOptions: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return (0..<40).map { current - $0 }
    }

    private var releaseYearBinding: Binding<Int?> {
        Binding(
            get: { formVm.puzzle.releaseYear },
            set: { formVm.puzzle.releaseYear = $0 }
        )
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { formVm.puzzle.startDate ?? formVm.puzzle.completionDate },
            set: { formVm.puzzle.startDate = $0 }
        )
    }

    private var purchaseLocationBinding: Binding<String> {
        Binding(
            get: { formVm.puzzle.purchaseLocation ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                formVm.puzzle.purchaseLocation = trimmed.isEmpty ? nil : String(trimmed.prefix(200))
            }
        )
    }

    private var purchasePriceBinding: Binding<String> {
        Binding(
            get: {
                guard let price = formVm.puzzle.purchasePrice else { return "" }
                return String(format: "%.2f", price)
            },
            set: { newValue in
                formVm.puzzle.purchasePrice = PurchasePriceFormatting.parse(newValue)
            }
        )
    }

    private var dimensionsBinding: Binding<String> {
        Binding(
            get: { formVm.puzzle.dimensionsText ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                formVm.puzzle.dimensionsText = trimmed.isEmpty ? nil : String(trimmed.prefix(80))
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
