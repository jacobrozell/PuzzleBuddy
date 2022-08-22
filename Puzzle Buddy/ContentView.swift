//
//  ContentView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import SwiftUI

// enter day you start
// enter day you want to finish the puzzle
// based on puzzle piece count -> calc how many peices you need to complete per day
//
// Stats:
// avg peices per hour
// total time worked
// day of week completed


// Version History
// 1.0 -> App works locally and caches
// 1.1 -> Adds Cloud
// 1.3 -> Add Stats

// Sponsorship from certain puzzle brands to be featured in the app?
//struct PuzzleWishlist {
//    @Published var wishlistLink: [URL]
//}


// MARK: - PuzzleStore
@MainActor
class PuzzleStore: ObservableObject {
    @Published var puzzles: [Puzzle] = [.fixture(), .fixture()]

    func delete(at offsets: IndexSet) {
        puzzles.remove(atOffsets: offsets)
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject var ps = PuzzleStore()
    @State private var present = false

    var body: some View {
        NavigationView {
            PuzzleList(ps: ps)
                .navigationViewStyle(.stack)
                .navigationTitle(Text("Puzzle Buddy"))
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            present.toggle()
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                .sheet(isPresented: $present) {
                    PuzzleForm(ps: ps, isPresented: $present)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
