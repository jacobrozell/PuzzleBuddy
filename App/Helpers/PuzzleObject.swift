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

    /// Deep copy for edit mode so in-form changes do not mutate the live detail binding.
    func copy() -> Puzzle {
        let copiedPhotos = photos.map {
            PuzzlePhoto(id: $0.id, sortOrder: $0.sortOrder, image: $0.image, createdAt: $0.createdAt)
        }
        let copiedCompletions = completions.map {
            PuzzleCompletion(
                id: $0.id,
                completionNumber: $0.completionNumber,
                startedAt: $0.startedAt,
                completedAt: $0.completedAt,
                timeSpentHours: $0.timeSpentHours,
                timeSpentMinutes: $0.timeSpentMinutes,
                rating: $0.rating
            )
        }
        var copiedTime: PuzzleTime?
        if let estimatedTimeSpent {
            copiedTime = PuzzleTime(hours: estimatedTimeSpent.hours, minutes: estimatedTimeSpent.minutes)
        }
        let copy = Puzzle(
            name: name,
            pieces: pieces,
            rating: rating,
            difficulty: difficulty,
            estimatedTimeSpent: copiedTime,
            completionDate: completionDate,
            status: status,
            startDate: startDate,
            hasMissingPieces: hasMissingPieces,
            notes: notes,
            source: source,
            purchaseLocation: purchaseLocation,
            releaseYear: releaseYear,
            puzzleType: puzzleType,
            material: material,
            disposition: disposition,
            progressPercent: progressPercent,
            purchasePrice: purchasePrice,
            purchaseCurrencyCode: purchaseCurrencyCode,
            puzzleShape: puzzleShape,
            cutType: cutType,
            dimensionsText: dimensionsText,
            timesCompleted: timesCompleted,
            photos: copiedPhotos,
            completions: copiedCompletions,
            isDemo: isDemo,
            barcode: barcode,
            tags: tags
        )
        copy.id = id
        copy.image = image
        return copy
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
