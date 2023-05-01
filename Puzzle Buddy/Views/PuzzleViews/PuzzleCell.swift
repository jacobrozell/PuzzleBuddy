//
//  PuzzleCell.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - PuzzleCell
struct PuzzleCell: View {
    @ObservedObject var ps: PuzzleStore
    @Binding var puzzle: Puzzle

    var body: some View {
        NavigationLink {
            PuzzleDetail(ps: ps, puzzle: $puzzle)
        } label: {
            PuzzleCellView(puzzle: $puzzle)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: PuzzleCellView
private struct PuzzleCellView: View {
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Text(puzzle.name)
                    .font(.headline)
                    .aspectRatio(contentMode: .fill)
                    .lineLimit(0)

                Divider()

                RatingsView(rating: $puzzle.rating)
                    .padding(.top)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
            .padding(.vertical)

            HStack(alignment: .top) {
                if let pieces = puzzle.pieces {
                    VStack {
                        Text("Total Pieces:")
                            .bold()

                        Text("\(pieces)")
                            .padding(.vertical)
                    }
                    .padding(.vertical)
                    .aspectRatio(contentMode: .fill)
                }

                Spacer()

                if let time = puzzle.estimatedTimeSpent {
                    VStack {
                        Text("Time Spent:")
                            .bold()

                        Text(time.toName())
                            .padding(.vertical)
                    }
                    .padding(.vertical)
                    .aspectRatio(contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)

            HStack(alignment: .bottom) {
                Text("Completed:")
                Text(puzzle.completionDate, style: .offset)
            }
        }
        .overlay(alignment: .topLeading) {
            Text(puzzle.difficulty.rawValue)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.red)
                .clipShape(Circle())
        }
    }
}

// MARK: - Previews
struct PuzzleCellPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            PuzzleCell(ps: .init(), puzzle: .constant(.fixture(name: "Test 1", pieces: 125)))
            PuzzleCell(ps: .init(), puzzle: .constant(.fixture(name: "Test 2", pieces: 500, rating: .five)))
        }
    }
}
