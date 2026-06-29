//
//  AppLinks.swift
//  Puzzle Buddy
//

import Foundation

enum AppLinks {
    static let pagesBase = "https://jacobrozell.github.io/PuzzleBuddy"

    static let privacyPolicy = URL(string: "\(pagesBase)/privacy.html")!
    static let support = URL(string: "\(pagesBase)/support.html")!
    static let accessibility = URL(string: "\(pagesBase)/accessibility.html")!
    static let marketing = URL(string: "\(pagesBase)/")!

    /// Short URL shown on share collages (no `https://` prefix).
    static var shareFooterLabel: String {
        guard let host = marketing.host else { return AppInfo.displayName }
        var path = marketing.path
        if path.hasSuffix("/") { path.removeLast() }
        return path.isEmpty || path == "/" ? host : "\(host)\(path)"
    }
}
