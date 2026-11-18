//
//  TipJarAndWidgetTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class TipJarAndWidgetTests: XCTestCase {
    func testTipProductIDsStayInTierOrder() {
        let shuffled = [
            TipJarProductIDs.large,
            TipJarProductIDs.small,
            TipJarProductIDs.medium,
        ]
        XCTAssertEqual(
            TipJarProductIDs.sorted(shuffled),
            [TipJarProductIDs.small, TipJarProductIDs.medium, TipJarProductIDs.large]
        )
        XCTAssertEqual(TipJarProductIDs.accessibilitySuffix(for: TipJarProductIDs.medium), "medium")
    }

    func testWidgetSnapshotPrefersTheRunningPuzzle() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let running = Puzzle.fixture(name: "  Mountain Lake  ", pieces: 1000)
        running.status = .inProgress
        running.progressPercent = 40
        running.timerAccumulatedSeconds = 25 * 60
        running.timerRunningSince = now
        let earlier = Puzzle.fixture(name: "Older", pieces: 500)
        earlier.status = .inProgress
        earlier.startDate = now.addingTimeInterval(-86_400)
        let todo = Puzzle.fixture(name: "Shelf", pieces: 300)
        todo.status = .todo
        let wishlist = Puzzle.fixture(name: "Want", pieces: 200)
        wishlist.status = .wishlist
        let done = Puzzle.fixture(name: "Finished", pieces: 100)
        done.status = .completed
        let abandoned = Puzzle.fixture(name: "Gave up", pieces: 50)
        abandoned.status = .abandoned
        todo.isOnLoan = true

        let snapshot = CollectionWidgetSnapshotBuilder.make(
            from: [earlier, wishlist, todo, running, done, abandoned],
            now: now
        )

        XCTAssertEqual(snapshot.inProgressCount, 2)
        XCTAssertEqual(snapshot.todoCount, 1)
        XCTAssertEqual(snapshot.completedCount, 1)
        XCTAssertEqual(snapshot.wishlistCount, 1)
        XCTAssertEqual(snapshot.abandonedCount, 1)
        XCTAssertEqual(snapshot.onLoanCount, 1)
        XCTAssertEqual(snapshot.totalCount, 6)
        XCTAssertEqual(snapshot.featuredPuzzleID, running.id)
        XCTAssertEqual(snapshot.featuredTitle, "Mountain Lake")
        XCTAssertEqual(snapshot.featuredDetail, "\(1000.formatted(.number)) pieces · 40%")
        XCTAssertEqual(snapshot.featuredStatus, "Timer on · 25m")
        XCTAssertEqual(snapshot.featuredProgressPercent, 40)
        XCTAssertFalse(snapshot.featuredIsBacklog)
        XCTAssertEqual(snapshot.featuredTimerRunningSince, now)
        XCTAssertEqual(snapshot.featuredTimerAccumulatedSeconds, 25 * 60)
        XCTAssertEqual(snapshot.liveTimerAnchor, now.addingTimeInterval(-Double(25 * 60)))
        XCTAssertEqual(snapshot.updatedAt, now)
        XCTAssertEqual(
            WidgetDeepLink.url(for: running.id).absoluteString,
            "puzzlebuddy://puzzle/\(running.id.uuidString)"
        )
    }

    func testWidgetDeepLinkIgnoresAnythingButAPuzzleUUID() {
        XCTAssertEqual(
            WidgetDeepLink.puzzleID(from: URL(string: "puzzlebuddy://puzzle/not-a-uuid")!),
            nil
        )
        XCTAssertEqual(
            WidgetDeepLink.puzzleID(from: URL(string: "https://example.com/puzzle")!),
            nil
        )
        XCTAssertEqual(
            WidgetDeepLink.puzzleID(from: URL(string: "puzzlebuddy://collection")!),
            nil
        )
    }

    func testWidgetSnapshotRoundTripsWithoutATitle() {
        let defaults = UserDefaults(suiteName: "TipJarAndWidgetTests.\(UUID().uuidString)")!
        let snapshot = CollectionWidgetSnapshot(
            inProgressCount: 0,
            todoCount: 4,
            featuredTitle: nil,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        CollectionWidgetSnapshotStore.publish(snapshot, defaults: defaults)
        XCTAssertEqual(CollectionWidgetSnapshotStore.load(defaults: defaults), snapshot)
    }

    func testTableFooterCountsTheUntitledPuzzleOnce() {
        var untitled = CollectionWidgetSnapshot.empty
        untitled.inProgressCount = 1
        untitled.todoCount = 2
        XCTAssertEqual(untitled.tableFooter, "2 to do")

        var several = CollectionWidgetSnapshot.empty
        several.inProgressCount = 3
        several.featuredTitle = "Mountain Lake"
        several.todoCount = 1
        XCTAssertEqual(several.tableFooter, "2 more in progress · 1 to do")
        XCTAssertEqual(CollectionWidgetSnapshot.empty.tableFooter, "To-do is clear")
    }

    func testWidgetDayCountAdvancesOnTheTimeline() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 15))!
        var snapshot = CollectionWidgetSnapshot.empty
        snapshot.featuredStartDate = now
        snapshot.featuredTitle = "Coastal Town"
        snapshot.updatedAt = now

        let dates = snapshot.tableTimelineDates(from: now, calendar: calendar, horizonDays: 2)
        XCTAssertEqual(dates.count, 3)
        XCTAssertEqual(snapshot.featuredStatusLine(at: dates[0], calendar: calendar), "Started today")
        XCTAssertEqual(snapshot.featuredStatusLine(at: dates[1], calendar: calendar), "1 day on the table")
        XCTAssertEqual(snapshot.featuredStatusLine(at: dates[2], calendar: calendar), "2 days on the table")
    }

    func testRunningTimerKeepsCountingAfterTheSnapshotIsPublished() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var snapshot = CollectionWidgetSnapshot.empty
        snapshot.featuredTimerAccumulatedSeconds = 25 * 60
        snapshot.featuredTimerRunningSince = now
        snapshot.featuredStartDate = now.addingTimeInterval(-86_400)

        XCTAssertEqual(snapshot.featuredStatusLine(at: now), "Timer on · 25m")
        XCTAssertEqual(snapshot.featuredStatusLine(at: now.addingTimeInterval(60)), "Timer on · 26m")
        XCTAssertEqual(snapshot.tableTimelineDates(from: now).count, 1)
        XCTAssertTrue(snapshot.showsLiveTimer(at: now))
    }

    func testWidgetSnapshotDecodesAPayloadWithoutTheLaterFields() throws {
        let json = """
        {"inProgressCount":1,"todoCount":2,"featuredTitle":"Old","updatedAt":"2023-11-14T22:13:20Z"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(CollectionWidgetSnapshot.self, from: Data(json.utf8))
        XCTAssertEqual(snapshot.inProgressCount, 1)
        XCTAssertEqual(snapshot.todoCount, 2)
        XCTAssertEqual(snapshot.featuredTitle, "Old")
        XCTAssertEqual(snapshot.completedCount, 0)
        XCTAssertEqual(snapshot.featuredTimerAccumulatedSeconds, 0)
        XCTAssertNil(snapshot.featuredTimerRunningSince)
        XCTAssertNil(snapshot.featuredStartDate)
        XCTAssertEqual(snapshot.featuredProgressPercent, 0)
        XCTAssertEqual(snapshot.completionsByMonth, [])
        XCTAssertEqual(snapshot.activityYear, 0)
        XCTAssertNil(snapshot.glanceFootnote)
        XCTAssertNil(snapshot.yearChartSpokenSummary)
        XCTAssertFalse(snapshot.showsYearChart)
        XCTAssertEqual(snapshot.insightLines, [])
        XCTAssertEqual(snapshot.paceLabels, [])
        XCTAssertFalse(snapshot.featuredIsBacklog)
        XCTAssertFalse(snapshot.showsPaceChart)
    }

    func testWidgetSnapshotRoundTripsActivityStats() {
        let defaults = UserDefaults(suiteName: "TipJarAndWidgetTests.\(UUID().uuidString)")!
        var snapshot = CollectionWidgetSnapshot(
            inProgressCount: 1,
            todoCount: 2,
            completedCount: 4,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        snapshot.featuredProgressPercent = 40
        snapshot.completionsThisMonth = 1
        snapshot.completionsThisYear = 3
        snapshot.completionsByMonth = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0]
        snapshot.activityYear = 2026
        snapshot.currentMonthIndex = 10
        snapshot.totalPiecesCompleted = 1_500
        snapshot.totalMinutesPuzzling = 210
        CollectionWidgetSnapshotStore.publish(snapshot, defaults: defaults)
        XCTAssertEqual(CollectionWidgetSnapshotStore.load(defaults: defaults), snapshot)
        let pieces = 1_500.formatted(.number)
        XCTAssertEqual(snapshot.glanceFootnote, "1 finished this month · \(pieces) pieces · 3.5 hours")
        XCTAssertEqual(
            snapshot.yearChartSpokenSummary,
            "3 finished in 2026. October: 1. November: 2."
        )
    }

    func testWidgetSnapshotCopiesCollectionStats() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 15))!
        let done = Puzzle.fixture(
            name: "Finished",
            pieces: 1000,
            estimatedTimeSpent: Puzzle.PuzzleTime(hours: 3, minutes: 30)
        )
        done.status = .completed
        done.completionDate = now
        let running = Puzzle.fixture(name: "Mountain Lake", pieces: 500)
        running.status = .inProgress
        running.progressPercent = 140

        let snapshot = CollectionWidgetSnapshotBuilder.make(
            from: [done, running],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.featuredProgressPercent, 100)
        XCTAssertEqual(snapshot.totalPiecesCompleted, 1000)
        XCTAssertEqual(snapshot.totalMinutesPuzzling, 210)
        XCTAssertEqual(snapshot.completionsThisMonth, 1)
        XCTAssertEqual(snapshot.completionsThisYear, 1)
        XCTAssertEqual(snapshot.activityYear, 2026)
        XCTAssertEqual(snapshot.currentMonthIndex, 10)
        XCTAssertEqual(snapshot.completionsByMonth[10], 1)
        XCTAssertEqual(snapshot.completionsByMonth.reduce(0, +), 1)
        XCTAssertTrue(snapshot.showsYearChart)
        XCTAssertEqual(snapshot.puzzlingTimeLabel, CollectionStats.formatHours(fromMinutes: 210))
    }

    func testWidgetTimeLabelMatchesCollectionStats() {
        for minutes in [0, 12, 60, 90, 210, 600, 1_000] {
            XCTAssertEqual(
                CollectionWidgetSnapshot.puzzlingTimeLabel(minutes: minutes),
                CollectionStats.formatHours(fromMinutes: minutes)
            )
        }
    }

    func testWidgetDeepLinkRemembersStatsAndClearsAPuzzle() {
        let defaults = UserDefaults(suiteName: "TipJarAndWidgetTests.\(UUID().uuidString)")!
        let id = UUID()
        WidgetDeepLink.remember(WidgetDeepLink.url(for: id), defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: WidgetDeepLink.pendingPuzzleIDKey), id.uuidString)

        WidgetDeepLink.remember(WidgetDeepLink.statsURL, defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: WidgetDeepLink.pendingDestinationKey), WidgetDeepLink.destinationStats)
        XCTAssertNil(defaults.string(forKey: WidgetDeepLink.pendingPuzzleIDKey))

        WidgetDeepLink.remember(URL(string: "puzzlebuddy://collection")!, defaults: defaults)
        XCTAssertEqual(
            defaults.string(forKey: WidgetDeepLink.pendingDestinationKey),
            WidgetDeepLink.destinationPuzzles
        )

        WidgetDeepLink.remember(WidgetDeepLink.url(for: id), defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: WidgetDeepLink.pendingPuzzleIDKey), id.uuidString)
        XCTAssertNil(defaults.string(forKey: WidgetDeepLink.pendingDestinationKey))
    }

    func testWidgetFeaturesTheNextToDoWhenTheTableIsClear() {
        let loaned = Puzzle.fixture(name: "Aaa Loaned", pieces: 100)
        loaned.status = .todo
        loaned.isOnLoan = true
        let later = Puzzle.fixture(name: "Zebra", pieces: 200)
        later.status = .todo
        let next = Puzzle.fixture(name: "Alpine", pieces: 500)
        next.status = .todo
        next.hasMissingPieces = true
        let untitled = Puzzle.fixture(name: "  ", pieces: 50)
        untitled.status = .todo

        let snapshot = CollectionWidgetSnapshotBuilder.make(from: [loaned, later, untitled, next])

        XCTAssertTrue(snapshot.featuredIsBacklog)
        XCTAssertEqual(snapshot.featuredPuzzleID, next.id)
        XCTAssertEqual(snapshot.featuredTitle, "Alpine")
        XCTAssertEqual(snapshot.featuredStatus, "Up next")
        XCTAssertEqual(snapshot.featuredDetail, "\(500.formatted(.number)) pieces · Missing pieces")
        XCTAssertEqual(snapshot.tableFooter, "3 more to do")
        XCTAssertNil(snapshot.featuredTimerRunningSince)
        XCTAssertNil(snapshot.featuredStartDate)
    }

    func testWidgetSnapshotCopiesStatsTheGlanceCanShow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 15))!
        let done = Puzzle.fixture(
            name: "Finished",
            pieces: 1000,
            rating: .fourHalf,
            estimatedTimeSpent: Puzzle.PuzzleTime(hours: 3, minutes: 30)
        )
        done.status = .completed
        done.completionDate = now
        done.startDate = calendar.date(byAdding: .day, value: -14, to: now)
        done.timesCompleted = 2
        done.puzzleType = .landscape
        done.source = "Cobble Hill"
        let running = Puzzle.fixture(name: "Mountain Lake", pieces: 500)
        running.status = .inProgress
        running.progressPercent = 40
        running.hasMissingPieces = true

        let snapshot = CollectionWidgetSnapshotBuilder.make(
            from: [done, running],
            now: now,
            calendar: calendar
        )

        let usual = 1_000.formatted(.number)
        XCTAssertEqual(
            snapshot.insightLines,
            [
                "40% along",
                "1 with missing pieces",
                "4.5 avg rating",
                "About 2 weeks to finish",
                "Usually \(usual) pieces",
                "3.5 hrs per 1,000 pieces",
                "1 replay",
                "Busiest: November",
                "Mostly Landscape",
                "Mostly Cobble Hill",
            ]
        )
        XCTAssertEqual(snapshot.paceLabels, ["Quick finish"])
        XCTAssertEqual(snapshot.paceCounts, [1])
        XCTAssertTrue(snapshot.showsPaceChart)
        XCTAssertEqual(snapshot.paceSpokenSummary, "Your pace. Quick finish: 1.")
        XCTAssertEqual(snapshot.featuredDetail, "\(500.formatted(.number)) pieces · 40% · Missing pieces")
    }
}
