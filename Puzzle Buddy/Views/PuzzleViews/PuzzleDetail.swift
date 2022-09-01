//
//  PuzzleDetail.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct PuzzleDetail: View {
    let puzzle: Puzzle

    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "puzzlepiece.extension.fill")
                    .resizable()
                    .aspectRatio(1.5/1, contentMode: .fit)
                    .padding()
                    .foregroundColor(Color.blue.opacity(0.5))
                    .padding(.horizontal)

                Text(puzzle.name)
                    .font(.title)

                Text("\(puzzle.pieces) Pieces")
                    .font(.subheadline)


                HStack {
                    // rating
                    RatingsView(puzzle: puzzle)

                    Spacer()

                    // difficulty
                    Text("Difficulty: \(puzzle.difficulty.rawValue)")

                }
                .padding()

                // Completion Date
                VStack {
                    HStack {
                        Text("Date Completed: ")
                        Text(puzzle.completionDate, style: .date)
                    }

                    HStack {
                        Text("Estimated Time Spent:")

                        Text(puzzle.estimatedTimeSpent.toName())
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct PuzzleDetail_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleDetail(puzzle: .fixture())
    }
}
