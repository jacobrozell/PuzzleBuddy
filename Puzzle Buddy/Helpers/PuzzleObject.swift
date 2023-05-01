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
    //change to double
    enum Rating: Double, CaseIterable, Identifiable {
        case none = 0.0
        case one = 1.0
        case oneHalf = 1.5
        case two = 2.0
        case twoHalf = 2.5
        case three = 3
        case threeHalf = 3.5
        case four = 4
        case fourHalf = 4.5
        case five = 5

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
        var hours: Int?
        var minutes: Int?

        init(hours: Int? = nil, minutes: Int? = nil) {
            self.hours = hours
            self.minutes = minutes
        }

        init(name: String) {
            let intArray = name.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap({ Int($0) })
            self.hours = intArray.first
            self.minutes = intArray.last
        }

        func toName() -> String? {
            guard let hours = hours, let mins = minutes else {
                return nil
            }

            return "\(hours)hr:\(mins)min"
        }

        /// Returns # of minutes
        func toMin() -> Int {
            guard let hours = hours, let minutes = minutes else {
                return 1
            }

            return max((hours * 60) + minutes, 1)
        }
    }

    enum Status: String, CaseIterable, Identifiable {
        case todo = "To-Do"
        case completed = "Completed"

        var id: String {
            self.rawValue
        }
    }

    var id: UUID = UUID()
    @Published var name: String = ""
    @Published var pieces: Int?
    @Published var rating: Rating = .none
    @Published var difficulty: Difficulty = .none
    @Published var estimatedTimeSpent: PuzzleTime?
    @Published var completionDate: Date = Date()
    @Published var status: Status = .todo
    @Published var image: UIImage?

    internal init() {
        self.name = ""
    }

    internal init(name: String,
                  pieces: Int?,
                  rating: Rating = .none,
                  difficulty: Difficulty = .none,
                  estimatedTimeSpent: PuzzleTime?,
                  completionDate: Date?,
                  status: Status = .todo
    ) {
        self.name = name
        self.pieces = pieces
        self.rating = rating
        self.difficulty = difficulty
        self.estimatedTimeSpent = estimatedTimeSpent
        self.completionDate = completionDate ?? Date()
        self.status = status
    }

//    var category
//    var barcode // scan barcode on certain brands
//    var timer // ability to start timer in app ?

//    var price: Double
//    var notes: String

    // var urlLink

    func getDataFields() -> [String: Any] {
            return [
                "id": id.uuidString,
                "name": name,
                "pieces": pieces ?? "nil",
                "rating": rating.rawValue,
                "difficulty": difficulty.rawValue,
                "completionDate": completionDate.timeIntervalSince1970,
                "estimatedTimeSpent": estimatedTimeSpent?.toName() ?? "nil",
                "status": status.rawValue,
                "imageData": image?.jpegData(compressionQuality: 0.30)?.base64EncodedString() ?? "nil"
            ]
        }

}

// MARK: - PuzzleFixture
extension Puzzle {
    static func fixture() -> Puzzle {
        .init(name: "",
              pieces: nil,
              rating: .none,
              difficulty: .none,
              estimatedTimeSpent: nil,
              completionDate: Date(),
              status: .todo
        )
    }

    static func fixture(name: String, pieces: Int, rating: Puzzle.Rating? = Puzzle.Rating.none, difficulty: Puzzle.Difficulty? = Puzzle.Difficulty.none, estimatedTimeSpent: Puzzle.PuzzleTime? = nil) -> Puzzle {
        .init(name: name,
              pieces: pieces,
              rating: .none,
              difficulty: .none,
              estimatedTimeSpent: nil,
              completionDate: Date(),
              status: .todo
        )
    }
}

extension Puzzle {
    static func fromData(_ data: [String: Any?]) -> Puzzle {
        let p: Puzzle = .fixture()

        if let id = data["id"] as? String, let id = UUID(uuidString: id) {
            p.id = id
        } else {
            print("KeyError: id not found")
        }

        if let name = data["name"] as? String {
            p.name = name
        } else {
            print("KeyError: name not found")
        }

        if let pieces = data["pieces"] as? Int {
            p.pieces = pieces
        } else {
            print("KeyError: pieces not found")
        }

        if let rating = data["rating"] as? Double {
            p.rating = Puzzle.Rating(rawValue: rating) ?? .one
        } else {
            print("KeyError: rating not found")
        }

        if let difficulty = data["difficulty"] as? String {
            p.difficulty = Puzzle.Difficulty(rawValue: difficulty) ?? .one
        } else {
            print("KeyError: difficulty not found")
        }

        if let estimatedTimeSpent = data["estimatedTimeSpent"] as? String {
            p.estimatedTimeSpent = Puzzle.PuzzleTime(name: estimatedTimeSpent)
        } else {
            print("KeyError: estimatedTimeSpent not found")
        }

        if let completionDate = data["completionDate"] as? Double {
            p.completionDate = Date(timeIntervalSince1970: TimeInterval(completionDate))
        } else {
            print("KeyError: completionDate not found")
        }

        if let status = data["status"] as? String {
            p.status = Puzzle.Status(rawValue: status) ?? .todo
        } else {
            print("KeyError: status not found")
        }

        if let imageData = data["imageData"] as? String, let data = Data(base64Encoded: imageData) {
            p.image = UIImage(data: data)
        } else {
            print("KeyError: image not found")
        }

        return p
    }
}
