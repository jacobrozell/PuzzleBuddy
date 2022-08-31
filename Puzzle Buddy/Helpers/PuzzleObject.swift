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
        var hours: Int?
        var minutes: Int?

        func toName() -> String {
            "\(hours ?? 0)hr \(minutes ?? 0)min"
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
    @Published var rating: Rating?
    @Published var difficulty: Difficulty?
    @Published var estimatedTimeSpent: PuzzleTime?
    @Published var completionDate: Date = Date()

    internal init(name: String) {
        self.name = name
    }

    internal init(name: String,
                  pieces: Int,
                  rating: Rating? = nil,
                  difficulty: Difficulty? = nil,
                  estimatedTimeSpent: PuzzleTime = .init(hours: 0, minutes: 0),
                  completionDate: Date = Date())
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
        return .init(name: "Puzzle Buddy Test")
    }
}
