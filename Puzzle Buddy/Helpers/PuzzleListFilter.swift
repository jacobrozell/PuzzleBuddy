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
            return "No puzzles match your search. Try a different name, brand, barcode, or clear the search field."
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

    func emptyStateMessage(hasSearchQuery: Bool, hasTagFilter: Bool) -> String {
        if hasTagFilter {
            return hasSearchQuery
                ? "No puzzles with this tag match your search."
                : "No puzzles use this tag yet."
        }
        return emptyStateMessage(hasSearchQuery: hasSearchQuery)
    }
}

// MARK: - PuzzleListPieceCountFilter

enum PuzzleListPieceCountFilter: String, CaseIterable, Identifiable {
    case any = "Any"
    case upTo500 = "≤500"
    case thousand = "1000"
    case atLeast1500 = "1500+"

    var id: String { rawValue }

    var title: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .any: return "Any piece count"
        case .upTo500: return "500 pieces or fewer"
        case .thousand: return "Around 1000 pieces"
        case .atLeast1500: return "1500 pieces or more"
        }
    }

    func matches(_ puzzle: Puzzle) -> Bool {
        guard let pieces = puzzle.pieces else { return false }
        switch self {
        case .any:
            return true
        case .upTo500:
            return pieces <= 500
        case .thousand:
            return (751...1249).contains(pieces)
        case .atLeast1500:
            return pieces >= 1500
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

    static func defaultFor(statusFilter: PuzzleListStatusFilter) -> PuzzleListSortOption {
        switch statusFilter {
        case .todo, .inProgress:
            return .name
        case .completed, .all:
            return .completionDate
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
        missingPiecesOnly: Bool = false,
        needsPhotoOnly: Bool = false,
        pieceCountFilter: PuzzleListPieceCountFilter = .any,
        tagFilter: String? = nil
    ) -> [Puzzle] {
        let statusFiltered = PuzzleListStatusFilter.filter(puzzles, by: statusFilter)
        let missingFiltered = filterMissingPieces(statusFiltered, missingPiecesOnly: missingPiecesOnly)
        let photoFiltered = filterNeedsPhoto(missingFiltered, needsPhotoOnly: needsPhotoOnly)
        let pieceFiltered = filterPieceCount(photoFiltered, pieceCountFilter: pieceCountFilter)
        let tagFiltered = PuzzleTagIndex.filter(pieceFiltered, matching: tagFilter)
        let searched = search(tagFiltered, query: searchText)
        return sort(searched, by: sortOption)
    }

    static func filterMissingPieces(_ puzzles: [Puzzle], missingPiecesOnly: Bool) -> [Puzzle] {
        guard missingPiecesOnly else { return puzzles }
        return puzzles.filter(\.hasMissingPieces)
    }

    static func filterNeedsPhoto(_ puzzles: [Puzzle], needsPhotoOnly: Bool) -> [Puzzle] {
        guard needsPhotoOnly else { return puzzles }
        return puzzles.filter { $0.image == nil }
    }

    static func filterPieceCount(
        _ puzzles: [Puzzle],
        pieceCountFilter: PuzzleListPieceCountFilter
    ) -> [Puzzle] {
        guard pieceCountFilter != .any else { return puzzles }
        return puzzles.filter { pieceCountFilter.matches($0) }
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
        missingPiecesOnly: Bool,
        needsPhotoOnly: Bool = false,
        pieceCountFilter: PuzzleListPieceCountFilter = .any,
        tagFilter: String? = nil
    ) -> Bool {
        statusFilter != .all
            || hasActiveSearch(searchText)
            || missingPiecesOnly
            || needsPhotoOnly
            || pieceCountFilter != .any
            || tagFilter != nil
    }

    static func search(_ puzzles: [Puzzle], query: String) -> [Puzzle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return puzzles }

        let normalizedQuery = trimmed.lowercased()
        let digitQuery = trimmed.filter(\.isNumber)

        return puzzles.filter { puzzle in
            if puzzle.name.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            if let source = puzzle.source, source.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            if matchesBarcode(puzzle.barcode, query: normalizedQuery, digitQuery: digitQuery) {
                return true
            }
            if puzzle.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) }) {
                return true
            }
            return false
        }
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

    private static func matchesBarcode(_ barcode: String?, query: String, digitQuery: String) -> Bool {
        guard let barcode, !barcode.isEmpty else { return false }
        let normalizedBarcode = barcode.lowercased()
        if normalizedBarcode.contains(query) {
            return true
        }
        guard !digitQuery.isEmpty else { return false }
        let barcodeDigits = barcode.filter(\.isNumber)
        return barcodeDigits.contains(digitQuery)
    }

    private static func difficultyValue(_ puzzle: Puzzle) -> Int {
        Int(puzzle.difficulty.rawValue) ?? 0
    }
}
