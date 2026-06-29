//
//  PuzzleCell.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - PuzzleCell
struct PuzzleCell: View {
    @ObservedObject var ps: PuzzleStore
    @Binding var puzzle: Puzzle
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationLink {
            PuzzleDetail(ps: ps, puzzle: $puzzle)
        } label: {
            PuzzleCellView(puzzle: $puzzle)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(A11yID.puzzleRow(id: puzzle.id))
        .accessibilityLabel(cellAccessibilityLabel)
        .accessibilityHint("Opens puzzle details. Use the actions rotor to delete.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Delete puzzle") {
            showDeleteConfirmation = true
        }
        .confirmationDialog(
            "Delete \(puzzle.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deletePuzzle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This puzzle will be removed from your collection. This cannot be undone.")
        }
        .frame(maxWidth: .infinity)
    }

    private func deletePuzzle() {
        guard let index = ps.puzzles.firstIndex(where: { $0.id == puzzle.id }) else { return }
        ps.delete(at: IndexSet(integer: index))
    }

    private var cellAccessibilityLabel: String {
        var parts = [puzzle.name]
        if let source = puzzle.source, !source.isEmpty {
            parts.append(source)
        }
        if let pieces = puzzle.pieces {
            parts.append("\(pieces) pieces")
        }
        if puzzle.rating != .none {
            parts.append(puzzle.rating.accessibilityDescription)
        }
        if puzzle.difficulty != .none {
            parts.append(puzzle.difficulty.accessibilityDescription)
        }
        parts.append(puzzle.status.accessibilityDescription)
        if puzzle.hasMissingPieces {
            parts.append("Missing pieces")
        }
        if !puzzle.tags.isEmpty {
            parts.append("Tags: \(puzzle.tags.joined(separator: ", "))")
        }
        if puzzle.status == .completed {
            parts.append("Completed \(puzzle.completionDate.formatted(date: .abbreviated, time: .omitted))")
        } else if puzzle.status == .inProgress {
            parts.append("Started \(puzzle.completionDate.formatted(date: .abbreviated, time: .omitted))")
            parts.append(PuzzleProgressSemantics.displayLabel(for: puzzle.progressPercent))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: PuzzleCellView
private struct PuzzleCellView: View {
    @Binding var puzzle: Puzzle
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var usesStackedLayout: Bool {
        AdaptiveLayout.usesStackedRowLayout(
            dynamicType: dynamicTypeSize,
            verticalSizeClass: verticalSizeClass
        )
    }

    var body: some View {
        Group {
            if usesStackedLayout {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    puzzleThumbnail
                    puzzleTextBlock
                }
            } else {
                HStack(alignment: .center, spacing: DS.Spacing.s3) {
                    puzzleThumbnail
                    puzzleTextBlock
                }
            }
        }
        .padding(.vertical, DS.Spacing.s2)
        .padding(.horizontal, DS.Spacing.s3)
        .brandCardSurface()
    }

    private var puzzleThumbnail: some View {
        Group {
            if let image = puzzle.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Brand.textSecondary.opacity(0.25), lineWidth: 0.5))
            } else {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.title)
                    .foregroundStyle(Brand.accent)
                    .frame(width: 72, height: 72)
                    .background(Brand.cardElevated)
                    .clipShape(Circle())
            }
        }
        .accessibilityHidden(true)
    }

    private var puzzleTextBlock: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(puzzle.name)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if let source = puzzle.source, !source.isEmpty {
                Text(source)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .lineLimit(1)
            }

            if !puzzle.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(puzzle.tags.prefix(2), id: \.self) { tag in
                        HStack(spacing: 3) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                            Text(tag)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(Brand.textSecondary)
                        .padding(.horizontal, DS.Spacing.s2)
                        .padding(.vertical, 2)
                        .background(Brand.cardElevated)
                        .clipShape(Capsule())
                    }
                    if puzzle.tags.count > 2 {
                        Text("+\(puzzle.tags.count - 2)")
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }
                .accessibilityLabel("Tags: \(puzzle.tags.joined(separator: ", "))")
            }

            if puzzle.rating != .none {
                RatingsView(rating: .constant(puzzle.rating))
                    .scaleEffect(0.9, anchor: .leading)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .accessibilityIdentifier(A11yID.puzzleCellRating)
            }

            HStack(spacing: DS.Spacing.s2) {
                PuzzleStatusPill(status: puzzle.status)

                if puzzle.timesCompleted > 1 {
                    Text("×\(puzzle.timesCompleted)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                        .padding(.horizontal, DS.Spacing.s2)
                        .padding(.vertical, 2)
                        .background(Brand.cardElevated)
                        .clipShape(Capsule())
                        .accessibilityLabel("Completed \(puzzle.timesCompleted) times")
                }

                if puzzle.hasMissingPieces {
                    Label("Missing pieces", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Brand.accentWarm)
                        .labelStyle(.titleAndIcon)
                        .accessibilityIdentifier(A11yID.puzzleCellMissingPieces)
                }
            }

            if puzzle.status == .inProgress {
                PuzzleListProgressBar(progress: puzzle.progressPercent)
            }

            HStack {
                if let pieces = puzzle.pieces {
                    Text("\(pieces) pieces")
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }

                Spacer(minLength: DS.Spacing.s2)

                if let trailingDate = PuzzleDateSemantics.listTrailingDate(for: puzzle) {
                    Text(trailingDate, style: .date)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews
struct PuzzleCellPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            PuzzleCell(ps: PreviewSupport.puzzleStore, puzzle: .constant(.fixture(name: "Test 1", pieces: 125)))
            PuzzleCell(ps: PreviewSupport.puzzleStore, puzzle: .constant(inProgressPreview()))
            PuzzleCell(ps: PreviewSupport.puzzleStore, puzzle: .constant(.fixture(name: "Test 2", pieces: 500, rating: .five)))
        }
        .padding()
        .brandBackground()
    }

    private static func inProgressPreview() -> Puzzle {
        let puzzle = Puzzle.fixture(name: "Tabletop Sky", pieces: 300, rating: .two)
        puzzle.status = .inProgress
        puzzle.progressPercent = 45
        return puzzle
    }
}
