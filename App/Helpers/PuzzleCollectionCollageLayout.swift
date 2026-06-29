//
//  PuzzleCollectionCollageLayout.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleCollectionCollageLayout {
    static let maxCells = 12

    static func gridDimensions(for count: Int) -> (columns: Int, rows: Int, displayed: Int) {
        let displayed = min(max(count, 1), maxCells)

        switch displayed {
        case 1:
            return (1, 1, 1)
        case 2:
            return (2, 1, 2)
        case 3, 4:
            return (2, 2, displayed)
        case 5...6:
            return (3, 2, displayed)
        case 7...9:
            return (3, 3, displayed)
        default:
            return (4, 3, displayed)
        }
    }
}
