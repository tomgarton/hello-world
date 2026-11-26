import XCTest
@testable import Puggle

/// The greeting at the top of Today, and the one line under it.
final class TodayHeadingTests: XCTestCase {
    func testTheGreetingFollowsTheTimeOfDay() {
        XCTAssertEqual(TodayHeading.greeting(hour: 7, name: "Tom"), "Morning, Tom")
        XCTAssertEqual(TodayHeading.greeting(hour: 13, name: "Tom"), "Afternoon, Tom")
        XCTAssertEqual(TodayHeading.greeting(hour: 19, name: " Tom "), "Evening, Tom")
        XCTAssertEqual(TodayHeading.greeting(hour: 23, name: "Tom"), "Hello, Tom")
        XCTAssertEqual(TodayHeading.greeting(hour: 3, name: "Tom"), "Hello, Tom")
        XCTAssertEqual(TodayHeading.greeting(hour: 7, name: ""), "Morning")
    }

    func testTheLineSaysOneThingInOrderOfWhatMattersNow() {
        var facts = TodayHeading.Facts()
        XCTAssertEqual(TodayHeading.line(facts), "", "An empty day with no weather says nothing")
        facts.weather = "18° and raining outside."
        XCTAssertEqual(TodayHeading.line(facts), "18° and raining outside.")
        facts.numbers = ["Ollie: 4 feeds, 510 ml · 3 nappies", "Bea: 2 meals"]
        XCTAssertEqual(TodayHeading.line(facts), "Ollie: 4 feeds, 510 ml · 3 nappies\nBea: 2 meals")
        facts.lastNight = "Ollie slept 9h 20m last night · Woke twice"
        XCTAssertEqual(TodayHeading.line(facts), "Ollie slept 9h 20m last night · Woke twice")
        facts.feeding = ["Ollie"]
        XCTAssertEqual(TodayHeading.line(facts), "Ollie is feeding.")
        facts.asleep = [("Bea", "40 min")]
        XCTAssertEqual(TodayHeading.line(facts), "Bea has been asleep for 40 min.")
        facts.asleep = [("Bea", "40 min"), ("Ollie", "5 min")]
        XCTAssertEqual(TodayHeading.line(facts), "Bea and Ollie are asleep.")
        facts.due = ["Due for Ollie · Calpol · 14:00"]
        XCTAssertEqual(TodayHeading.line(facts), "Due for Ollie · Calpol · 14:00")
    }

    func testAsleepWithNothingCountedSaysOnlyThat() {
        var facts = TodayHeading.Facts()
        facts.asleep = [("Bea", nil)]
        XCTAssertEqual(TodayHeading.line(facts), "Bea is asleep.")
    }

    func testLastNightIsTheNewsOnlyUntilTen() {
        XCTAssertTrue(TodayHeading.isEarly(hour: 7))
        XCTAssertFalse(TodayHeading.isEarly(hour: 10))
        XCTAssertFalse(TodayHeading.isEarly(hour: 2))
    }

    func testTheWeatherInWords() {
        XCTAssertEqual(TodayHeading.weather(.rain, degrees: 18), "18° and raining outside.")
        XCTAssertEqual(TodayHeading.weather(.clear, degrees: nil), "Fine outside.")
    }
}
