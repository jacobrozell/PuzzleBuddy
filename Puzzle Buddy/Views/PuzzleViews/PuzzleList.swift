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
    @State private var listStatus: Puzzle.Status = .completed
    @State private var filterInt: Int = 1 {
        didSet {
            switch filterInt {
            case 0:
                listStatus = .todo

            case 1:
                listStatus = .completed

            case 2:
                listStatus = .inProgress

            default:
                listStatus = .todo
            }
        }
    }

    var body: some View {
        List {
            VStack {
                Picker("Sort by: Status", selection: $filterInt) {
                    Text("To-Do").tag(0)

                    Text("Completed").tag(1)

                    Text("In-Progress").tag(2)

                }
                .pickerStyle(.segmented)
                .padding()

                // List
                ForEach(ps.puzzles.filter({ $0.status == listStatus }), id: \.id) { p in
                    PuzzleCell(ps: ps, puzzle: p)
                }
                .onDelete(perform: ps.delete(at:))
            }
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
