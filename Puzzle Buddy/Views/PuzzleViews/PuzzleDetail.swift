//
//  PuzzleDetail.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct PuzzleDetail: View {
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
    @State private var isEditable = false
    @State private var editFormVm: PuzzleFormViewModel?
    @Binding var puzzle: Puzzle

    private var trimmedNameIsEmpty: Bool {
        puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack {
            if isEditable, let editFormVm {
                PuzzleFormInternal(formVm: editFormVm, allPuzzles: ps.puzzles)
                    .adaptiveScrollChrome()
            } else {
                ScrollView {
                    DetailView(puzzle: $puzzle, ps: ps)
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
                        editFormVm = PuzzleFormViewModel(puzzle: puzzle)
                        isEditable = true
                        return
                    }

                    guard !trimmedNameIsEmpty else { return }

                    do {
                        try ps.update(puzzle: puzzle)
                        editFormVm = nil
                        isEditable = false
                    } catch {
                        eh.handle(title: "Could not save puzzle", message: error.localizedDescription)
                    }
                } label: {
                    Text("\(isEditable ? "Save" : "Edit")")
                }
                .disabled(isEditable && trimmedNameIsEmpty)
                .opacity(isEditable && trimmedNameIsEmpty ? 0.6 : 1.0)
                .optionalAccessibilityIdentifier(A11yID.puzzleDetailEditButton)
                .accessibilityLabel(isEditable ? "Save puzzle changes" : "Edit puzzle")
                .accessibilityHint(
                    isEditable
                        ? (trimmedNameIsEmpty ? "Enter a puzzle name to enable saving" : "Saves your edits and returns to details")
                        : "Opens the puzzle form for editing"
                )
            }
        }
        .readableBrandScreenChrome()
    }
}

// MARK: - DetailView
struct DetailView: View {
    @Binding var puzzle: Puzzle
    @ObservedObject var ps: PuzzleStore
    @EnvironmentObject var eh: ErrorHandling
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
                    VStack(spacing: DS.Spacing.s4) {
                        summaryPanel
                        progressPanel
                    }
                    .frame(maxWidth: .infinity)
                    statsPanel
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: DS.Spacing.s4) {
                    summaryPanel
                    progressPanel
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

    private var progressPanel: some View {
        GroupBox {
            PuzzleProgressSection(
                progressPercent: $puzzle.progressPercent,
                status: $puzzle.status,
                onCommit: {
                    do {
                        try ps.update(puzzle: puzzle)
                    } catch {
                        eh.handle(title: "Could not save progress", message: error.localizedDescription)
                    }
                }
            )
        }
        .groupBoxStyle(BrandGroupBoxStyle())
        .accessibilityIdentifier(A11yID.puzzleDetailProgress)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Puzzle progress")
    }

    private var statsPanel: some View {
        GroupBox {
            VStack(spacing: DS.Spacing.s4) {
                detailRow(label: "Status", value: puzzle.status.accessibilityDescription)

                if let source = puzzle.source?.trimmingCharacters(in: .whitespacesAndNewlines), !source.isEmpty {
                    detailRow(label: "Source", value: source)
                }

                if !puzzle.tags.isEmpty {
                    detailRow(label: "Tags", value: puzzle.tags.joined(separator: ", "))
                }

                if let barcode = puzzle.barcode, !barcode.isEmpty {
                    CopyableDetailRow(
                        label: "Barcode",
                        value: barcode,
                        copiedAnnouncement: "Barcode copied",
                        accessibilityIdentifier: A11yID.puzzleDetailBarcodeRow
                    )
                }

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
                        label: "Finish style",
                        value: paceLabel,
                        accessibilityIdentifier: A11yID.puzzleDetailPaceRow
                    )
                }

                if let pieces = puzzle.pieces {
                    detailRow(label: "Pieces", value: "\(pieces)")
                }

                if let paceValue = detailMetrics.formattedHoursPer1000Pieces {
                    detailRow(
                        label: "Speed",
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
