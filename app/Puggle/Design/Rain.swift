import SwiftUI

// Rain that lands on things (Tom, 17 November 2026): little pops where drops hit Puggle, the friends, the fence and
// the ground, and drips gathering on edges and falling. Flat and small, in the rain's own colour, with no outline.
// Rain, a thunderstorm and sun showers; never snow. Nothing at all with Reduce Motion, as the scene is then still.

enum Rain {
    /// How hard it is raining, or nil when it isn't.
    static func strength(_ weather: Weather) -> Double? {
        switch weather {
        case .rain: 1
        case .storm: 1.7
        case .showers: 0.5
        default: nil
        }
    }

    /// How far the rain leans. In a thunderstorm the wind comes in slow gusts, so the slant swings a little.
    static func lean(_ weather: Weather, t: Double) -> CGFloat {
        switch weather {
        case .storm: 0.3 + 0.1 * CGFloat(sin(t * 0.31)) + 0.04 * CGFloat(sin(t * 0.83 + 1))
        case .showers: 0.1
        default: 0.14
        }
    }

    static func colour(night: Bool) -> Color { night ? Color(hex: 0xC4C8F0) : Color.white }
}

/// Somewhere a drop can land: along the top of something, or anywhere in an area of ground or water.
struct RainTarget {
    enum Kind { case ledge, ground, water }
    var kind: Kind
    var a: CGPoint
    var b: CGPoint
    /// How often drops land here, against the others: about its length or its area.
    var weight: Double

    static func ledge(_ a: CGPoint, _ b: CGPoint) -> RainTarget {
        RainTarget(kind: .ledge, a: a, b: b, weight: Double(hypot(b.x - a.x, b.y - a.y)))
    }

    /// An area, given by two corners. Counts for less than its size: the ground is mostly seen edge-on.
    static func area(_ kind: Kind, _ rect: CGRect) -> RainTarget {
        RainTarget(kind: kind, a: CGPoint(x: rect.minX, y: rect.minY), b: CGPoint(x: rect.maxX, y: rect.maxY),
                   weight: Double(rect.width * rect.height).squareRoot() * 2.2)
    }

    func point(_ random: inout SeededRandom) -> CGPoint {
        let u = CGFloat(random.unit()), v = CGFloat(random.unit())
        switch kind {
        case .ledge: return CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u)
        case .ground, .water: return CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * v)
        }
    }
}

/// An edge water gathers on, and where its drip lands.
struct DripSpot {
    var at: CGPoint
    var lands: CGFloat
}

/// Pops where drops land, and drips falling from edges, drawn over whatever they belong to.
struct RainHits: View {
    let targets: [RainTarget]
    var drips: [DripSpot] = []
    let strength: Double
    let night: Bool
    let t: Double
    /// Pops a second over everything here, before the strength.
    var rate = 7.0
    /// Keeps two layers from popping in step.
    var salt: UInt64 = 0

    static let popLength = 0.22

    var body: some View {
        Canvas { context, _ in
            let colour = Rain.colour(night: night)
            let total = targets.reduce(0) { $0 + $1.weight }
            if total > 0 {
                // Lanes, each popping once a period at its own moment, somewhere new each time.
                let lanes = 12
                let period = Double(lanes) / (rate * strength)
                for lane in 0..<lanes {
                    var phase = SeededRandom(UInt64(lane) &* 6_007 &+ salt)
                    let shifted = t + phase.unit() * period
                    let cycle = (shifted / period).rounded(.down)
                    let age = (shifted - cycle * period) / Self.popLength
                    guard age < 1 else { continue }
                    var random = SeededRandom(UInt64(bitPattern: Int64(cycle)) &* 92_821 &+ UInt64(lane) &* 7 &+ salt &* 131)
                    var pick = random.unit() * total
                    var target = targets[0]
                    for candidate in targets {
                        pick -= candidate.weight
                        if pick <= 0 { target = candidate; break }
                    }
                    let at = target.point(&random)
                    if target.kind == .water {
                        dimple(&context, at, age, colour)
                    } else {
                        // On the ground, smaller (it is further back) and pale blue, or they vanish on the sand.
                        let ground = target.kind == .ground
                        pop(&context, at, age, ground ? Color(hex: night ? 0x8E96D6 : 0x9DBCD8) : colour, scale: ground ? 1 : 1.35,
                            tilt: CGFloat(random.range(-0.4, 0.4)))
                    }
                }
            }
            for (index, spot) in drips.enumerated() {
                drip(&context, spot, index, colour)
            }
        }
        .allowsHitTesting(false)
    }

    /// A tiny crown: a flat splash and three droplets thrown up and out, falling back.
    private func pop(_ context: inout GraphicsContext, _ at: CGPoint, _ age: Double, _ colour: Color, scale: CGFloat, tilt: CGFloat) {
        let a = CGFloat(age)
        let fade = 1 - age * age
        let splash = CGRect(x: at.x - 3.5 * scale * (0.6 + a), y: at.y - 0.8 * scale, width: 7 * scale * (0.6 + a), height: 1.6 * scale)
        context.fill(Path(ellipseIn: splash), with: .color(colour.opacity(0.55 * fade)))
        for side in [-1.0, 0.0, 1.0] {
            let angle = -.pi / 2 + (side * 0.85 + Double(tilt))
            let reach = (2 + 5 * a) * scale
            let x = at.x + CGFloat(cos(angle)) * reach
            // Up and out, then gravity pulls it back down.
            let y = at.y + CGFloat(sin(angle)) * reach * (side == 0 ? 1.15 : 0.9) + 9 * a * a * scale
            let r = (side == 0 ? 1.15 : 0.95) * scale * (1 - 0.5 * a)
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(colour.opacity(0.85 * fade)))
        }
    }

    /// On water a drop leaves a small ring that spreads and fades.
    private func dimple(_ context: inout GraphicsContext, _ at: CGPoint, _ age: Double, _ colour: Color) {
        let a = CGFloat(age)
        let ring = CGRect(x: at.x - 2 - 5 * a, y: at.y - 0.8 - 1.6 * a, width: 4 + 10 * a, height: 1.6 + 3.2 * a)
        context.stroke(Path(ellipseIn: ring), with: .color(colour.opacity(0.6 * (1 - age))), lineWidth: 1)
    }

    /// Water gathers into a drop, hangs, lets go, falls and pops where it lands. Slower when it is only showers.
    private func drip(_ context: inout GraphicsContext, _ spot: DripSpot, _ index: Int, _ colour: Color) {
        var random = SeededRandom(UInt64(index) &* 4_391 &+ salt &+ 77)
        let period = random.range(1.7, 3.0) / min(max(strength, 0.6), 1.4)
        let p = (t + random.unit() * period).truncatingRemainder(dividingBy: period) / period
        let drop = Color(hex: night ? 0x9FA6E6 : 0xD8E8F6)
        let fall = spot.lands - spot.at.y
        // How long the fall takes, from rest under gravity, as a share of the period.
        let falling = min(0.3, (Double(max(fall, 1)) / 600).squareRoot() / period)
        let gather = 0.62
        if p < gather {
            // Swelling and hanging, a little stretched just before it goes.
            let grow = CGFloat(p / gather)
            let r = 0.7 + 1.9 * grow
            let stretch = 1 + 0.35 * max(0, grow - 0.8) / 0.2
            let rect = CGRect(x: spot.at.x - r, y: spot.at.y, width: r * 2, height: r * 2 * stretch)
            context.fill(Path(ellipseIn: rect), with: .color(drop.opacity(0.9)))
            context.fill(Path(ellipseIn: CGRect(x: rect.minX + r * 0.5, y: rect.minY + r * 0.4, width: r * 0.6, height: r * 0.6)),
                         with: .color(Color.white.opacity(0.8)))
        } else if p < gather + falling {
            let f = (p - gather) / falling
            let y = spot.at.y + fall * CGFloat(f * f)
            let rect = CGRect(x: spot.at.x - 1.6, y: y, width: 3.2, height: 4.4)
            context.fill(Path(ellipseIn: rect), with: .color(drop.opacity(0.9)))
        } else {
            let age = (p - gather - falling) * period / Self.popLength
            if age < 1 { pop(&context, CGPoint(x: spot.at.x, y: spot.lands), age, Color(hex: night ? 0x8E96D6 : 0x9DBCD8), scale: 1.1, tilt: 0) }
        }
    }
}

/// The rain on and around Puggle, drawn over her: the near rain, pops on her hat and shoulders, and drips off her
/// brim. Measured from her drawing at 118 points high, standing 26 points up from the bottom of the scene.
struct PuggleRain: View {
    let weather: Weather
    let night: Bool
    /// How far she stands from the middle.
    var puggleX: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let strength = Rain.strength(weather), !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                frame(strength: strength, t: timeline.date.timeIntervalSince(SceneClock.start))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// One moment, for pictures of it as well.
    func frame(strength: Double, t: Double) -> some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = geometry.size.height
            let x = w / 2 + puggleX, b = h
            ZStack {
                // A few near drops, longer and quicker than the rest, in front of her.
                NearRain(weather: weather, night: night, t: t)
                RainHits(targets: [
                    .ledge(CGPoint(x: x - 35, y: b - 113), CGPoint(x: x - 20, y: b - 120)),
                    .ledge(CGPoint(x: x - 18, y: b - 122), CGPoint(x: x, y: b - 134)),
                    .ledge(CGPoint(x: x, y: b - 134), CGPoint(x: x + 18, y: b - 122)),
                    .ledge(CGPoint(x: x + 20, y: b - 120), CGPoint(x: x + 36, y: b - 112)),
                    .ledge(CGPoint(x: x - 27, y: b - 74), CGPoint(x: x - 15, y: b - 79)),
                    .ledge(CGPoint(x: x + 15, y: b - 79), CGPoint(x: x + 27, y: b - 74)),
                ], drips: [DripSpot(at: CGPoint(x: x - 36, y: b - 111), lands: b - 25),
                           DripSpot(at: CGPoint(x: x + 37, y: b - 109), lands: b - 24)],
                         strength: strength, night: night, t: t, rate: 2.2, salt: 5)
            }
        }
    }
}

/// The nearest rain: fewer drops, longer and quicker, in front of Puggle.
struct NearRain: View {
    let weather: Weather
    let night: Bool
    let t: Double

    var body: some View {
        Canvas { context, size in
            guard let strength = Rain.strength(weather) else { return }
            let lean = Rain.lean(weather, t: t)
            var streaks = Path()
            for i in 0..<Int(10 * strength) {
                var random = SeededRandom(UInt64(i) &* 3_119 &+ 41)
                let speed = random.range(640, 820)
                let length = CGFloat(random.range(18, 26))
                let span = Double(size.height + 60)
                let y = CGFloat((random.range(0, 1) * span + speed * t).truncatingRemainder(dividingBy: span)) - 30
                let x = CGFloat(random.range(-0.1, 1.2)) * size.width - y * lean
                streaks.move(to: CGPoint(x: x, y: y))
                streaks.addLine(to: CGPoint(x: x - length * lean, y: y + length))
            }
            context.stroke(streaks, with: .color(Rain.colour(night: night).opacity(0.38)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}
