//
//  PuzzleList.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import SwiftUI


// MARK: - PuzzleList
struct PuzzleList: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore
    @State private var present = false
    @State private var searchText: String = ""

    var body: some View {
        List {
            ForEach(ps.puzzles, id: \.id) { p in
                if let index = ps.puzzles.firstIndex(where: { $0.id == p.id }) {
                    PuzzleCell(ps: ps, puzzle: $ps.puzzles[index])
                        .id(ps.puzzles[index].id)
                }
            }
            .onDelete(perform: { indexSet in
                ps.delete(at: indexSet)
            })
        }
        .refreshable {
            await ps.fetchPuzzles()
        }
//        .listStyle(.plain)
        .sheet(isPresented: $present) {
            PuzzleForm(isPresented: $present, ps: ps)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                present.toggle()
            } label: {
                Text("Add")
                    .padding(4)
                    .font(.title)
                    .frame(maxWidth: 80, maxHeight: 80)
                    .contentShape(Circle())
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .padding()
            .opacity(0.75)
        }
    }
}

// MARK: - Previews
//struct PuzzleListPreviews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            let ps = PuzzleStore()
//            PuzzleList(ps: ps)
//                .task {
//                    ps.puzzles.append(.fixture())
//                    ps.puzzles.append(.fixture())
//                }
//        }
//    }
//}
