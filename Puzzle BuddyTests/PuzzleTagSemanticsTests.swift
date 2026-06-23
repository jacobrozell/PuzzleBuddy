//
//  PuzzleTagSemanticsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleTagSemanticsTests: XCTestCase {
    func testNormalizedTrimsAndCapsLength() {
        let long = String(repeating: "a", count: 40)
        XCTAssertEqual(PuzzleTagSemantics.normalized("  cozy  "), "cozy")
        XCTAssertEqual(PuzzleTagSemantics.normalized(long)?.count, PuzzleTagSemantics.maxTagLength)
        XCTAssertNil(PuzzleTagSemantics.normalized("   "))
    }

    func testSanitizedTagsDedupesCaseInsensitively() {
        let tags = PuzzleTagSemantics.sanitizedTags(["Cozy", "cozy", " Winter ", "winter"])
        XCTAssertEqual(tags, ["Cozy", "Winter"])
    }

    func testSanitizedTagsEnforcesMaxCount() {
        let raw = (1...12).map { "tag\($0)" }
        XCTAssertEqual(PuzzleTagSemantics.sanitizedTags(raw).count, PuzzleTagSemantics.maxTagsPerPuzzle)
    }

    func testMatchesIsCaseInsensitive() {
        XCTAssertTrue(PuzzleTagSemantics.matches("Cozy", selected: "cozy"))
        XCTAssertFalse(PuzzleTagSemantics.matches("Cozy", selected: "winter"))
    }

    func testTagIndexCountsAndFilters() {
        let first = Puzzle.fixture(name: "A", pieces: 500)
        first.tags = ["Cozy", "Winter"]
        let second = Puzzle.fixture(name: "B", pieces: 500)
        second.tags = ["cozy"]

        let counts = PuzzleTagIndex.counts(from: [first, second])
        XCTAssertEqual(counts.first?.name, "Cozy")
        XCTAssertEqual(counts.first?.count, 2)

        let filtered = PuzzleTagIndex.filter([first, second], matching: "winter")
        XCTAssertEqual(filtered.map(\.name), ["A"])
    }

    func testSuggestedTagsExcludesExisting() {
        let puzzle = Puzzle.fixture(name: "A", pieces: 500)
        puzzle.tags = ["Cozy"]
        let other = Puzzle.fixture(name: "B", pieces: 500)
        other.tags = ["Winter", "Gift"]

        let suggestions = PuzzleTagIndex.suggestedTags(
            excluding: puzzle.tags,
            from: [puzzle, other]
        )
        XCTAssertEqual(Set(suggestions), Set(["Winter", "Gift"]))
    }

    func testMatchingTagsFiltersByQuery() {
        let catalog = ["Cozy", "Winter", "Wysocki", "Gift"]

        XCTAssertEqual(
            PuzzleTagIndex.matchingTags(query: "wys", excluding: [], fromCatalog: catalog),
            ["Wysocki"]
        )
        XCTAssertEqual(
            PuzzleTagIndex.matchingTags(query: "", excluding: ["Cozy"], fromCatalog: catalog, limit: 2),
            ["Winter", "Wysocki"]
        )
    }

    func testFilteredCountsMatchesQuery() {
        let tags = [
            PuzzleTagCount(name: "Cozy", count: 3),
            PuzzleTagCount(name: "Winter", count: 2),
            PuzzleTagCount(name: "Wysocki", count: 1)
        ]

        XCTAssertEqual(
            PuzzleTagIndex.filteredCounts(tags, matching: "win").map(\.name),
            ["Winter"]
        )
        XCTAssertEqual(PuzzleTagIndex.filteredCounts(tags, matching: "").count, 3)
    }
}
