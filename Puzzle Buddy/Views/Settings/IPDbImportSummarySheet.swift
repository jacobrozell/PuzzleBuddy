//
//  IPDbImportSummarySheet.swift
//  Puzzle Buddy
//

import SwiftUI

struct IPDbImportSummarySheet: View {
    @Environment(\.dismiss) private var dismiss

    let summary: PuzzleImportSummary

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(summary.imported > 0 ? "Import complete" : "Nothing imported", systemImage: summary.imported > 0 ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(summary.imported > 0 ? Brand.accent : Brand.textSecondary)
                    Text(summary.message)
                        .foregroundStyle(Brand.textPrimary)
                }

                if summary.imported > 0 {
                    Section("Imported") {
                        LabeledContent("New puzzles", value: "\(summary.imported)")
                    }

                    Section {
                        Label("Add box photos", systemImage: "photo.on.rectangle.angled")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.textPrimary)
                        Text("CSV exports do not include images. Open each imported puzzle and add a photo from your camera or library.")
                            .font(.footnote)
                            .foregroundStyle(Brand.textSecondary)
                        Text("Tip: use the Needs photo filter on your collection list to find puzzles still missing a box image.")
                            .font(.footnote)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }

                if summary.skippedDuplicates > 0 || summary.skippedInvalid > 0 {
                    Section("Skipped") {
                        if summary.skippedDuplicates > 0 {
                            LabeledContent("Duplicates", value: "\(summary.skippedDuplicates)")
                        }
                        if summary.skippedInvalid > 0 {
                            LabeledContent("Invalid rows", value: "\(summary.skippedInvalid)")
                        }
                    }
                }

                if summary.hasErrors {
                    Section("Issues") {
                        ForEach(summary.errors, id: \.self) { error in
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(Brand.accentWarm)
                        }
                    }
                }

                Section {
                    LegalDisclaimerFooter(
                        text: LegalCopy.ipdbImportDisclaimer,
                        style: .form
                    )
                }
            }
            .navigationTitle("Import results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .optionalAccessibilityIdentifier(A11yID.ipdbImportDoneButton)
                        .accessibilityLabel("Done")
                        .accessibilityHint("Closes import results")
                }
            }
            .optionalAccessibilityIdentifier(A11yID.ipdbImportSummarySheet)
            .onAppear {
                guard summary.imported > 0 else { return }
                var announcement = "Import complete. \(summary.imported) new puzzles added."
                if summary.skippedDuplicates > 0 {
                    announcement += " \(summary.skippedDuplicates) duplicates skipped."
                }
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }
}
