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
    }
}

private struct StarsView: View {
    private static let MAX_RATING: Float = 5 // Defines upper limit of the rating
    private static let COLOR = Color.orange // The color of the stars

    @Binding var rating: Double
    @State private var fullCount: Int
    @State private var emptyCount: Int
    @State private var halfFullCount: Int = 0

    init(rating: Binding<Double>) {
        self._rating = rating
        self.fullCount = Int(rating.wrappedValue)
        emptyCount = Int(StarsView.MAX_RATING - Float(rating.wrappedValue))
        halfFullCount = (Float(fullCount + emptyCount) < StarsView.MAX_RATING) ? 1 : 0
    }

    var body: some View {
        HStack {
            ForEach(0..<fullCount) { _ in
                self.fullStar
            }
            ForEach(0..<halfFullCount) { _ in
                self.halfFullStar
            }
            ForEach(0..<emptyCount) { _ in
                self.emptyStar
            }
        }
        .task {
            calc()
        }
    }

    private func calc() {
        fullCount = Int($rating.wrappedValue)
        emptyCount = Int(StarsView.MAX_RATING - Float($rating.wrappedValue))
        halfFullCount = (Float(fullCount + emptyCount) < StarsView.MAX_RATING) ? 1 : 0
    }

    private var fullStar: some View {
        Image(systemName: "star.fill").foregroundColor(StarsView.COLOR)
    }

    private var halfFullStar: some View {
        Image(systemName: "star.lefthalf.fill").foregroundColor(StarsView.COLOR)
    }

    private var emptyStar: some View {
        Image(systemName: "star").foregroundColor(StarsView.COLOR)
    }
}

struct RatingsView_Previews: PreviewProvider {
    static var previews: some View {
        RatingsView(rating: .constant(.one))
    }
}
