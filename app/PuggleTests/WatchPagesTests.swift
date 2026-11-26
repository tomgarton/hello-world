import XCTest
@testable import Puggle

/// The figures the iPhone sends for the Watch's pages.
@MainActor
final class WatchPagesTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    /// Midday on a day in 2026.
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 26, hour: 12))! }
    private func at(daysAgo: Int, hour: Double) -> Date {
        calendar.startOfDay(for: now).addingTimeInterval(Double(-daysAgo) * 86400 + hour * 3600)
    }

    func testFourteenWholeDaysOldestFirstAndTodayLeftOut() {
        // Two hours yesterday, and an hour today that must not count.
        let stretches = [DateInterval(start: at(daysAgo: 1, hour: 13), end: at(daysAgo: 1, hour: 15)),
                         DateInterval(start: at(daysAgo: 0, hour: 9), end: at(daysAgo: 0, hour: 10))]
        let days = WidgetFeed.sleepDays(stretches: stretches, now: now, calendar: calendar)
        XCTAssertEqual(days.count, 14)
        XCTAssertEqual(days.last ?? nil, 2)
        XCTAssertTrue(days.dropLast().allSatisfy { $0 == nil })
    }

    func testANightIsSharedBetweenTheTwoDaysItTouches() {
        // 19:00 three days ago to 07:00 two days ago: five hours, then seven.
        let night = DateInterval(start: at(daysAgo: 3, hour: 19), end: at(daysAgo: 2, hour: 7))
        let days = WidgetFeed.sleepDays(stretches: [night], now: now, calendar: calendar)
        XCTAssertEqual(days[11] ?? 0, 5, accuracy: 0.001)
        XCTAssertEqual(days[12] ?? 0, 7, accuracy: 0.001)
    }

    func testADayWithNoSleepIsAGapNotANought() {
        let days = WidgetFeed.sleepDays(stretches: [], now: now, calendar: calendar)
        XCTAssertTrue(days.allSatisfy { $0 == nil })
    }

    // The Watch moving the fourteen days on after midnight, before the iPhone writes again.

    /// A child as the iPhone wrote them at 21:00 yesterday: fourteen days of 10 hours to the day before, a
    /// nap of 1½ hours yesterday afternoon, and asleep since 19:00.
    private func writtenLastNight(asleep: Bool = true) -> WidgetSnapshot.Child {
        var child = WidgetSnapshot.preview.children[0]
        child.sleepDays = Array(repeating: 10, count: 13) + [12]
        child.sleepDaysEnd = at(daysAgo: 1, hour: 0)
        child.sleepsToday = [WidgetSnapshot.Stretch(start: at(daysAgo: 1, hour: 13), end: at(daysAgo: 1, hour: 14.5), sleep: 0),
                             WidgetSnapshot.Stretch(start: at(daysAgo: 1, hour: 19), end: nil, sleep: 1)]
        child.asleepSince = asleep ? at(daysAgo: 1, hour: 19) : nil
        child.lastWoke = asleep ? nil : at(daysAgo: 1, hour: 23)
        return child
    }

    func testTheDaysMoveOnByOneAfterMidnight() {
        let days = writtenLastNight().sleepDays(now: now, calendar: calendar) ?? []
        XCTAssertEqual(days.count, 14)
        // The day before yesterday is now second to last, and yesterday is the nap and 19:00 to midnight.
        XCTAssertEqual(days[12] ?? 0, 12, accuracy: 0.001)
        XCTAssertEqual(days[13] ?? 0, 6.5, accuracy: 0.001)
    }

    func testASleepTheWatchSawEndIsCutThere() {
        let days = writtenLastNight(asleep: false).sleepDays(now: now, calendar: calendar) ?? []
        XCTAssertEqual(days[13] ?? 0, 5.5, accuracy: 0.001)
    }

    func testDaysNothingCoversAreGaps() {
        // Written three days ago, woken that evening: that day, then two days with nothing.
        var child = writtenLastNight(asleep: false)
        child.sleepDaysEnd = at(daysAgo: 3, hour: 0)
        child.sleepsToday = [WidgetSnapshot.Stretch(start: at(daysAgo: 3, hour: 13), end: at(daysAgo: 3, hour: 15), sleep: 0)]
        let days = child.sleepDays(now: now, calendar: calendar) ?? []
        XCTAssertEqual(days.count, 14)
        XCTAssertEqual(days[11] ?? 0, 2, accuracy: 0.001)
        XCTAssertNil(days[12] ?? nil)
        XCTAssertNil(days[13] ?? nil)
        XCTAssertEqual(days[10] ?? 0, 12, accuracy: 0.001)
    }

    func testASleepRunningForDaysFillsThem() {
        var child = writtenLastNight()
        child.sleepDaysEnd = at(daysAgo: 2, hour: 0)
        child.sleepsToday = [WidgetSnapshot.Stretch(start: at(daysAgo: 2, hour: 19), end: nil, sleep: 0)]
        let days = child.sleepDays(now: now, calendar: calendar) ?? []
        XCTAssertEqual(days[12] ?? 0, 5, accuracy: 0.001)
        XCTAssertEqual(days[13] ?? 0, 24, accuracy: 0.001)
    }

    func testTheSameDayOrAnOlderSummaryIsLeftAlone() {
        var child = writtenLastNight()
        child.sleepDaysEnd = at(daysAgo: 0, hour: 0)
        XCTAssertEqual(child.sleepDays(now: now, calendar: calendar), child.sleepDays)
        child.sleepDaysEnd = nil
        XCTAssertEqual(child.sleepDays(now: now, calendar: calendar), child.sleepDays)
        child.sleepDays = nil
        XCTAssertNil(child.sleepDays(now: now, calendar: calendar))
    }
}
