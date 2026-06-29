//
//  PuzzleMetadataEnums.swift
//  Puzzle Buddy
//

import Foundation

// MARK: - PuzzleType

enum PuzzleType: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case landscape = "Landscape"
    case mystery = "Mystery"
    case gradient = "Gradient"
    case collage = "Collage"
    case panoramic = "Panoramic"
    case other = "Other"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .none: return "Not set"
        default: return rawValue
        }
    }

    var accessibilityDescription: String {
        self == .none ? "No puzzle type" : "Type \(rawValue)"
    }

    static var selectableCases: [PuzzleType] {
        allCases.filter { $0 != .none }
    }
}

// MARK: - PuzzleMaterial

enum PuzzleMaterial: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case cardboard = "Cardboard"
    case wood = "Wood"
    case plastic = "Plastic"
    case other = "Other"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .none: return "Not set"
        default: return rawValue
        }
    }

    var accessibilityDescription: String {
        self == .none ? "No material" : "Material \(rawValue)"
    }

    static var selectableCases: [PuzzleMaterial] {
        allCases.filter { $0 != .none }
    }
}

// MARK: - PuzzleDisposition

enum PuzzleDisposition: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case kept = "Kept"
    case donated = "Donated"
    case sold = "Sold"
    case gifted = "Gifted"
    case trashed = "Trashed"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .none: return "Not set"
        default: return rawValue
        }
    }

    var accessibilityDescription: String {
        self == .none ? "No disposition" : "Disposition \(rawValue)"
    }

    static var selectableCases: [PuzzleDisposition] {
        allCases.filter { $0 != .none }
    }
}

// MARK: - PuzzleShape

enum PuzzleShape: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case rectangular = "Rectangular"
    case square = "Square"
    case round = "Round"
    case irregular = "Irregular"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .none: return "Not set"
        default: return rawValue
        }
    }

    var accessibilityDescription: String {
        self == .none ? "No shape" : "Shape \(rawValue)"
    }

    static var selectableCases: [PuzzleShape] {
        allCases.filter { $0 != .none }
    }
}

// MARK: - PuzzleCutType

enum PuzzleCutType: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case ribbon = "Ribbon"
    case grid = "Grid"
    case random = "Random"
    case unknown = "Unknown"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .none: return "Not set"
        default: return rawValue
        }
    }

    var accessibilityDescription: String {
        self == .none ? "No cut type" : "Cut type \(rawValue)"
    }

    static var selectableCases: [PuzzleCutType] {
        allCases.filter { $0 != .none }
    }
}
