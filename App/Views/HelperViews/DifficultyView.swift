//
//  DifficultyView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct DifficultyView: View {
    let puzzle: Puzzle
    
    var body: some View {
        if puzzle.difficulty == .none {
            Text("N/A")
                .accessibilityLabel("No difficulty")
        } else {
            Text("Difficulty: \(puzzle.difficulty.rawValue)")
                .accessibilityLabel(puzzle.difficulty.accessibilityDescription)
        }
    }
}

struct DifficultyView_Previews: PreviewProvider {
    static var previews: some View {
        DifficultyView(puzzle: .fixture())
    }
}
