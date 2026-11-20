import XCTest
@testable import Puggle

final class NextUpTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private func ago(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }

    func testFeedIsGuessedFromTheUsualGap() {
        // Fed every three hours, the last one two hours ago: the next is an hour away.
        let feeds = (0..<8).map { ago(2 + Double($0) * 3) }
        let guess = NextUp.soonest(feeds: feeds, sleeps: [], nappies: [], now: now)
        XCTAssertEqual(guess?.kind, .feed)
        XCTAssertEqual(guess?.at.timeIntervalSince(now) ?? 0, 3600, accuracy: 150)
    }

    func testNothingIsSaidOnceTheTimeHasPassed() {
        // Fed every three hours, the last one four hours ago: the guess is behind, so there is none.
        let feeds = (0..<8).map { ago(4 + Double($0) * 3) }
        XCTAssertNil(NextUp.soonest(feeds: feeds, sleeps: [], nappies: [], now: now))
    }

    func testTooLittleToGoOnSaysNothing() {
        XCTAssertNil(NextUp.soonest(feeds: [ago(1), ago(4), ago(7)], sleeps: [], nappies: [], now: now))
    }

    func testTheNightIsLeftOutOfTheUsualGap() {
        // Three-hour gaps by day and one eleven-hour night: the usual gap is still three hours.
        let feeds = [1.0, 4, 7, 18, 21, 24, 27].map(ago)
        XCTAssertEqual(NextUp.usualGap(feeds, now: now, least: 45 * 60, most: 6 * 3600) ?? 0, 3 * 3600, accuracy: 1)
    }

    func testTheSoonestOfTheThreeWins() {
        let feeds = (0..<8).map { ago(1 + Double($0) * 3) }       // next in two hours
        let nappies = (0..<8).map { ago(1.5 + Double($0) * 2) }   // next in half an hour
        let guess = NextUp.soonest(feeds: feeds, sleeps: [], nappies: nappies, now: now)
        XCTAssertEqual(guess?.kind, .nappy)
    }

    func testSleepComesFromHowLongTheyAreUsuallyAwake() {
        // An hour's nap, then two hours awake, over and over. Woke an hour ago: the next sleep is an hour away.
        let sleeps = (0..<6).map { (start: ago(2 + Double($0) * 3), end: Optional(ago(1 + Double($0) * 3))) }
        let guess = NextUp.soonest(feeds: [], sleeps: sleeps, nappies: [], now: now)
        XCTAssertEqual(guess?.kind, .sleep)
        XCTAssertEqual(guess?.at.timeIntervalSince(now) ?? 0, 3600, accuracy: 150)
    }

    func testNoSleepGuessWhileAsleep() {
        var sleeps = (1..<6).map { (start: ago(2 + Double($0) * 3), end: Optional(ago(1 + Double($0) * 3))) }
        sleeps.append((start: ago(0.5), end: nil))
        XCTAssertNil(NextUp.soonest(feeds: [], sleeps: sleeps, nappies: [], now: now))
    }
}
