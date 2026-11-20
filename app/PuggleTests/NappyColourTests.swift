import XCTest
@testable import Puggle

/// A nappy's colour belongs to a dirty one only (20 November 2026).
final class NappyColourTests: XCTestCase {
    func testColourIsKeptForDirtyAndBoth() {
        XCTAssertEqual(LogSheet.colour("Green", for: "Dirty"), "Green")
        XCTAssertEqual(LogSheet.colour("Mustard", for: "Both"), "Mustard")
    }

    func testColourIsDroppedForWetAndDry() {
        XCTAssertNil(LogSheet.colour("Green", for: "Wet"))
        XCTAssertNil(LogSheet.colour("Green", for: "Dry"))
        XCTAssertNil(LogSheet.colour("", for: "Dirty"))
    }
}
