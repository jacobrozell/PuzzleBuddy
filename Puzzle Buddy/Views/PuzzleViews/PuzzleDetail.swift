//
//  PuzzleDetail.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct PuzzleDetail: View {
    @ObservedObject var ps: PuzzleStore
    @State private var isEditable = false
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack {
            if isEditable {
                PuzzleFormInternal(formVm: .init(puzzle: puzzle))
                    .adaptiveScrollChrome()
            } else {
                ScrollView {
                    DetailView(puzzle: $puzzle)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut, value: isEditable)
        .navigationTitle("\(puzzle.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard isEditable else {
                        isEditable.toggle()
                        return
                    }

                    ps.update(puzzle: puzzle)
                    isEditable.toggle()
                } label: {
                    Text("\(isEditable ? "Save" : "Edit")")
                }
                .optionalAccessibilityIdentifier(A11yID.puzzleDetailEditButton)
                .accessibilityLabel(isEditable ? "Save puzzle changes" : "Edit puzzle")
                .accessibilityHint(isEditable ? "Saves your edits and returns to details" : "Opens the puzzle form for editing")
            }
        }
        .readableBrandScreenChrome()
    }
}

// MARK: - DetailView
struct DetailView: View {
    @Binding var puzzle: Puzzle
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var usesWideLayout: Bool {
        AdaptiveLayout.usesWideDetailLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    var body: some View {
        Group {
            if usesWideLayout {
                HStack(alignment: .top, spacing: DS.Spacing.s5) {
                    summaryPanel
                        .frame(maxWidth: .infinity)
                    statsPanel
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: DS.Spacing.s4) {
                    summaryPanel
                    statsPanel
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical)
        .accessibilityElement(children: .contain)
    }

    private var summaryPanel: some View {
        GroupBox {
            puzzleImage
            Text(puzzle.name)
                .bold()
                .font(.title3)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if puzzle.rating != .none {
                RatingsView(rating: Binding(get: {
                    puzzle.rating
                }, set: { new in
                    puzzle.rating = new
                }), isInteractive: false)
                .allowsHitTesting(false)
                .padding(.horizontal)
            }

            if puzzle.difficulty != .none {
                Text("Difficulty: \(puzzle.difficulty.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityLabel(puzzle.difficulty.accessibilityDescription)
            }
        }
        .groupBoxStyle(BrandGroupBoxStyle())
        .accessibilityIdentifier(A11yID.puzzleDetailSummary)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Puzzle summary")
    }

    private var detailMetrics: PuzzleDetailMetrics {
        PuzzleDetailMetrics.compute(pieces: puzzle.pieces, time: puzzle.estimatedTimeSpent)
    }

    private var statsPanel: some View {
        GroupBox {
            VStack(spacing: DS.Spacing.s4) {
                detailRow(label: "Status", value: puzzle.status.accessibilityDescription)
                detailRow(
                    label: PuzzleDateSemantics.detailDateLabel(for: puzzle.status),
                    value: puzzle.completionDate.formatted(date: .abbreviated, time: .omitted)
                )
                detailRow(
                    label: "Missing pieces",
                    value: puzzle.hasMissingPieces ? "Yes" : "No"
                )

                if let notes = puzzle.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                    detailRow(label: "Notes", value: notes)
                }

                if let estimatedTimeSpent = puzzle.estimatedTimeSpent {
                    detailRow(label: "Time spent", value: estimatedTimeSpent.toName())
                }

                if let paceLabel = detailMetrics.timeBucketLabel {
                    detailRow(
                        label: "Puzzle pace",
                        value: paceLabel,
                        accessibilityIdentifier: A11yID.puzzleDetailPaceRow
                    )
                }

                if let pieces = puzzle.pieces {
                    detailRow(label: "Pieces", value: "\(pieces)")
                }

                if let paceValue = detailMetrics.formattedHoursPer1000Pieces {
                    detailRow(
                        label: "Pace",
                        value: paceValue,
                        accessibilityIdentifier: A11yID.puzzleDetailHoursPer1000Row
                    )
                }
            }
        }
        .groupBoxStyle(BrandGroupBoxStyle())
        .accessibilityIdentifier(A11yID.puzzleDetailStats)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Puzzle details")
    }

    @ViewBuilder
    private var puzzleImage: some View {
        if let image = puzzle.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: usesWideLayout ? 280 : 150, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                .padding()
                .accessibilityLabel("Puzzle photo for \(puzzle.name)")
        } else {
            Image(systemName: "puzzlepiece.extension.fill")
                .resizable()
                .foregroundStyle(Brand.accent)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: usesWideLayout ? 280 : 150, alignment: .center)
                .padding()
                .accessibilityLabel("No puzzle photo")
        }
    }

    @ViewBuilder
    private func detailRow(
        label: String,
        value: String,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        if AdaptiveLayout.usesStackedRowLayout(
            dynamicType: dynamicTypeSize,
            verticalSizeClass: verticalSizeClass
        ) {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text("\(label):")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(Brand.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label), \(value)")
            .optionalAccessibilityIdentifier(accessibilityIdentifier)
        } else {
            HStack {
                Text("\(label):")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(Brand.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label), \(value)")
            .optionalAccessibilityIdentifier(accessibilityIdentifier)
        }
    }
}

private struct BrandGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            configuration.label
            configuration.content
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
    }
}

// MARK: - Previews
struct PuzzleDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PuzzleDetail(ps: PreviewSupport.puzzleStore, puzzle: .constant(.fixture()))
        }
    }
}
