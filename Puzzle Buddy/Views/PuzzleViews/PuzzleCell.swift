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
    @State private var expanded: Bool = false
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack {
            HStack {
                if let image = puzzle.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .border(.primary, width: 0.5)
                        .clipShape(Circle())
                        .frame(maxWidth: 100, maxHeight: 100)
                        .padding(.vertical)
                }

                Spacer()

                // Card info
                HStack {
                    Text(puzzle.name.capitalized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)

                    VStack {
                        if let pieces = puzzle.pieces {
                            Text("Pieces: \(pieces)")
                                .italic()
                                .font(.footnote)
                        }

                        Spacer()

                        Text(puzzle.completionDate, style: .date)
                            .fontWeight(.light)
                            .italic()
                            .font(.footnote)
                    }
                    .padding(.vertical)
                }
            }
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
