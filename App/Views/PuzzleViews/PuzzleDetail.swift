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
    @State private var showRedoConfirmation = false
    @Binding var puzzle: Puzzle

    private var trimmedNameIsEmpty: Bool {
        if isEditable, let editFormVm {
            return editFormVm.puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return puzzle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack {
            if isEditable, let editFormVm {
                PuzzleFormInternal(formVm: editFormVm, allPuzzles: ps.puzzles)
                    .keyboardDismissToolbar()
                    .adaptiveScrollChrome()
            } else {
                ScrollView {
                    DetailView(
                        puzzle: $puzzle,
                        ps: ps,
                        onPuzzleAgain: puzzle.status == .completed ? { showRedoConfirmation = true } : nil
                    )
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut, value: isEditable)
        .navigationTitle("\(puzzle.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditable {
                    Button("Cancel") {
                        editFormVm = nil
                        isEditable = false
                    }
                    .optionalAccessibilityIdentifier(A11yID.puzzleDetailCancelButton)
                    .accessibilityLabel("Cancel editing")
                    .accessibilityHint("Discards unsaved changes and returns to details")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard isEditable else {
                        editFormVm = PuzzleFormViewModel(puzzle: puzzle.copy())
                        isEditable = true
                        return
                    }

                    guard let editFormVm, !trimmedNameIsEmpty else { return }

                    do {
                        try ps.update(puzzle: editFormVm.puzzle)
                        if let refreshed = ps.puzzles.first(where: { $0.id == editFormVm.puzzle.id }) {
                            puzzle = refreshed
                        }
                        self.editFormVm = nil
                        isEditable = false
                        BarcodeScanFeedback.scanAccepted()
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
        .confirmationDialog(
            "Puzzle again?",
            isPresented: $showRedoConfirmation,
            titleVisibility: .visible
        ) {
            Button("Puzzle again") {
                do {
                    try ps.startRedo(puzzle: puzzle)
                    if let refreshed = ps.puzzles.first(where: { $0.id == puzzle.id }) {
                        puzzle = refreshed
                    }
                } catch {
                    eh.handle(title: "Could not start again", message: error.localizedDescription)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Start this puzzle again? Your previous completions stay in your history.")
        }
    }
}

// MARK: - DetailView
struct DetailView: View {
    @Binding var puzzle: Puzzle
    @ObservedObject var ps: PuzzleStore
    var onPuzzleAgain: (() -> Void)?
    @EnvironmentObject var eh: ErrorHandling
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            summaryPanel
            progressPanel
            statsPanel
        }
        .padding(.horizontal)
        .padding(.vertical)
        .accessibilityElement(children: .contain)
    }

    private var summaryPanel: some View {
        GroupBox {
            PuzzlePhotoGalleryDetail(photos: puzzle.photos, puzzleName: puzzle.name)
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
                        if let refreshed = ps.puzzles.first(where: { $0.id == puzzle.id }) {
                            puzzle = refreshed
                        }
                    } catch {
                        eh.handle(title: "Could not save progress", message: error.localizedDescription)
                    }
                },
                onPuzzleAgain: onPuzzleAgain
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
                    detailRow(label: "Brand", value: source)
                }

                if let purchaseLocation = puzzle.purchaseLocation?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !purchaseLocation.isEmpty {
                    detailRow(label: "Bought at", value: purchaseLocation)
                }

                if let releaseYear = puzzle.releaseYear {
                    detailRow(label: "Year", value: String(releaseYear))
                }

                if puzzle.puzzleType != .none {
                    detailRow(label: "Type", value: puzzle.puzzleType.displayLabel)
                }

                if puzzle.material != .none {
                    detailRow(label: "Material", value: puzzle.material.displayLabel)
                }

                if puzzle.puzzleShape != .none {
                    detailRow(label: "Shape", value: puzzle.puzzleShape.displayLabel)
                }

                if puzzle.cutType != .none {
                    detailRow(label: "Cut type", value: puzzle.cutType.displayLabel)
                }

                if let dimensions = puzzle.dimensionsText?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !dimensions.isEmpty {
                    detailRow(label: "Finished size", value: dimensions)
                }

                if let price = puzzle.purchasePrice {
                    detailRow(
                        label: "Paid",
                        value: PurchasePriceFormatting.displayLabel(
                            price: price,
                            currencyCode: puzzle.purchaseCurrencyCode
                        )
                    )
                }

                if puzzle.timesCompleted > 0 {
                    detailRow(
                        label: "Times completed",
                        value: "\(puzzle.timesCompleted)"
                    )
                }

                ForEach(PuzzleCompletionSemantics.sortedNewestFirst(puzzle.completions)) { completion in
                    detailRow(
                        label: "Completion \(completion.completionNumber)",
                        value: completionSummary(completion)
                    )
                }

                if puzzle.status == .completed, puzzle.disposition != .none {
                    detailRow(label: "After finishing", value: puzzle.disposition.displayLabel)
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

                if let progressDays = PuzzleDateSemantics.progressDaysLabel(for: puzzle) {
                    detailRow(label: "Days puzzling", value: progressDays)
                }

                if let startDate = puzzle.startDate,
                   PuzzleDateSemantics.showsStartDatePicker(for: puzzle.status) {
                    detailRow(
                        label: "Started on",
                        value: startDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }

                detailRow(
                    label: "Missing pieces",
                    value: puzzle.hasMissingPieces ? "Yes" : "No"
                )

                if let notes = puzzle.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                    detailRow(label: "Notes", value: notes)
                }

                if let estimatedTimeSpent = puzzle.estimatedTimeSpent,
                   let timeLabel = estimatedTimeSpent.displayLabel {
                    detailRow(label: "Time spent", value: timeLabel)
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

    private func completionSummary(_ completion: PuzzleCompletion) -> String {
        var parts = [completion.completedAt.formatted(date: .abbreviated, time: .omitted)]
        if let timeLabel = completion.timeSpentLabel {
            parts.append(timeLabel)
        }
        return parts.joined(separator: " · ")
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
                    .fixedSize(horizontal: false, vertical: true)
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
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
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
