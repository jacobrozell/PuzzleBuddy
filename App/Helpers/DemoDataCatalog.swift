//
//  DemoDataCatalog.swift
//  Puzzle Buddy
//

import Foundation

enum DemoDataCatalog {
    /// Full demo shelf — sized for list, detail, and stats screenshots.
    static let puzzleCount = 13

    /// Used by marketing captures and UI tests for duplicate-check sheet routing.
    static let duplicateCheckPuzzleName = "The Bizarre Bookshop"
    /// Completed puzzle opened on the detail marketing screenshot.
    static let completedPuzzleName = "Paris in a Day"
    /// First seeded row in UI tests (`tapFirstSeededPuzzle`).
    static let primarySeededPuzzleName = duplicateCheckPuzzleName

    static func makePuzzles() -> [Puzzle] {
        [
            bizarreBookshopFixture(),
            canalCruiseFixture(),
            veniceRomanceFixture(),
            parisInADayFixture(),
            winterInCentralParkFixture(),
            starryNightFixture(),
            countryCottageFixture(),
            canalAtSunsetFixture(),
            yosemiteValleyFixture(),
            floralArchFixture(),
            underwaterParadiseFixture(),
            gradientLinesFixture(),
            mysteryAmusementParkFixture()
        ]
    }

    // MARK: - Featured fixtures (list + marketing)

    /// Ravensburger 1000 pc — Colin Thompson's cult favorite; duplicate-check demo target.
    private static func bizarreBookshopFixture() -> Puzzle {
        var puzzle = demoFixture(
            name: duplicateCheckPuzzleName,
            pieces: 1000,
            rating: .four,
            difficulty: .three
        )
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678905"
        puzzle.purchaseLocation = "Target"
        puzzle.releaseYear = 2019
        puzzle.puzzleType = .collage
        puzzle.material = .cardboard
        puzzle.puzzleShape = .rectangular
        puzzle.cutType = .grid
        puzzle.dimensionsText = "27 × 20 in"
        puzzle.purchasePrice = 24.99
        puzzle.purchaseCurrencyCode = "USD"
        puzzle.tags = ["books", "colin thompson", "cozy"]
        puzzle.notes = "Quirky book titles on every shelf — a fun Sunday build."
        applyPhotos(&puzzle, cover: "bizarre-bookshop-cover")
        return puzzle
    }

    /// Ravensburger 1000 pc — Grand Canal scene.
    private static func canalCruiseFixture() -> Puzzle {
        var puzzle = demoFixture(
            name: "Canal Cruise in Venice",
            pieces: 1000,
            rating: .five,
            difficulty: .three
        )
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678906"
        puzzle.purchaseLocation = "Amazon"
        puzzle.releaseYear = 2021
        puzzle.puzzleType = .landscape
        puzzle.material = .cardboard
        puzzle.puzzleShape = .rectangular
        puzzle.cutType = .grid
        puzzle.dimensionsText = "27 × 20 in"
        puzzle.purchasePrice = 22.99
        puzzle.purchaseCurrencyCode = "USD"
        puzzle.tags = ["venice", "travel", "europe"]
        applyPhotos(&puzzle, cover: "canal-cruise-venice-cover")
        return puzzle
    }

    /// Ravensburger 1000 pc — in-progress build on the puzzle table.
    private static func veniceRomanceFixture() -> Puzzle {
        var puzzle = demoFixture(
            name: "Venice Romance",
            pieces: 1000,
            rating: .two,
            difficulty: .four
        )
        puzzle.status = .inProgress
        puzzle.progressPercent = 45
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678907"
        puzzle.purchaseLocation = "Thrift store"
        puzzle.releaseYear = 2018
        puzzle.puzzleType = .landscape
        puzzle.material = .cardboard
        puzzle.puzzleShape = .rectangular
        puzzle.cutType = .grid
        puzzle.dimensionsText = "27 × 20 in"
        puzzle.purchasePrice = 6.00
        puzzle.purchaseCurrencyCode = "USD"
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 4, minutes: 30)
        puzzle.startDate = daysAgo(3)
        puzzle.tags = ["venice", "sunset", "travel"]
        applyPhotos(&puzzle, cover: "venice-romance-cover")
        return puzzle
    }

    /// Galison 1000 pc — Michael Storrings series; rich detail screen for screenshots.
    private static func parisInADayFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: completedPuzzleName,
            pieces: 1000,
            rating: .three,
            difficulty: .three,
            completedOn: dateInCurrentYear(month: 6, day: 18),
            startedDaysBefore: 5,
            hours: 8,
            minutes: 15
        )
        puzzle.source = "Galison"
        puzzle.barcode = "012345678908"
        puzzle.purchaseLocation = "Local bookshop"
        puzzle.releaseYear = 2022
        puzzle.puzzleType = .collage
        puzzle.disposition = .kept
        puzzle.dimensionsText = "20 × 27 in"
        puzzle.purchasePrice = 18.00
        puzzle.tags = ["paris", "michael storrings", "city"]
        puzzle.notes = "Gift from my sister — framed the box art after finishing."
        applyPhotos(&puzzle, cover: "paris-day-cover", gallery: ["paris-day-completed"])
        return puzzle
    }

    // MARK: - Stats showcase fixtures

    private static func winterInCentralParkFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: "Winter in Central Park",
            pieces: 500,
            rating: .fourHalf,
            difficulty: .two,
            completedOn: dateInCurrentYear(month: 1, day: 15),
            startedDaysBefore: 2,
            hours: 3,
            minutes: 10
        )
        puzzle.source = "Galison"
        puzzle.barcode = "012345678909"
        puzzle.purchaseLocation = "Local bookshop"
        puzzle.puzzleType = .landscape
        puzzle.purchasePrice = 16.99
        puzzle.tags = ["winter", "cozy", "city"]
        applyPhotos(&puzzle, cover: "bizarre-bookshop-cover")
        return puzzle
    }

    private static func starryNightFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: "Starry Night",
            pieces: 1000,
            rating: .five,
            difficulty: .four,
            completedOn: dateInCurrentYear(month: 2, day: 10),
            startedDaysBefore: 4,
            hours: 6,
            minutes: 45
        )
        puzzle.source = "Buffalo Games"
        puzzle.barcode = "012345678910"
        puzzle.purchaseLocation = "Target"
        puzzle.puzzleType = .other
        puzzle.purchasePrice = 14.99
        puzzle.tags = ["art", "classic"]
        applyPhotos(&puzzle, cover: "canal-cruise-venice-cover")
        return puzzle
    }

    private static func countryCottageFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: "Country Cottage",
            pieces: 750,
            rating: .four,
            difficulty: .three,
            completedOn: dateInCurrentYear(month: 3, day: 22),
            startedDaysBefore: 6,
            hours: 5,
            minutes: 20
        )
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678911"
        puzzle.purchaseLocation = "Amazon"
        puzzle.puzzleType = .landscape
        puzzle.purchasePrice = 19.99
        puzzle.tags = ["cozy", "cottage", "spring"]
        applyPhotos(&puzzle, cover: "venice-romance-cover")
        return puzzle
    }

    private static func canalAtSunsetFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: "Canal at Sunset",
            pieces: 1500,
            rating: .fourHalf,
            difficulty: .four,
            completedOn: dateInCurrentYear(month: 4, day: 25),
            startedDaysBefore: 10,
            hours: 14,
            minutes: 30
        )
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678912"
        puzzle.purchaseLocation = "Barnes & Noble"
        puzzle.puzzleType = .panoramic
        puzzle.purchasePrice = 29.99
        puzzle.tags = ["venice", "sunset", "travel"]
        applyPhotos(&puzzle, cover: "canal-cruise-venice-cover")
        return puzzle
    }

    private static func yosemiteValleyFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: "Yosemite Valley",
            pieces: 2000,
            rating: .five,
            difficulty: .five,
            completedOn: dateInCurrentYear(month: 5, day: 12),
            startedDaysBefore: 14,
            hours: 22,
            minutes: 0
        )
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678913"
        puzzle.purchaseLocation = "Amazon"
        puzzle.puzzleType = .landscape
        puzzle.purchasePrice = 34.99
        puzzle.tags = ["mountains", "nature", "national parks"]
        applyPhotos(&puzzle, cover: "paris-day-cover")
        return puzzle
    }

    private static func floralArchFixture() -> Puzzle {
        var puzzle = completedFixture(
            name: "Floral Arch",
            pieces: 300,
            rating: .threeHalf,
            difficulty: .one,
            completedOn: dateInCurrentYear(month: 6, day: 3),
            startedDaysBefore: 1,
            hours: 2,
            minutes: 0
        )
        puzzle.timesCompleted = 2
        puzzle.source = "Galison"
        puzzle.barcode = "012345678914"
        puzzle.purchaseLocation = "Target"
        puzzle.puzzleType = .collage
        puzzle.purchasePrice = 12.99
        puzzle.tags = ["flowers", "spring", "cozy"]
        applyPhotos(&puzzle, cover: "paris-day-completed")
        puzzle.completions = [
            PuzzleCompletion(
                completionNumber: 1,
                completedAt: dateInCurrentYear(month: 2, day: 20),
                rating: 3.0
            ),
            PuzzleCompletion(
                completionNumber: 2,
                completedAt: puzzle.completionDate,
                rating: 3.5
            )
        ]
        return puzzle
    }

    private static func underwaterParadiseFixture() -> Puzzle {
        var puzzle = demoFixture(
            name: "Underwater Paradise",
            pieces: 1000,
            rating: .none,
            difficulty: .three
        )
        puzzle.status = .inProgress
        puzzle.progressPercent = 62
        puzzle.source = "Ravensburger"
        puzzle.barcode = "012345678915"
        puzzle.purchaseLocation = "Amazon"
        puzzle.puzzleType = .other
        puzzle.purchasePrice = 21.99
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 6, minutes: 0)
        puzzle.startDate = daysAgo(7)
        puzzle.tags = ["ocean", "colorful"]
        applyPhotos(&puzzle, cover: "canal-cruise-venice-cover")
        return puzzle
    }

    private static func gradientLinesFixture() -> Puzzle {
        var puzzle = demoFixture(
            name: "Gradient Lines",
            pieces: 500,
            rating: .one,
            difficulty: .two
        )
        puzzle.status = .abandoned
        puzzle.progressPercent = 28
        puzzle.source = "Buffalo Games"
        puzzle.barcode = "012345678916"
        puzzle.purchaseLocation = "Thrift store"
        puzzle.puzzleType = .gradient
        puzzle.purchasePrice = 4.00
        puzzle.hasMissingPieces = true
        puzzle.notes = "Two edge pieces missing — donating the rest."
        puzzle.tags = ["abstract", "gradient"]
        applyPhotos(&puzzle, cover: "venice-romance-cover")
        return puzzle
    }

    private static func mysteryAmusementParkFixture() -> Puzzle {
        var puzzle = demoFixture(
            name: "Mystery Puzzle: Amusement Park",
            pieces: 1000,
            rating: .none,
            difficulty: .three
        )
        puzzle.status = .wishlist
        puzzle.source = "Ravensburger"
        puzzle.purchaseLocation = "Amazon"
        puzzle.puzzleType = .mystery
        puzzle.notes = "Save for summer — love the surprise reveal puzzles."
        puzzle.tags = ["mystery", "summer"]
        applyPhotos(&puzzle, cover: "bizarre-bookshop-cover")
        return puzzle
    }

    // MARK: - Helpers

    private static func demoFixture(
        name: String,
        pieces: Int,
        rating: Puzzle.Rating = .none,
        difficulty: Puzzle.Difficulty = .none
    ) -> Puzzle {
        let puzzle = Puzzle.fixture(name: name, pieces: pieces, rating: rating, difficulty: difficulty)
        puzzle.isDemo = true
        puzzle.purchaseCurrencyCode = puzzle.purchaseCurrencyCode ?? "USD"
        puzzle.material = .cardboard
        puzzle.puzzleShape = .rectangular
        puzzle.cutType = .grid
        return puzzle
    }

    private static func completedFixture(
        name: String,
        pieces: Int,
        rating: Puzzle.Rating,
        difficulty: Puzzle.Difficulty,
        completedOn: Date,
        startedDaysBefore: Int,
        hours: Int,
        minutes: Int = 0
    ) -> Puzzle {
        var puzzle = demoFixture(name: name, pieces: pieces, rating: rating, difficulty: difficulty)
        puzzle.status = .completed
        puzzle.progressPercent = 100
        puzzle.timesCompleted = 1
        puzzle.completionDate = completedOn
        puzzle.startDate = Calendar.current.date(byAdding: .day, value: -startedDaysBefore, to: completedOn)
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: hours, minutes: minutes)
        puzzle.disposition = .kept
        puzzle.completions = [
            PuzzleCompletion(
                completionNumber: 1,
                completedAt: completedOn,
                rating: rating == .none ? nil : rating.rawValue
            )
        ]
        return puzzle
    }

    private static func applyPhotos(_ puzzle: inout Puzzle, cover: String, gallery: [String] = []) {
        var names = [cover] + gallery
        puzzle.photos = DemoDataAssets.photos(named: names)
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    private static func dateInCurrentYear(month: Int, day: Int) -> Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
