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
                .padding(4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: PuzzleCellView
private struct PuzzleCellView: View {
    @State private var expanded: Bool = false
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Text(puzzle.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)

                GroupBox {
                    RatingsView(rating: $puzzle.rating)
                }
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .padding()

            if expanded {
                VStack {
                    HStack {
                        Text("Total Pieces:")
                            .bold()

                        Text("\(puzzle.pieces)")
                    }

                    HStack {
                        Text("Time Spent:")
                            .bold()

                        Text(puzzle.estimatedTimeSpent.toName())
                    }

                    HStack {
                        Text("Completed:")
                            .bold()

                        Text(puzzle.completionDate, style: .date)
                            .lineLimit(0)
                    }

                    HStack {
                        Text("Difficulty:")
                            .bold()

                        Text(puzzle.difficulty.rawValue)
                            .lineLimit(0)
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text(expanded ? "↑" : "↓")
                .foregroundColor(.primary)
                .animation(.linear, value: expanded)
                .onTapGesture {
                    expanded.toggle()
                }
                .padding(4)
                .background(Color.accentColor)
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
