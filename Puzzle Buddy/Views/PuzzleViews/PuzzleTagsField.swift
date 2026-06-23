//
//  PuzzleTagsField.swift
//  Puzzle Buddy
//

import SwiftUI

struct PuzzleTagsField: View {
    @Binding var tags: [String]
    let catalog: [String]

    @State private var draft = ""

    private var canAddMore: Bool {
        tags.count < PuzzleTagSemantics.maxTagsPerPuzzle
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedSuggestions: [String] {
        PuzzleTagIndex.matchingTags(
            query: draft,
            excluding: tags,
            fromCatalog: catalog
        )
    }

    private var showsNoMatchingTagsHint: Bool {
        canAddMore && !trimmedDraft.isEmpty && displayedSuggestions.isEmpty
    }

    private var isSearching: Bool {
        !trimmedDraft.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack {
                Text(tagCountLabel)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)

                Spacer()

                if !tags.isEmpty {
                    Button("Clear all") {
                        tags = []
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.accentWarm)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Clear all tags")
                }
            }

            if !tags.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 96), spacing: DS.Spacing.s2)],
                    alignment: .leading,
                    spacing: DS.Spacing.s2
                ) {
                    ForEach(tags, id: \.self) { tag in
                        tagChip(tag, removable: true)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tags, \(tags.joined(separator: ", "))")
            }

            if canAddMore {
                HStack(spacing: DS.Spacing.s2) {
                    Image(systemName: "tag")
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityHidden(true)

                    TextField("Add tag", text: $draft, prompt: Text("Search or add a tag…"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .optionalAccessibilityIdentifier(A11yID.puzzleFormTagsField)
                        .accessibilityLabel("Add tag")
                        .accessibilityHint("Type to search existing tags, separate multiple with commas, then press return")
                        .onSubmit(addDraft)

                    if !trimmedDraft.isEmpty {
                        Button {
                            draft = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Clear tag search")
                    }
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(Brand.cardElevated)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            }

            if showsNoMatchingTagsHint {
                Text("No matching tags. Press return to add “\(trimmedDraft)”.")
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }

            if canAddMore, !displayedSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(isSearching ? "Matching tags" : "Suggested tags")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Brand.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.s2) {
                            ForEach(displayedSuggestions, id: \.self) { suggestion in
                                Button {
                                    addTag(suggestion)
                                } label: {
                                    Label(suggestion, systemImage: "plus")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                                .accessibilityLabel("Add tag \(suggestion)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityLabel(isSearching ? "Matching tags" : "Suggested tags")
                }
            }
        }
    }

    private var tagCountLabel: String {
        if tags.isEmpty {
            return "Up to \(PuzzleTagSemantics.maxTagsPerPuzzle) tags"
        }
        return "\(tags.count) of \(PuzzleTagSemantics.maxTagsPerPuzzle) tags"
    }

    @ViewBuilder
    private func tagChip(_ tag: String, removable: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.caption2)
                .foregroundStyle(Brand.accent)

            Text(tag)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if removable {
                Button {
                    removeTag(tag)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 32, minHeight: 32)
                .contentShape(Rectangle())
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.leading, DS.Spacing.s2)
        .padding(.trailing, removable ? 4 : DS.Spacing.s2)
        .padding(.vertical, 6)
        .background(Brand.cardElevated)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Brand.accent.opacity(0.2), lineWidth: 1)
        }
        .foregroundStyle(Brand.textPrimary)
    }

    private func addTag(_ raw: String, clearDraft: Bool = true) {
        guard canAddMore else { return }
        tags = PuzzleTagSemantics.sanitizedTags(tags + [raw])
        if clearDraft {
            draft = ""
        }
    }

    private func addDraft() {
        let parts = draft
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.isEmpty {
            addTag(draft)
        } else {
            for part in parts {
                guard canAddMore else { break }
                addTag(part, clearDraft: false)
            }
            draft = ""
        }
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { PuzzleTagSemantics.matches($0, selected: tag) }
    }
}
