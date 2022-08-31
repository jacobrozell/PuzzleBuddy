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

    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $name, prompt: Text("Puzzle Name"))

                    TextField("Pieces", value: $pieces, format: .number, prompt: Text("# of Pieces"))

                    TextField("Hours Spent", value: $hoursSpent, format: .number, prompt: Text("Estimated Hours Spent"))

                    TextField("Minutes Spent", value: $minutesSpent, format: .number, prompt: Text("Estimated Minutes Spent"))
                } header: {
                    Text("Puzzle Info")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // rating
                Section {
                    Picker("Rating", selection: $rating) {
                        ForEach(Puzzle.Rating.allCases) { rating in
                            Text("\(rating.rawValue)")
                                .id(rating.id)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Rating")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Puzzle.Difficulty.allCases) { difficulty in
                            Text("\(difficulty.rawValue)")
                                .id(difficulty.id)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Difficulty")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section {
                    // completionDate - defaults to today
                    DatePicker("Completion Date", selection: $completionDate).datePickerStyle(.graphical)
                } header: {
                    Text("Completion Date")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button {
                do {
                    try ps.add(puzzle: .init(
                        name: name,
                        pieces: pieces ?? 100,
                        rating: .init(rawValue: rating),
                        difficulty: .init(rawValue: difficulty),
                        estimatedTimeSpent: .init(
                            hours: hoursSpent ?? 0,
                            minutes: minutesSpent ?? 0)))

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
            .disabled(name.isEmpty)
            .opacity(name.isEmpty ? 0.6 : 1.0)
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
