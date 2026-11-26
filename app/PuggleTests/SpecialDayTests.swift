import XCTest
@testable import Puggle

/// Special days: the right dates, only where they're marked.
final class SpecialDayTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testEasterSunday() {
        for (year, month, day) in [(2025, 4, 20), (2026, 4, 5), (2027, 3, 28), (2028, 4, 16), (2038, 4, 25)] {
            XCTAssertEqual(SpecialDay.easterSunday(year, calendar: calendar), date(year, month, day, 0), "\(year)")
        }
    }

    func testEasterRunsFromGoodFridayToEasterMonday() {
        XCTAssertNil(SpecialDay.on(date(2026, 4, 2), region: "GB", calendar: calendar))
        for day in 3...6 { XCTAssertEqual(SpecialDay.on(date(2026, 4, day), region: "GB", calendar: calendar), .easter) }
        XCTAssertNil(SpecialDay.on(date(2026, 4, 7), region: "GB", calendar: calendar))
    }

    func testOnlyWhereTheDayIsMarked() {
        XCTAssertEqual(SpecialDay.on(date(2026, 11, 5), region: "GB", calendar: calendar), .bonfireNight)
        XCTAssertEqual(SpecialDay.on(date(2026, 11, 5), region: "NZ", calendar: calendar), .bonfireNight)
        XCTAssertNil(SpecialDay.on(date(2026, 11, 5), region: "US", calendar: calendar))
        XCTAssertEqual(SpecialDay.on(date(2026, 10, 31), region: "AU", calendar: calendar), .halloween)
        XCTAssertNil(SpecialDay.on(date(2026, 10, 31), region: "JP", calendar: calendar))
        // Orthodox Easter falls on another weekend, so the Western one isn't shown there.
        XCTAssertNil(SpecialDay.on(date(2026, 4, 5), region: "GR", calendar: calendar))
        XCTAssertEqual(SpecialDay.on(date(2026, 12, 25), region: "GR", calendar: calendar), .christmas)
    }

    func testNewYearsEveIsEverywhereAndRunsPastMidnight() {
        XCTAssertEqual(SpecialDay.on(date(2026, 12, 31, 23), region: "JP", calendar: calendar), .newYearsEve)
        XCTAssertEqual(SpecialDay.on(date(2027, 1, 1, 0), region: nil, calendar: calendar), .newYearsEve)
        XCTAssertNil(SpecialDay.on(date(2027, 1, 1, 9), region: "GB", calendar: calendar))
    }

    func testChristmasIsTheTwentyFourthToTheTwentySixth() {
        XCTAssertNil(SpecialDay.on(date(2026, 12, 23), region: "AU", calendar: calendar))
        XCTAssertEqual(SpecialDay.on(date(2026, 12, 24), region: "AU", calendar: calendar), .christmas)
        XCTAssertEqual(SpecialDay.on(date(2026, 12, 26), region: "AU", calendar: calendar), .christmas)
    }
}
