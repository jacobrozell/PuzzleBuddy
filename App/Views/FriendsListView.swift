//
//  FriendsListView.swift
//  Puzzle Buddy
//
//  Hidden until ProductService.isFriendsListEnabled. Model + FriendStore are live.
//

import SwiftUI

/// Local friends list shell. Not linked from Settings while the feature flag is off.
struct FriendsListView: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @State private var showAddFriend = false
    @State private var newFriendName = ""
    @State private var renameTarget: Friend?
    @State private var renameText = ""
    @State private var deleteTarget: Friend?

    var body: some View {
        List {
            if ps.friends.friends.isEmpty {
                emptyState
            } else {
                ForEach(ps.friends.friends) { friend in
                    friendRow(friend)
                }
            }
        }
        .readableBrandScreenChrome()
        .navigationTitle("People")
        .toolbar { addToolbarItem }
        .alert("Add person", isPresented: $showAddFriend) {
            TextField("Name", text: $newFriendName)
            Button("Cancel", role: .cancel) {}
            Button("Add", action: addFriend)
        }
        .alert("Rename", isPresented: renamePresented) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renameTarget = nil }
            Button("Save", action: saveRename)
        }
        .confirmationDialog(
            "Delete \(deleteTarget?.displayName ?? "this person")?",
            isPresented: deletePresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let deleteTarget { deleteFriend(deleteTarget) }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        }
        .accessibilityIdentifier(A11yID.friendsList)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No people yet",
            systemImage: "person.2",
            description: Text("Names are created when you mark a puzzle On loan.")
        )
        .listRowBackground(Color.clear)
    }

    private var addToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                newFriendName = ""
                showAddFriend = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add person")
            .accessibilityIdentifier(A11yID.friendsListAddButton)
        }
    }

    private var deletePresented: Binding<Bool> {
        Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )
    }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }

    private func friendRow(_ friend: Friend) -> some View {
        let loanCount = ps.loanReferenceCount(for: friend.id)
        let subtitle: String? = loanCount > 0
            ? (loanCount == 1 ? "1 puzzle on loan" : "\(loanCount) puzzles on loan")
            : nil

        return VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(friend.displayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button("Rename") {
                renameTarget = friend
                renameText = friend.displayName
            }
            Button("Delete", role: .destructive) {
                deleteTarget = friend
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Rename") {
                renameTarget = friend
                renameText = friend.displayName
            }
            .tint(Brand.accent)

            Button("Delete", role: .destructive) {
                deleteTarget = friend
            }
        }
    }

    private func addFriend() {
        do {
            _ = try ps.friends.findOrCreate(displayName: newFriendName)
        } catch {
            eh.handle(title: "Could not add person", message: error.localizedDescription)
        }
    }

    private func saveRename() {
        guard var friend = renameTarget else { return }
        friend.displayName = renameText
        do {
            try ps.friends.upsert(friend)
            renameTarget = nil
        } catch {
            eh.handle(title: "Could not rename", message: error.localizedDescription)
        }
    }

    private func deleteFriend(_ friend: Friend) {
        do {
            try ps.friends.delete(friend, loanReferenceCount: ps.loanReferenceCount(for: friend.id))
        } catch {
            eh.handle(title: "Could not delete", message: error.localizedDescription)
        }
    }
}
