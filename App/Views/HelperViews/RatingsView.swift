//
//  RatingsView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - RatingsView

struct RatingsView: View {
    @Binding var rating: Puzzle.Rating
    var isInteractive: Bool = true

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(1...5, id: \.self) { starIndex in
                starTapTarget(for: starIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puzzle rating")
        .accessibilityValue(rating.accessibilityDescription)
        .modifier(RatingAdjustableAccessibility(isInteractive: isInteractive, rating: $rating))
    }

    private func starTapTarget(for starIndex: Int) -> some View {
        ZStack {
            StarGlyphs.display(for: rating.rawValue, at: starIndex)

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        rating = PuzzleRatingSelection.rating(forStar: starIndex, side: .left)
                    }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        rating = PuzzleRatingSelection.rating(forStar: starIndex, side: .right)
                    }
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

// MARK: - RatingAdjustableAccessibility

private struct RatingAdjustableAccessibility: ViewModifier {
    let isInteractive: Bool
    @Binding var rating: Puzzle.Rating

    func body(content: Content) -> some View {
        if isInteractive {
            content
                .accessibilityHint("Swipe up or down to change rating")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        rating = PuzzleRatingSelection.increment(rating)
                    case .decrement:
                        rating = PuzzleRatingSelection.decrement(rating)
                    @unknown default:
                        break
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - PuzzleRatingSelection

enum PuzzleRatingSelection {
    enum StarTapSide {
        case left
        case right
    }

    static func rating(forStar index: Int, side: StarTapSide) -> Puzzle.Rating {
        switch side {
        case .left:
            if index == 1 { return .none }
            return Puzzle.Rating(rawValue: Double(index) - 0.5) ?? .none
        case .right:
            return Puzzle.Rating(rawValue: Double(index)) ?? .one
        }
    }

    static func increment(_ rating: Puzzle.Rating) -> Puzzle.Rating {
        let ordered = Puzzle.Rating.allCases
        guard let index = ordered.firstIndex(of: rating), index < ordered.count - 1 else {
            return rating
        }
        return ordered[index + 1]
    }

    static func decrement(_ rating: Puzzle.Rating) -> Puzzle.Rating {
        let ordered = Puzzle.Rating.allCases
        guard let index = ordered.firstIndex(of: rating), index > 0 else {
            return rating
        }
        return ordered[index - 1]
    }
}

// MARK: - StarGlyphs

private enum StarGlyphs {
    @ViewBuilder
    static func display(for rating: Double, at position: Int) -> some View {
        let threshold = Double(position)
        if rating >= threshold {
            fullStar
        } else if rating >= threshold - 0.5 {
            halfStar
        } else {
            emptyStar
        }
    }

    private static var fullStar: some View {
        Image(systemName: "star.fill")
            .foregroundStyle(Brand.accentWarm)
    }

    private static var halfStar: some View {
        Image(systemName: "star.lefthalf.fill")
            .foregroundStyle(Brand.accentWarm)
    }

    private static var emptyStar: some View {
        Image(systemName: "star")
            .foregroundStyle(Brand.accentWarm.opacity(0.45))
    }
}

// MARK: - Puzzle.Rating accessibility

extension Puzzle.Rating {
    var accessibilityDescription: String {
        if self == .none {
            return "No rating"
        }
        return String(format: "Rating %.1f out of 5", rawValue)
    }
}

// MARK: - Previews

struct RatingsView_Previews: PreviewProvider {
    static var previews: some View {
        RatingsView(rating: .constant(.fourHalf))
    }
}
