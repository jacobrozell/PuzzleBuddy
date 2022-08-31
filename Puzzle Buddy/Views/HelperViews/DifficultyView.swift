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
        Text("Difficulty: \(puzzle.difficulty?.rawValue ?? "1")")
    }
}

struct DifficultyView_Previews: PreviewProvider {
    static var previews: some View {
        DifficultyView(puzzle: .fixture())
    }
}
