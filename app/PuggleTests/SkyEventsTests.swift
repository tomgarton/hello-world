import XCTest
@testable import Puggle

/// The moon, the meteor showers and the thunder follow the calendar and the clock (17 November 2026).
final class SkyEventsTests: XCTestCase {
    private func utc(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    func testTheMoonIsFullWhenItReallyIs() {
        // Full moons: 25 January 2024 at 17:54 UTC, and 5 November 2025 at 13:19 UTC.
        XCTAssertEqual(SkyEvents.moonAge(utc("2024-01-25T17:54:00Z")), 0.5, accuracy: 0.03)
        XCTAssertEqual(SkyEvents.moonAge(utc("2025-11-05T13:19:00Z")), 0.5, accuracy: 0.03)
        // A new moon, 21 September 2025 at 19:54 UTC, is nowhere near full.
        XCTAssertFalse(SkyEvents.fullMoon(utc("2025-09-21T19:54:00Z")))
    }

    func testMeteorsOnlyAroundAPeak() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        XCTAssertTrue(SkyEvents.meteors(utc("2026-12-14T22:00:00Z"), calendar: calendar))
        XCTAssertTrue(SkyEvents.meteors(utc("2026-08-13T01:00:00Z"), calendar: calendar))
        XCTAssertFalse(SkyEvents.meteors(utc("2026-03-10T22:00:00Z"), calendar: calendar))
    }

    func testLightningIsBriefAndRegular() {
        XCTAssertGreaterThan(Thunder.strike(at: Thunder.every * 3 + 0.1).glow, 0)
        XCTAssertEqual(Thunder.strike(at: Thunder.every * 3 + 1).glow, 0)
        XCTAssertEqual(Thunder.untilNext(after: Thunder.every * 3 + 2), Thunder.every - 2, accuracy: 0.001)
    }
}
