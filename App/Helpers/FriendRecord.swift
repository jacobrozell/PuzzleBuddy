//
//  FriendRecord.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData

@Model
final class FriendRecord {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var createdAt: Date
    var updatedAt: Date
    var remoteId: String?
    var isDemo: Bool = false

    init(
        id: UUID = UUID(),
        displayName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        remoteId: String? = nil,
        isDemo: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.remoteId = remoteId
        self.isDemo = isDemo
    }

    convenience init(from friend: Friend) {
        self.init(
            id: friend.id,
            displayName: friend.displayName,
            createdAt: friend.createdAt,
            updatedAt: friend.updatedAt,
            remoteId: friend.remoteId,
            isDemo: friend.isDemo
        )
    }

    func apply(from friend: Friend) {
        displayName = friend.displayName
        createdAt = friend.createdAt
        updatedAt = friend.updatedAt
        remoteId = friend.remoteId
        isDemo = friend.isDemo
    }

    func toFriend() -> Friend {
        Friend(
            id: id,
            displayName: displayName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            remoteId: remoteId,
            isDemo: isDemo
        )
    }
}
