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
    enum Rating: Double, CaseIterable, Identifiable {
        case none = 0.0
        case one = 1.0
        case oneHalf = 1.5
        case two = 2.0
        case twoHalf = 2.5
        case three = 3.0
        case threeHalf = 3.5
        case four = 4.0
        case fourHalf = 4.5
        case five = 5.0

        var id: Double {
            self.rawValue
        }
    }

    enum Difficulty: String, CaseIterable, Identifiable {
        case none = "0"
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
            self.hours = hours ?? 1
            self.minutes = minutes ?? 1
        }

        init(name: String) {
            let intArray = name.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap({ Int($0) })
            self.hours = intArray.first ?? 1
            self.minutes = intArray.last ?? 1
        }

        func toName() -> String {
            "\(hours)hr:\(minutes)min"
        }

        /// Returns # of minutes
        func toMin() -> Int {
            return max((self.hours * 60) + self.minutes, 1)
        }
    }

    enum Status: String, CaseIterable, Identifiable {
        case todo = "To-Do"
//        case inProgress = "In-Progress"
        case completed = "Completed"

        var id: String {
            self.rawValue
        }
    }

    var id: UUID = UUID()
    @Published var name: String = ""
    @Published var pieces: Int? = nil
    @Published var rating: Rating = .none
    @Published var difficulty: Difficulty = .none
    @Published var estimatedTimeSpent: PuzzleTime? = nil
    @Published var completionDate: Date = Date()
    @Published var status: Status = .todo

    internal init(name: String,
                  pieces: Int?,
                  rating: Rating?,
                  difficulty: Difficulty?,
                  estimatedTimeSpent: PuzzleTime?,
                  completionDate: Date,
                  status: Status = .todo
    ) {
        self.name = name
        self.pieces = pieces
        self.rating = rating ?? .none
        self.difficulty = difficulty ?? .none
        self.estimatedTimeSpent = estimatedTimeSpent
        self.completionDate = completionDate
        self.status = status
    }

//    var category
//    var barcode // scan barcode on certain brands
//    var timer // ability to start timer in app ?

//    var price: Double
//    var notes: String
//    var image: UIImage // reverse image search to find info
    // var urlLink

    func getDataFields() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "pieces": pieces ?? "nil",
            "rating": rating.rawValue,
            "difficulty": difficulty.rawValue,
            "completionDate": completionDate,
            "estimatedTimeSpent": estimatedTimeSpent?.toName() ?? "nil",
            "status": status.rawValue,
        ]
    }
}

// MARK: - PuzzleFixture
extension Puzzle {
    static func fixture() -> Puzzle {
        .init(name: "Puzzle Buddy Test",
              pieces: nil,
              rating: nil,
              difficulty: nil,
              estimatedTimeSpent: nil,
              completionDate: Date(),
              status: .todo
        )
    }
}
