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
        VStack {
            //image

            // name
            Text(puzzle.name)

            // rating
            Text(puzzle.rating?.rawValue ?? "5")

            // difficulty
            Text(puzzle.difficulty?.rawValue ?? "1")

            // total time spent
            Text("\(puzzle.estimatedTimeSpent?.hours ?? 0)hr \(puzzle.estimatedTimeSpent?.minutes ?? 0)min")

            // Completion Date
//            Text(puzzle.completionDate)

            // Progress by days

            HStack {
                Text("\(puzzle.pieces) Pieces")

                Spacer()

                if let difficulty = puzzle.difficulty {
                    Text("Difficulty: \(difficulty.rawValue)")
                        .foregroundColor(Color.red.opacity(0.50 * (Double(difficulty.rawValue) ?? 0.0)))
                }

                Spacer()

                if let timeSpent = puzzle.estimatedTimeSpent {
                    Text("\(timeSpent.hours ?? 0)hr \(timeSpent.minutes ?? 0)min")
                }

                Text(puzzle.completionDate.formatted(date: .abbreviated, time: .omitted)).italic()
            }
            .padding()
        }
    }
}

struct PuzzleDetail_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleDetail()
    }
}
