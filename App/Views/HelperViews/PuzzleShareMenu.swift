//
//  PuzzleCollectionShare.swift
//  Puzzle Buddy
//

import SwiftUI
import UIKit

struct PuzzleSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let caption: String
}

enum PuzzleCollectionShare {
    @MainActor
    static func makePayload(puzzles: [Puzzle]) -> PuzzleSharePayload? {
        guard !puzzles.isEmpty else { return nil }
        let stats = CollectionStats.compute(from: puzzles)
        let caption = PuzzleShareSummary.make(from: stats, puzzles: puzzles)
        let image = PuzzleCollectionCollageRenderer.render(puzzles: puzzles, stats: stats)
        return PuzzleSharePayload(image: image, caption: caption)
    }
}

struct PuzzleShareSheet: UIViewControllerRepresentable {
    let payload: PuzzleSharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [payload.image, payload.caption],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FileShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PuzzleShareMenu: View {
    let entireCollection: [Puzzle]
    let visibleList: [Puzzle]

    @State private var sharePayload: PuzzleSharePayload?

    var body: some View {
        Menu {
            Button {
                sharePayload = PuzzleCollectionShare.makePayload(puzzles: entireCollection)
            } label: {
                Label(
                    "Share Entire Collection (\(entireCollection.count))",
                    systemImage: "square.grid.2x2"
                )
            }
            .disabled(entireCollection.isEmpty)

            Button {
                sharePayload = PuzzleCollectionShare.makePayload(puzzles: visibleList)
            } label: {
                Label(
                    "Share Visible List (\(visibleList.count))",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
            .disabled(visibleList.isEmpty)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier(A11yID.puzzleShareButton)
        .accessibilityLabel("Share collection")
        .accessibilityHint("Creates a collage image of your puzzles to share")
        .sheet(item: $sharePayload) { payload in
            PuzzleShareSheet(payload: payload)
                .presentationDetents([.medium, .large])
        }
    }
}
