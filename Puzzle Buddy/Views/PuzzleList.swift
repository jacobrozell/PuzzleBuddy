//
//  PuzzleList.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import SwiftUI

// MARK: - PuzzleList
struct PuzzleList: View {
    @ObservedObject var ps: PuzzleStore

    var body: some View {
        List {
            ForEach(ps.puzzles, id: \.id) { p in
                PuzzleCell(puzzle: p)
            }
            .onDelete(perform: ps.delete(at:))
        }
        .listStyle(.automatic)
    }
}

// MARK: - PuzzleCell
struct PuzzleCell: View {
    let puzzle: Puzzle

    var body: some View {
        NavigationLink {
            PuzzleDetail(puzzle: puzzle)
        } label: {
            VStack {
                Text("**Name: \(puzzle.name)**")
                    .lineLimit(2)
                    .padding(.vertical)
            }
        }
    }
}
