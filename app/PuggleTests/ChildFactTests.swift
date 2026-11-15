import XCTest
@testable import Puggle

/// Which three facts a child's card shows on Today, and when it offers the sleep button.
final class ChildFactTests: XCTestCase {
    func testABabyShowsFedAwakeAndNappy() {
        XCTAssertEqual(ChildFact.kinds(milk: true, potty: false, asleep: false), [.fed, .awake, .nappy])
    }

    func testAnOlderChildShowsAwakeAteAndWhatTheyUse() {
        XCTAssertEqual(ChildFact.kinds(milk: false, potty: true, asleep: false), [.awake, .ate, .potty])
        XCTAssertEqual(ChildFact.kinds(milk: false, potty: false, asleep: false), [.awake, .ate, .nappy])
    }

    func testAsleepTakesThePlaceOfAwake() {
        XCTAssertEqual(ChildFact.kinds(milk: true, potty: false, asleep: true), [.fed, .asleep, .nappy])
        XCTAssertEqual(ChildFact.kinds(milk: false, potty: true, asleep: true), [.asleep, .ate, .potty])
    }

    func testTheSleepButtonIsForNappersTheVeryYoungAndTheEvening() {
        // A three-year-old who no longer naps: nothing at midday, there again from five.
        XCTAssertFalse(ChildFact.offersSleep(asleep: false, hour: 13, napped: false, months: 40))
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 17, napped: false, months: 40))
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 3, napped: false, months: 40))
        // One who napped in the last two weeks keeps it all day.
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 13, napped: true, months: 40))
        // A baby has it whether or not a nap has been logged yet.
        XCTAssertTrue(ChildFact.offersSleep(asleep: false, hour: 13, napped: false, months: 5))
        // Asleep: always, so they can be woken.
        XCTAssertTrue(ChildFact.offersSleep(asleep: true, hour: 13, napped: false, months: 40))
    }
}
