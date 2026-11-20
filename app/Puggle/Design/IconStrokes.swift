import SwiftUI

// Icons that draw themselves on, after the Draw animation in SF Symbols 7 (Tom, 15 November 2026).
//
// Apple's guidance, read closely (the Human Interface Guidelines on SF Symbols, the Symbols framework, and
// the WWDC25 session "What's new in SF Symbols 7"), and how each part is met here:
//
//  - Drawing follows the path, like a handwritten stroke. Each path has a start and an end, so a direction,
//    chosen for the symbol's design and meaning. Here: `DRAW` in docs/tools/make_icons.py sets each stroke's
//    start and direction, and its place in the order.
//  - Something symmetrical can draw from its middle, both ways at once. Here: `Way.midOut` and `.endsIn`.
//  - A closed shape draws one way round, clockwise unless said otherwise. Here: closed strokes are turned
//    clockwise and begin at a chosen point.
//  - Three ways to play it. By layer, the usual one: each layer starts a little after the last, overlapping.
//    Whole symbol: every path starts and ends together, quicker and more immediate. Individually: one layer
//    at a time. Here: `DrawPlayback`, where a layer is a motion group.
//  - Parts that are not drawn "appear in". Here: colours and filled details fade and grow into place.
//  - End caps are round by default and keep the path's own cap while drawing. Here: round throughout.
//  - Draw Off takes the symbol away, either on in the same direction or back the way it came. Here:
//    `IconDrawView.Phase.off(reversed:)`.
//  - Variable Draw shows progress: the path drawn to a share of its length over a faint copy of itself.
//    Here: `.reink` uses that look for a moment, to say an entry has been written.
//
// Apple gives no timings. Those here are chosen: a pen that eases in and out of each stroke, at a steady pace.

/// An icon's strokes and colours as the generator wrote them (IconStrokes.json): the larger drawing of
/// each icon, as the path data it is made from, in the order it is drawn.
struct IconStrokes: Decodable {
    struct Stroke: Decodable {
        let d: String
        let fine: Bool
        /// How it is drawn: see `DRAW` in docs/tools/make_icons.py.
        let mode: String
        let group: Int
        let track: Int
    }

    struct Fill: Decodable {
        let d: String
        /// "accent" (the colour the person can change), "fixed" (a colour of its own) or "ink" (a filled detail in the line's colour).
        let kind: String
        let colour: String?
        /// The motion group it appears after.
        let after: Int
        /// "centre", or "up" to rise from its foot.
        let grow: String
    }

    let box: CGFloat
    let turn: CGFloat
    let weight: CGFloat
    let fine: CGFloat
    let strokes: [Stroke]
    let fills: [Fill]

    static let all: [String: IconStrokes] = {
        guard let url = Bundle.main.url(forResource: "IconStrokes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: IconStrokes].self, from: data)) ?? [:]
    }()
}

/// How the layers of a drawing are played, as Apple names them.
enum DrawPlayback: CaseIterable {
    /// Each motion group starts a little after the one before, overlapping it. The usual one.
    case byLayer
    /// Everything starts and ends together. Quicker and more immediate.
    case wholeSymbol
    /// One motion group at a time: the next starts when the last has finished.
    case individually
}

/// One stroke made ready: its points in the order they are drawn, in the icon's own units and the right way up.
struct DrawLine {
    enum Way { case single, midOut, endsIn }

    let points: [CGPoint]
    /// How far along the stroke each point is.
    let along: [CGFloat]
    let closed: Bool
    let fine: Bool
    let way: Way
    let group: Int
    let track: Int

    var length: CGFloat { along.last ?? 0 }
    /// How far one pen travels: half, where two draw it from the middle or from both ends.
    var travel: CGFloat { way == .single ? length : length / 2 }

    /// The whole stroke.
    var whole: Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        let last = closed ? points.count - 1 : points.count
        for point in points[1..<max(1, last)] { path.addLine(to: point) }
        if closed { path.closeSubpath() }
        return path
    }

    /// The part between two distances along it.
    private func piece(_ from: CGFloat, _ to: CGFloat, into path: inout Path) {
        let from = max(0, from), to = min(length, to)
        guard to - from > 0.0001, points.count > 1 else { return }
        func point(at distance: CGFloat, in segment: Int) -> CGPoint {
            let a = points[segment], b = points[segment + 1]
            let span = along[segment + 1] - along[segment]
            let share = span > 0 ? (distance - along[segment]) / span : 0
            return CGPoint(x: a.x + (b.x - a.x) * share, y: a.y + (b.y - a.y) * share)
        }
        var segment = 0
        while segment < points.count - 2, along[segment + 1] <= from { segment += 1 }
        path.move(to: point(at: from, in: segment))
        while segment < points.count - 1 {
            if along[segment + 1] >= to {
                path.addLine(to: point(at: to, in: segment))
                return
            }
            path.addLine(to: points[segment + 1])
            segment += 1
        }
    }

    /// What shows once a share of it has been drawn on.
    func drawn(_ share: CGFloat) -> Path {
        if share >= 0.9995 { return whole }
        var path = Path()
        guard share > 0 else { return path }
        let full = length
        switch way {
        case .single:
            piece(0, share * full, into: &path)
        case .midOut:
            piece(full / 2 - share * full / 2, full / 2 + share * full / 2, into: &path)
        case .endsIn:
            piece(0, share * full / 2, into: &path)
            piece(full - share * full / 2, full, into: &path)
        }
        return path
    }

    /// What is left once a share of it has been drawn off, going the same way it was drawn on.
    func left(_ share: CGFloat) -> Path {
        if share <= 0.0005 { return whole }
        var path = Path()
        guard share < 1 else { return path }
        let full = length
        switch way {
        case .single:
            piece(share * full, full, into: &path)
        case .midOut:
            piece(0, full / 2 - share * full / 2, into: &path)
            piece(full / 2 + share * full / 2, full, into: &path)
        case .endsIn:
            piece(share * full / 2, full - share * full / 2, into: &path)
        }
        return path
    }
}

/// A colour or a filled detail made ready.
struct DrawFill {
    enum Kind: Equatable { case accent, fixed(UInt32), ink }
    let path: Path
    let kind: Kind
    let after: Int
    let rises: Bool
    let bounds: CGRect
}

/// When each track starts and how long it takes, and when each colour appears, in seconds.
struct DrawTimeline {
    struct Track {
        let lines: [Int]
        let start: Double
        let duration: Double
        let travel: CGFloat
    }

    struct Appear {
        let start: Double
        let duration: Double
    }

    let tracks: [Track]
    /// One for each fill, in the same order.
    let appears: [Appear]
    let total: Double

    /// A pen eases in and out of a stroke.
    static func eased(_ t: Double) -> Double {
        let t = min(1, max(0, t))
        return t * t * (3 - 2 * t)
    }

    /// Something appearing arrives quickly and settles.
    static func settled(_ t: Double) -> Double {
        let t = min(1, max(0, t))
        return 1 - pow(1 - t, 3)
    }
}

/// An icon ready to be drawn: its strokes arranged, its colours, and the order of things.
final class IconDrawing {
    let box: CGFloat
    let weight: CGFloat
    let fine: CGFloat
    let lines: [DrawLine]
    let fills: [DrawFill]

    private static var made: [String: IconDrawing?] = [:]

    /// The drawing for an icon by name, made once. Nil where the app has no strokes for it.
    static func named(_ name: String) -> IconDrawing? {
        if let ready = made[name] { return ready }
        let drawing = IconStrokes.all[name].map(IconDrawing.init)
        made[name] = drawing
        return drawing
    }

    init(_ strokes: IconStrokes) {
        box = strokes.box
        weight = strokes.weight
        fine = strokes.fine
        var turn = CGAffineTransform.identity
        if strokes.turn != 0 {
            turn = CGAffineTransform(translationX: strokes.box / 2, y: strokes.box / 2)
                .rotated(by: strokes.turn * .pi / 180)
                .translatedBy(x: -strokes.box / 2, y: -strokes.box / 2)
        }
        lines = strokes.strokes.compactMap { stroke in
            let (points, closed) = SVGPath.points(of: SVGPath.path(stroke.d).applying(turn))
            guard points.count > 1 else { return nil }
            let (arranged, way) = Self.arrange(points, closed: closed, mode: stroke.mode)
            var along: [CGFloat] = [0]
            for index in 1..<arranged.count {
                along.append(along[index - 1] + hypot(arranged[index].x - arranged[index - 1].x, arranged[index].y - arranged[index - 1].y))
            }
            return DrawLine(points: arranged, along: along, closed: closed, fine: stroke.fine, way: way, group: stroke.group, track: stroke.track)
        }
        fills = strokes.fills.map { fill in
            let path = SVGPath.path(fill.d).applying(turn)
            let kind: DrawFill.Kind = fill.kind == "accent" ? .accent : fill.kind == "ink" ? .ink
                : .fixed(UInt32((fill.colour ?? "#000000").dropFirst(), radix: 16) ?? 0)
            return DrawFill(path: path, kind: kind, after: fill.after, rises: fill.grow == "up", bounds: path.boundingRect)
        }
    }

    /// Puts a stroke's points in the order they are drawn. An open stroke may be turned round. A closed one
    /// is made to run clockwise (or the other way, where asked) and to begin at the point asked for.
    static func arrange(_ points: [CGPoint], closed: Bool, mode: String) -> ([CGPoint], DrawLine.Way) {
        guard closed else {
            switch mode {
            case "r": return (points.reversed(), .single)
            case "m": return (points, .midOut)
            case "e": return (points, .endsIn)
            default: return (points, .single)
            }
        }
        // A ring: the points without the last, which repeats the first.
        var ring = Array(points.dropLast())
        guard ring.count > 2 else { return (points, .single) }
        let counter = mode.hasSuffix("-")
        let anchor = counter ? String(mode.dropLast()) : mode
        if !anchor.isEmpty {
            let xs = ring.map(\.x), ys = ring.map(\.y)
            let midX = ((xs.min() ?? 0) + (xs.max() ?? 0)) / 2, midY = ((ys.min() ?? 0) + (ys.max() ?? 0)) / 2
            var target: CGPoint?
            if anchor.hasPrefix("@") {
                let parts = anchor.dropFirst().split(separator: ",").compactMap { Double($0) }
                if parts.count == 2 { target = CGPoint(x: parts[0], y: parts[1]) }
            }
            func score(_ p: CGPoint) -> CGFloat {
                if let target { return hypot(p.x - target.x, p.y - target.y) }
                switch anchor {
                case "T": return p.y * 1000 + abs(p.x - midX)
                case "B": return -p.y * 1000 + abs(p.x - midX)
                case "L": return p.x * 1000 + abs(p.y - midY)
                case "R": return -p.x * 1000 + abs(p.y - midY)
                case "TL": return p.x + p.y
                case "TR": return -p.x + p.y
                case "BL": return p.x - p.y
                case "BR": return -p.x - p.y
                default: return 0
                }
            }
            if let first = ring.indices.min(by: { score(ring[$0]) < score(ring[$1]) }), first > 0 {
                ring = Array(ring[first...] + ring[..<first])
            }
        }
        // On a screen, where y runs down, this sum is above zero for a ring that runs clockwise.
        var sum: CGFloat = 0
        for index in ring.indices {
            let a = ring[index], b = ring[(index + 1) % ring.count]
            sum += a.x * b.y - b.x * a.y
        }
        if (sum > 0) == counter { ring = [ring[0]] + ring.dropFirst().reversed() }
        return (ring + [ring[0]], .single)
    }

    /// The longest an icon takes to draw on by layer, in seconds, at the usual pace.
    static let longest = 1.1

    /// When everything happens for one way of playing it. `pace` above 1 is quicker.
    func timeline(_ playback: DrawPlayback = .byLayer, pace: Double = 1) -> DrawTimeline {
        // A stroke's time follows how far the pen travels, within limits, so a dash is not a blink and an
        // outline is not a wait.
        func time(for travel: CGFloat) -> Double { min(0.6, max(0.16, 0.12 + Double(travel) / 90)) }
        struct Made { var lines: [Int]; var travel: CGFloat; var duration: Double }
        let groups = Dictionary(grouping: lines.indices, by: { lines[$0].group })
        var tracks: [DrawTimeline.Track] = [], begins: [Int: Double] = [:], lasts: [Int: Double] = [:]
        var clock = 0.0
        var all: [(group: Int, made: [Made])] = []
        for group in groups.keys.sorted() {
            let byTrack = Dictionary(grouping: groups[group] ?? [], by: { lines[$0].track })
            let made = byTrack.keys.sorted().map { track -> Made in
                let members = byTrack[track] ?? []
                let travel = members.reduce(0) { $0 + lines[$1].travel }
                return Made(lines: members, travel: travel, duration: time(for: travel))
            }
            all.append((group, made))
        }
        let longest = all.flatMap { $0.made.map(\.duration) }.max() ?? 0.3
        let together = min(0.5, max(0.3, longest))
        for (group, made) in all {
            let duration = playback == .wholeSymbol ? together : (made.map(\.duration).max() ?? 0.2)
            let start = playback == .wholeSymbol ? 0 : clock
            begins[group] = start
            lasts[group] = duration
            for track in made {
                tracks.append(.init(lines: track.lines, start: start, duration: playback == .wholeSymbol ? together : track.duration, travel: track.travel))
            }
            switch playback {
            case .byLayer: clock = start + duration * 0.6      // the next begins before this one has ended
            case .individually: clock = start + duration       // the next waits its turn
            case .wholeSymbol: break
            }
        }
        // What is not drawn appears as its group's drawing is finishing, one after another.
        var waiting: [Int: Int] = [:]
        let appears = fills.map { fill -> DrawTimeline.Appear in
            let turn = waiting[fill.after, default: 0]
            waiting[fill.after] = turn + 1
            let start = (begins[fill.after] ?? 0) + (lasts[fill.after] ?? 0) * 0.75 + Double(turn) * 0.07
            return .init(start: start, duration: fill.rises ? 0.4 : 0.28)
        }
        let end = max(tracks.map { $0.start + $0.duration }.max() ?? 0, appears.map { $0.start + $0.duration }.max() ?? 0)
        // By layer stays brisk: an icon with many parts is hurried so the whole takes no more than this.
        let pace = playback == .byLayer ? pace * max(1, end / Self.longest) : pace
        return DrawTimeline(tracks: tracks.map { .init(lines: $0.lines, start: $0.start / pace, duration: $0.duration / pace, travel: $0.travel) },
                            appears: appears.map { .init(start: $0.start / pace, duration: $0.duration / pace) },
                            total: end / pace)
    }

    /// How much of each stroke has been drawn at a moment on a timeline, from 0 to 1.
    func shares(at time: Double, on timeline: DrawTimeline) -> [CGFloat] {
        var shares = [CGFloat](repeating: 0, count: lines.count)
        for track in timeline.tracks {
            let travelled = CGFloat(DrawTimeline.eased((time - track.start) / max(track.duration, 0.001))) * track.travel
            var before: CGFloat = 0
            for index in track.lines {
                let own = lines[index].travel
                shares[index] = own > 0 ? min(1, max(0, (travelled - before) / own)) : 1
                before += own
            }
        }
        return shares
    }
}

/// An icon part-way through being drawn, at a moment on its timeline. The moment is what is animated.
struct IconDrawView: View, Animatable {
    enum Phase: Equatable {
        /// Drawing on, from nothing: for an icon coming into view.
        case on
        /// Drawing off. Reversed goes back the way it came; otherwise it leaves the way it arrived.
        case off(reversed: Bool)
        /// The line fades to a faint copy and is drawn over again, the colours staying put: Apple's Variable
        /// Draw look, played once, for an icon already in view. It says an entry has been written.
        case reink
    }

    let drawing: IconDrawing
    let timeline: DrawTimeline
    let phase: Phase
    var time: Double
    /// The colour inside, and whether the icon is on a dark ground (a thinner line, dimmer fixed colours).
    let accent: Color
    let dark: Bool

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    /// How faint the copy under a line being drawn over is.
    static let faint = 0.28

    var body: some View {
        Canvas { context, size in
            let unit = size.width / drawing.box
            context.scaleBy(x: unit, y: unit)
            let thin: CGFloat = dark ? 0.62 : 1
            let moment: Double = phase == .off(reversed: true) ? timeline.total - time : time
            let leaving = phase == .off(reversed: false)

            // The colours and filled details. Drawing over, they stay as they are.
            func fill(_ index: Int) {
                let fill = drawing.fills[index]
                var arrived = 1.0
                if phase != .reink {
                    let appear = timeline.appears[index]
                    arrived = DrawTimeline.settled((moment - appear.start) / max(appear.duration, 0.001))
                    if leaving { arrived = 1 - arrived }
                }
                guard arrived > 0.001 else { return }
                var layer = context
                layer.opacity = fill.rises ? min(1, arrived * 3) : arrived
                if arrived < 0.999 {
                    if fill.rises {
                        layer.translateBy(x: 0, y: fill.bounds.maxY)
                        layer.scaleBy(x: 1, y: arrived)
                        layer.translateBy(x: 0, y: -fill.bounds.maxY)
                    } else {
                        let scale = 0.72 + 0.28 * arrived
                        layer.translateBy(x: fill.bounds.midX, y: fill.bounds.midY)
                        layer.scaleBy(x: scale, y: scale)
                        layer.translateBy(x: -fill.bounds.midX, y: -fill.bounds.midY)
                    }
                }
                switch fill.kind {
                case .accent: layer.fill(fill.path, with: .color(accent))
                case .ink: layer.fill(fill.path, with: .color(Palette.ink))
                case .fixed(let hex):
                    // In dark a fixed colour is a fifth dimmer, as in the picture, so the pale line shows against it.
                    let k = dark ? 0.8 : 1.0
                    let r = Double((hex >> 16) & 0xFF) / 255 * k, g = Double((hex >> 8) & 0xFF) / 255 * k, b = Double(hex & 0xFF) / 255 * k
                    layer.fill(fill.path, with: .color(Color(red: r, green: g, blue: b)))
                }
            }
            for index in drawing.fills.indices where drawing.fills[index].kind != .ink { fill(index) }

            func stroke(_ path: Path, _ line: DrawLine, in layer: GraphicsContext) {
                layer.stroke(path, with: .color(Palette.ink),
                             style: StrokeStyle(lineWidth: (line.fine ? drawing.fine : drawing.weight) * thin, lineCap: .round, lineJoin: .round))
            }
            if phase == .reink {
                // The faint copy: the whole line, fading down as the drawing over begins.
                var under = context
                under.opacity = 1 - (1 - Self.faint) * min(1, time / 0.12)
                for line in drawing.lines { stroke(line.whole, line, in: under) }
            }
            let shares = drawing.shares(at: moment, on: timeline)
            for (index, line) in drawing.lines.enumerated() {
                let path = leaving ? line.left(shares[index]) : line.drawn(shares[index])
                if !path.isEmpty { stroke(path, line, in: context) }
            }
            for index in drawing.fills.indices where drawing.fills[index].kind == .ink { fill(index) }
        }
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
                    path.move(to: current)
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

    /// One stroke as points close enough together to pass for its curves, and whether it closes on itself.
    /// The first stroke only, where a path holds more than one.
    static func points(of path: Path) -> ([CGPoint], Bool) {
        var points: [CGPoint] = [], closed = false, moved = false, done = false
        func add(_ point: CGPoint) {
            if let last = points.last, hypot(last.x - point.x, last.y - point.y) < 0.0005 { return }
            points.append(point)
        }
        path.forEach { element in
            guard !done else { return }
            switch element {
            case .move(let to):
                if moved { done = true } else { moved = true; add(to) }
            case .line(let to):
                add(to)
            case .quadCurve(let to, let control):
                guard let from = points.last else { return }
                for step in 1...12 {
                    let t = CGFloat(step) / 12, u = 1 - t
                    add(CGPoint(x: u * u * from.x + 2 * u * t * control.x + t * t * to.x, y: u * u * from.y + 2 * u * t * control.y + t * t * to.y))
                }
            case .curve(let to, let c1, let c2):
                guard let from = points.last else { return }
                // More pieces for a longer curve, so none is longer than about half a unit.
                let rough = hypot(c1.x - from.x, c1.y - from.y) + hypot(c2.x - c1.x, c2.y - c1.y) + hypot(to.x - c2.x, to.y - c2.y)
                let steps = max(6, min(40, Int((rough / 0.45).rounded(.up))))
                for step in 1...steps {
                    let t = CGFloat(step) / CGFloat(steps), u = 1 - t
                    let x = u * u * u * from.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * to.x
                    let y = u * u * u * from.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * to.y
                    add(CGPoint(x: x, y: y))
                }
            case .closeSubpath:
                closed = true
                done = true
            }
        }
        if closed, let first = points.first {
            if let last = points.last, hypot(last.x - first.x, last.y - first.y) < 0.0005 { points.removeLast() }
            points.append(first)
        }
        return (points, closed)
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

/// One of Apple's own symbols that changes by drawing: the old one is drawn off, then the new one drawn on,
/// with Apple's Draw effects. That is how Apple's Magic Replace changes a symbol from SF Symbols 7. Draw
/// needs iOS 26; before that the symbol changes with the replace effect.
struct DrawnSymbol: View {
    let name: String

    var body: some View {
        if #available(iOS 26.0, *) {
            Drawing(name: name)
        } else {
            Image(systemName: name).contentTransition(.symbolEffect(.replace.downUp))
        }
    }

    @available(iOS 26.0, *)
    private struct Drawing: View {
        let name: String
        /// The symbol on show, which changes a moment after `name` does: once the old one has been drawn off.
        @State private var shown: String?
        @State private var gone = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            Image(systemName: shown ?? name)
                .symbolEffect(.drawOff, isActive: gone)
                .onChange(of: name) { _, next in
                    guard !reduceMotion else { shown = next; return }
                    gone = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(Self.off))
                        shown = next
                        gone = false
                    }
                }
        }

        /// How long the old symbol is given to draw off before the new one starts.
        static let off = 0.35
    }
}
