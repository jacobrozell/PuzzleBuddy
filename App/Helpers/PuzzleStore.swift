//
//  PuzzleStore.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import SwiftData
import SwiftUI
import UIKit

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
    @Published private(set) var pendingCompletionUndo: CompletionUndoSnapshot?

    let friends: FriendStore
    private let modelContext: ModelContext
    private var didRunLegacyPhotoMigration = false

    #if DEBUG
    /// Test seam: next mutation that saves will throw `PuzzleStoreError.saveFailed`.
    static var forcesNextSaveFailure = false
    #endif

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.friends = FriendStore(modelContext: modelContext)
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
                try add(puzzle: puzzle, source: .import)
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

    @discardableResult
    func importBackup(
        _ incoming: [Puzzle],
        friends: [Friend] = [],
        policy: PuzzleBackupImportPolicy,
        preSkippedInvalid: Int = 0
    ) throws -> PuzzleImportSummary {
        var summary = PuzzleImportSummary(source: .jsonBackup)
        summary.skippedInvalid = preSkippedInvalid

        var candidates: [Puzzle] = []
        for var puzzle in incoming {
            let trimmedName = puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                summary.skippedInvalid += 1
                continue
            }
            puzzle.name = trimmedName
            candidates.append(puzzle)
        }

        if policy == .replaceAll {
            guard !candidates.isEmpty || incoming.isEmpty else {
                return summary
            }
            try clearAllPuzzles()
        }

        for friend in friends {
            try self.friends.upsert(friend)
        }
        self.friends.reload()

        let existingIDs = Set(puzzles.map(\.id))
        var seenIDs = existingIDs

        for puzzle in candidates {
            if policy == .mergeSkipExistingIDs, seenIDs.contains(puzzle.id) {
                summary.skippedExisting += 1
                continue
            }

            do {
                try addFromBackup(puzzle: puzzle)
                seenIDs.insert(puzzle.id)
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
                eventName: "puzzle_backup_restored",
                message: "Restored puzzles from JSON backup.",
                metadata: [
                    "puzzle_count": "\(summary.imported)",
                    "import_policy": policy == .replaceAll ? "replace_all" : "merge"
                ]
            )
        }

        return summary
    }

    func add(puzzle: Puzzle, source: PuzzleAddSource = .manual) throws {
        try addLocally(puzzle: puzzle, source: source)
    }

    private func addLocally(puzzle: Puzzle, source: PuzzleAddSource) throws {
        try validateBarcodeUniqueness(for: puzzle)
        var puzzle = puzzle
        try prepareLoanFields(&puzzle)
        puzzle.prepareForPersistence()
        let record = PuzzleRecord(from: puzzle)
        modelContext.insert(record)
        do {
            try syncPhotos(for: puzzle)
            if puzzle.status == .completed {
                try appendCompletion(for: puzzle)
            }
            try saveContext()
            puzzles.append(puzzleFromRecord(record))
            BarcodeMetadataCache.store(from: puzzle)
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_added",
                message: "Puzzle saved.",
                metadata: PuzzleAnalyticsMetadata.metadata(for: puzzle, addSource: source)
            )
            AnalyticsMilestones.logCollectionSizeMilestones(puzzleCount: puzzles.count)
            AnalyticsUserContext.syncCollection(from: puzzles)
        } catch {
            modelContext.rollback()
            loadLocalPuzzles()
            throw error
        }
    }

    private func addFromBackup(puzzle: Puzzle) throws {
        try validateBarcodeUniqueness(for: puzzle)
        var puzzle = puzzle
        try prepareLoanFields(&puzzle, createMissingFriends: false)
        puzzle.prepareForPersistence()
        let record = PuzzleRecord(from: puzzle)
        modelContext.insert(record)
        try syncPhotos(for: puzzle)
        try syncCompletions(for: puzzle)
        try saveContext()
        puzzles.append(puzzleFromRecord(record))
        BarcodeMetadataCache.store(from: puzzle)
    }

    func delete(at offsets: IndexSet) throws {
        try deleteLocally(at: offsets)
        AppLog.shared.info(.puzzles, eventName: "puzzle_deleted", message: "Puzzle deleted.")
    }

    private func deleteLocally(at offsets: IndexSet) throws {
        for index in offsets {
            let puzzle = puzzles[index]
            if let record = fetchRecord(id: puzzle.id) {
                deleteRelatedRecords(puzzleID: puzzle.id)
                modelContext.delete(record)
            }
        }
        puzzles.remove(atOffsets: offsets)
        try saveContext()
    }

    func update(puzzle: Puzzle) throws {
        let previousStatus = puzzles.first(where: { $0.id == puzzle.id })?.status
        try updateLocally(puzzle: puzzle)
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_updated",
            message: "Puzzle updated.",
            metadata: PuzzleAnalyticsMetadata.metadata(for: puzzle)
        )
        if let previousStatus, previousStatus != puzzle.status {
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_status_changed",
                message: "Puzzle status changed.",
                metadata: [
                    "status_from": previousStatus.rawValue,
                    "status_to": puzzle.status.rawValue,
                    "piece_count_bucket": PuzzleAnalyticsMetadata.pieceCountBucket(for: puzzle.pieces)
                ]
            )
        }
    }

    func startRedo(puzzle: Puzzle) throws {
        guard puzzle.status == .completed else { return }
        var puzzle = puzzle
        puzzle.status = .inProgress
        puzzle.progressPercent = 0
        puzzle.startDate = Date()
        // Keep completionDate as the latest finish so history, sort, and stats stay accurate.
        clearPendingUndo(for: puzzle.id)
        try update(puzzle: puzzle)
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_redo_started",
            message: "Started puzzle again.",
            metadata: ["completion_count": "\(puzzle.timesCompleted)"]
        )
    }

    func markReturned(puzzle: Puzzle) throws {
        guard puzzle.isOnLoan else { return }
        var puzzle = puzzle
        PuzzleLoanSemantics.clearLoan(on: puzzle)
        try update(puzzle: puzzle)
        AppLog.shared.info(.puzzles, eventName: "puzzle_marked_returned", message: "Puzzle marked returned.")
    }

    /// Removes one completion log. When deleting the last log on a completed puzzle,
    /// pass `statusIfRemovingLast` (e.g. `.inProgress` or `.todo`).
    func deleteCompletion(
        puzzleID: UUID,
        completionID: UUID,
        statusIfRemovingLast: Puzzle.Status? = nil,
        logDeletedEvent: Bool = true
    ) throws {
        guard fetchRecord(id: puzzleID) != nil else {
            throw PuzzleStoreError.recordNotFound
        }
        guard fetchCompletionRecord(id: completionID, puzzleID: puzzleID) != nil else {
            throw PuzzleStoreError.completionNotFound
        }

        let recordsBeforeDelete = fetchCompletionRecords(puzzleID: puzzleID)
        let isRemovingLast = recordsBeforeDelete.count == 1
        let removedNumber = recordsBeforeDelete.first(where: { $0.id == completionID })?.completionNumber

        if isRemovingLast,
           let record = fetchRecord(id: puzzleID),
           Puzzle.Status(rawValue: record.status) == .completed,
           statusIfRemovingLast == nil {
            throw PuzzleStoreError.statusRequiredAfterRemovingLastCompletion
        }

        if let record = fetchCompletionRecord(id: completionID, puzzleID: puzzleID) {
            modelContext.delete(record)
        }

        try reconcileCompletions(for: puzzleID, statusIfEmpty: statusIfRemovingLast)
        clearPendingUndo(ifMatching: completionID)

        if logDeletedEvent {
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_completion_deleted",
                message: "Removed puzzle completion log.",
                metadata: [
                    "completion_number": removedNumber.map { "\($0)" } ?? "0"
                ]
            )
        }
    }

    func undoLastCompletion(puzzleID: UUID, now: Date = Date()) throws {
        guard let snapshot = pendingCompletionUndo, snapshot.puzzleID == puzzleID else {
            throw PuzzleStoreError.completionUndoUnavailable
        }
        guard snapshot.isActive(now: now) else {
            pendingCompletionUndo = nil
            throw PuzzleStoreError.completionUndoUnavailable
        }

        let recordsBeforeDelete = fetchCompletionRecords(puzzleID: puzzleID)
        let isRemovingLast = recordsBeforeDelete.count == 1
        let removedNumber = recordsBeforeDelete.first(where: { $0.id == snapshot.completionID })?.completionNumber

        try deleteCompletion(
            puzzleID: puzzleID,
            completionID: snapshot.completionID,
            statusIfRemovingLast: snapshot.previousStatus,
            logDeletedEvent: false
        )

        if isRemovingLast, let record = fetchRecord(id: puzzleID) {
            record.status = snapshot.previousStatus.rawValue
            record.progressPercent = snapshot.previousProgressPercent
            if let index = puzzles.firstIndex(where: { $0.id == puzzleID }) {
                puzzles[index] = puzzleFromRecord(record)
            }
            try saveContext()
        }

        pendingCompletionUndo = nil
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_completion_undone",
            message: "Undid accidental puzzle completion.",
            metadata: [
                "completion_number": removedNumber.map { "\($0)" } ?? "0"
            ]
        )
    }

    func activeCompletionUndo(for puzzleID: UUID, now: Date = Date()) -> CompletionUndoSnapshot? {
        CompletionUndoSemantics.activeSnapshot(
            pendingCompletionUndo,
            puzzleID: puzzleID,
            now: now
        )
    }

    func dismissCompletionUndo(for puzzleID: UUID) {
        guard pendingCompletionUndo?.puzzleID == puzzleID else { return }
        pendingCompletionUndo = nil
    }

    /// Updates an existing completion log in place (SwiftData row), then renumbers if dates shifted.
    func updateCompletion(puzzleID: UUID, completion: PuzzleCompletion) throws {
        guard let record = fetchCompletionRecord(id: completion.id, puzzleID: puzzleID) else {
            throw PuzzleStoreError.completionNotFound
        }

        record.completedAt = completion.completedAt
        record.startedAt = completion.startedAt
        record.timeSpentHours = completion.timeSpentHours
        record.timeSpentMinutes = completion.timeSpentMinutes
        record.rating = completion.rating

        PuzzleCompletionSemantics.renumberRecords(fetchCompletionRecords(puzzleID: puzzleID))
        try reconcileCompletions(for: puzzleID, statusIfEmpty: nil)
        clearPendingUndo(ifMatching: completion.id)

        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_completion_updated",
            message: "Updated puzzle completion log.",
            metadata: ["completion_number": "\(completion.completionNumber)"]
        )
    }

    private func loadLocalPuzzles() {
        state = .fetching

        do {
            if !didRunLegacyPhotoMigration {
                try migrateLegacyCoverPhotosIfNeeded()
                didRunLegacyPhotoMigration = true
            }

            let descriptor = FetchDescriptor<PuzzleRecord>(
                sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
            )
            puzzles = try modelContext.fetch(descriptor).map { puzzleFromRecord($0) }
            friends.reload()
            BarcodeMetadataCache.warmCache(from: puzzles)
            state = .done
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_list_refreshed",
                message: "Loaded local puzzles.",
                metadata: PuzzleAnalyticsMetadata.collectionSnapshotMetadata(for: puzzles)
            )
            AnalyticsSessionContext.logSnapshotIfNeeded(puzzles: puzzles)
        } catch {
            state = .idle
            AppLog.shared.warning(.puzzles, eventName: "puzzle_load_failed", message: error.localizedDescription)
        }
    }

    var demoPuzzleCount: Int {
        puzzles.filter(\.isDemo).count
    }

    func clearAllPuzzles() throws {
        try modelContext.fetch(FetchDescriptor<PuzzlePhotoRecord>()).forEach { modelContext.delete($0) }
        try modelContext.fetch(FetchDescriptor<PuzzleCompletionRecord>()).forEach { modelContext.delete($0) }
        let records = try modelContext.fetch(FetchDescriptor<PuzzleRecord>())
        records.forEach { modelContext.delete($0) }
        try saveContext()
        puzzles = []
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_collection_cleared",
            message: "Cleared all local puzzles."
        )
    }

    func loadDemoPuzzles() throws {
        for puzzle in DemoDataCatalog.makePuzzles() {
            try add(puzzle: puzzle, source: .demo)
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
        if !demoIndices.isEmpty {
            try delete(at: IndexSet(demoIndices))
        }
        try friends.removeDemoFriends()
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
        guard let record = fetchRecord(id: puzzle.id) else {
            throw PuzzleStoreError.recordNotFound
        }

        let previousStatus = Puzzle.Status(rawValue: record.status) ?? .todo
        let previousProgressPercent = record.progressPercent
        var puzzle = puzzle
        try prepareLoanFields(&puzzle)
        puzzle.prepareForPersistence()
        record.apply(from: puzzle)

        do {
            if puzzle.status == .completed && previousStatus != .completed {
                let completionID = try appendCompletion(for: puzzle)
                pendingCompletionUndo = CompletionUndoSemantics.snapshot(
                    puzzleID: puzzle.id,
                    completionID: completionID,
                    previousStatus: previousStatus,
                    previousProgressPercent: previousProgressPercent
                )
            }

            try syncPhotos(for: puzzle)

            if let index = puzzles.firstIndex(where: { $0.id == puzzle.id }) {
                puzzles[index] = puzzleFromRecord(record)
            }
            BarcodeMetadataCache.store(from: puzzle)
            try saveContext()
        } catch {
            modelContext.rollback()
            loadLocalPuzzles()
            throw error
        }
    }

    @discardableResult
    private func appendCompletion(for puzzle: Puzzle) throws -> UUID {
        let existing = fetchCompletionRecords(puzzleID: puzzle.id)
        let nextNumber = (existing.map(\.completionNumber).max() ?? 0) + 1
        let completion = PuzzleCompletionSemantics.makeCompletion(from: puzzle, number: nextNumber)
        modelContext.insert(PuzzleCompletionRecord(from: completion, puzzleID: puzzle.id))
        if let record = fetchRecord(id: puzzle.id) {
            record.timesCompleted = nextNumber
        }
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_completion_recorded",
            message: "Recorded puzzle completion.",
            metadata: PuzzleAnalyticsMetadata.completionMetadata(for: puzzle, completionNumber: nextNumber)
        )
        var completedCount = puzzles.filter { $0.status == .completed }.count
        if !puzzles.contains(where: { $0.id == puzzle.id && $0.status == .completed }) {
            completedCount += 1
        }
        AnalyticsMilestones.logCompletionMilestones(completedCount: completedCount)
        AnalyticsUserContext.syncCollection(from: puzzles)
        return completion.id
    }

    private func clearPendingUndo(for puzzleID: UUID) {
        guard pendingCompletionUndo?.puzzleID == puzzleID else { return }
        pendingCompletionUndo = nil
    }

    private func clearPendingUndo(ifMatching completionID: UUID) {
        guard pendingCompletionUndo?.completionID == completionID else { return }
        pendingCompletionUndo = nil
    }

    private func syncPhotos(for puzzle: Puzzle) throws {
        let normalized = PuzzlePhotoSemantics.sortedAndNormalized(
            Array(puzzle.photos.filter { $0.image != nil }.prefix(PuzzlePhotoLimits.maxCount))
        )
        let existing = fetchPhotoRecords(puzzleID: puzzle.id)

        // Build replacements first, then delete old rows so a failure before insert
        // never leaves the puzzle with zero photos in the pending context.
        let replacements = normalized.map { PuzzlePhotoRecord(from: $0, puzzleID: puzzle.id) }
        existing.forEach { modelContext.delete($0) }
        replacements.forEach { modelContext.insert($0) }

        if let record = fetchRecord(id: puzzle.id) {
            if normalized.isEmpty {
                record.imageData = puzzle.image?.jpegData(compressionQuality: 0.30)
            } else {
                record.imageData = normalized.first?.image?.jpegData(compressionQuality: 0.30)
            }
        }
    }

    private func syncCompletions(for puzzle: Puzzle) throws {
        let existing = fetchCompletionRecords(puzzleID: puzzle.id)
        existing.forEach { modelContext.delete($0) }

        for completion in puzzle.completions {
            modelContext.insert(PuzzleCompletionRecord(from: completion, puzzleID: puzzle.id))
        }

        if let record = fetchRecord(id: puzzle.id) {
            record.timesCompleted = max(puzzle.timesCompleted, puzzle.completions.count)
        }
    }

    /// Syncs denormalized puzzle fields after completion rows change. Mutates existing
    /// `PuzzleCompletionRecord` rows in place — does not delete/reinsert the full set.
    private func reconcileCompletions(
        for puzzleID: UUID,
        statusIfEmpty: Puzzle.Status?
    ) throws {
        guard let puzzleRecord = fetchRecord(id: puzzleID) else {
            throw PuzzleStoreError.recordNotFound
        }

        let records = fetchCompletionRecords(puzzleID: puzzleID)
        PuzzleCompletionSemantics.renumberRecords(records)

        let count = records.count
        puzzleRecord.timesCompleted = count

        let currentStatus = Puzzle.Status(rawValue: puzzleRecord.status) ?? .todo

        if count == 0 {
            if currentStatus == .completed {
                guard let statusIfEmpty else {
                    throw PuzzleStoreError.statusRequiredAfterRemovingLastCompletion
                }
                puzzleRecord.status = statusIfEmpty.rawValue
                if statusIfEmpty == .todo {
                    puzzleRecord.progressPercent = 0
                }
            }
        } else if let newest = records.max(by: { $0.completedAt < $1.completedAt }) {
            puzzleRecord.completionDate = newest.completedAt
        }

        if let index = puzzles.firstIndex(where: { $0.id == puzzleID }) {
            puzzles[index] = puzzleFromRecord(puzzleRecord)
        }

        try saveContext()
    }

    private func migrateLegacyCoverPhotosIfNeeded() throws {
        let records = try modelContext.fetch(FetchDescriptor<PuzzleRecord>())
        for record in records {
            let photos = fetchPhotoRecords(puzzleID: record.id)
            guard photos.isEmpty, let imageData = record.imageData else { continue }
            modelContext.insert(
                PuzzlePhotoRecord(
                    puzzleID: record.id,
                    sortOrder: 0,
                    imageData: imageData
                )
            )
        }
        try saveContext()
    }

    private func puzzleFromRecord(_ record: PuzzleRecord) -> Puzzle {
        var puzzle = record.toPuzzle()
        puzzle.photos = fetchPhotoRecords(puzzleID: record.id).map { $0.toPuzzlePhoto() }
        if puzzle.photos.isEmpty, let imageData = record.imageData, let image = UIImage(data: imageData) {
            puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: image)]
        }
        puzzle.completions = fetchCompletionRecords(puzzleID: record.id).map { $0.toPuzzleCompletion() }
        puzzle.timesCompleted = max(record.timesCompleted, puzzle.completions.count)
        puzzle.image = puzzle.coverImage
        if let friendID = puzzle.loanedToFriendID {
            puzzle.loanedToDisplayName = friends.friend(id: friendID)?.displayName
        }
        return puzzle
    }

    private func prepareLoanFields(_ puzzle: inout Puzzle, createMissingFriends: Bool = true) throws {
        let wasOnLoan = puzzles.first(where: { $0.id == puzzle.id })?.isOnLoan ?? false
        PuzzleLoanSemantics.prepareLoanState(puzzle: puzzle)

        if puzzle.isOnLoan {
            if let name = puzzle.loanedToDisplayName {
                if createMissingFriends {
                    puzzle.loanedToFriendID = try friends.findOrCreate(
                        displayName: name,
                        isDemo: puzzle.isDemo
                    ).id
                } else if let existing = friends.friends.first(where: {
                    $0.displayName.caseInsensitiveCompare(name) == .orderedSame
                }) {
                    puzzle.loanedToFriendID = existing.id
                }
                // else keep loanedToFriendID from backup when friends were imported first
            } else if puzzle.loanedToFriendID == nil {
                // anonymous loan
            }
            // else keep existing loanedToFriendID from backup
        }

        if puzzle.isOnLoan && !wasOnLoan {
            AppLog.shared.info(.puzzles, eventName: "puzzle_marked_on_loan", message: "Puzzle marked on loan.")
        }
    }

    func loanReferenceCount(for friendID: UUID) -> Int {
        puzzles.filter { $0.loanedToFriendID == friendID }.count
    }

    private func deleteRelatedRecords(puzzleID: UUID) {
        fetchPhotoRecords(puzzleID: puzzleID).forEach { modelContext.delete($0) }
        fetchCompletionRecords(puzzleID: puzzleID).forEach { modelContext.delete($0) }
    }

    private func fetchPhotoRecords(puzzleID: UUID) -> [PuzzlePhotoRecord] {
        var descriptor = FetchDescriptor<PuzzlePhotoRecord>(
            predicate: #Predicate { $0.puzzleID == puzzleID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "puzzle_photo_fetch_failed",
                message: error.localizedDescription
            )
            return []
        }
    }

    private func fetchCompletionRecords(puzzleID: UUID) -> [PuzzleCompletionRecord] {
        var descriptor = FetchDescriptor<PuzzleCompletionRecord>(
            predicate: #Predicate { $0.puzzleID == puzzleID },
            sortBy: [SortDescriptor(\.completionNumber)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "puzzle_completion_fetch_failed",
                message: error.localizedDescription
            )
            return []
        }
    }

    private func fetchCompletionRecord(id: UUID, puzzleID: UUID) -> PuzzleCompletionRecord? {
        let completionID = id
        let parentID = puzzleID
        var descriptor = FetchDescriptor<PuzzleCompletionRecord>(
            predicate: #Predicate { record in
                record.id == completionID && record.puzzleID == parentID
            }
        )
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "puzzle_completion_fetch_failed",
                message: error.localizedDescription
            )
            return nil
        }
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
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "puzzle_record_fetch_failed",
                message: error.localizedDescription
            )
            return nil
        }
    }

    private func saveContext() throws {
        #if DEBUG
        if Self.forcesNextSaveFailure {
            Self.forcesNextSaveFailure = false
            throw PuzzleStoreError.saveFailed
        }
        #endif
        try modelContext.save()
    }
}
