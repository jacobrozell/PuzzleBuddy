//
//  PuzzleStore.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import SwiftData
import SwiftUI

// MARK: - PuzzleStore
@MainActor
class PuzzleStore: ObservableObject {
    enum PuzzleStoreState {
        case idle
        case fetching
        case done
    }

    @Published var puzzles: [Puzzle] = []
    @Published var state: PuzzleStoreState = .idle

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.puzzles = []

        if UITestSupport.shouldSeedPuzzles {
            clearAllLocalRecords()
            do {
                try loadDemoPuzzles()
            } catch {
                AppLog.shared.warning(
                    .puzzles,
                    eventName: "demo_data_seed_failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    func fetchPuzzles() async {
        loadLocalPuzzles()
    }

    func findPuzzle(matchingBarcode barcode: String?, excludingID: UUID? = nil) -> Puzzle? {
        PuzzleDuplicateChecker.findDuplicate(
            barcode: barcode,
            excludingID: excludingID,
            in: puzzles
        )
    }

    @discardableResult
    func importPuzzles(_ incoming: [Puzzle]) throws -> PuzzleImportSummary {
        var summary = PuzzleImportSummary()

        for var puzzle in incoming {
            let trimmedName = puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                summary.skippedInvalid += 1
                continue
            }
            puzzle.name = trimmedName

            do {
                try add(puzzle: puzzle)
                summary.imported += 1
            } catch {
                if case PuzzleStoreError.duplicateBarcode = error {
                    summary.skippedDuplicates += 1
                } else {
                    summary.skippedInvalid += 1
                    if summary.errors.count < 5 {
                        summary.errors.append(error.localizedDescription)
                    }
                }
            }
        }

        if summary.imported > 0 {
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_import_completed",
                message: "Imported puzzles from file.",
                metadata: [
                    "puzzle_count": "\(summary.imported)",
                    "puzzle_status": "imported"
                ]
            )
        }

        return summary
    }

    func add(puzzle: Puzzle) throws {
        try addLocally(puzzle: puzzle)
    }

    private func addLocally(puzzle: Puzzle) throws {
        try validateBarcodeUniqueness(for: puzzle)
        let record = PuzzleRecord(from: puzzle)
        modelContext.insert(record)
        try modelContext.save()
        puzzles.append(puzzle)
        BarcodeMetadataCache.store(from: puzzle)
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_added",
            message: "Puzzle saved.",
            metadata: ["puzzle_status": puzzle.status.rawValue]
        )
    }

    func delete(at offsets: IndexSet) {
        deleteLocally(at: offsets)
        AppLog.shared.info(.puzzles, eventName: "puzzle_deleted", message: "Puzzle deleted.")
    }

    private func deleteLocally(at offsets: IndexSet) {
        for index in offsets {
            let puzzle = puzzles[index]
            if let record = fetchRecord(id: puzzle.id) {
                modelContext.delete(record)
            }
        }
        puzzles.remove(atOffsets: offsets)
        try? modelContext.save()
    }

    func update(puzzle: Puzzle) throws {
        try updateLocally(puzzle: puzzle)
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_updated",
            message: "Puzzle updated.",
            metadata: ["puzzle_status": puzzle.status.rawValue]
        )
    }

    private func loadLocalPuzzles() {
        state = .fetching

        do {
            let descriptor = FetchDescriptor<PuzzleRecord>(
                sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
            )
            puzzles = try modelContext.fetch(descriptor).map { $0.toPuzzle() }
            BarcodeMetadataCache.warmCache(from: puzzles)
            state = .done
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_list_refreshed",
                message: "Loaded local puzzles.",
                metadata: ["puzzle_count": "\(puzzles.count)"]
            )
        } catch {
            state = .idle
            AppLog.shared.warning(.puzzles, eventName: "puzzle_load_failed", message: error.localizedDescription)
        }
    }

    var demoPuzzleCount: Int {
        puzzles.filter(\.isDemo).count
    }

    func clearAllPuzzles() throws {
        let records = try modelContext.fetch(FetchDescriptor<PuzzleRecord>())
        records.forEach { modelContext.delete($0) }
        try modelContext.save()
        puzzles = []
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_collection_cleared",
            message: "Cleared all local puzzles."
        )
    }

    func loadDemoPuzzles() throws {
        for puzzle in DemoDataCatalog.makePuzzles() {
            try add(puzzle: puzzle)
        }
        AppLog.shared.info(
            .puzzles,
            eventName: "demo_data_loaded",
            message: "Loaded demo puzzles.",
            metadata: ["puzzle_count": "\(demoPuzzleCount)"]
        )
    }

    func removeDemoPuzzles() throws {
        let demoIndices = puzzles.enumerated().compactMap { index, puzzle in
            puzzle.isDemo ? index : nil
        }
        guard !demoIndices.isEmpty else { return }

        delete(at: IndexSet(demoIndices))
        AppLog.shared.info(
            .puzzles,
            eventName: "demo_data_removed",
            message: "Removed demo puzzles.",
            metadata: ["removed_count": "\(demoIndices.count)"]
        )
    }

    private func clearAllLocalRecords() {
        try? clearAllPuzzles()
    }

    private func updateLocally(puzzle: Puzzle) throws {
        try validateBarcodeUniqueness(for: puzzle)
        guard let record = fetchRecord(id: puzzle.id) else { return }
        record.apply(from: puzzle)
        if let index = puzzles.firstIndex(where: { $0.id == puzzle.id }) {
            puzzles[index] = puzzle
        }
        BarcodeMetadataCache.store(from: puzzle)
        try modelContext.save()
    }

    private func validateBarcodeUniqueness(for puzzle: Puzzle) throws {
        puzzle.barcode = BarcodeNormalizer.normalize(puzzle.barcode)
        if let duplicate = findPuzzle(matchingBarcode: puzzle.barcode, excludingID: puzzle.id) {
            throw PuzzleStoreError.duplicateBarcode(
                existingPuzzleName: duplicate.name,
                barcode: puzzle.barcode ?? ""
            )
        }
    }

    private func fetchRecord(id: UUID) -> PuzzleRecord? {
        let puzzleID = id
        var descriptor = FetchDescriptor<PuzzleRecord>(
            predicate: #Predicate { $0.id == puzzleID }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
