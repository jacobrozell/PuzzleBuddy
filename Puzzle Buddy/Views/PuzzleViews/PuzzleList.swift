//
//  PuzzleList.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import SwiftUI

// MARK: - PuzzleListWrapper
struct PuzzleListWrapper: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore
    @State private var present = false

    var body: some View {
        VStack {
            PuzzleList(ps: ps)

            Button {
                present.toggle()
            } label: {
                Image(systemName: "plus.circle")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
            .padding()
        }
        .navigationTitle("Your Puzzle Buddy")
        .sheet(isPresented: $present) {
            PuzzleForm(isPresented: $present, ps: ps)
        }
    }
}

// MARK: - PuzzleList
struct PuzzleList: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore

    var body: some View {
        List {
            ForEach(ps.puzzles, id: \.id) { p in
                PuzzleCell(ps: ps, puzzle: p)
            }
            .onDelete(perform: ps.delete(at:))
        }
        .listStyle(.automatic)
    }
}

// MARK: - Previews
struct PuzzleListPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            let ps = PuzzleStore()
            PuzzleList(ps: ps)
                .task {
                    ps.puzzles.append(.fixture())
                    ps.puzzles.append(.fixture())
                }
        }
    }
}
