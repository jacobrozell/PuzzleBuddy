//
//  RatingsView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct RatingsView: View {
    @State private var rating: Int = 1
    let puzzle: Puzzle

    var body: some View {
        Text("Rating: \(puzzle.rating?.rawValue ?? "1")")
    }
}

struct RatingsView_Previews: PreviewProvider {
    static var previews: some View {
        RatingsView(puzzle: .fixture())
    }
}
