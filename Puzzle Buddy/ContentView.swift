//
//  ContentView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import SwiftUI

// enter day you start
// enter day you want to finish the puzzle
// based on puzzle piece count -> calc how many peices you need to complete per day
//
// Stats:
// avg peices per hour
// total time worked
// day of week completed


// Version History
// 1.0 -> App works locally and caches
// 1.1 -> Adds Cloud
// 1.3 -> Add Stats

// Sponsorship from certain puzzle brands to be featured in the app?
//struct PuzzleWishlist {
//    @Published var wishlistLink: [URL]
//}


// MARK: - Puzzle
class Puzzle: ObservableObject {
    enum Pieces: Int, CaseIterable, Identifiable {
        case twentyFive = 25
        case fifty = 50
        case hundred = 100
        case fiveHundred = 500
        case thousand = 1000
        case twoThousand = 2000
        case fiveThousand = 5000

        var id: Int {
            self.rawValue
        }
    }

    enum Rating: String, CaseIterable, Identifiable {
        case one
        case two
        case three
        case forur
        case five

        var id: String {
            self.rawValue
        }
    }

    enum Difficulty: Int, CaseIterable, Identifiable {
        case one = 1
        case two
        case three
        case four
        case five

        var id: Int {
            self.rawValue
        }
    }

    struct PuzzleTime {
        var hours: Int?
        var minutes: Int?
    }

    enum Status {
        case todo
        case inProgress
        case completed
    }

    var id: UUID = UUID()
    @Published var name: String = ""
    @Published var pieces: Pieces = .thousand
    @Published var rating: Rating?
    @Published var difficulty: Difficulty?
    @Published var estimatedTimeSpent: PuzzleTime?
    @Published var completionDate: Date = Date()

    internal init(name: String) {
        self.name = name
    }

//    var category
//    var barcode // scan barcode on certain brands
//    var timer // ability to start timer in app ?

//    var price: Double
//    var notes: String
//    var image: UIImage // reverse image search to find info
    // var urlLink

}

extension Puzzle {
    static func fixture() -> Puzzle {
        return .init(name: "")
    }
}

// MARK: - PuzzleStore
class PuzzleStore: ObservableObject {
    @Published var puzzles: [Puzzle] = [.fixture(), .fixture()]
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject var ps = PuzzleStore()
    @State private var present = false

    var body: some View {
        NavigationView {
            PuzzleList(ps: ps)
                .navigationViewStyle(.stack)
                .navigationTitle(Text("Puzzle Buddy"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            present.toggle()
                        } label: {
                            Image(systemName: "plus.circle")
                        }

                    }
                }
                .sheet(isPresented: $present) {
                    PuzzleForm(ps: ps)
                }
        }
    }
}

// MARK: - PuzzleList
struct PuzzleList: View {
    @ObservedObject var ps: PuzzleStore

    var body: some View {
        List {
            ForEach(ps.puzzles, id: \.id) { p in
                PuzzleCell(puzzle: p)
            }

            Button {
                ps.puzzles.append(.fixture())
            } label: {
                Text("Add New Puzzle")
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - PuzzleForm
struct PuzzleForm: View {
    @ObservedObject var ps: PuzzleStore

    @State private var name: String = ""
    @State private var pieces: Puzzle.Pieces = .thousand
    @State private var rating: Puzzle.Rating = .three
    @State private var difficulty: Puzzle.Difficulty = .three

    var body: some View {
        VStack {
            GroupBox {
                // Name
                TextField("Name", text: $name, prompt: Text("Puzzle Name"))

                // peices
                Picker(selection: $pieces) {
                    ForEach(Puzzle.Pieces.allCases) { peices in
                        Text("\(peices.rawValue)")
                            .id(peices.rawValue)
                    }
                } label: {
                    Text("# of Peices")
                }

                // rating
                Picker(selection: $rating) {
                    ForEach(Puzzle.Rating.allCases) { rating in
                        Text("\(rating.rawValue)")
                            .id(rating.rawValue)
                    }
                } label: {
                    Text("Rating")
                }
                .pickerStyle(.segmented)

                // difficulty
                Picker(selection: $difficulty) {
                    ForEach(Puzzle.Difficulty.allCases) { difficulty in
                        Text("\(difficulty.rawValue)")
                            .id(difficulty.rawValue)
                    }
                } label: {
                    Text("Difficulty")
                }
                .pickerStyle(.segmented)
                .padding()

                // estimatedTimeSpent
                // completionDate - defaults to today
            }

            Button {
                if !name.isEmpty {
                    ps.puzzles.append(.init(name: name))
                }
            } label: {
                Text("Submit")
            }
            .padding()
            .disabled(name.isEmpty)
            .opacity(name.isEmpty ? 0.60 : 1.0)
        }
    }
}

// MARK: - PuzzleCell
struct PuzzleCell: View {
    let puzzle: Puzzle

    var body: some View {
        VStack {
            HStack {
                Text("**Name: \(puzzle.name)**")

                Spacer()

                Text(puzzle.completionDate.formatted(date: .abbreviated, time: .omitted)).italic()
            }
            .padding(.vertical)

            HStack {
                Text("\(puzzle.pieces.rawValue.formatted()) Pieces")

                Spacer()

                Text("Difficulty: \(puzzle.difficulty?.rawValue.formatted() ?? "")")
                    .foregroundColor(Color.red.opacity(0.50 * Double(puzzle.difficulty?.rawValue ?? 1)))

                Spacer()

                Text("\(puzzle.estimatedTimeSpent?.hours ?? 0)hr \(puzzle.estimatedTimeSpent?.minutes ?? 0)min")
            }
            .padding(.vertical)
        }
        .padding()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
