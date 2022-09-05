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
    }
}

// MARK: - PuzzleList
struct PuzzleList: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore
    @State private var listStatus: Puzzle.Status = .todo
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            Picker("Sort by: Status", selection: $listStatus) {
                Text("To-Do")
                    .tag(Puzzle.Status.todo)

                Text("In-Progress")
                    .tag(Puzzle.Status.inProgress)

                Text("Completed")
                    .tag(Puzzle.Status.completed)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                // List
                ForEach(ps.puzzles.filter({ $0.status == listStatus }), id: \.id) { p in
                    if let index = ps.puzzles.firstIndex(where: { $0.id == p.id }) {
                        PuzzleCell(puzzle: $ps.puzzles[index])
                            .id(index)
                    }
                }
                .onDelete(perform: ps.delete(at:))
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: listStatus)
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
