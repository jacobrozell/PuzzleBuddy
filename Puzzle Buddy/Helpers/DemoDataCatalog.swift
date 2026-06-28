//
//  DemoDataCatalog.swift
//  Puzzle Buddy
//

import Foundation

enum DemoDataCatalog {
    static let puzzleCount = 4

    static func makePuzzles() -> [Puzzle] {
        [
            demoFixture(name: "Mountain Sunset", pieces: 500, rating: .four),
            demoFixture(name: "Ocean Breeze", pieces: 1000, rating: .five),
            inProgressFixture(name: "Tabletop Sky", pieces: 300),
            completedFixture(name: "Harbor Lights", pieces: 750)
        ]
    }

    private static func demoFixture(
        name: String,
        pieces: Int,
        rating: Puzzle.Rating = .none,
        difficulty: Puzzle.Difficulty = .none
    ) -> Puzzle {
        let puzzle = Puzzle.fixture(name: name, pieces: pieces, rating: rating, difficulty: difficulty)
        puzzle.isDemo = true
        return puzzle
    }

    private static func completedFixture(name: String, pieces: Int) -> Puzzle {
        let puzzle = demoFixture(name: name, pieces: pieces, rating: .three)
        puzzle.status = .completed
        puzzle.progressPercent = 100
        puzzle.source = "Galison"
        puzzle.purchaseLocation = "Local bookshop"
        puzzle.releaseYear = 2022
        puzzle.puzzleType = .landscape
        puzzle.material = .cardboard
        puzzle.disposition = .kept
        puzzle.startDate = Calendar.current.date(byAdding: .day, value: -5, to: puzzle.completionDate)
        return puzzle
    }

    private static func inProgressFixture(name: String, pieces: Int) -> Puzzle {
        let puzzle = demoFixture(name: name, pieces: pieces, rating: .two)
        puzzle.status = .inProgress
        puzzle.progressPercent = 45
        puzzle.source = "Ravensburger"
        puzzle.purchaseLocation = "Thrift store"
        puzzle.puzzleType = .gradient
        puzzle.material = .cardboard
        puzzle.startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        return puzzle
    }
}
