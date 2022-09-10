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
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
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
                VStack {
                    Text("Total Pieces:")
                        .bold()

                    Text("\(puzzle.pieces)")
                        .padding(.vertical)
                }
                .padding(.vertical)
                .aspectRatio(contentMode: .fill)

                Spacer()

                VStack {
                    Text("Time Spent:")
                        .bold()

                    Text(puzzle.estimatedTimeSpent.toName())
                        .padding(.vertical)
                }
                .padding(.vertical)
                .aspectRatio(contentMode: .fill)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)

            VStack {
                Text("Completed:")
                    .bold()
                
                Text(puzzle.completionDate, style: .date)
                    .lineLimit(0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fit)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            PuzzleCell(ps: .init(), puzzle: .constant(.fixture()))
            PuzzleCell(ps: .init(), puzzle: .constant(.fixture()))
        }
    }
}
