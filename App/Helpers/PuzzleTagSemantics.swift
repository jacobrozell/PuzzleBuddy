//
//  PuzzleTagSemantics.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleTagSemantics {
    static let maxTagsPerPuzzle = 10
    static let maxTagLength = 32

    static func normalized(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxTagLength))
    }

    static func sanitizedTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for tag in tags {
            guard let normalized = normalized(tag) else { continue }
            let key = normalized.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(normalized)
            if result.count >= maxTagsPerPuzzle { break }
        }

        return result
    }

    static func matches(_ tag: String, selected: String) -> Bool {
        guard let left = normalized(tag), let right = normalized(selected) else { return false }
        return left.caseInsensitiveCompare(right) == .orderedSame
    }

    static func contains(_ tags: [String], matching selected: String) -> Bool {
        tags.contains { matches($0, selected: selected) }
    }
}

struct PuzzleTagCount: Equatable, Identifiable {
    let name: String
    let count: Int

    var id: String { name.lowercased() }
}

enum PuzzleTagIndex {
    static func counts(from puzzles: [Puzzle], limit: Int = 20) -> [PuzzleTagCount] {
        var frequencies: [String: (display: String, count: Int)] = [:]

        for puzzle in puzzles {
            for tag in puzzle.tags {
                guard let normalized = PuzzleTagSemantics.normalized(tag) else { continue }
                let key = normalized.lowercased()
                if let existing = frequencies[key] {
                    frequencies[key] = (existing.display, existing.count + 1)
                } else {
                    frequencies[key] = (normalized, 1)
                }
            }
        }

        return frequencies.values
            .map { PuzzleTagCount(name: $0.display, count: $0.count) }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    static func allTagNames(from puzzles: [Puzzle]) -> [String] {
        counts(from: puzzles, limit: Int.max).map(\.name)
    }

    static func suggestedTags(
        excluding existing: [String],
        from puzzles: [Puzzle],
        limit: Int = 8
    ) -> [String] {
        matchingTags(
            query: "",
            excluding: existing,
            fromCatalog: allTagNames(from: puzzles),
            limit: limit
        )
    }

    static func matchingTags(
        query: String,
        excluding existing: [String],
        fromCatalog catalog: [String],
        limit: Int = 8
    ) -> [String] {
        let excluded = Set(existing.map { $0.lowercased() })
        let available = catalog.filter { !excluded.contains($0.lowercased()) }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let candidates: [String]
        if trimmed.isEmpty {
            candidates = available
        } else {
            candidates = available.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        }

        return Array(candidates.prefix(limit))
    }

    static func filteredCounts(
        _ tags: [PuzzleTagCount],
        matching query: String
    ) -> [PuzzleTagCount] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return tags }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    static func filter(_ puzzles: [Puzzle], matching selectedTag: String?) -> [Puzzle] {
        guard let selectedTag, let normalized = PuzzleTagSemantics.normalized(selectedTag) else {
            return puzzles
        }
        return puzzles.filter { PuzzleTagSemantics.contains($0.tags, matching: normalized) }
    }
}
