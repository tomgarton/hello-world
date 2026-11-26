import XCTest
@testable import Puggle

/// Which three facts a child's card shows on Today, and when it offers the sleep button.
final class ChildFactTests: XCTestCase {
    func testABabyShowsFedAwakeAndNappy() {
        XCTAssertEqual(ChildFact.kinds(milk: true, potty: false, asleep: false), [.fed, .awake, .nappy])
    }

    func testAnOlderChildShowsAwakeAteAndWhatTheyUse() {
        XCTAssertEqual(ChildFact.kinds(milk: false, potty: true, asleep: false), [.ate, .awake, .potty])
        XCTAssertEqual(ChildFact.kinds(milk: false, potty: false, asleep: false), [.ate, .awake, .nappy])
    }

    func testAsleepTakesThePlaceOfAwake() {
        XCTAssertEqual(ChildFact.kinds(milk: true, potty: false, asleep: true), [.fed, .asleep, .nappy])
        XCTAssertEqual(ChildFact.kinds(milk: false, potty: true, asleep: true), [.ate, .asleep, .potty])
    }

    func testTheSleepButtonIsForNappersTheVeryYoungAndTheEvening() {
        // A five-year-old who no longer naps: nothing at midday, there again from five.
        XCTAssertFalse(ChildFact.offersSleep(asleep: false, hour: 13, napped: false, months: 60))
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 17, napped: false, months: 60))
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 3, napped: false, months: 60))
        // One who napped in the last two weeks keeps it all day.
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 13, napped: true, months: 60))
        // Two and a half, no naps logged yet: still offered, as most still nap.
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 13, napped: false, months: 30))
        // A baby has it whether or not a nap has been logged yet.
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 13, napped: false, months: 5))
        // Asleep: always, so they can be woken.
        XCTAssertTrue(ChildFact.offersSleep(asleep: true, hour: 13, napped: false, months: 60))
    }
}
