//
//  PickNextPuzzleView.swift
//  Puzzle Buddy
//

import SwiftUI

struct PickNextPuzzleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ps: PuzzleStore
    var entryPoint: String = "list"

    @State private var includeInProgress: Bool = false
    @State private var pieceCountFilter: PuzzleListPieceCountFilter = .any
    @State private var tagFilter: String? = nil
    @State private var pickedID: UUID? = nil
    @State private var isSpinning: Bool = false
    @State private var openPuzzleRequest: PickNextOpenRequest?

    private var eligible: [Puzzle] {
        PuzzleRandomPicker.eligible(
            from: ps.puzzles,
            includeInProgress: includeInProgress,
            pieceCountFilter: pieceCountFilter,
            tagFilter: tagFilter
        )
    }

    private var picked: Puzzle? {
        guard let pickedID else { return nil }
        return ps.puzzles.first(where: { $0.id == pickedID })
    }

    private var availableTags: [PuzzleTagCount] {
        PuzzleTagIndex.counts(from: ps.puzzles)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    filterCard
                    resultCard
                    spinButton
                }
                .padding(DS.Spacing.s4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .brandBackground()
            .navigationTitle("Pick my next puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier(A11yID.pickNextDoneButton)
                }
            }
            .navigationDestination(item: $openPuzzleRequest) { request in
                if let index = ps.puzzles.firstIndex(where: { $0.id == request.id }) {
                    PuzzleDetail(ps: ps, puzzle: $ps.puzzles[index])
                } else {
                    MissingPuzzleDestination()
                }
            }
        }
        .accessibilityIdentifier(A11yID.pickNextScreen)
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Filters")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            Toggle(isOn: $includeInProgress) {
                Text("Include In-Progress puzzles")
                    .font(.subheadline)
            }
            .tint(Brand.accent)
            .accessibilityHint("When on, puzzles already on your table can be re-picked")

            HStack {
                Text("Pieces")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                Menu {
                    ForEach(PuzzleListPieceCountFilter.allCases) { option in
                        Button {
                            pieceCountFilter = option
                        } label: {
                            if pieceCountFilter == option {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                        .accessibilityLabel(option.accessibilityLabel)
                    }
                } label: {
                    Label(pieceCountFilter.title, systemImage: "number")
                        .font(.subheadline.weight(.medium))
                }
                .accessibilityIdentifier(A11yID.pickNextPieceFilter)
            }

            HStack {
                Text("Tag")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                Menu {
                    Button {
                        tagFilter = nil
                    } label: {
                        if tagFilter == nil {
                            Label("Any tag", systemImage: "checkmark")
                        } else {
                            Text("Any tag")
                        }
                    }
                    ForEach(availableTags) { tag in
                        Button {
                            tagFilter = tag.name
                        } label: {
                            if tagFilter?.caseInsensitiveCompare(tag.name) == .orderedSame {
                                Label("\(tag.name) (\(tag.count))", systemImage: "checkmark")
                            } else {
                                Text("\(tag.name) (\(tag.count))")
                            }
                        }
                    }
                } label: {
                    Label(tagFilter ?? "Any", systemImage: "tag")
                        .font(.subheadline.weight(.medium))
                }
                .disabled(availableTags.isEmpty)
                .accessibilityIdentifier(A11yID.pickNextTagFilter)
            }

            Text(poolSummary)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .accessibilityIdentifier(A11yID.pickNextPoolSummary)
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
    }

    private var resultCard: some View {
        VStack(spacing: DS.Spacing.s3) {
            if let picked {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(Brand.accentWarm)
                    .symbolEffect(.bounce, value: pickedID)
                    .accessibilityHidden(true)

                Text(picked.name.isEmpty ? "Untitled puzzle" : picked.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(A11yID.pickNextResultName)

                if let pieces = picked.pieces {
                    Text("\(pieces) pieces")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }

                if !picked.tags.isEmpty {
                    Text(picked.tags.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    openPuzzleRequest = PickNextOpenRequest(id: picked.id)
                } label: {
                    Label("Open puzzle", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .accessibilityIdentifier(A11yID.pickNextOpenButton)
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
                Text(eligible.isEmpty
                     ? "No eligible puzzles. Adjust filters or add To-Do puzzles."
                     : "Tap Spin to pick a puzzle from your backlog.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.s5)
        .background(Brand.cardElevated)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var spinButton: some View {
        Button {
            spin()
        } label: {
            Label(picked == nil ? "Spin" : "Spin again", systemImage: "dice.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(BrandPrimaryButtonStyle())
        .disabled(eligible.isEmpty || isSpinning)
        .accessibilityIdentifier(A11yID.pickNextSpinButton)
        .accessibilityHint("Picks a random puzzle from the filtered backlog")
    }

    private var poolSummary: String {
        let count = eligible.count
        switch count {
        case 0: return "No eligible puzzles match these filters."
        case 1: return "1 puzzle in the pool."
        default: return "\(count) puzzles in the pool."
        }
    }

    private func spin() {
        let pool = eligible
        guard !pool.isEmpty else { return }
        isSpinning = true
        let next = PuzzleRandomPicker.pick(from: pool, excluding: pickedID)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            pickedID = next?.id
        }
        if next != nil {
            AppLog.shared.info(
                .ui,
                eventName: "pick_next_puzzle_selected",
                message: "Pick next puzzle selected.",
                metadata: [
                    "entry_point": entryPoint,
                    "piece_count_bucket": PuzzleAnalyticsMetadata.pieceCountBucket(for: pieceCountFilter)
                ]
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isSpinning = false
        }
    }
}

private struct PickNextOpenRequest: Identifiable, Hashable {
    let id: UUID
}
