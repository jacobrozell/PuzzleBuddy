//
//  DemoDataAssets.swift
//  Puzzle Buddy
//

import UIKit

enum DemoDataAssets {
    static func image(named resourceName: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "jpg"),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return UIImage(data: data)
    }

    static func photos(named resourceNames: [String]) -> [PuzzlePhoto] {
        resourceNames.enumerated().compactMap { index, name in
            guard let image = image(named: name) else { return nil }
            return PuzzlePhoto(sortOrder: index, image: image)
        }
    }
}
