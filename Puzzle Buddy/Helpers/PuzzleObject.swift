//
//  PuzzleObject.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import FirebaseAuth
import SwiftUI

// MARK: - PuzzleUser
public typealias PuzzleUser = FirebaseAuth.User

// MARK: - Puzzle
class Puzzle: ObservableObject {
    enum Rating: String, CaseIterable, Identifiable {
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"

        var id: String {
            self.rawValue
        }
    }

    enum Difficulty: String, CaseIterable, Identifiable {
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"

        var id: String {
            self.rawValue
        }
    }

    struct PuzzleTime {
        var hours: Int
        var minutes: Int

        init(hours: Int? = nil, minutes: Int? = nil) {
            self.hours = hours ?? 0
            self.minutes = minutes ?? 0
        }

        init(name: String) {
            let intArray = name.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap({ Int($0) })
            self.hours = intArray.first ?? 0
            self.minutes = intArray.last ?? 0
        }

        func toName() -> String {
            "\(hours)hr:\(minutes)min"
        }
    }

    enum Status {
        case todo
        case inProgress
        case completed
    }

    var id: UUID = UUID()
    @Published var name: String = ""
    @Published var pieces: Int = 500
    @Published var rating: Rating
    @Published var difficulty: Difficulty
    @Published var estimatedTimeSpent: PuzzleTime
    @Published var completionDate: Date = Date()

    internal init(name: String,
                  pieces: Int,
                  rating: Rating,
                  difficulty: Difficulty,
                  estimatedTimeSpent: PuzzleTime,
                  completionDate: Date)
    {
        self.name = name
        self.pieces = pieces
        self.rating = rating
        self.difficulty = difficulty
        self.estimatedTimeSpent = estimatedTimeSpent
        self.completionDate = completionDate
    }

//    var category
//    var barcode // scan barcode on certain brands
//    var timer // ability to start timer in app ?

//    var price: Double
//    var notes: String
//    var image: UIImage // reverse image search to find info
    // var urlLink

}

extension Puzzle {
    static func fixture() -> Puzzle {
        .init(name: "Puzzle Buddy Test", pieces: 1000, rating: .three, difficulty: .three, estimatedTimeSpent: .init(hours: 10, minutes: 5), completionDate: Date())
    }
}
