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

    var body: some View {
        NavigationLink {
            PuzzleDetail(ps: ps, puzzle: $puzzle)
        } label: {
            PuzzleCellView(puzzle: $puzzle)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(A11yID.puzzleRow(id: puzzle.id))
        .accessibilityLabel(cellAccessibilityLabel)
        .accessibilityHint("Opens puzzle details")
        .accessibilityAddTraits(.isButton)
        .frame(maxWidth: .infinity)
    }

    private var cellAccessibilityLabel: String {
        var parts = [puzzle.name]
        if let pieces = puzzle.pieces {
            parts.append("\(pieces) pieces")
        }
        parts.append(puzzle.status.rawValue)
        parts.append(puzzle.completionDate.formatted(date: .abbreviated, time: .omitted))
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
            if let image = puzzle.image {
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
            Text(puzzle.name.capitalized)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack {
                if let pieces = puzzle.pieces {
                    Text("\(pieces) pieces")
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }

                Spacer(minLength: DS.Spacing.s2)

                Text(puzzle.completionDate, style: .date)
                    .font(.footnote)
                    .foregroundStyle(Brand.textSecondary)
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
            PuzzleCell(ps: PreviewSupport.puzzleStore, puzzle: .constant(.fixture(name: "Test 2", pieces: 500, rating: .five)))
        }
        .padding()
        .brandBackground()
    }
}
