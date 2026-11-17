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

    func testLightningIsBrief() {
        let at = Thunder.strikeTime(3)
        XCTAssertGreaterThan(Thunder.strike(at: at + 0.1).glow, 0)
        if Thunder.doubleTime(3) == nil { XCTAssertEqual(Thunder.strike(at: at + 1.2).glow, 0) }
        XCTAssertEqual(Thunder.untilNext(after: at - 2), 2, accuracy: 0.001)
    }

    func testStrikesAreIrregularButNeverTooClose() {
        for seed: UInt64 in [1, 99, 123_456] {
            Thunder.seed = seed
            let times = (0..<400).map(Thunder.strikeTime)
            let gaps = zip(times.dropFirst(), times).map { $0 - $1 }
            XCTAssertGreaterThanOrEqual(gaps.min() ?? 0, 5 - 0.001)
            XCTAssertLessThanOrEqual(gaps.max() ?? 99, 13 + 0.001)
            // Not a metronome: the gaps really vary.
            XCTAssertGreaterThan((gaps.max() ?? 0) - (gaps.min() ?? 0), 5)
            let doubles = (0..<400).compactMap(Thunder.doubleTime).count
            XCTAssertTrue((40...120).contains(doubles), "\(doubles) doubles in 400")
            // Every second bolt and every flash inside a cloud is clear of the next strike.
            for slot in 0..<400 {
                if let second = Thunder.doubleTime(slot) { XCTAssertLessThan(second + Thunder.length, Thunder.strikeTime(slot + 1)) }
                if let sheet = Thunder.sheetTime(slot) { XCTAssertLessThan(sheet + Thunder.sheetLength, Thunder.strikeTime(slot + 1)) }
            }
        }
    }

    func testEachLaunchHasItsOwnStorm() {
        Thunder.seed = 1
        let one = (0..<20).map(Thunder.strikeTime)
        Thunder.seed = 2
        let two = (0..<20).map(Thunder.strikeTime)
        XCTAssertNotEqual(one, two)
        Thunder.seed = SceneClock.seed
    }
}
