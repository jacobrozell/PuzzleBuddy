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
            GroupBox {
                PuzzleCellView(puzzle: $puzzle)
                    .padding()
            }
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
                HStack {
                    Text(puzzle.name)
                        .font(.headline)
                        .lineLimit(0)

                    Spacer()

                    if puzzle.difficulty != .none {
                        Text(puzzle.difficulty.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }

                RatingsView(rating: $puzzle.rating)
                    .padding(.vertical)

                Divider()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)

            HStack(alignment: .top) {
                if let pieces = puzzle.pieces {
                    GroupBox {
                        VStack {
                            Text("Total Pieces:")
                                .bold()

                            Text("\(pieces)")
                        }
                    }
                }

                if let timeSpent = puzzle.estimatedTimeSpent.toName() {
                    GroupBox {
                        VStack {
                            Text("Time Spent:")
                                .bold()

                            Text(timeSpent)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            if let completionDate = puzzle.completionDate {
                HStack(alignment: .bottom) {
                    Text("Completed:")
                    Text(completionDate, style: .date)
                    Text(completionDate, style: .time)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Previews
//struct PuzzleCellPreview: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            PuzzleCell(ps: .init(), puzzle: .constant(.fixture()))
//            PuzzleCell(ps: .init(), puzzle: .constant(.fixture()))
//        }
//    }
//}
