//
//  AppLinks.swift
//  Puzzle Buddy
//

import Foundation

enum AppLinks {
    static let pagesBase = "https://jacobrozell.github.io/PuzzleBuddy"

    /// App Store Connect Apple ID (numeric). Used for product and write-review URLs.
    static let appStoreID = "1642548378"

    static let privacyPolicy = URL(string: "\(pagesBase)/privacy.html")!
    static let support = URL(string: "\(pagesBase)/support.html")!
    static let accessibility = URL(string: "\(pagesBase)/accessibility.html")!
    static let marketing = URL(string: "\(pagesBase)/")!
    static let appStoreProduct = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    static let appStoreWriteReview = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    /// Short URL shown on share collages (no `https://` prefix).
    static var shareFooterLabel: String {
        guard let host = marketing.host else { return AppInfo.displayName }
        var path = marketing.path
        if path.hasSuffix("/") { path.removeLast() }
        return path.isEmpty || path == "/" ? host : "\(host)\(path)"
    }
}
