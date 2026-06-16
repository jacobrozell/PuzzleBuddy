//
//  RatingsView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct RatingsView: View {
    @Binding var rating: Puzzle.Rating

    var body: some View {
        StarsView(rating: Binding(get: {
            rating.rawValue
        }, set: { newValue in
            rating = Puzzle.Rating(rawValue: newValue) ?? .one
        }))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ratingAccessibilityLabel)
    }

    private var ratingAccessibilityLabel: String {
        if rating == .none {
            return "No rating"
        }
        return String(format: "Rating %.1f out of 5", rating.rawValue)
    }
}

private struct StarsView: View {
    @Binding var rating: Double

    var body: some View {
        HStack {
            switch rating {
            case 0:
                EmptyView()

            case 1:
                fullStar
                emptyStar
                emptyStar
                emptyStar
                emptyStar

            case 1.5:
                fullStar
                halfFullStar
                emptyStar
                emptyStar
                emptyStar

            case 2.0:
                fullStar
                fullStar
                emptyStar
                emptyStar
                emptyStar

            case 2.5:
                fullStar
                fullStar
                halfFullStar
                emptyStar
                emptyStar

            case 3.0:
                fullStar
                fullStar
                fullStar
                emptyStar
                emptyStar

            case 3.5:
                fullStar
                fullStar
                fullStar
                halfFullStar
                emptyStar

            case 4.0:
                fullStar
                fullStar
                fullStar
                fullStar
                emptyStar

            case 4.5:
                fullStar
                fullStar
                fullStar
                halfFullStar
                emptyStar

            case 5.0:
                fullStar
                fullStar
                fullStar
                fullStar
                fullStar

            default:
                Text("N/A")
            }
        }
    }

    private var fullStar: some View {
        Image(systemName: "star.fill").foregroundStyle(Brand.accentWarm)
    }

    private var halfFullStar: some View {
        Image(systemName: "star.lefthalf.fill").foregroundStyle(Brand.accentWarm)
    }

    private var emptyStar: some View {
        Image(systemName: "star").foregroundStyle(Brand.accentWarm.opacity(0.45))
    }
}

struct RatingsView_Previews: PreviewProvider {
    static var previews: some View {
        RatingsView(rating: .constant(.one))
    }
}
