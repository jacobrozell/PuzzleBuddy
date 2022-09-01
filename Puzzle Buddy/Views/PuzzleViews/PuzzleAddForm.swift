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

    @State private var name: String = ""
    @State private var pieces: Int?
    @State private var rating: String = "3"
    @State private var difficulty: String = "3"
    @State private var hoursSpent: Int?
    @State private var minutesSpent: Int?
    @State private var completionDate: Date = Date()

    var isValid: Bool {
        return !name.isEmpty
        && (pieces != nil)
        && !rating.isEmpty
        && !difficulty.isEmpty
    }

    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $name, prompt: Text("Puzzle Name"))
                        .keyboardType(.namePhonePad)
                        .disableAutocorrection(true)

                    TextField("Pieces", value: $pieces, format: .number, prompt: Text("# of Pieces"))
                        .keyboardType(.numberPad)

                    HStack {
                        Text("Rating:")

                        Spacer()

                        Picker("Rating", selection: $rating) {
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

                        Picker("Difficulty", selection: $difficulty) {
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
                    TextField("Hours Spent", value: $hoursSpent, format: .number, prompt: Text("Estimated Hours Spent"))
                        .keyboardType(.numberPad)

                    TextField("Minutes Spent", value: $minutesSpent, format: .number, prompt: Text("Estimated Minutes Spent"))
                        .keyboardType(.numberPad)
                } header: {
                    Text("Stats")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section {
                    DatePicker("Completion Date", selection: $completionDate)
                        .datePickerStyle(.graphical)
                } header: {
                    Text("Date Completed")
                }
            }

            Button {
                do {
                    try ps.add(puzzle: .init(
                        name: name,
                        pieces: pieces ?? 100,
                        rating: .init(rawValue: rating) ?? .three,
                        difficulty: .init(rawValue: difficulty) ?? .three,
                        estimatedTimeSpent: .init(
                            hours: hoursSpent ?? 0,
                            minutes: minutesSpent ?? 0),
                        completionDate: completionDate))

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
            .disabled(!isValid)
            .opacity(!isValid ? 0.6 : 1.0)
        }
    }
}

// MARK: - Preview
struct PuzzleForm_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            PuzzleForm(ps: .init(), isPresented: .constant(false))
        }
    }
}
