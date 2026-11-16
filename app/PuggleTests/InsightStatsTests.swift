import XCTest
@testable import Puggle

/// The sums behind Insights: a child's days against their own recent past.
final class InsightStatsTests: XCTestCase {
    private let calendar = Calendar.current
    private var day0: Date { calendar.startOfDay(for: Date(timeIntervalSince1970: 1_800_000_000)) }
    private func at(_ day: Int, _ hour: Double) -> Date { calendar.date(byAdding: .day, value: day, to: day0)!.addingTimeInterval(hour * 3600) }
    private func sleep(_ day: Int, _ from: Double, _ to: Double) -> InsightStats.Entry {
        .init(kind: .sleep, start: at(day, from), asleep: [DateInterval(start: at(day, from), end: at(day, to))])
    }

    func testANightIsSharedBetweenTheTwoDaysItCrosses() {
        // Asleep from 7 in the evening to 6 the next morning.
        let days = InsightStats.days([sleep(0, 19, 30)], from: at(0, 0), to: at(1, 12))
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].sleep, 5 * 3600, accuracy: 1)
        XCTAssertEqual(days[1].sleep, 6 * 3600, accuracy: 1)
        XCTAssertEqual(days[0].nightSleep, 5 * 3600, accuracy: 1, "All of it is night")
        XCTAssertEqual(days[1].longestNight, 11 * 3600, accuracy: 1, "The stretch belongs to the morning it ended on")
        XCTAssertEqual(days[0].sleeps, 1)
    }

    func testANapIsDaySleep() {
        let days = InsightStats.days([sleep(0, 13, 14.5)], from: at(0, 0), to: at(0, 23))
        XCTAssertEqual(days[0].daySleep, 1.5 * 3600, accuracy: 1)
        XCTAssertEqual(days[0].nightSleep, 0, accuracy: 1)
    }

    func testCountsByKind() {
        let entries: [InsightStats.Entry] = [
            .init(kind: .bottle, start: at(0, 8), ml: 150), .init(kind: .bottle, start: at(0, 12), ml: 180), .init(kind: .breastfeed, start: at(0, 16)),
            .init(kind: .nappy, start: at(0, 9), detail: "Wet"), .init(kind: .nappy, start: at(0, 11), detail: "Both"), .init(kind: .nappy, start: at(0, 15), detail: "Dirty"),
        ]
        let day = InsightStats.days(entries, from: at(0, 0), to: at(0, 23))[0]
        XCTAssertEqual(day.bottleML, 330)
        XCTAssertEqual(day.feeds, 3)
        XCTAssertEqual([day.nappies, day.wet, day.dirty], [3, 2, 2])
    }

    func testUsualIsTheMiddleHalfAndNeedsAWeek() {
        XCTAssertNil(InsightStats.usual([12, 13, 12.5, 13, 12, 14]), "Six days is not enough")
        let usual = InsightStats.usual([10, 11, 12, 13, 14, 15, 16, 0, 0])
        XCTAssertEqual(usual?.lowerBound ?? 0, 11.5, accuracy: 0.01, "Days with nothing are left out, not counted as nought")
        XCTAssertEqual(usual?.upperBound ?? 0, 14.5, accuracy: 0.01)
    }

    func testStandingAllowsAHair() {
        let usual = 12.0...14.0
        XCTAssertEqual(InsightStats.standing(13, in: usual), .within)
        XCTAssertEqual(InsightStats.standing(14.1, in: usual), .within)
        XCTAssertEqual(InsightStats.standing(15, in: usual), .more)
        XCTAssertEqual(InsightStats.standing(11, in: usual), .less)
    }

    func testComparedWithTheStretchBefore() {
        XCTAssertEqual(InsightStats.compare(102, with: 100), .same)
        XCTAssertEqual(InsightStats.compare(130, with: 100), .more(30))
        XCTAssertEqual(InsightStats.compare(70, with: 100), .less(30))
        XCTAssertNil(InsightStats.compare(70, with: nil))
        XCTAssertNil(InsightStats.compare(70, with: 0), "Nothing before is nothing to compare with")
    }

    func testAUsualDayFindsTheNightAsOneRunAndTheNap() {
        var entries: [InsightStats.Entry] = []
        for day in 0..<10 {
            entries.append(sleep(day, 19, 30.5))      // 7 pm to 6:30 am
            entries.append(sleep(day, 13, 14.5))      // a nap
            entries.append(.init(kind: .bottle, start: at(day, 7)))
            entries.append(.init(kind: .bottle, start: at(day, 11)))
        }
        let usual = InsightStats.usualDay(entries, from: at(1, 0), to: at(9, 0))
        XCTAssertEqual(usual.days, 8)
        let runs = usual.sleepRuns
        XCTAssertEqual(runs.count, 2, "The night once, not twice, and the nap")
        XCTAssertEqual(runs.map(\.from), [13, 19])
        XCTAssertEqual(runs.map(\.to), [14.5, 30.5])
        XCTAssertEqual(usual.feedTimes, [7.25, 11.25])
        XCTAssertTrue(usual.asleep(atHour: 2))
        XCTAssertFalse(usual.asleep(atHour: 10))
    }

    func testWordsForStandingAndComparing() {
        XCTAssertEqual(InsightWords.standing(.more, name: "Ollie"), "More than Ollie\u{2019}s usual")
        XCTAssertEqual(InsightWords.compared(.same, as: .time, to: "last week").text, "About the same as last week")
        XCTAssertEqual(InsightWords.compared(.more(2400), as: .time, to: "last week").text, "40 min longer than last week")
        XCTAssertEqual(InsightWords.compared(.less(4), as: .count, to: "last week").text, "4 fewer than last week")
        XCTAssertEqual(InsightWords.hours(13 * 3600 + 5 * 60), "13h 05m")
    }
}
