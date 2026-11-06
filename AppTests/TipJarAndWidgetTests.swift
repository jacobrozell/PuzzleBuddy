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
    }
}