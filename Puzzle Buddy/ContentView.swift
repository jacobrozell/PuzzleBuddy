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

// MARK: - Puzzle
struct Puzzle: Identifiable {
    enum Pieces: Int {
        case twentyFive = 25
        case fifty = 50
        case hundred = 100
        case fiveHundred = 500
        case thousand = 1000
        case twoThousand = 2000
        case fiveThousand = 5000
    }

    enum Rating: String {
        case one
        case two
        case three
        case forur
        case five
    }

    enum Difficulty: Int {
        case one = 1
        case two
        case three
        case four
        case five
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
    var name: String
    var pieces: Pieces
    var rating: Rating?
    var difficulty: Difficulty?
    var estimatedTimeSpent: PuzzleTime?
    var completionDate: Date
//    var
//    var barcode // scan barcode on certain brands
//    var timer // ability to start timer in app ?

//    var price: Double
//    var notes: String
//    var image: UIImage
}

extension Puzzle {
    static func fixture() -> Puzzle {
        return .init(id: UUID(), name: "Puzzle", pieces: .thousand, rating: .three, difficulty: .three, estimatedTimeSpent: .init(hours: 5, minutes: 0), completionDate: Date())
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
                    PuzzleForm()
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
    @State private var editingPuzzle: Puzzle = .fixture()

    var body: some View {
        Text("Puzzle Form")
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
