//
//  PuzzleObject.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import SwiftUI

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
        var hours: Int?
        var minutes: Int?

        init(hours: Int? = nil, minutes: Int? = nil) {
            self.hours = hours
            self.minutes = minutes
        }

        init(name: String) {
            let intArray = name.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap({ Int($0) })
            self.hours = intArray.first ?? nil
            self.minutes = intArray.last ?? nil
        }

        func toName() -> String {
            guard let hours = hours, let minutes = minutes else {
                return "N/A"
            }

            return "\(hours)hr:\(minutes)min"
        }

        /// Human-readable label for UI (e.g. detail screen, form preview).
        var displayLabel: String? {
            let hourValue = max(hours ?? 0, 0)
            let minuteValue = max(minutes ?? 0, 0)
            guard hourValue > 0 || minuteValue > 0 else { return nil }

            var parts: [String] = []
            if hourValue > 0 {
                parts.append(hourValue == 1 ? "1 hr" : "\(hourValue) hr")
            }
            if minuteValue > 0 {
                parts.append(minuteValue == 1 ? "1 min" : "\(minuteValue) min")
            }
            return parts.joined(separator: " ")
        }

        mutating func normalizeComponents() {
            var hourValue = max(hours ?? 0, 0)
            var minuteValue = max(minutes ?? 0, 0)
            if minuteValue >= 60 {
                hourValue += minuteValue / 60
                minuteValue %= 60
            }
            hours = hourValue
            minutes = minuteValue
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
        case wishlist = "Wishlist"
        case todo = "To-Do"
        case inProgress = "In-Progress"
        case completed = "Completed"
        case abandoned = "Abandoned"

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
    @Published var startDate: Date? = nil
    @Published var status: Status = .todo
    @Published var hasMissingPieces: Bool = false
    @Published var notes: String? = nil
    @Published var source: String? = nil
    @Published var purchaseLocation: String? = nil
    @Published var releaseYear: Int? = nil
    @Published var puzzleType: PuzzleType = .none
    @Published var material: PuzzleMaterial = .none
    @Published var disposition: PuzzleDisposition = .none
    @Published var progressPercent: Int = 0
    @Published var purchasePrice: Double?
    @Published var purchaseCurrencyCode: String?
    @Published var puzzleShape: PuzzleShape = .none
    @Published var cutType: PuzzleCutType = .none
    @Published var dimensionsText: String? = nil
    @Published var timesCompleted: Int = 0
    @Published var photos: [PuzzlePhoto] = []
    @Published var completions: [PuzzleCompletion] = []
    @Published var isDemo: Bool = false
    @Published var barcode: String? = nil
    @Published var tags: [String] = []
    @Published var image: UIImage? = nil {
        didSet {
            syncCoverPhotoFromLegacyImage()
        }
    }

    /// Cover photo for list cells and legacy callers.
    var coverImage: UIImage? {
        PuzzlePhotoSemantics.coverImage(from: photos) ?? image
    }

    private func syncCoverPhotoFromLegacyImage() {
        guard let image else { return }
        if photos.isEmpty {
            photos = [PuzzlePhoto(sortOrder: 0, image: image)]
        } else if let coverIndex = photos.firstIndex(where: { $0.sortOrder == 0 }) {
            photos[coverIndex].image = image
        } else if let firstIndex = photos.indices.first {
            photos[firstIndex].image = image
        }
    }

    internal init(name: String,
                  pieces: Int?,
                  rating: Rating = .none,
                  difficulty: Difficulty = .none,
                  estimatedTimeSpent: PuzzleTime?,
                  completionDate: Date,
                  status: Status = .todo,
                  startDate: Date? = nil,
                  hasMissingPieces: Bool = false,
                  notes: String? = nil,
                  source: String? = nil,
                  purchaseLocation: String? = nil,
                  releaseYear: Int? = nil,
                  puzzleType: PuzzleType = .none,
                  material: PuzzleMaterial = .none,
                  disposition: PuzzleDisposition = .none,
                  progressPercent: Int = 0,
                  purchasePrice: Double? = nil,
                  purchaseCurrencyCode: String? = nil,
                  puzzleShape: PuzzleShape = .none,
                  cutType: PuzzleCutType = .none,
                  dimensionsText: String? = nil,
                  timesCompleted: Int = 0,
                  photos: [PuzzlePhoto] = [],
                  completions: [PuzzleCompletion] = [],
                  isDemo: Bool = false,
                  barcode: String? = nil,
                  tags: [String] = []
    ) {
        self.name = name
        self.pieces = pieces
        self.rating = rating
        self.difficulty = difficulty
        self.estimatedTimeSpent = estimatedTimeSpent
        self.completionDate = completionDate
        self.startDate = startDate
        self.status = status
        self.hasMissingPieces = hasMissingPieces
        self.notes = notes
        self.source = source
        self.purchaseLocation = purchaseLocation
        self.releaseYear = releaseYear
        self.puzzleType = puzzleType
        self.material = material
        self.disposition = disposition
        self.progressPercent = PuzzleProgressSemantics.clamped(progressPercent)
        self.purchasePrice = purchasePrice
        self.purchaseCurrencyCode = purchaseCurrencyCode
        self.puzzleShape = puzzleShape
        self.cutType = cutType
        self.dimensionsText = dimensionsText
        self.timesCompleted = timesCompleted
        self.photos = PuzzlePhotoSemantics.sortedAndNormalized(photos)
        self.completions = completions
        self.isDemo = isDemo
        self.barcode = BarcodeNormalizer.normalize(barcode)
        self.tags = PuzzleTagSemantics.sanitizedTags(tags)
        self.image = PuzzlePhotoSemantics.coverImage(from: self.photos)
    }

    func prepareForPersistence() {
        photos = PuzzlePhotoSemantics.sortedAndNormalized(
            photos.filter { $0.image != nil }
        )
        if photos.count > PuzzlePhotoLimits.maxCount {
            photos = Array(photos.prefix(PuzzlePhotoLimits.maxCount))
            photos = PuzzlePhotoSemantics.normalizedSortOrders(photos)
        }
        image = PuzzlePhotoSemantics.coverImage(from: photos)
        if let price = purchasePrice {
            purchasePrice = max(0, min(price, 999_999.99))
            if purchaseCurrencyCode == nil {
                purchaseCurrencyCode = Locale.current.currency?.identifier ?? "USD"
            }
        } else {
            purchaseCurrencyCode = nil
        }
        if let dimensionsText {
            self.dimensionsText = String(dimensionsText.prefix(80))
        }
    }

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
            "startDate": startDate as Any? ?? "nil",
            "estimatedTimeSpent": estimatedTimeSpent?.toName() ?? "nil",
            "status": status.rawValue,
            "hasMissingPieces": hasMissingPieces,
            "notes": notes ?? "nil",
            "source": source ?? "nil",
            "purchaseLocation": purchaseLocation ?? "nil",
            "releaseYear": releaseYear ?? "nil",
            "puzzleType": puzzleType.rawValue,
            "material": material.rawValue,
            "disposition": disposition.rawValue,
            "progressPercent": progressPercent,
            "purchasePrice": purchasePrice ?? "nil",
            "purchaseCurrencyCode": purchaseCurrencyCode ?? "nil",
            "puzzleShape": puzzleShape.rawValue,
            "cutType": cutType.rawValue,
            "dimensionsText": dimensionsText ?? "nil",
            "timesCompleted": timesCompleted,
            "isDemo": isDemo,
            "barcode": barcode ?? "nil",
            "tags": tags,
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

    static func fixture(name: String, pieces: Int, rating: Puzzle.Rating = .none, difficulty: Puzzle.Difficulty = .none, estimatedTimeSpent: Puzzle.PuzzleTime? = nil) -> Puzzle {
        .init(name: name,
              pieces: pieces,
              rating: rating,
              difficulty: difficulty,
              estimatedTimeSpent: estimatedTimeSpent,
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

        if let completionDate = data["completionDate"] as? Date {
            p.completionDate = completionDate
        } else {
            print("KeyError: completionDate not found")
        }

        if let startDate = data["startDate"] as? Date {
            p.startDate = startDate
        }

        if let status = data["status"] as? String {
            p.status = Puzzle.Status(rawValue: status) ?? .todo
        } else {
            print("KeyError: status not found")
        }

        if let hasMissingPieces = data["hasMissingPieces"] as? Bool {
            p.hasMissingPieces = hasMissingPieces
        }

        if let notes = data["notes"] as? String, notes != "nil" {
            p.notes = notes
        }

        if let source = data["source"] as? String, source != "nil" {
            p.source = source
        }

        if let purchaseLocation = data["purchaseLocation"] as? String, purchaseLocation != "nil" {
            p.purchaseLocation = purchaseLocation
        }

        if let releaseYear = data["releaseYear"] as? Int {
            p.releaseYear = releaseYear
        }

        if let puzzleType = data["puzzleType"] as? String {
            p.puzzleType = PuzzleType(rawValue: puzzleType) ?? .none
        }

        if let material = data["material"] as? String {
            p.material = PuzzleMaterial(rawValue: material) ?? .none
        }

        if let disposition = data["disposition"] as? String {
            p.disposition = PuzzleDisposition(rawValue: disposition) ?? .none
        }

        if let progressPercent = data["progressPercent"] as? Int {
            p.progressPercent = PuzzleProgressSemantics.clamped(progressPercent)
        }

        if let purchasePrice = data["purchasePrice"] as? Double {
            p.purchasePrice = purchasePrice
        }

        if let purchaseCurrencyCode = data["purchaseCurrencyCode"] as? String, purchaseCurrencyCode != "nil" {
            p.purchaseCurrencyCode = purchaseCurrencyCode
        }

        if let puzzleShape = data["puzzleShape"] as? String {
            p.puzzleShape = PuzzleShape(rawValue: puzzleShape) ?? .none
        }

        if let cutType = data["cutType"] as? String {
            p.cutType = PuzzleCutType(rawValue: cutType) ?? .none
        }

        if let dimensionsText = data["dimensionsText"] as? String, dimensionsText != "nil" {
            p.dimensionsText = dimensionsText
        }

        if let timesCompleted = data["timesCompleted"] as? Int {
            p.timesCompleted = timesCompleted
        }

        if let isDemo = data["isDemo"] as? Bool {
            p.isDemo = isDemo
        }

        if let barcode = data["barcode"] as? String, barcode != "nil" {
            p.barcode = BarcodeNormalizer.normalize(barcode)
        }

        if let tags = data["tags"] as? [String] {
            p.tags = PuzzleTagSemantics.sanitizedTags(tags)
        }

        if let imageData = data["imageData"] as? String, let data = Data(base64Encoded: imageData) {
            p.image = UIImage(data: data)
        } else {
            print("KeyError: image not found")
        }

        p.prepareForPersistence()
        return p
    }
}

// MARK: - Accessibility

extension Puzzle.Status {
    var accessibilityDescription: String {
        switch self {
        case .wishlist:
            return "Wishlist, not yet owned"
        case .todo:
            return "To-Do, not started"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .abandoned:
            return "Abandoned, will not finish"
        }
    }
}

extension Puzzle {
    /// Side effects when status changes (progress percent, start date).
    func noteStatusChanged(from previousStatus: Status, to newStatus: Status) {
        progressPercent = PuzzleProgressSemantics.progress(for: newStatus, current: progressPercent)
        switch newStatus {
        case .inProgress where startDate == nil:
            startDate = Date()
        case .completed where startDate == nil && previousStatus == .inProgress:
            startDate = completionDate
        case .abandoned where previousStatus == .inProgress && startDate == nil:
            startDate = completionDate
        default:
            break
        }
    }
}

extension Puzzle.Difficulty {
    var accessibilityDescription: String {
        if self == .none {
            return "No difficulty"
        }
        return "Difficulty \(rawValue) out of 5"
    }
}
