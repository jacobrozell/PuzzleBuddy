//
//  PuzzleDetail.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct PuzzleDetail: View {
    @ObservedObject var ps: PuzzleStore
    @State private var isEditable = false
    @State private var puzzle: Puzzle

    init(ps: PuzzleStore, puzzle: Puzzle) {
        _ps = ObservedObject(wrappedValue: ps)
        self.puzzle = puzzle
    }

    var body: some View {
        VStack {
            if isEditable {
                PuzzleFormInternal(formVm: .init(puzzle: puzzle))
            } else {
                ScrollView {
                    DetailView(puzzle: $puzzle)
                }
            }
        }
        .animation(.easeInOut, value: isEditable)
        .navigationTitle("\(puzzle.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard isEditable else {
                        isEditable.toggle()
                        return
                    }

                    // Save Pressed
                    //Attempt to save to database
                    // Then Switch back if successful
                    isEditable.toggle()

                } label: {
                    Text("\(isEditable ? "Save" : "Edit")")
                }
            }
        }
    }
}

// MARK: - DetailView
struct DetailView: View {
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack {
            Image(systemName: "puzzlepiece.extension.fill")
                .resizable()
                .aspectRatio(2.5/2, contentMode: .fill)
                .foregroundColor(Color.accentColor)
                .padding(.horizontal)

            Text(puzzle.name)
                .font(.title)

            Text("\(puzzle.pieces) Pieces")
                .font(.subheadline)

            RatingsView(rating: $puzzle.rating)
                .padding(.vertical)

            Divider()

            if puzzle.difficulty != .none {
                Text("Difficulty: \(puzzle.difficulty.rawValue)")
            }

            // Completion Date
            VStack {
                HStack {
                    Text("Date Completed: ")
                    Text(puzzle.completionDate, style: .date)
                }

                if let ets = puzzle.estimatedTimeSpent {
                    HStack {
                        Text("Estimated Time Spent:")
                        
                        Text(ets.toName())
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - Previews
//struct PuzzleDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            PuzzleDetail(ps: .init(), puzzle: .fixture())
//        }
//    }
//}
