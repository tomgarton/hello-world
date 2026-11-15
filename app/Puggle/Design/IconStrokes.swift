import SwiftUI

/// An icon's own strokes, so the app can draw it on line by line (Tom, 15 November 2026: of Apple's symbol
/// effects, drawing on is the one he likes best). Written by `docs/tools/make_icons.py --install` into
/// IconStrokes.json: the larger drawing of each icon, as the path data it is made from.
struct IconStrokes: Decodable {
    let box: CGFloat
    let turn: CGFloat
    let weight: CGFloat
    let fine: CGFloat
    let lines: [String]
    let fineLines: [String]
    let ink: [String]

    static let all: [String: IconStrokes] = {
        guard let url = Bundle.main.url(forResource: "IconStrokes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: IconStrokes].self, from: data)) ?? [:]
    }()

    /// How long the strokes are in all, in the icon's own units, so each takes time in step with its length.
    var parts: [(path: Path, fine: Bool, length: CGFloat)] {
        (lines.map { ($0, false) } + fineLines.map { ($0, true) }).map { text, fine in
            let path = SVGPath.path(text)
            return (path, fine, SVGPath.length(of: path))
        }
    }
}

/// The lines of an icon, drawn as far as `progress`: one stroke after another, each for a share of the time
/// that matches its length. At 1 it is the whole icon.
struct IconLines: Shape {
    let strokes: IconStrokes
    var progress: CGFloat
    /// Only the fine lines, or only the others: the two are stroked at different weights.
    let fine: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let parts = strokes.parts
        let total = max(parts.reduce(0) { $0 + $1.length }, 1)
        var drawn = Path(), before: CGFloat = 0
        for part in parts {
            let from = before / total, to = (before + part.length) / total
            before += part.length
            guard part.fine == fine, progress > from else { continue }
            let share = min(1, (progress - from) / max(to - from, 0.0001))
            drawn.addPath(share >= 1 ? part.path : part.path.trimmedPath(from: 0, to: share))
        }
        let scale = rect.width / strokes.box
        var place = CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale)
        if strokes.turn != 0 {
            place = place.translatedBy(x: strokes.box / 2, y: strokes.box / 2).rotated(by: strokes.turn * .pi / 180)
                .translatedBy(x: -strokes.box / 2, y: -strokes.box / 2)
        }
        return drawn.applying(place)
    }
}

/// Reads the path data the icons are written in: M, L, H, V, C, A and Z, all with absolute positions.
enum SVGPath {
    static func path(_ text: String) -> Path {
        var path = Path()
        var numbers: [CGFloat] = []
        var command: Character = "M"
        var current = CGPoint.zero, start = CGPoint.zero
        var token = ""

        func flush() {
            if let value = Double(token) { numbers.append(CGFloat(value)) }
            token = ""
        }
        func run() {
            switch command {
            case "M":
                while numbers.count >= 2 {
                    current = CGPoint(x: numbers[0], y: numbers[1]); numbers.removeFirst(2)
                    if path.isEmpty || start != current || true { path.move(to: current) }
                    start = current
                    command = "L"
                    if numbers.count >= 2 { run(); return }
                }
            case "L":
                while numbers.count >= 2 {
                    current = CGPoint(x: numbers[0], y: numbers[1]); numbers.removeFirst(2)
                    path.addLine(to: current)
                }
            case "H":
                while let x = numbers.first { numbers.removeFirst(); current.x = x; path.addLine(to: current) }
            case "V":
                while let y = numbers.first { numbers.removeFirst(); current.y = y; path.addLine(to: current) }
            case "C":
                while numbers.count >= 6 {
                    let end = CGPoint(x: numbers[4], y: numbers[5])
                    path.addCurve(to: end, control1: CGPoint(x: numbers[0], y: numbers[1]), control2: CGPoint(x: numbers[2], y: numbers[3]))
                    current = end; numbers.removeFirst(6)
                }
            case "A":
                while numbers.count >= 7 {
                    let end = CGPoint(x: numbers[5], y: numbers[6])
                    arc(&path, from: current, to: end, rx: numbers[0], ry: numbers[1], turn: numbers[2], large: numbers[3] != 0, sweep: numbers[4] != 0)
                    current = end; numbers.removeFirst(7)
                }
            case "Z":
                path.closeSubpath(); current = start
            default: break
            }
            numbers = []
        }

        for character in text {
            if character.isLetter && character != "e" {
                flush(); run()
                command = character
                if character == "Z" { run() }
            } else if character == "," || character == " " {
                flush()
            } else if character == "-" && !token.isEmpty && !token.hasSuffix("e") {
                flush(); token = "-"
            } else {
                token.append(character)
            }
        }
        flush(); run()
        return path
    }

    /// An elliptical arc as curves, by the method in the SVG notes: find the centre, then step round it.
    private static func arc(_ path: inout Path, from: CGPoint, to: CGPoint, rx: CGFloat, ry: CGFloat, turn: CGFloat, large: Bool, sweep: Bool) {
        guard rx > 0, ry > 0, from != to else { path.addLine(to: to); return }
        let phi = turn * .pi / 180, cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (from.x - to.x) / 2, dy = (from.y - to.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy, y1 = -sinPhi * dx + cosPhi * dy
        var rx = rx, ry = ry
        let grow = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if grow > 1 { rx *= sqrt(grow); ry *= sqrt(grow) }
        let top = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let bottom = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let factor = (large == sweep ? -1 : 1) * sqrt(max(0, top / max(bottom, 1e-9)))
        let cx1 = factor * rx * y1 / ry, cy1 = -factor * ry * x1 / rx
        let cx = cosPhi * cx1 - sinPhi * cy1 + (from.x + to.x) / 2
        let cy = sinPhi * cx1 + cosPhi * cy1 + (from.y + to.y) / 2
        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let value = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return value
        }
        let startAngle = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var delta = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep, delta > 0 { delta -= 2 * .pi } else if sweep, delta < 0 { delta += 2 * .pi }
        let steps = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let each = delta / CGFloat(steps), k = 4 / 3 * tan(each / 4)
        var a = startAngle
        for _ in 0..<steps {
            let b = a + each
            func point(_ t: CGFloat, _ ox: CGFloat, _ oy: CGFloat) -> CGPoint {
                let x = rx * (cos(t) + ox), y = ry * (sin(t) + oy)
                return CGPoint(x: cosPhi * x - sinPhi * y + cx, y: sinPhi * x + cosPhi * y + cy)
            }
            path.addCurve(to: point(b, 0, 0), control1: point(a, -k * sin(a), k * cos(a)), control2: point(b, k * sin(b), -k * cos(b)))
            a = b
        }
    }

    /// A path's length, near enough: it is walked in short straight pieces.
    static func length(of path: Path) -> CGFloat {
        var total: CGFloat = 0, last = CGPoint.zero, start = CGPoint.zero
        func add(_ point: CGPoint) { total += hypot(point.x - last.x, point.y - last.y); last = point }
        path.forEach { element in
            switch element {
            case .move(let to): last = to; start = to
            case .line(let to): add(to)
            case .quadCurve(let to, let control):
                let from = last
                for i in 1...8 {
                    let t = CGFloat(i) / 8, u = 1 - t
                    add(CGPoint(x: u * u * from.x + 2 * u * t * control.x + t * t * to.x, y: u * u * from.y + 2 * u * t * control.y + t * t * to.y))
                }
            case .curve(let to, let c1, let c2):
                let from = last
                for i in 1...10 {
                    let t = CGFloat(i) / 10, u = 1 - t
                    let x = u * u * u * from.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * to.x
                    let y = u * u * u * from.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * to.y
                    add(CGPoint(x: x, y: y))
                }
            case .closeSubpath: add(start)
            }
        }
        return total
    }
}
