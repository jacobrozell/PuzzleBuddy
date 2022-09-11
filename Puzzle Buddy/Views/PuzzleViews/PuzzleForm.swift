//
//  PuzzleForm.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import Photos
import PhotosUI
import SwiftUI

// MARK: - PuzzleForm
struct PuzzleForm: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @Binding var isPresented: Bool

    @State private var puzzle: Puzzle

    /// Detail Init
    init(puzzle: Puzzle, ps: PuzzleStore) {
        self._ps = ObservedObject(wrappedValue: ps)
        self._isPresented = .constant(false)
        self.puzzle = puzzle
    }

    /// Normal Path Init
    init(isPresented: Binding<Bool>, ps: PuzzleStore) {
        self._ps = ObservedObject(wrappedValue: ps)
        self._isPresented = isPresented
        self.puzzle = .init(name: "", pieces: 0, rating: .three, difficulty: .three, estimatedTimeSpent: .init(hours: 0, minutes: 0), completionDate: Date())
    }

    var body: some View {
        VStack {
            PuzzleFormInternal(puzzle: $puzzle)
            SubmitAddButton(ps: ps, puzzle: $puzzle, isPresented: $isPresented)
        }
    }
}

// MARK: - PuzzleFormInternal
struct PuzzleFormInternal: View {
    @Binding var puzzle: Puzzle

    var body: some View {
        Form {
            Section {
                VStack {
                    HStack {
                        Text("Name:")

                        Spacer()

                        TextField("Name", text: $puzzle.name, prompt: Text("Puzzle Name"))
                            .keyboardType(.namePhonePad)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }

                    Divider()

                    HStack {
                        Text("Pieces:")

                        Spacer()

                        TextField("Pieces", value: $puzzle.pieces, format: .number, prompt: Text("# of Pieces"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Divider()

                    HStack {
                        Text("Status:")

                        Spacer()

                        Picker("Status", selection: $puzzle.status) {
                            ForEach(Puzzle.Status.allCases) { status in
                                Text(status.rawValue)
                                    .id(status)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            } header: {
                Text("Puzzle Info")
            }

            // Rating Section
            Section {
                HStack {
                    Text("Rating:")

                    Spacer()

                    // TODO: Editable RatingsView
                    Picker("Rating", selection: $puzzle.rating) {
                        ForEach(Puzzle.Rating.allCases) { rating in
                            Text("\(rating.rawValue, specifier: "%.1f")")
                                .id(rating)
                                .tag(rating)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("Difficulty:")

                    Spacer()

                    Picker("Difficulty", selection: $puzzle.difficulty) {
                        ForEach(Puzzle.Difficulty.allCases) { difficulty in
                            Text("\(difficulty.rawValue)")
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
                HStack {
                    Text("Hours Spent:")

                    Spacer()

                    TextField("Hours Spent", value: $puzzle.estimatedTimeSpent.hours, format: .number, prompt: Text("Estimated Hours Spent"))
                        .keyboardType(.numberPad)
                        .frame(alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Minutes Spent:")

                    Spacer()

                    TextField("Minutes Spent", value: $puzzle.estimatedTimeSpent.minutes, format: .number, prompt: Text("Estimated Minutes Spent"))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Text("How long did it take?")
            }

            // Completion Section
            Section {
                DatePicker("Completion Date", selection: $puzzle.completionDate)
                    .datePickerStyle(.graphical)
            } header: {
                Text("When did you finish \(!puzzle.name.isEmpty ? puzzle.name : "the puzzle")?")
            }

            // Image Section
            Section {
                HStack {
                    // Image Cell
                    GroupBox {
                        ImageCell()
                    }
                    .padding()
                }
            } header: {
                Text("Add Images")
            }
        }
    }
}

struct ImageCell: View {
    var body: some View {
        Text("Add Image")
    }
}

// MARK: - SubmitAddButton
struct SubmitAddButton: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @Binding var puzzle: Puzzle
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            do {
                try ps.add(puzzle: puzzle)

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
        .disabled($puzzle.wrappedValue.name.isEmpty)
        .opacity($puzzle.wrappedValue.name.isEmpty ? 0.6 : 1.0)
    }
}

// MARK: - Preview
struct PuzzleForm_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            PuzzleForm(isPresented: .constant(false), ps: .init())
        }
    }
}
