//
//  PuzzleListFilter.swift
//  Puzzle Buddy
//

import Foundation

// MARK: - PuzzleListStatusFilter

enum PuzzleListStatusFilter: String, CaseIterable, Identifiable {
    case todo = "To-Do"
    case inProgress = "In-Progress"
    case completed = "Completed"
    case all = "All"

    var id: String { rawValue }

    var title: String { rawValue }

    func matches(_ puzzle: Puzzle) -> Bool {
        switch self {
        case .todo:
            return puzzle.status == .todo
        case .inProgress:
            return puzzle.status == .inProgress
        case .completed:
            return puzzle.status == .completed
        case .all:
            return true
        }
    }

    static func filter(_ puzzles: [Puzzle], by statusFilter: PuzzleListStatusFilter) -> [Puzzle] {
        puzzles.filter { statusFilter.matches($0) }
    }

    func emptyStateMessage(hasSearchQuery: Bool) -> String {
        if hasSearchQuery {
            return "No puzzles match your search. Try a different name or clear the search field."
        }
        switch self {
        case .todo:
            return "No puzzles on your shelf. Add a To-Do puzzle or switch to All."
        case .inProgress:
            return "Nothing on the table right now. Move a puzzle to In-Progress when you start."
        case .completed:
            return "No completed puzzles yet. Finish one and mark it Completed."
        case .all:
            return "No puzzles yet. Tap Add puzzle to start your collection."
        }
    }
}

// MARK: - PuzzleListSortOption

enum PuzzleListSortOption: String, CaseIterable, Identifiable {
    case completionDate = "Date"
    case name = "Name"
    case rating = "Rating"
    case difficulty = "Difficulty"
    case pieces = "Pieces"

    var id: String { rawValue }

    var title: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .completionDate: return "Sort by completion date, newest first"
        case .name: return "Sort by name, A to Z"
        case .rating: return "Sort by rating, highest first"
        case .difficulty: return "Sort by difficulty, highest first"
        case .pieces: return "Sort by piece count, largest first"
        }
    }
}

// MARK: - PuzzleListQuery

enum PuzzleListQuery {
    static func apply(
        puzzles: [Puzzle],
        statusFilter: PuzzleListStatusFilter,
        searchText: String,
        sortOption: PuzzleListSortOption,
        missingPiecesOnly: Bool = false
    ) -> [Puzzle] {
        let statusFiltered = PuzzleListStatusFilter.filter(puzzles, by: statusFilter)
        let missingFiltered = filterMissingPieces(statusFiltered, missingPiecesOnly: missingPiecesOnly)
        let searched = search(missingFiltered, query: searchText)
        return sort(searched, by: sortOption)
    }

    static func filterMissingPieces(_ puzzles: [Puzzle], missingPiecesOnly: Bool) -> [Puzzle] {
        guard missingPiecesOnly else { return puzzles }
        return puzzles.filter(\.hasMissingPieces)
    }

    static func resultCountLabel(
        displayedCount: Int,
        totalCount: Int,
        hasActiveFilters: Bool
    ) -> String {
        guard totalCount > 0 else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let total = formatter.string(from: NSNumber(value: totalCount)) ?? "\(totalCount)"
        guard hasActiveFilters, displayedCount != totalCount else {
            return "\(total) puzzles"
        }
        let shown = formatter.string(from: NSNumber(value: displayedCount)) ?? "\(displayedCount)"
        return "Showing \(shown) of \(total)"
    }

    static func hasActiveFilters(
        statusFilter: PuzzleListStatusFilter,
        searchText: String,
        missingPiecesOnly: Bool
    ) -> Bool {
        statusFilter != .all || hasActiveSearch(searchText) || missingPiecesOnly
    }

    static func search(_ puzzles: [Puzzle], query: String) -> [Puzzle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return puzzles }
        return puzzles.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    static func sort(_ puzzles: [Puzzle], by option: PuzzleListSortOption) -> [Puzzle] {
        switch option {
        case .completionDate:
            return puzzles.sorted { $0.completionDate > $1.completionDate }
        case .name:
            return puzzles.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .rating:
            return puzzles.sorted { $0.rating.rawValue > $1.rating.rawValue }
        case .difficulty:
            return puzzles.sorted {
                difficultyValue($0) > difficultyValue($1)
            }
        case .pieces:
            return puzzles.sorted { ($0.pieces ?? -1) > ($1.pieces ?? -1) }
        }
    }

    static func hasActiveSearch(_ searchText: String) -> Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func difficultyValue(_ puzzle: Puzzle) -> Int {
        Int(puzzle.difficulty.rawValue) ?? 0
    }
}
