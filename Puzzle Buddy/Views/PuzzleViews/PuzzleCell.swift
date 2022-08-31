//
//  PuzzleCell.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - PuzzleCell
struct PuzzleCell: View {
    let puzzle: Puzzle

    var body: some View {
        NavigationLink {
            PuzzleDetail(puzzle: puzzle)
        } label: {
            PuzzleCellView(puzzle: puzzle)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: PuzzleCellView
private struct PuzzleCellView: View {
    let puzzle: Puzzle

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(puzzle.name)
                    .font(.headline)

                Spacer()

                Text("Pieces: \(puzzle.pieces)")
                    .font(.body)
                    .padding(.vertical)
            }

            Divider()

            HStack {
                Text("Rating: \(puzzle.rating?.rawValue ?? "None")")
                    .font(.subheadline)

                Spacer()

                Text("Difficulty: \(puzzle.difficulty?.rawValue ?? "None")")
                    .font(.subheadline)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Previews
struct PuzzleCellPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            PuzzleCell(puzzle: .fixture())
            PuzzleCell(puzzle: .fixture())
            PuzzleCell(puzzle: .fixture())
        }
    }
}
