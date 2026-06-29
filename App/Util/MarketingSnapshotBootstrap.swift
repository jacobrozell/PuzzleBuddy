//
//  MarketingSnapshotBootstrap.swift
//  Puzzle Buddy
//

import Foundation

/// Routes cold-launch screenshot automation to the correct tab, sheet, or detail screen.
enum MarketingSnapshotBootstrap {
    static let uiTestReset = "-ui_test_reset"
    static let snapshotTab = "-snapshot_tab"
    static let snapshotPuzzleDetail = "-snapshot_puzzle_detail"
    static let snapshotAddPuzzle = "-snapshot_add_puzzle"
    static let snapshotDuplicateCheck = "-snapshot_duplicate_check"
    static let snapshotOnboarding = "-snapshot_onboarding"
    static let snapshotOnboardingPage = "-snapshot_onboarding_page"

    enum Tab: String {
        case puzzles
        case stats
        case settings
    }

    static var isMarketingCapture: Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains(where: { $0.hasPrefix("-snapshot_") }) { return true }
        return args.contains(uiTestReset)
    }

    static var shouldResetCollection: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestReset)
    }

    static var shouldShowOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains(snapshotOnboarding)
    }

    static var shouldShowAddPuzzle: Bool {
        ProcessInfo.processInfo.arguments.contains(snapshotAddPuzzle)
    }

    static var shouldShowDuplicateCheck: Bool {
        ProcessInfo.processInfo.arguments.contains(snapshotDuplicateCheck)
    }

    static var shouldOpenPuzzleDetail: Bool {
        ProcessInfo.processInfo.arguments.contains(snapshotPuzzleDetail)
    }

    static var forcedTab: Tab? {
        guard let value = value(following: snapshotTab) else { return nil }
        return Tab(rawValue: value)
    }

    static var initialOnboardingPage: Int {
        guard let raw = value(following: snapshotOnboardingPage),
              let page = Int(raw),
              (0 ... 3).contains(page)
        else { return 0 }
        return page
    }

    static func puzzleDetailName(defaultName: String = DemoDataCatalog.completedPuzzleName) -> String {
        value(following: snapshotPuzzleDetail) ?? defaultName
    }

    static func duplicateCheckPuzzleName(defaultName: String = DemoDataCatalog.duplicateCheckPuzzleName) -> String {
        value(following: snapshotDuplicateCheck) ?? defaultName
    }

    static func prepareLaunchStateIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains(uiTestReset) else { return }
        OnboardingStorage.reset()
        if isMarketingCapture {
            acknowledgeShowcaseMilestones()
        }
        if !shouldShowOnboarding {
            OnboardingStorage.markComplete()
        }
    }

    /// Keeps stats screenshots free of first-run milestone banners.
    private static func acknowledgeShowcaseMilestones() {
        let stats = CollectionStats.compute(from: DemoDataCatalog.makePuzzles())
        for milestone in CollectionMilestones.earned(from: stats) {
            CollectionMilestones.acknowledge(milestone.id)
        }
    }

    static func puzzleDetailID(in puzzles: [Puzzle]) -> UUID? {
        guard shouldOpenPuzzleDetail else { return nil }
        let name = puzzleDetailName()
        return puzzles.first(where: { $0.name == name })?.id
    }

    static func duplicateCheckPuzzle(in puzzles: [Puzzle]) -> Puzzle? {
        guard shouldShowDuplicateCheck else { return nil }
        let name = duplicateCheckPuzzleName()
        return puzzles.first(where: { $0.name == name })
    }

    static func reinforceTabSelection(_ select: @escaping (Tab) -> Void) {
        guard let tab = forcedTab else { return }
        Task { @MainActor in
            for delayMs in [100, 400, 900] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                select(tab)
            }
        }
    }

    private static func value(following flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
}
