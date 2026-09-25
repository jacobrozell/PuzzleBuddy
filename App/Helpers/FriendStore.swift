//
//  FriendStore.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData

enum FriendStoreError: LocalizedError, Equatable {
    case emptyDisplayName
    case referencedByLoans(count: Int)

    var errorDescription: String? {
        switch self {
        case .emptyDisplayName:
            return "Enter a name for this person."
        case .referencedByLoans(let count):
            return count == 1
                ? "This person still has 1 puzzle on loan. Mark it returned before deleting."
                : "This person still has \(count) puzzles on loan. Mark them returned before deleting."
        }
    }
}

@MainActor
final class FriendStore: ObservableObject {
    @Published private(set) var friends: [Friend] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<FriendRecord>(
            sortBy: [SortDescriptor(\.displayName, order: .forward)]
        )
        do {
            friends = try modelContext.fetch(descriptor).map { $0.toFriend() }
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "friend_load_failed",
                message: error.localizedDescription
            )
            friends = []
        }
    }

    func friend(id: UUID) -> Friend? {
        friends.first { $0.id == id } ?? fetchRecord(id: id)?.toFriend()
    }

    @discardableResult
    func findOrCreate(displayName: String, isDemo: Bool = false) throws -> Friend {
        guard let normalized = FriendSemantics.normalizedDisplayName(displayName) else {
            throw FriendStoreError.emptyDisplayName
        }

        if let existing = friends.first(where: {
            $0.displayName.caseInsensitiveCompare(normalized) == .orderedSame
        }) {
            return existing
        }

        if let record = fetchAllRecords().first(where: {
            $0.displayName.caseInsensitiveCompare(normalized) == .orderedSame
        }) {
            let friend = record.toFriend()
            if !friends.contains(where: { $0.id == friend.id }) {
                friends.append(friend)
                friends.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            }
            return friend
        }

        let friend = Friend(displayName: normalized, isDemo: isDemo)
        let record = FriendRecord(from: friend)
        modelContext.insert(record)
        // Defer save to the puzzle write so a failed puzzle save can roll back this friend.
        friends.append(friend)
        friends.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        AppLog.shared.info(.puzzles, eventName: "friend_created", message: "Friend created.")
        return friend
    }

    func upsert(_ friend: Friend) throws {
        guard FriendSemantics.normalizedDisplayName(friend.displayName) != nil else {
            throw FriendStoreError.emptyDisplayName
        }
        var updated = friend
        updated.displayName = FriendSemantics.normalizedDisplayName(friend.displayName) ?? friend.displayName
        updated.updatedAt = Date()

        if let record = fetchRecord(id: updated.id) {
            record.apply(from: updated)
        } else {
            modelContext.insert(FriendRecord(from: updated))
        }
        try modelContext.save()
        reload()
    }

    func delete(_ friend: Friend, loanReferenceCount: Int) throws {
        if loanReferenceCount > 0 {
            throw FriendStoreError.referencedByLoans(count: loanReferenceCount)
        }
        if let record = fetchRecord(id: friend.id) {
            modelContext.delete(record)
            try modelContext.save()
        }
        friends.removeAll { $0.id == friend.id }
    }

    func removeDemoFriends(keepingFriendIDs: Set<UUID> = []) throws {
        let demoRecords = fetchAllRecords().filter(\.isDemo)
        guard !demoRecords.isEmpty else { return }
        for record in demoRecords where !keepingFriendIDs.contains(record.id) {
            modelContext.delete(record)
        }
        try modelContext.save()
        reload()
    }

    private func fetchRecord(id: UUID) -> FriendRecord? {
        var descriptor = FetchDescriptor<FriendRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchAllRecords() -> [FriendRecord] {
        (try? modelContext.fetch(FetchDescriptor<FriendRecord>())) ?? []
    }
}
