import XCTest
@testable import Puggle

/// Puggle's evening follows the children's (19 November 2026).
final class EveningTests: XCTestCase {
    func testBedtimeByAge() {
        XCTAssertEqual(Evening.bedtime(ageMonths: 5), 19 * 60)
        XCTAssertEqual(Evening.bedtime(ageMonths: 30), 19 * 60 + 15)
        XCTAssertEqual(Evening.bedtime(ageMonths: 60), 19 * 60 + 45)
        XCTAssertEqual(Evening.bedtime(ageMonths: 96), 20 * 60)
    }

    func testByTheClockSheReadsThenSleeps() {
        let evening = Evening(bedtime: 19 * 60 + 15)
        XCTAssertFalse(evening.inBedroom(minute: 18 * 60 + 40))
        XCTAssertTrue(evening.inBedroom(minute: 18 * 60 + 45))
        XCTAssertEqual(evening.pose(minute: 19 * 60), .reading)
        XCTAssertEqual(evening.pose(minute: 19 * 60 + 15), .asleep)
        XCTAssertTrue(evening.inBedroom(minute: 3 * 60))
        XCTAssertFalse(evening.inBedroom(minute: 7 * 60))
    }

    func testFollowingTheLogs() {
        var evening = Evening(bedtime: 19 * 60, followsLogs: true, allAsleep: false)
        // Someone is still up: she reads in the evening, and sits up in the night.
        XCTAssertEqual(evening.pose(minute: 20 * 60), .reading)
        XCTAssertEqual(evening.pose(minute: 23 * 60), .stirring)
        // Everyone asleep straight after tea: she is in bed too.
        evening.allAsleep = true
        XCTAssertTrue(evening.inBedroom(minute: 18 * 60 + 30))
        XCTAssertEqual(evening.pose(minute: 18 * 60 + 30), .asleep)
    }

    func testSheStirsWhenAChildIsSeenToInTheNight() {
        let now = Date.now
        let evening = Evening(bedtime: 19 * 60, followsLogs: true, allAsleep: true, lastLogged: now.addingTimeInterval(-120))
        XCTAssertEqual(evening.pose(minute: 2 * 60, at: now), .stirring)
        XCTAssertEqual(evening.pose(minute: 2 * 60, at: now.addingTimeInterval(600)), .asleep)
    }
}
