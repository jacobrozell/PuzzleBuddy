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
            switch ps.state {
            case .fetching:
                ProgressView()

                Spacer()
            case .idle, .done:
                PuzzleList(ps: ps)
            }

            Button {
                present.toggle()
            } label: {
                Text("Add Puzzle")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
            .padding()
        }
        .sheet(isPresented: $present) {
            PuzzleForm(isPresented: $present, ps: ps)
        }
        .task {
            ps.fetchPuzzles()
        }
    }
}

// MARK: - PuzzleList
struct PuzzleList: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            List {
                ForEach(ps.puzzles, id: \.id) { p in
                    if let index = ps.puzzles.firstIndex(where: { $0.id == p.id }) {
                        PuzzleCell(ps: ps, puzzle: $ps.puzzles[index])
                            .id(ps.puzzles[index].id)
                    }
                }
                .onDelete(perform: ps.delete(at:))
            }
            .refreshable {
                ps.fetchPuzzles()
            }
            .listStyle(.plain)
        }
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
