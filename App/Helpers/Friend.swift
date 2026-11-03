//
//  Friend.swift
//  Puzzle Buddy
//

import Foundation

struct Friend: Equatable, Identifiable {
    var id: UUID
    var displayName: String
    var createdAt: Date
    var updatedAt: Date
    var remoteId: String?
    var isDemo: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        remoteId: String? = nil,
        isDemo: Bool = false
    ) {
        self.id = id
        self.displayName = FriendSemantics.normalizedDisplayName(displayName) ?? ""
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.remoteId = remoteId
        self.isDemo = isDemo
    }
}

enum FriendSemantics {
    static let displayNameMaxLength = 80

    static func normalizedDisplayName(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(displayNameMaxLength))
    }
}
