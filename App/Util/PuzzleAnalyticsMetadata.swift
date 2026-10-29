//
//  PuzzleAnalyticsMetadata.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleAddSource: String {
    case manual
    case barcode
    case `import`
    case demo
}

enum PuzzleAnalyticsMetadata {
    static func pieceCountBucket(for pieces: Int?) -> String {
        guard let pieces else { return "unknown" }
        switch pieces {
        case ...500: return "under_500"
        case 501...749: return "500"
        case 750...1499: return "1000"
        default: return "1500_plus"
        }
    }

    static func pieceCountBucket(for filter: PuzzleListPieceCountFilter) -> String {
        switch filter {
        case .any: return "any"
        case .upTo500: return "under_500"
        case .thousand: return "1000"
        case .atLeast1500: return "1500_plus"
        }
    }

    static func ratingBucket(for rating: Puzzle.Rating) -> String {
        guard rating != .none else { return "none" }
        let stars = Int(rating.rawValue.rounded(.down))
        switch stars {
        case 1, 2: return "1_2"
        case 3: return "3"
        case 4: return "4"
        default: return "5"
        }
    }

    static func hasPhoto(for puzzle: Puzzle) -> Bool {
        puzzle.coverImage != nil || !puzzle.photos.filter { $0.image != nil }.isEmpty
    }

    static func photoCount(for puzzle: Puzzle) -> Int {
        let fromGallery = puzzle.photos.filter { $0.image != nil }.count
        if fromGallery > 0 { return min(fromGallery, PuzzlePhotoLimits.maxCount) }
        return puzzle.coverImage != nil ? 1 : 0
    }

    static func puzzleTypeLabel(for puzzle: Puzzle) -> String {
        puzzle.puzzleType == .none ? "None" : puzzle.puzzleType.rawValue
    }

    static func metadata(for puzzle: Puzzle, addSource: PuzzleAddSource? = nil) -> [String: String] {
        var values: [String: String] = [
            "puzzle_status": puzzle.status.rawValue,
            "piece_count_bucket": pieceCountBucket(for: puzzle.pieces),
            "has_photo": hasPhoto(for: puzzle) ? "true" : "false",
            "photo_count": "\(photoCount(for: puzzle))",
        ]
        if let addSource {
            values["add_source"] = addSource.rawValue
        }
        return values
    }

    static func completionMetadata(for puzzle: Puzzle, completionNumber: Int) -> [String: String] {
        var values = metadata(for: puzzle)
        values["completion_number"] = "\(completionNumber)"
        values["puzzle_type"] = puzzleTypeLabel(for: puzzle)
        values["difficulty"] = puzzle.difficulty.rawValue
        values["rating_bucket"] = ratingBucket(for: puzzle.rating)
        values["has_missing_pieces"] = puzzle.hasMissingPieces ? "true" : "false"
        return values
    }

    /// Coarse collection size for user properties and session snapshots (not exact counts).
    static func collectionSizeBucket(_ count: Int) -> String {
        switch max(0, count) {
        case 0: return "0"
        case 1: return "1"
        case 2...5: return "2_5"
        case 6...20: return "6_20"
        case 21...50: return "21_50"
        default: return "51_plus"
        }
    }

    static func completedCountBucket(_ count: Int) -> String {
        switch max(0, count) {
        case 0: return "0"
        case 1: return "1"
        case 2...5: return "2_5"
        default: return "6_plus"
        }
    }

    /// `nil` means no prior open recorded (true first session for analytics).
    static func daysSinceLastOpenBucket(days: Int?) -> String {
        guard let days else { return "first_open" }
        switch max(0, days) {
        case 0: return "0"
        case 1: return "1"
        case 2...7: return "2_7"
        case 8...30: return "8_30"
        default: return "31_plus"
        }
    }

    static func collectionSnapshotMetadata(for puzzles: [Puzzle]) -> [String: String] {
        let wishlist = puzzles.filter { $0.status == .wishlist }.count
        let todo = puzzles.filter { $0.status == .todo }.count
        let inProgress = puzzles.filter { $0.status == .inProgress }.count
        let completed = puzzles.filter { $0.status == .completed }.count
        let abandoned = puzzles.filter { $0.status == .abandoned }.count
        return [
            "puzzle_count": "\(puzzles.count)",
            "count_wishlist": "\(wishlist)",
            "count_todo": "\(todo)",
            "count_in_progress": "\(inProgress)",
            "count_completed": "\(completed)",
            "count_abandoned": "\(abandoned)",
            "collection_size_bucket": collectionSizeBucket(puzzles.count),
            "completed_count_bucket": completedCountBucket(completed),
        ]
    }
}
