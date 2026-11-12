import SwiftUI

// A small character rig, in the spirit of Rive but only what Puggle needs.
//
// A rig file (Resources/Rigs/*.rig.json) lists a character's parts, the point
// each one turns about, and her moves. The player below draws the parts and
// moves them. Three things are layered, then smoothed:
//
//   1. Ambient motion made here: breathing, blinking, a swaying tail.
//   2. Where her eyes are looking.
//   3. A move from the file, as poses to hold one after another.
//
// Moves are pose-to-pose: each pose is held until the next. Every part then
// chases its pose on a spring, so reactions snap while loose parts (tail,
// flower, arms) arrive a beat late and settle. That is the whole trick.

// MARK: The file

struct Rig: Codable {
    var name: String
    /// Width and height the parts are drawn in.
    var size: [CGFloat]
    var parts: [Part]
    var moves: [String: Move]?

    struct Part: Codable {
        var id: String
        var parent: String?
        /// The point this part turns and scales about.
        var pivot: [CGFloat]
        /// How tightly it follows its pose. Lower is looser; 0 follows at once.
        var spring: Double?
        var shapes: [Shape]
    }

    struct Shape: Codable {
        /// "ellipse" (x, y is the centre), "rect" or "path".
        var kind: String
        var x: CGFloat?, y: CGFloat?, rx: CGFloat?, ry: CGFloat?
        var w: CGFloat?, h: CGFloat?, r: CGFloat?
        /// For a path: M, L, Q, C and Z with absolute points.
        var d: String?
        var rotate: CGFloat?
        var fill: String?
        var stroke: String?
        /// The outline's colour in the coloured line style. Without it the stroke never changes.
        var tint: String?
        var width: CGFloat?
        var cap: String?
    }

    struct Move: Codable {
        var about: String?
        /// Poses in order. Each is held from its time until the next.
        var keys: [Key]
        /// Seconds until the move is over and ambient motion is all there is.
        var length: Double

        struct Key: Codable {
            var t: Double
            var pose: [String: Pose]
        }
    }

    /// How one part is moved from where it was drawn.
    struct Pose: Codable, Equatable {
        /// Degrees, clockwise.
        var r: Double?
        var x: Double?, y: Double?
        var sx: Double?, sy: Double?
    }

    static func load(_ name: String) -> Rig? {
        guard let url = Bundle.main.url(forResource: "\(name).rig", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Rig.self, from: data)
    }
}

/// A part's five numbers, always all present, for adding and smoothing.
struct PartState: Equatable {
    var r = 0.0, x = 0.0, y = 0.0, sx = 1.0, sy = 1.0

    static let rest = PartState()

    /// Lays a pose from the file over this state: turns and shifts add, scales multiply.
    mutating func add(_ pose: Rig.Pose, amount: Double = 1) {
        r += (pose.r ?? 0) * amount
        x += (pose.x ?? 0) * amount
        y += (pose.y ?? 0) * amount
        sx *= 1 + ((pose.sx ?? 1) - 1) * amount
        sy *= 1 + ((pose.sy ?? 1) - 1) * amount
    }

    var values: [Double] { [r, x, y, sx, sy] }
    init() {}
    init(_ v: [Double]) { r = v[0]; x = v[1]; y = v[2]; sx = v[3]; sy = v[4] }
}

// MARK: Line style

/// How characters are outlined: one dark line, or each line a darker shade of its own colour.
enum LineStyle: String {
    case ink, tinted

    /// Coloured lines are the look (chosen 12 November 2026). The Developer menu can still show the dark line.
    static var chosen: LineStyle { LineStyle(rawValue: UserDefaults.standard.string(forKey: "lineStyle") ?? "") ?? .tinted }
}

/// True where a character stands under the moon, so it takes the night's light.
private struct MoonlitKey: EnvironmentKey {
    static let defaultValue = false
}

private struct LineStyleKey: EnvironmentKey {
    static var defaultValue: LineStyle { .chosen }
}

extension EnvironmentValues {
    var moonlit: Bool {
        get { self[MoonlitKey.self] }
        set { self[MoonlitKey.self] = newValue }
    }

    var lineStyle: LineStyle {
        get { self[LineStyleKey.self] }
        set { self[LineStyleKey.self] = newValue }
    }
}

extension Color {
    /// "#8A5A3C" from a rig file.
    init(rigHex: String) {
        self.init(hex: UInt32(rigHex.dropFirst(), radix: 16) ?? 0)
    }

    /// A darker, slightly richer shade: the outline for this fill in the coloured line style.
    var outlineShade: Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        // Pale colours need a deeper line, or they melt into a light sky.
        return Color(hue: Double(h), saturation: Double(min(1, s * 1.2 + 0.1)), brightness: Double(b * (s < 0.25 ? 0.5 : 0.62)), opacity: Double(a))
    }

    /// The colour as it looks by moonlight: cooler and a little deeper, leaning
    /// violet, but still itself. Night is a change of light, not a loss of colour.
    func moonlit(_ on: Bool, _ amount: Double = 0.8) -> Color {
        guard on else { return self }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        let red = Double(r) * (1 - amount * 0.34)
        let green = Double(g) * (1 - amount * 0.36)
        var blue = Double(b) * (1 - amount * 0.06)
        blue += amount * 0.18 * (1 - blue)
        return Color(red: red, green: green, blue: blue, opacity: Double(a))
    }
}

// MARK: Drawing

enum RigRenderer {
    /// Draws every part, each moved by its state and by its parents'.
    static func draw(_ rig: Rig, states: [String: PartState], style: LineStyle, moonlit: Bool = false, in context: inout GraphicsContext, size: CGSize) {
        let scale = min(size.width / rig.size[0], size.height / rig.size[1])
        let fit = CGAffineTransform(translationX: (size.width - rig.size[0] * scale) / 2, y: size.height - rig.size[1] * scale)
            .scaledBy(x: scale, y: scale)
        var world: [String: CGAffineTransform] = [:]
        for part in rig.parts {
            let state = states[part.id] ?? .rest
            let pivot = CGPoint(x: part.pivot[0], y: part.pivot[1])
            // About the pivot: scale, then turn, then shift.
            let local = CGAffineTransform(translationX: pivot.x + state.x, y: pivot.y + state.y)
                .rotated(by: state.r * .pi / 180)
                .scaledBy(x: state.sx, y: state.sy)
                .translatedBy(x: -pivot.x, y: -pivot.y)
            let parent = part.parent.flatMap { world[$0] } ?? fit
            let transform = local.concatenating(parent)
            world[part.id] = transform
            guard !part.shapes.isEmpty else { continue }
            var layer = context
            layer.concatenate(transform)
            for shape in part.shapes { draw(shape, style: style, moonlit: moonlit, in: &layer) }
        }
    }

    private static func draw(_ shape: Rig.Shape, style: LineStyle, moonlit: Bool, in context: inout GraphicsContext) {
        var path = outline(of: shape)
        if let turn = shape.rotate, let x = shape.x, let y = shape.y {
            path = path.applying(CGAffineTransform(translationX: x, y: y).rotated(by: turn * .pi / 180).translatedBy(x: -x, y: -y))
        }
        if let fill = shape.fill {
            context.fill(path, with: .color(Color(rigHex: fill).moonlit(moonlit, 0.6)))
        }
        if let stroke = shape.stroke {
            let colour = style == .tinted ? (shape.tint ?? stroke) : stroke
            context.stroke(path, with: .color(Color(rigHex: colour).moonlit(moonlit, 0.6)),
                           style: StrokeStyle(lineWidth: shape.width ?? 1, lineCap: shape.cap == "round" ? .round : .butt, lineJoin: .round))
        }
    }

    private static func outline(of shape: Rig.Shape) -> Path {
        switch shape.kind {
        case "ellipse":
            let rx = shape.rx ?? 0, ry = shape.ry ?? rx
            return Path(ellipseIn: CGRect(x: (shape.x ?? 0) - rx, y: (shape.y ?? 0) - ry, width: rx * 2, height: ry * 2))
        case "rect":
            return Path(roundedRect: CGRect(x: shape.x ?? 0, y: shape.y ?? 0, width: shape.w ?? 0, height: shape.h ?? 0), cornerRadius: shape.r ?? 0)
        default:
            return path(from: shape.d ?? "")
        }
    }

    /// Reads "M88 166 Q120 156 152 166 L180 244 Z": absolute M, L, Q, C and Z.
    static func path(from d: String) -> Path {
        var path = Path()
        var command: Character = "M"
        var numbers: [CGFloat] = []
        func flush() {
            func point(_ i: Int) -> CGPoint { CGPoint(x: numbers[i], y: numbers[i + 1]) }
            switch command {
            case "M" where numbers.count >= 2: path.move(to: point(0))
            case "L" where numbers.count >= 2: path.addLine(to: point(0))
            case "Q" where numbers.count >= 4: path.addQuadCurve(to: point(2), control: point(0))
            case "C" where numbers.count >= 6: path.addCurve(to: point(4), control1: point(0), control2: point(2))
            case "Z": path.closeSubpath()
            default: break
            }
            numbers = []
        }
        var token = ""
        func endToken() {
            if let value = Double(token) { numbers.append(CGFloat(value)) }
            token = ""
        }
        for character in d {
            if character.isLetter {
                endToken(); flush()
                command = character
                if character == "Z" { flush() }
            } else if character == " " || character == "," {
                endToken()
            } else {
                token.append(character)
            }
        }
        endToken(); flush()
        return path
    }
}

// MARK: Moving

/// Works out where every part should be at a moment, and eases each towards it.
final class RigRuntime {
    let rig: Rig
    private let springs: [String: Double]

    /// Where a finger is, -1 to 1 each way; her eyes follow.
    var look = CGPoint.zero
    var asleep = false
    /// 1 by day, 0.5 at night: scales how big her reactions are.
    var energy = 1.0

    private var move: (name: String, start: Date)?
    private var shown: [String: [Double]] = [:]
    private var speed: [String: [Double]] = [:]
    private var last: Date?
    private let born = Date.now

    init(rig: Rig) {
        self.rig = rig
        springs = Dictionary(uniqueKeysWithValues: rig.parts.map { ($0.id, $0.spring ?? 260) })
    }

    /// Starts a move from the file. An unknown name does nothing.
    func play(_ name: String, at date: Date = .now) {
        guard rig.moves?[name] != nil, !asleep else { return }
        move = (name, date)
    }

    /// The pose to head for: ambient, plus her look, plus the move's current pose.
    func target(at date: Date) -> [String: PartState] {
        let t = date.timeIntervalSince(born)
        var states: [String: PartState] = [:]
        func change(_ id: String, _ edit: (inout PartState) -> Void) {
            var state = states[id] ?? .rest
            edit(&state)
            states[id] = state
        }
        // Breathing: the chest rises and the arms ride it.
        let breath = sin(t * 2 * .pi / (asleep ? 5 : 3.6))
        change("upper") { $0.sy = 1 + (asleep ? 0.02 : 0.012) * breath }
        change("arm-left") { $0.r = 1.5 * breath }
        change("arm-right") { $0.r = -1.5 * breath }
        if asleep {
            change("head") { $0.r = 6; $0.y = 4 }
            change("eye-left") { $0.sy = 0.12 }
            change("eye-right") { $0.sy = 0.12 }
            change("tail") { $0.r = 10 }
        } else {
            change("tail") { $0.r = 5 * sin(t * 2 * .pi / 2.8) }
            change("clip") { $0.r = 2 * sin(t * 2 * .pi / 3.6 + 1) }
            // A blink every few seconds, never on a steady beat; sometimes two together.
            let beat = 4.2, index = floor(t / beat)
            var random = SeededRandom(UInt64(index) &* 2654435761 &+ 17)
            let start = index * beat + random.range(0.2, 2.6)
            let twice = random.unit() < 0.25
            let since = t - start
            if (since >= 0 && since < 0.13) || (twice && since >= 0.3 && since < 0.43) {
                change("eye-left") { $0.sy = 0.12 }
                change("eye-right") { $0.sy = 0.12 }
            }
            // Eyes lead, and the head follows a little.
            for eye in ["eye-left", "eye-right"] {
                change(eye) { $0.x += Double(look.x) * 4.5; $0.y += Double(look.y) * 3.5 }
            }
            change("head") { $0.r += Double(look.x) * 2.5 }
        }
        // The move's current pose, held until its next one.
        if let playing = move, let script = rig.moves?[playing.name] {
            let into = date.timeIntervalSince(playing.start)
            if into >= script.length {
                move = nil
            } else if let key = script.keys.last(where: { $0.t <= into }) {
                for (id, pose) in key.pose {
                    change(id) { $0.add(pose, amount: energy) }
                }
            }
        }
        return states
    }

    /// Eases every part towards its pose and returns where each now is.
    func advance(to date: Date) -> [String: PartState] {
        let goal = target(at: date)
        // The first frame, and any long gap (the app was away), start settled.
        guard let last, date.timeIntervalSince(last) < 0.25 else {
            self.last = date
            for part in rig.parts {
                shown[part.id] = (goal[part.id] ?? .rest).values
                speed[part.id] = [0, 0, 0, 0, 0]
            }
            return goal
        }
        self.last = date
        let elapsed = max(date.timeIntervalSince(last), 0)
        let steps = max(1, Int((elapsed / 0.004).rounded(.up)))
        let dt = elapsed / Double(steps)
        var result: [String: PartState] = [:]
        for part in rig.parts {
            let aim = (goal[part.id] ?? .rest).values
            let stiffness = springs[part.id] ?? 260
            guard stiffness > 0 else {
                shown[part.id] = aim
                result[part.id] = PartState(aim)
                continue
            }
            var value = shown[part.id] ?? aim
            var velocity = speed[part.id] ?? [0, 0, 0, 0, 0]
            // A little under critical damping: quick, with one small settle.
            let damping = 2 * stiffness.squareRoot() * 0.62
            for _ in 0..<steps {
                for i in 0..<5 {
                    velocity[i] += (stiffness * (aim[i] - value[i]) - damping * velocity[i]) * dt
                    value[i] += velocity[i] * dt
                }
            }
            shown[part.id] = value
            speed[part.id] = velocity
            result[part.id] = PartState(value)
        }
        return result
    }
}

// MARK: The view

/// A rigged character. Still when `moving` is false: drawn exactly as her parts were.
struct RigView: View {
    let runtime: RigRuntime
    var moving = true
    @Environment(\.lineStyle) private var lineStyle
    @Environment(\.moonlit) private var moonlit

    var body: some View {
        if moving {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let states = runtime.advance(to: timeline.date)
                    RigRenderer.draw(runtime.rig, states: states, style: lineStyle, moonlit: moonlit, in: &context, size: size)
                }
            }
        } else {
            Canvas { context, size in
                RigRenderer.draw(runtime.rig, states: [:], style: lineStyle, moonlit: moonlit, in: &context, size: size)
            }
        }
    }
}

/// One frame of a rig, for strips of frames that show a move pose by pose.
struct RigFrame: View {
    let rig: Rig
    let states: [String: PartState]
    @Environment(\.lineStyle) private var lineStyle

    var body: some View {
        Canvas { context, size in
            RigRenderer.draw(rig, states: states, style: lineStyle, in: &context, size: size)
        }
    }
}
