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
                VStack {
                    HStack {
                        Text("Name:")

                        Spacer()

                        TextField("Name", text: $formVm.puzzle.name, prompt: Text("Puzzle Name"))
                            .keyboardType(.namePhonePad)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                            .optionalAccessibilityIdentifier(A11yID.puzzleFormNameField)
                            .accessibilityLabel("Puzzle name")
                    }

                    Divider()

                    HStack {
                        Text("Pieces:")

                        Spacer()

                        TextField("Pieces", value: $formVm.puzzle.pieces, format: .number, prompt: Text("# of Pieces"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .optionalAccessibilityIdentifier(A11yID.puzzleFormPiecesField)
                            .accessibilityLabel("Number of pieces")
                    }

                    Divider()

                    HStack {
                        Text("Status:")

                        Spacer()

                        Picker("Status", selection: $formVm.puzzle.status) {
                            ForEach(Puzzle.Status.allCases) { status in
                                Text(status.rawValue)
                                    .id(status)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Puzzle status")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } header: {
                Text("Puzzle Info")
                    .frame(alignment: .leading)
            }

            // Rating Section
            Section {
                HStack {
                    Text("Rating:")

                    Spacer()

                    // TODO: Editable RatingsView
                    Picker("Rating", selection: $formVm.puzzle.rating) {
                        ForEach(Puzzle.Rating.allCases) { rating in
                            Group {
                                if rating == .none {
                                    Text("N/A")
                                } else {
                                    Text("\(rating.rawValue, specifier: "%.1f")")
                                }
                            }
                            .id(rating)
                            .tag(rating)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Puzzle rating")
                    .accessibilityValue(formVm.puzzle.rating == .none ? "No rating" : "\(formVm.puzzle.rating.rawValue, specifier: "%.1f") out of 5")
                }

                HStack {
                    Text("Difficulty:")

                    Spacer()

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
                    .pickerStyle(.menu)
                    .accessibilityLabel("Puzzle difficulty")
                    .accessibilityValue(formVm.puzzle.difficulty == .none ? "No difficulty" : "Difficulty \(formVm.puzzle.difficulty.rawValue) out of 5")
                }
            } header: {
                Text("How did you like it?")
            }

            // Time Spent Section
            Section {
                HStack {
                    //                    Text("Hours Spent:")
                    //
                    //                    Spacer()

                    TextField(
                        "Hours Spent",
                        value: Binding(
                            get: { formVm.puzzle.estimatedTimeSpent?.hours },
                            set: { new in
                                if formVm.puzzle.estimatedTimeSpent == nil {
                                    formVm.puzzle.estimatedTimeSpent = Puzzle.PuzzleTime()
                                }
                                formVm.puzzle.estimatedTimeSpent?.hours = new
                            }
                        ),
                        format: .number,
                        prompt: Text("Estimated Hours Spent")
                    )
                    .keyboardType(.numberPad)
                    .frame(alignment: .trailing)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Estimated hours spent")
                }

                HStack {
                    //                    Text("Minutes Spent:")
                    //
                    //                    Spacer()

                    TextField(
                        "Minutes Spent",
                        value: Binding(
                            get: { formVm.puzzle.estimatedTimeSpent?.minutes },
                            set: { new in
                                if formVm.puzzle.estimatedTimeSpent == nil {
                                    formVm.puzzle.estimatedTimeSpent = Puzzle.PuzzleTime()
                                }
                                formVm.puzzle.estimatedTimeSpent?.minutes = new
                            }
                        ),
                        format: .number,
                        prompt: Text("Estimated Minutes Spent")
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Estimated minutes spent")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } header: {
                Text("How long did it take?")
            }

            // Completion Section
            Section {
                DatePicker("Completion Date", selection: $formVm.puzzle.completionDate)
                    .datePickerStyle(.graphical)
                    .accessibilityLabel("Completion date")
            } header: {
                Text("When did you finish \(!formVm.puzzle.name.isEmpty ? formVm.puzzle.name : "the puzzle")?")
            }
        }
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
