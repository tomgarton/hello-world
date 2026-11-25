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
}
