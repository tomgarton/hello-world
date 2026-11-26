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

    func testEveryIconHasADrawingThatStaysInsideItsBox() {
        XCTAssertEqual(IconStrokes.all.count, 20)
        for name in IconStrokes.all.keys {
            guard let drawing = IconDrawing.named(name) else { XCTFail(name); continue }
            XCTAssertEqual(drawing.lines.count, IconStrokes.all[name]?.strokes.count, name)
            for line in drawing.lines {
                XCTAssertGreaterThan(line.length, 0, name)
                for point in line.points {
                    XCTAssertTrue(point.x >= -1.5 && point.y >= -1.5 && point.x <= drawing.box + 1.5 && point.y <= drawing.box + 1.5, "\(name) \(point)")
                }
            }
        }
    }

    /// On a screen a ring runs clockwise when this sum is above zero.
    private func turnsClockwise(_ points: [CGPoint]) -> Bool {
        var sum: CGFloat = 0
        for index in 0..<(points.count - 1) { sum += points[index].x * points[index + 1].y - points[index + 1].x * points[index].y }
        return sum > 0
    }

    func testAClosedStrokeRunsClockwiseFromWhereItIsAsked() {
        // A square written anticlockwise from its bottom left.
        let square = [CGPoint(x: 0, y: 10), CGPoint(x: 10, y: 10), CGPoint(x: 10, y: 0), CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 10)]
        XCTAssertFalse(turnsClockwise(square))
        let (arranged, way) = IconDrawing.arrange(square, closed: true, mode: "TL")
        XCTAssertEqual(way, .single)
        XCTAssertEqual(arranged.first, CGPoint(x: 0, y: 0))
        XCTAssertEqual(arranged.last, CGPoint(x: 0, y: 0))
        XCTAssertTrue(turnsClockwise(arranged))
        XCTAssertFalse(turnsClockwise(IconDrawing.arrange(square, closed: true, mode: "TL-").0))
    }

    func testEveryClosedStrokeInEveryIconRunsTheWayItWasAsked() {
        for (name, strokes) in IconStrokes.all {
            guard let drawing = IconDrawing.named(name) else { continue }
            for (line, stroke) in zip(drawing.lines, strokes.strokes) where line.closed {
                XCTAssertEqual(turnsClockwise(line.points), !stroke.mode.hasSuffix("-"), "\(name) \(stroke.mode)")
            }
        }
    }

    func testAStrokeDrawsFromItsStartItsMiddleOrItsEnds() {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0)]
        func line(_ way: DrawLine.Way) -> DrawLine { DrawLine(points: points, along: [0, 10], closed: false, fine: false, way: way, group: 0, track: 0) }
        XCTAssertEqual(line(.single).drawn(0.3).boundingRect.maxX, 3, accuracy: 0.001)
        XCTAssertEqual(line(.single).drawn(0.3).boundingRect.minX, 0, accuracy: 0.001)
        let middle = line(.midOut).drawn(0.4).boundingRect
        XCTAssertEqual(middle.minX, 3, accuracy: 0.001)
        XCTAssertEqual(middle.maxX, 7, accuracy: 0.001)
        XCTAssertEqual(SVGPath.length(of: line(.endsIn).drawn(0.4)), 4, accuracy: 0.001)
        // Drawn off the same way, what is left is the rest.
        XCTAssertEqual(line(.single).left(0.3).boundingRect.minX, 3, accuracy: 0.001)
        XCTAssertEqual(SVGPath.length(of: line(.midOut).left(0.4)), 6, accuracy: 0.001)
        for way in [DrawLine.Way.single, .midOut, .endsIn] {
            XCTAssertEqual(SVGPath.length(of: line(way).drawn(0.25)) + SVGPath.length(of: line(way).left(0.25)), 10, accuracy: 0.001)
            XCTAssertTrue(line(way).drawn(0).isEmpty)
            XCTAssertEqual(SVGPath.length(of: line(way).drawn(1)), 10, accuracy: 0.001)
        }
    }

    func testTheThreeWaysOfPlayingIt() {
        guard let nappy = IconDrawing.named("icon-nappy") else { return XCTFail("no nappy") }
        let layered = nappy.timeline(.byLayer), together = nappy.timeline(.wholeSymbol), single = nappy.timeline(.individually)
        // Whole symbol: every path starts and ends at the same time.
        XCTAssertTrue(together.tracks.allSatisfy { $0.start == 0 && $0.duration == together.tracks[0].duration })
        // One at a time: no group starts before the one before it has ended.
        let ends = Dictionary(grouping: single.tracks, by: { nappy.lines[$0.lines[0]].group }).mapValues { $0.map { $0.start + $0.duration }.max() ?? 0 }
        let starts = Dictionary(grouping: single.tracks, by: { nappy.lines[$0.lines[0]].group }).mapValues { $0.map(\.start).min() ?? 0 }
        for group in 1..<starts.count { XCTAssertGreaterThanOrEqual(starts[group] ?? 0, (ends[group - 1] ?? 0) - 0.0001) }
        // By layer: each starts after the last has started and before it has ended.
        let begin = Dictionary(grouping: layered.tracks, by: { nappy.lines[$0.lines[0]].group }).mapValues { $0.map(\.start).min() ?? 0 }
        let finish = Dictionary(grouping: layered.tracks, by: { nappy.lines[$0.lines[0]].group }).mapValues { $0.map { $0.start + $0.duration }.max() ?? 0 }
        for group in 1..<begin.count {
            XCTAssertGreaterThan(begin[group] ?? 0, begin[group - 1] ?? 0)
            XCTAssertLessThan(begin[group] ?? 0, finish[group - 1] ?? 0)
        }
        XCTAssertLessThan(together.total, layered.total)
        XCTAssertLessThan(layered.total, single.total)
        // A quicker pace is the same thing in less time.
        XCTAssertEqual(nappy.timeline(.byLayer, pace: 2).total, layered.total / 2, accuracy: 0.0001)
    }

    func testEveryIconIsWholeAtTheEndAndEmptyAtTheStart() {
        for name in IconStrokes.all.keys {
            guard let drawing = IconDrawing.named(name) else { continue }
            for playback in DrawPlayback.allCases {
                let timeline = drawing.timeline(playback)
                XCTAssertTrue(drawing.shares(at: timeline.total, on: timeline).allSatisfy { $0 > 0.999 }, "\(name) \(playback)")
                XCTAssertTrue(drawing.shares(at: 0, on: timeline).allSatisfy { $0 == 0 }, "\(name) \(playback)")
                // By layer, the usual way, stays brisk. One at a time is allowed to take its time.
                let limit = playback == .byLayer ? 1.11 : playback == .wholeSymbol ? 0.9 : 2.6
                XCTAssertLessThan(timeline.total, limit, "\(name) \(playback) takes \(timeline.total)")
                XCTAssertTrue(timeline.appears.allSatisfy { $0.start + $0.duration <= timeline.total + 0.0001 }, name)
            }
        }
    }

    func testStrokesInATrackAreDrawnOneAfterAnother() {
        guard let nappy = IconDrawing.named("icon-nappy") else { return XCTFail("no nappy") }
        let timeline = nappy.timeline(.individually)
        // The outline is two strokes in one track: the top, then the rest. Part-way, the top is done first.
        guard let outline = timeline.tracks.first(where: { $0.lines.count == 2 }) else { return XCTFail("no outline track") }
        let early = nappy.shares(at: outline.start + outline.duration * 0.35, on: timeline)
        XCTAssertGreaterThan(early[outline.lines[0]], early[outline.lines[1]])
        let late = nappy.shares(at: outline.start + outline.duration * 0.9, on: timeline)
        XCTAssertEqual(late[outline.lines[0]], 1, accuracy: 0.0001)
        XCTAssertGreaterThan(late[outline.lines[1]], 0.5)
    }
}
