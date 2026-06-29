//
//  MissingPuzzleDestination.swift
//  Puzzle Buddy
//

import SwiftUI

struct MissingPuzzleDestination: View {
    var body: some View {
        ContentUnavailableView(
            "Puzzle no longer available",
            systemImage: "puzzlepiece.extension",
            description: Text("This puzzle may have been deleted from your collection.")
        )
        .readableBrandScreenChrome()
        .navigationTitle("Not found")
        .navigationBarTitleDisplayMode(.inline)
    }
}
