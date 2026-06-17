//
//  PuzzleTagsField.swift
//  Puzzle Buddy
//

import SwiftUI

struct PuzzleTagsField: View {
    @Binding var tags: [String]
    let suggestions: [String]

    @State private var draft = ""

    private var canAddMore: Bool {
        tags.count < PuzzleTagSemantics.maxTagsPerPuzzle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            if !tags.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 88), spacing: DS.Spacing.s2)],
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
                TextField("Add tag", text: $draft, prompt: Text("cozy, Wysocki, winter…"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormTagsField)
                    .accessibilityLabel("Add tag")
                    .accessibilityHint("Enter a label and press return")
                    .onSubmit(addDraft)
            }

            if canAddMore, !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s2) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                addTag(suggestion)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityLabel("Add tag \(suggestion)")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityLabel("Suggested tags")
            }
        }
    }

    @ViewBuilder
    private func tagChip(_ tag: String, removable: Bool) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if removable {
                Button {
                    removeTag(tag)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.horizontal, DS.Spacing.s2)
        .padding(.vertical, 4)
        .background(Brand.cardElevated)
        .clipShape(Capsule())
        .foregroundStyle(Brand.textPrimary)
    }

    private func addDraft() {
        addTag(draft)
        draft = ""
    }

    private func addTag(_ raw: String) {
        guard canAddMore else { return }
        tags = PuzzleTagSemantics.sanitizedTags(tags + [raw])
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { PuzzleTagSemantics.matches($0, selected: tag) }
    }
}
