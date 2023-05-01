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

    init(puzzle: Puzzle, ps: PuzzleStore) {
        self._ps = ObservedObject(wrappedValue: ps)
        self._isPresented = .constant(false)
        self._formVm = StateObject(wrappedValue: PuzzleFormViewModel(puzzle: puzzle))
    }

    var body: some View {
        VStack {
            PuzzleFormInternal(formVm: formVm)

            SubmitAddButton(ps: ps, formVm: formVm, isPresented: $isPresented)
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
                    }

                    Divider()

                    HStack {
                        Text("Pieces:")

                        Spacer()

                        TextField("Pieces", value: $formVm.puzzle.pieces, format: .number, prompt: Text("# of Pieces"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
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
                }
            } header: {
                Text("How did you like it?")
            }

            // Time Spent Section
            Section {
                if let ets = formVm.puzzle.estimatedTimeSpent {
                    VStack {
                        TextField("Hours Spent", value: Binding {
                            ets.hours
                        } set: { new in
                            formVm.puzzle.estimatedTimeSpent?.hours = new
                        }, format: .number, prompt: Text("Estimated Hours Spent"))
                        .keyboardType(.numberPad)
                        .frame(alignment: .trailing)
                        .multilineTextAlignment(.leading)

                        TextField("Minutes Spent", value: Binding {
                            ets.minutes
                        } set: { new in
                            formVm.puzzle.estimatedTimeSpent?.minutes = new
                        }, format: .number, prompt: Text("Estimated Minutes Spent"))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.leading)
                    }
                }
            } header: {
                Text("How long did it take?")
            }

            // Completion Section
            Section {
                DatePicker("Completion Date", selection: Binding(get: {
                    formVm.puzzle.completionDate ?? Date()
                }, set: { new in
                    formVm.puzzle.completionDate = new
                }))
                    .datePickerStyle(.graphical)
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

                // dismiss view
                isPresented = false
            } catch {
                eh.handle(title: "Error Adding Puzzle!", message: "\(error.localizedDescription)")
            }
        } label: {
            Text("Submit")
                .contentShape(Rectangle())
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(16.0)
        .padding(.horizontal)
        .disabled(formVm.puzzle.name.isEmpty)
        .opacity(!formVm.puzzle.name.isEmpty ? 1.0 : 0.8)
    }
}

// MARK: - Preview
//struct PuzzleForm_Preview: PreviewProvider {
//    static var previews: some View {
//        Group {
//            PuzzleForm(isPresented: .constant(false), ps: .init())
//        }
//    }
//}
