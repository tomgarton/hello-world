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
    /// The face she has when nothing says otherwise: ["eyes": "open", "bill": "closed"].
    var face: [String: String]?
    var moves: [String: Move]?
    /// The colours this character's clothes come in, for the cast: each is a swap of one colour for another.
    var wardrobe: Wardrobe?
    /// Empty space above the head, in the drawing's units, for something held over it (an umbrella).
    var headroom: CGFloat?
    /// How far something held (an umbrella's canopy) reaches past the drawing's sides, in the drawing's units.
    /// The drawing keeps its size and place; it is only given this much more room to draw in on each side.
    var sideroom: CGFloat?

    struct Wardrobe: Codable {
        /// The first is as drawn (no swaps).
        var looks: [[String: String]]
        /// A raincoat's yellow, for wet days.
        var rain: [String: String]?
    }

    /// The same character with some colours swapped for others: the same clothes in another colour.
    func wearing(_ swaps: [String: String]) -> Rig {
        guard !swaps.isEmpty else { return self }
        var copy = self
        for part in copy.parts.indices {
            for shape in copy.parts[part].shapes.indices {
                if let fill = copy.parts[part].shapes[shape].fill, let new = swaps[fill.uppercased()] { copy.parts[part].shapes[shape].fill = new }
                if let stroke = copy.parts[part].shapes[shape].stroke, let new = swaps[stroke.uppercased()] { copy.parts[part].shapes[shape].stroke = new }
                if let tint = copy.parts[part].shapes[shape].tint, let new = swaps[tint.uppercased()] { copy.parts[part].shapes[shape].tint = new }
            }
        }
        return copy
    }

    struct Part: Codable {
        var id: String
        var parent: String?
        /// The point this part turns and scales about.
        var pivot: [CGFloat]
        /// How tightly it follows its pose. Lower is looser; 0 follows at once.
        var spring: Double?
        /// Drawn only while her face is set this way: "eyes=happy", or any of several: "outfit=rain|sun".
        var when: String?
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
        /// "body" unless said: one move plays per track, and tracks play together,
        /// so she can wag her tail or change her face during anything.
        var track: String?
        /// Poses in order. Each is held from its time until the next.
        var keys: [Key]
        /// Seconds until the move is over and ambient motion is all there is.
        var length: Double
        /// Goes round again from the start until it is stopped (walking).
        var loops: Bool?
        /// Her hands have somewhere exact to be (her cheeks, a book), so the poses are not made smaller at night.
        var exact: Bool?

        struct Key: Codable {
            var t: Double
            var pose: [String: Pose]
            /// Which face shapes to show from here: ["eyes": "happy", "bill": "open"].
            var face: [String: String]?
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

/// Where a warm lamp is, as a point on the character's own box (0,0 top left). Nil when there is none.
private struct WarmLightKey: EnvironmentKey {
    static let defaultValue: UnitPoint? = nil
}

/// Drawn as if by hand: a line that wavers a little, and a grain like paper in the colour.
private struct HandDrawnKey: EnvironmentKey {
    static var defaultValue: Bool { UserDefaults.standard.string(forKey: "drawingStyle") == "pencil" }
}

private struct LineStyleKey: EnvironmentKey {
    static var defaultValue: LineStyle { .chosen }
}

extension EnvironmentValues {
    var moonlit: Bool {
        get { self[MoonlitKey.self] }
        set { self[MoonlitKey.self] = newValue }
    }

    var warmLight: UnitPoint? {
        get { self[WarmLightKey.self] }
        set { self[WarmLightKey.self] = newValue }
    }

    var handDrawn: Bool {
        get { self[HandDrawnKey.self] }
        set { self[HandDrawnKey.self] = newValue }
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
    static func draw(_ rig: Rig, states: [String: PartState], face: [String: String]? = nil, style: LineStyle, moonlit: Bool = false,
                     warmLight: UnitPoint? = nil, handDrawn: Bool = false, in context: inout GraphicsContext, size: CGSize) {
        let face = face ?? rig.face ?? [:]
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
            // A face shape shows only while the face is set to it.
            // "outfit=rain|sun" shows for either.
            // "outfit=rain&arms=front" needs both.
            let hidden = (part.when ?? "").split(separator: "&").contains { condition in
                let when = condition.split(separator: "=")
                return when.count == 2 && !when[1].split(separator: "|").contains(where: { face[String(when[0])] == String($0) })
            }
            if hidden { continue }
            var layer = context
            layer.concatenate(transform)
            for (index, shape) in part.shapes.enumerated() {
                draw(shape, key: handDrawn ? "\(rig.name)/\(part.id)/\(index)" : nil, style: style, moonlit: moonlit, in: &layer)
            }
        }
        if handDrawn {
            // Grain, as of crayon on paper, only over what has been drawn.
            var grain = context
            grain.blendMode = .sourceAtop
            grain.concatenate(fit)
            let specks = HandDrawn.grain(width: rig.size[0], height: rig.size[1])
            grain.fill(specks.light, with: .color(.white.opacity(0.16)))
            grain.fill(specks.dark, with: .color(.black.opacity(0.10)))
        }
        // Warm light from a lamp nearby, laid only over what has been drawn.
        if let warmLight {
            var lit = context
            lit.blendMode = .sourceAtop
            let centre = CGPoint(x: size.width * warmLight.x, y: size.height * warmLight.y)
            lit.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .radialGradient(Gradient(colors: [Color(hex: 0xFFD98A).opacity(0.55), Color(hex: 0xFFD98A).opacity(0)]),
                                           center: centre, startRadius: 0, endRadius: size.width * 0.75))
        }
    }

    private static func draw(_ shape: Rig.Shape, key: String?, style: LineStyle, moonlit: Bool, in context: inout GraphicsContext) {
        var path = outline(of: shape)
        if let turn = shape.rotate, let x = shape.x, let y = shape.y {
            path = path.applying(CGAffineTransform(translationX: x, y: y).rotated(by: turn * .pi / 180).translatedBy(x: -x, y: -y))
        }
        // By hand: the same shape, wavering a little. Kept, so it is worked out once.
        var sketch: Path?
        if let key {
            path = HandDrawn.wavering(path, key: key, phase: 0)
            sketch = HandDrawn.wavering(path, key: key + "/2", phase: 2.4)
        }
        if let fill = shape.fill {
            context.fill(path, with: .color(Color(rigHex: fill).moonlit(moonlit, 0.6)))
        }
        if let stroke = shape.stroke {
            let colour = style == .tinted ? (shape.tint ?? stroke) : stroke
            let width = shape.width ?? 1
            let cap: CGLineCap = shape.cap == "round" ? .round : .butt
            let ink = Color(rigHex: colour).moonlit(moonlit, 0.6)
            // An outline (it has a tint) is drawn like a pencil: a thinner line and a second, lighter pass.
            if let sketch, shape.tint != nil, width < 12 {
                context.stroke(path, with: .color(ink.opacity(0.92)), style: StrokeStyle(lineWidth: width * 0.74, lineCap: .round, lineJoin: .round))
                context.stroke(sketch, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: width * 0.36, lineCap: .round, lineJoin: .round))
            } else {
                context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: .round))
            }
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

// MARK: Feelings

/// What ears, spines and hair do for a feeling, as her tail does. `ears` turns them up (positive) or down,
/// `lift` raises them, `spines` is their size, `tall` and `lean` are how a lick or curl stands. `one` is one
/// ear and the spines on that side only, for noticing something.
struct RigFeeling {
    let name: String, ears: Double, lift: Double, spines: Double, tall: Double, lean: Double, one: Bool
    /// The tail: how far it turns from rest (up is negative), how long it is drawn, and whether it wags.
    var tail = 0.0, reach = 1.0, wags = false

    static let happy = RigFeeling(name: "Happy", ears: 12, lift: 2, spines: 1.14, tall: 1.18, lean: 0, one: false, tail: -16, wags: true)
    // Seen from the front, a tail straight up is hidden behind her: proud is as high as it can go and still show.
    static let proud = RigFeeling(name: "Proud", ears: 14, lift: 3, spines: 1.18, tall: 1.24, lean: -6, one: false, tail: -34, reach: 1.18)
    static let surprised = RigFeeling(name: "Surprised", ears: 22, lift: 5, spines: 1.38, tall: 1.4, lean: -14, one: false, tail: 26, reach: 1.1)
    static let shy = RigFeeling(name: "Shy", ears: -30, lift: 0, spines: 0.66, tall: 0.68, lean: 16, one: false, tail: 74, reach: 0.72)
    static let sleepy = RigFeeling(name: "Sleepy", ears: -18, lift: 0, spines: 0.84, tall: 0.82, lean: 26, one: false, tail: 44, reach: 0.9)
    static let curious = RigFeeling(name: "Curious", ears: 20, lift: 3, spines: 1.24, tall: 1.1, lean: -18, one: true, tail: -12)
    static let all = [happy, proud, surprised, shy, sleepy, curious]

    /// The poses to hold, by part. `amount` is how much of the feeling: 1 in full, 0.5 at night.
    func held(_ amount: Double = 1) -> [String: PartState] {
        func pose(r: Double = 0, y: Double = 0, size: Double = 1, tall: Double = 1) -> PartState {
            var state = PartState()
            state.r = r * amount
            state.y = y * amount
            state.sx = 1 + (size - 1) * amount
            state.sy = 1 + (size * tall - 1) * amount
            return state
        }
        var held: [String: PartState] = [:]
        held["ear-left"] = pose(r: ears, y: -lift)
        held["ear-right"] = one ? .rest : pose(r: -ears, y: -lift)
        for index in 1...8 { held["spine-\(index)"] = pose(size: one && index > 4 ? 1 : spines) }
        for hair in ["lick", "curl", "tuft", "crest", "sweep"] { held[hair] = pose(r: lean, tall: tall) }
        // Her tail: calm at rest, up and wagging when happy, straight up when proud, stiff and straight out
        // when surprised, tucked in when shy, drooping when sleepy.
        var tailPose = PartState()
        tailPose.r = tail * amount
        tailPose.sx = 1 + (reach - 1) * amount
        held["tail"] = tailPose
        return held
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
    /// The proposed refinements (reports/Cartoon character craft for Puggle.md): a blink that shuts fast and
    /// opens slowly, eyes that lead a head tilt, a landing that stops at the ground, a stretched frame when
    /// her eyes jump, and ears, spines and hair that show a feeling. On in the app since 14 November 2026.
    var refined = true
    /// For tests: a blink or a head tilt asked for now, in place of waiting for one.
    var blinkAt: Date?
    var tiltAt: (start: Date, side: Double)?
    /// Poses held on top of everything else, by part: how ears, spines and hair show a feeling.
    var held: [String: PartState] = [:]
    /// A feeling asked for, for a moment: shy at a first tap.
    private var felt: (feeling: RigFeeling, until: Date)?
    func feel(_ feeling: RigFeeling, for seconds: Double) { felt = (feeling, Date.now.addingTimeInterval(seconds)) }
    /// Eyes in the middle of a quick move, drawn stretched along the way for a moment.
    private var smears: [String: (from: [Double], start: Date)] = [:]
    private var eyesWere: [String: [Double]] = [:]

    /// How far open the eyes are, `since` seconds into a blink: 1 open, about 0.1 shut. Nil when not blinking.
    private func blink(_ since: Double) -> Double? {
        guard since >= 0 else { return nil }
        if !refined { return since < 0.13 ? 0.12 : nil }
        // Shut in 80 ms, held for 50, open again over 160: faster down than up, as an eyelid is.
        if since < 0.08 { return 1 - 0.9 * (since / 0.08) }
        if since < 0.13 { return 0.1 }
        if since < 0.29 { let u = (since - 0.13) / 0.16; return 0.1 + 0.9 * u * u * (3 - 2 * u) }
        return nil
    }

    /// Walking on the spot for as long as this is true.
    var walking = false {
        didSet {
            guard walking != oldValue else { return }
            if walking { play("walk") } else if playing["body"]?.name == "walk" { playing["body"] = nil }
        }
    }

    /// One move per track.
    private var playing: [String: (name: String, start: Date)] = [:]
    /// Her face just now, for the drawing.
    private(set) var face: [String: String] = [:]
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
        // The hop with weight, where she has one, in place of the plain one.
        let name = refined && rig.moves?[name + "-refined"] != nil ? name + "-refined" : name
        guard let move = rig.moves?[name], !asleep || name.hasPrefix("wake") else { return }
        playing[move.track ?? "body"] = (name, date)
    }

    /// Ends a move that goes round (reading), or cuts any other short. Her parts ease back on their springs.
    func stop(_ name: String) {
        for (track, now) in playing where now.name == name { playing[track] = nil }
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
            change("tail") { $0.r = 10 }
        } else {
            change("tail") { $0.r = 5 * sin(t * 2 * .pi / 2.8) }
            change("clip") { $0.r = 2 * sin(t * 2 * .pi / 3.6 + 1) }
            // A blink every few seconds, never on a steady beat; sometimes two together.
            let beat = 4.2, index = floor(t / beat)
            var random = SeededRandom(UInt64(index) &* 2654435761 &+ 17)
            let start = index * beat + random.range(0.2, 2.6)
            let twice = random.unit() < 0.25
            // A test that asks for its own blinks and tilts gets only those.
            let scripted = blinkAt != nil || tiltAt != nil
            var open = scripted ? nil : (blink(t - start) ?? (twice ? blink(t - start - 0.3) : nil))
            if let blinkAt { open = blink(date.timeIntervalSince(blinkAt)) ?? open }
            // Now and then she tips her head to one side, as if wondering, and holds it.
            let pause = 9.0, turn = floor(t / pause)
            var whim = SeededRandom(UInt64(turn) &* 40503 &+ 5)
            let begin = turn * pause + whim.range(1, 6)
            var tilt: (since: Double, side: Double)?
            if !scripted, t >= begin, t < begin + 1.9 { tilt = (t - begin, whim.unit() < 0.5 ? -1.0 : 1.0) }
            if let tiltAt, date.timeIntervalSince(tiltAt.start) >= 0, date.timeIntervalSince(tiltAt.start) < 1.9 {
                tilt = (date.timeIntervalSince(tiltAt.start), tiltAt.side)
            }
            if let tilt, refined {
                // She looks first; a blink as her head starts after her eyes; her clip is the last to arrive.
                // Going back, the same order: eyes, then head, then clip.
                let side = tilt.side, since = tilt.since
                if since < 1.5 { for eye in ["eye-left", "eye-right"] { change(eye) { $0.x += 4.5 * side } } }
                if since >= 0.16, since < 1.62 { change("head") { $0.r += 7 * side } }
                if since >= 0.3, since < 1.76 { for late in ["clip", "lick", "curl"] { change(late) { $0.r += 5 * side } } }
                open = blink(since - 0.1) ?? blink(since - 1.46) ?? open
            } else if let tilt, tilt.since < 1.5 {
                change("head") { $0.r += 6 * tilt.side }
                change("clip") { $0.r += 5 * tilt.side }
            }
            if let open {
                change("eye-left") { $0.sy = open }
                change("eye-right") { $0.sy = open }
            }
            // Eyes lead, and the head follows a little.
            for eye in ["eye-left", "eye-right"] {
                change(eye) { $0.x += Double(look.x) * 4.5; $0.y += Double(look.y) * 3.5 }
            }
            change("head") { $0.r += Double(look.x) * 2.5 }
        }
        var showing = rig.face ?? [:]
        if asleep {
            showing["eyes"] = "closed"
            showing["brows"] = "on"
            // Zs drift up beside her, slowly.
            showing["air"] = "zzz"
            change("zed-a") { $0.y = -4 * sin(t * 2 * .pi / 5); $0.r = 6 * sin(t * 2 * .pi / 5) }
            change("zed-b") { $0.y = -6 * sin(t * 2 * .pi / 5 - 0.9); $0.r = -8 * sin(t * 2 * .pi / 5 - 0.9) }
            change("brow-left") { $0.y = 1; $0.r = -14 }
            change("brow-right") { $0.y = 1; $0.r = 14 }
        }
        var tailMoved = false
        // Each track's current pose, held until its next one.
        for (track, now) in playing.sorted(by: { $0.key < $1.key }) {
            guard let script = rig.moves?[now.name] else { continue }
            var into = date.timeIntervalSince(now.start)
            if script.loops == true { into = into.truncatingRemainder(dividingBy: script.length) }
            if into >= script.length {
                playing[track] = nil
            } else if let key = script.keys.last(where: { $0.t <= into }) {
                for (id, pose) in key.pose {
                    change(id) { $0.add(pose, amount: script.exact == true ? 1 : energy) }
                    if id == "tail" { tailMoved = true }
                }
                for (feature, shape) in key.face ?? [:] { showing[feature] = shape }
            }
        }
        // Ears, spines and hair take a position for what she is feeling: sleepy asleep, happy in a wave or a
        // hooray, a small happy for a nod, surprised on waking, curious while her eyes follow something.
        if refined {
            var mood: (feeling: RigFeeling, amount: Double)?
            if asleep { mood = (.sleepy, 1) }
            else if let felt, date < felt.until { mood = (felt.feeling, 1) }
            else if let move = playing["body"]?.name {
                if move.hasPrefix("wake") || move.hasPrefix("oh") { mood = (.surprised, 1) }
                else if move.hasPrefix("read") { mood = (.curious, 0.6) }
                else if move.hasPrefix("proud") { mood = (.proud, 1) }
                else if move.hasPrefix("nod") { mood = (.happy, 0.6) }
                else if !move.hasPrefix("walk") { mood = (.happy, 1) }
            } else if abs(look.x) + abs(look.y) > 0.3 { mood = (.curious, 1) }
            if let mood {
                if mood.feeling.name == "Shy" { showing["cheeks"] = "shy" }
                for (id, pose) in mood.feeling.held(mood.amount * energy) {
                    // A move that places her tail itself keeps it; the feeling places it otherwise.
                    if id == "tail" {
                        if tailMoved || asleep { continue }
                        let wag = mood.feeling.wags ? 7 * sin(t * 2 * .pi / 0.42) * mood.amount * energy : 0
                        change(id) { $0.r += pose.r + wag; $0.sx *= pose.sx }
                        continue
                    }
                    change(id) { $0.r += pose.r; $0.x += pose.x; $0.y += pose.y; $0.sx *= pose.sx; $0.sy *= pose.sy }
                }
            }
        }
        for (id, pose) in held {
            change(id) { $0.r += pose.r; $0.x += pose.x; $0.y += pose.y; $0.sx *= pose.sx; $0.sy *= pose.sy }
        }
        face = showing
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
                var drawn = aim
                if refined, part.id.hasPrefix("eye-") {
                    // A quick eye move is one stretched frame or two, then round again at the new place.
                    let was = eyesWere[part.id] ?? aim
                    if hypot(aim[1] - was[1], aim[2] - was[2]) >= 3 { smears[part.id] = (was, date) }
                    eyesWere[part.id] = aim
                    if let smear = smears[part.id], date.timeIntervalSince(smear.start) < 0.065 {
                        let dx = aim[1] - smear.from[1], dy = aim[2] - smear.from[2]
                        let radius = part.shapes.first?.rx ?? 6.5
                        drawn[1] = smear.from[1] + dx / 2
                        drawn[2] = smear.from[2] + dy / 2
                        drawn[0] += atan2(dy, dx) * 180 / .pi
                        drawn[3] *= 1 + hypot(dx, dy) / (2 * radius)
                        drawn[4] *= 0.86
                    }
                }
                shown[part.id] = aim
                result[part.id] = PartState(drawn)
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
            // A landing stops at the ground: the spring must not carry her feet through it.
            if refined, part.id == "body", value[2] > 0 {
                value[2] = 0
                velocity[2] = min(velocity[2], 0)
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
    @Environment(\.warmLight) private var warmLight
    @Environment(\.handDrawn) private var handDrawn
    @Environment(\.outfit) private var outfit

    var body: some View {
        if moving {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let states = runtime.advance(to: timeline.date)
                    RigRenderer.draw(runtime.rig, states: states, face: runtime.face.merging(["outfit": outfit]) { _, new in new }, style: lineStyle, moonlit: moonlit, warmLight: warmLight, handDrawn: handDrawn, in: &context, size: size)
                }
            }
        } else {
            Canvas { context, size in
                RigRenderer.draw(runtime.rig, states: [:], face: (runtime.rig.face ?? [:]).merging(["outfit": outfit]) { _, new in new }, style: lineStyle, moonlit: moonlit, warmLight: warmLight, handDrawn: handDrawn, in: &context, size: size)
            }
        }
    }
}

/// One frame of a rig, for strips of frames that show a move pose by pose.
struct RigFrame: View {
    let rig: Rig
    let states: [String: PartState]
    var face: [String: String]?
    @Environment(\.lineStyle) private var lineStyle
    @Environment(\.handDrawn) private var handDrawn
    @Environment(\.moonlit) private var moonlit
    @Environment(\.outfit) private var outfit

    var body: some View {
        Canvas { context, size in
            RigRenderer.draw(rig, states: states, face: (face ?? rig.face ?? [:]).merging(["outfit": outfit]) { _, new in new }, style: lineStyle, moonlit: moonlit, handDrawn: handDrawn, in: &context, size: size)
        }
    }
}

// MARK: Drawn by hand

/// The hand-drawn look: outlines that waver and a paper grain. (Her eyes, once part of it, are now how she is always drawn.)
enum HandDrawn {
    private static var paths: [String: Path] = [:]
    private static var specks: (light: Path, dark: Path)?

    /// The path with a slow waver along it, the same every time for the same key.
    static func wavering(_ path: Path, key: String, phase: Double) -> Path {
        if let kept = paths[key] { return kept }
        var seed = SeededRandom(UInt64(abs(key.hashValue % 1_000_003)) &* 31 &+ 7)
        // hashValue changes between launches; the look need only hold within one.
        let shift = seed.range(0, 6.28) + phase
        var result = Path()
        var points: [CGPoint] = []
        var closed = false
        func finish() {
            guard points.count > 1 else { points = []; return }
            // Walk the line in small steps, so straight runs can waver too.
            var fine: [CGPoint] = []
            for i in 0..<(points.count - 1) {
                let a = points[i], b = points[i + 1]
                let steps = max(1, Int(hypot(b.x - a.x, b.y - a.y) / 2.5))
                for step in 0..<steps {
                    let f = CGFloat(step) / CGFloat(steps)
                    fine.append(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
                }
            }
            if !closed { fine.append(points[points.count - 1]) }
            var lengths: [CGFloat] = [0]
            for i in 1..<fine.count { lengths.append(lengths[i - 1] + hypot(fine[i].x - fine[i - 1].x, fine[i].y - fine[i - 1].y)) }
            let total = max(lengths.last ?? 1, 1)
            // Whole numbers of waves, so a closed shape meets itself.
            let slow = max(1, (total / 52).rounded()), quick = max(2, (total / 21).rounded())
            // Short marks waver less, or they would lose their shape.
            let reach = min(0.8, total / 90)
            var moved: [CGPoint] = []
            for i in 0..<fine.count {
                let before = fine[max(i - 1, 0)], after = fine[min(i + 1, fine.count - 1)]
                let dx = after.x - before.x, dy = after.y - before.y
                let length = max(hypot(dx, dy), 0.001)
                let along = Double(lengths[i] / total) * 2 * .pi
                let push = CGFloat(sin(along * Double(slow) + shift) + 0.3 * sin(along * Double(quick) + shift * 1.7)) * reach
                moved.append(CGPoint(x: fine[i].x - dy / length * push, y: fine[i].y + dx / length * push))
            }
            result.addLines(moved)
            if closed { result.closeSubpath() }
            points = []
            closed = false
        }
        path.cgPath.flattened(threshold: 0.4).applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                finish()
                points = [element.pointee.points[0]]
            case .addLineToPoint:
                points.append(element.pointee.points[0])
            case .closeSubpath:
                if let first = points.first { points.append(first) }
                closed = true
                finish()
            default:
                break
            }
        }
        finish()
        paths[key] = result
        return result
    }

    /// Small specks, light and dark, over the whole drawing.
    static func grain(width: CGFloat, height: CGFloat) -> (light: Path, dark: Path) {
        if let specks { return specks }
        var random = SeededRandom(8191)
        var light = Path(), dark = Path()
        for i in 0..<2600 {
            let size = CGFloat(random.range(0.5, 1.5))
            let speck = CGRect(x: CGFloat(random.range(0, 1)) * width, y: CGFloat(random.range(0, 1)) * height, width: size, height: size)
            if i.isMultiple(of: 2) { light.addEllipse(in: speck) } else { dark.addEllipse(in: speck) }
        }
        specks = (light, dark)
        return (light, dark)
    }
}
