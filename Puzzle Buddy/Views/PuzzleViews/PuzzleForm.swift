//
//  PuzzleForm.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

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

    init(puzzle: Binding<Puzzle>) {
        self._puzzle = puzzle
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $puzzle.name, prompt: Text("Puzzle Name"))
                    .keyboardType(.namePhonePad)
                    .disableAutocorrection(true)

                TextField("Pieces", value: $puzzle.pieces, format: .number, prompt: Text("# of Pieces"))
                    .keyboardType(.numberPad)

                HStack {
                    Text("Rating:")

                    Spacer()

                    Picker("Rating", selection: $puzzle.rating) {
                        ForEach(Puzzle.Rating.allCases) { rating in
                            Text("\(rating.rawValue)")
                                .id(rating)
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
                        }
                    }
                    .pickerStyle(.menu)
                }

            } header: {
                Text("Puzzle Info")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                TextField("Hours Spent", value: $puzzle.estimatedTimeSpent.hours, format: .number, prompt: Text("Estimated Hours Spent"))
                    .keyboardType(.numberPad)

                TextField("Minutes Spent", value: $puzzle.estimatedTimeSpent.minutes, format: .number, prompt: Text("Estimated Minutes Spent"))
                    .keyboardType(.numberPad)

                HStack {
                    Text("Status:")

                    Spacer()

                    Picker("Status", selection: $puzzle.status) {
                        ForEach(Puzzle.Status.allCases) { status in
                            Text(status.rawValue)
                                .id(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Stats")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                DatePicker("Completion Date", selection: $puzzle.completionDate)
                    .datePickerStyle(.graphical)
            } header: {
                Text("Date Completed")
            }
        }
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
