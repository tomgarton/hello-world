import XCTest
import SwiftUI
@testable import Puggle

final class IconStrokesTests: XCTestCase {
    func testAnArcIsReadAsARoundShape() {
        // A full circle of radius 5 about (12, 12), as two half arcs.
        let path = SVGPath.path("M7 12A5 5 0 1 0 17 12A5 5 0 1 0 7 12Z")
        let box = path.boundingRect
        XCTAssertEqual(box.minX, 7, accuracy: 0.05)
        XCTAssertEqual(box.maxX, 17, accuracy: 0.05)
        XCTAssertEqual(box.minY, 7, accuracy: 0.05)
        XCTAssertEqual(box.maxY, 17, accuracy: 0.05)
        XCTAssertEqual(SVGPath.length(of: path), 2 * .pi * 5, accuracy: 0.3)
    }

    func testLinesAcrossAndUpAreRead() {
        let path = SVGPath.path("M2 4H10V9L2 9Z")
        XCTAssertEqual(path.boundingRect, CGRect(x: 2, y: 4, width: 8, height: 5))
    }

    func testEveryIconStaysInsideItsBox() {
        XCTAssertFalse(IconStrokes.all.isEmpty)
        for (name, strokes) in IconStrokes.all {
            for part in strokes.parts {
                let box = part.path.boundingRect
                XCTAssertTrue(box.minX >= -1 && box.minY >= -1 && box.maxX <= strokes.box + 1 && box.maxY <= strokes.box + 1, "\(name) \(box)")
                XCTAssertGreaterThan(part.length, 0, name)
            }
        }
    }

    func testHalfwayDrawsLessThanAll() {
        guard let nappy = IconStrokes.all["icon-nappy"] else { return XCTFail("no nappy") }
        let frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        let half = SVGPath.length(of: IconLines(strokes: nappy, progress: 0.5, fine: false).path(in: frame))
        let whole = SVGPath.length(of: IconLines(strokes: nappy, progress: 1, fine: false).path(in: frame))
        XCTAssertEqual(half / whole, 0.5, accuracy: 0.08)
    }
}
