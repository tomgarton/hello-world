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

/// Rain that lands on things (17 November 2026).
final class RainTests: XCTestCase {
    func testOnlyRainLands() {
        XCTAssertNil(Rain.strength(.snow))
        XCTAssertNil(Rain.strength(.clear))
        XCTAssertGreaterThan(Rain.strength(.storm) ?? 0, Rain.strength(.rain) ?? 0)
        XCTAssertGreaterThan(Rain.strength(.rain) ?? 0, Rain.strength(.showers) ?? 0)
    }

    func testTheStormLeansInGustsButNeverWildly() {
        let leans = stride(from: 0.0, to: 120, by: 0.5).map { Rain.lean(.storm, t: $0) }
        XCTAssertGreaterThan((leans.max() ?? 0) - (leans.min() ?? 0), 0.12)
        XCTAssertGreaterThan(leans.min() ?? 0, 0.1)
        XCTAssertLessThan(leans.max() ?? 1, 0.5)
        XCTAssertEqual(Rain.lean(.rain, t: 0), Rain.lean(.rain, t: 40))
    }

    func testDropsLandOnTheirTarget() {
        var random = SeededRandom(7)
        let ledge = RainTarget.ledge(CGPoint(x: 0, y: 10), CGPoint(x: 100, y: 10))
        let ground = RainTarget.area(.ground, CGRect(x: 0, y: 50, width: 100, height: 20))
        for _ in 0..<50 {
            let on = ledge.point(&random)
            XCTAssertEqual(on.y, 10, accuracy: 0.001)
            XCTAssertTrue((0...100).contains(on.x))
            let down = ground.point(&random)
            XCTAssertTrue((50...70).contains(down.y))
        }
    }

    /// The moon's lit part: none at new, half at the quarters, all at full; growing on the right in the north
    /// and on the left in the south, and shrinking from the same side.
    func testMoonPhaseShape() {
        XCTAssertEqual(SkyEvents.moonLit(0), 0, accuracy: 0.001)
        XCTAssertEqual(SkyEvents.moonLit(0.25), 0.5, accuracy: 0.001)
        XCTAssertEqual(SkyEvents.moonLit(0.5), 1, accuracy: 0.001)
        let disc = CGRect(x: 0, y: 0, width: 100, height: 100)
        func middle(_ age: Double, south: Bool) -> CGFloat { MoonShape.lit(in: disc, age: age, south: south).boundingRect.midX }
        XCTAssertGreaterThan(middle(0.15, south: false), 50, "a waxing crescent is lit on the right in the north")
        XCTAssertLessThan(middle(0.15, south: true), 50, "and on the left in the south")
        XCTAssertLessThan(middle(0.85, south: false), 50, "a waning crescent is lit on the left in the north")
        XCTAssertEqual(MoonShape.lit(in: disc, age: 0.5, south: false).boundingRect.width, 100, accuracy: 0.5)
    }
}
