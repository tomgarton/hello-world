import XCTest
@testable import Puggle

/// The night sky follows the half of the world the family is in.
final class HemisphereTests: XCTestCase {
    func testRegionsSouthOfTheEquator() {
        XCTAssertTrue(Hemisphere.isSouth(region: "AU"))
        XCTAssertTrue(Hemisphere.isSouth(region: "NZ"))
        XCTAssertFalse(Hemisphere.isSouth(region: "GB"))
        XCTAssertFalse(Hemisphere.isSouth(region: "US"))
        XCTAssertFalse(Hemisphere.isSouth(region: nil))
    }

    func testEachAuroraHasItsOwnColours() {
        // Borealis is strongest in green; australis, as seen from Australia and New Zealand, in pink.
        XCTAssertEqual(Aurora.borealis.max { $0.strength < $1.strength }?.colour, 0x7FE0B0)
        XCTAssertEqual(Aurora.australis.max { $0.strength < $1.strength }?.colour, 0xF29BC4)
    }
}
