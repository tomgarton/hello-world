import SwiftUI

/// The weather a scene is showing. For now it is chosen in the Developer menu;
/// later it can come from the real weather where the family is. Everything a
/// scene needs to know about a kind of weather is here, so the source can
/// change without the scenes changing.
enum Weather: String, CaseIterable, Identifiable {
    case clear, rain, storm, hot, windy, cold, snow, fog

    var id: String { rawValue }

    static var current: Weather { Weather(rawValue: UserDefaults.standard.string(forKey: "debugWeather") ?? "") ?? .clear }

    var name: String {
        switch self {
        case .clear: "Fine"
        case .rain: "Rain"
        case .storm: "Storm"
        case .hot: "Hot"
        case .windy: "Windy"
        case .cold: "Cold"
        case .snow: "Snow"
        case .fog: "Fog"
        }
    }

    /// No sun, moon or stars to be seen.
    var overcast: Bool { self == .rain || self == .storm || self == .snow || self == .fog }
    /// Something is falling.
    var wet: Bool { self == .rain || self == .storm || self == .snow }
    /// How fast the clouds go, against a fine day.
    var windiness: Double { self == .windy ? 4 : (self == .storm ? 2.6 : 1) }
    /// How far grass and washing swing, against a fine day.
    var sway: Double { self == .windy ? 3 : (self == .storm ? 2.2 : 1) }
    var extraClouds: Int {
        switch self {
        case .rain, .snow: 3
        case .storm: 4
        case .fog, .windy: 1
        default: 0
        }
    }

    /// What Puggle wears: "rain" (boots and a coat), "warm" (scarf and beanie), "sun" (hat and zinc) or "none".
    var outfit: String {
        switch self {
        case .rain, .storm: "rain"
        case .cold, .snow: "warm"
        case .hot: "sun"
        default: "none"
        }
    }

    /// What she wears at this time: no sun hat after dark.
    func outfit(night: Bool) -> String { self == .hot && night ? "none" : outfit }

    /// Laid over the sky to turn it grey, pale or warm. Nil on a fine day.
    func skyWash(night: Bool) -> Color? {
        switch self {
        case .rain: night ? Color(hex: 0x1A1C3A).opacity(0.4) : Color(hex: 0x8F96B2).opacity(0.5)
        case .storm: night ? Color(hex: 0x12132C).opacity(0.55) : Color(hex: 0x5F6684).opacity(0.62)
        case .snow: night ? Color(hex: 0x3A3F6E).opacity(0.3) : Color(hex: 0xC9D2E2).opacity(0.55)
        case .fog: night ? Color(hex: 0x4A4E82).opacity(0.35) : Color(hex: 0xE6E8EC).opacity(0.6)
        case .cold: night ? nil : Color(hex: 0xCFE2F2).opacity(0.3)
        // A pale haze: yellow over a blue sky would only turn it green.
        case .hot: night ? nil : Color(hex: 0xFFF6E2).opacity(0.3)
        default: nil
        }
    }

    /// Rain clouds are grey. Nil leaves the clouds as the time of day has them.
    func cloudTint(night: Bool) -> Color? {
        switch self {
        case .rain, .snow: night ? Color(hex: 0x6F70A8).opacity(0.5) : Color(hex: 0xD3D7E2).opacity(0.92)
        case .storm: night ? Color(hex: 0x4A4C82).opacity(0.6) : Color(hex: 0x9499B0).opacity(0.92)
        default: nil
        }
    }
}

private struct OutfitKey: EnvironmentKey {
    static let defaultValue = "none"
}

extension EnvironmentValues {
    /// What a rigged character is wearing: see `Weather.outfit`.
    var outfit: String {
        get { self[OutfitKey.self] }
        set { self[OutfitKey.self] = newValue }
    }
}

// MARK: Layers a scene adds for the weather

/// Behind the ground, in front of the far scenery: fog lying in the dips.
struct WeatherBehind: View {
    let weather: Weather
    let night: Bool
    let t: Double

    var body: some View {
        if weather == .fog {
            GeometryReader { geometry in
                let w = geometry.size.width, h = geometry.size.height
                let mist = night ? Color(hex: 0x8F8CD8) : Color.white
                ZStack {
                    // Two banks of fog, sliding past each other very slowly.
                    LinearGradient(colors: [mist.opacity(0), mist.opacity(night ? 0.32 : 0.75), mist.opacity(night ? 0.2 : 0.55)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(width: w * 1.6, height: h * 0.5)
                        .position(x: w * 0.5 + CGFloat(sin(t * 0.07)) * w * 0.2, y: h * 0.52)
                    Capsule().fill(mist.opacity(night ? 0.22 : 0.55))
                        .frame(width: w * 0.9, height: h * 0.1).blur(radius: 10)
                        .position(x: w * 0.4 - CGFloat(sin(t * 0.05 + 1)) * w * 0.25, y: h * 0.4)
                }
            }
        }
    }
}

/// On the ground: snow or frost along the top of the hill, and puddles.
struct WeatherGround: View {
    let weather: Weather
    let night: Bool
    let t: Double

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = geometry.size.height
            ZStack {
                if weather == .snow {
                    // Snow lying along the top of the hill.
                    HillEdge(rise: 0.6, left: 0.8, right: 0.78)
                        .stroke(Color.white.opacity(night ? 0.55 : 0.95), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .offset(y: 4)
                } else if weather == .cold {
                    // A rim of frost.
                    HillEdge(rise: 0.6, left: 0.8, right: 0.78)
                        .stroke(Color.white.opacity(night ? 0.3 : 0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .offset(y: 1)
                }
                if weather == .rain || weather == .storm {
                    // Puddles, with rings where the drops land. One is under Puggle's feet.
                    Puddle(night: night, t: t).frame(width: 96, height: 16).position(x: w * 0.5, y: h - 26)
                    Puddle(night: night, t: t + 1.3).frame(width: 60, height: 11).position(x: w * 0.86, y: h * 0.9)
                    Puddle(night: night, t: t + 2.1).frame(width: 44, height: 9).position(x: w * 0.08, y: h * 0.93)
                }
            }
        }
    }
}

struct Puddle: View {
    let night: Bool
    let t: Double

    var body: some View {
        Canvas { context, size in
            let water = night ? Color(hex: 0x3A4590) : Color(hex: 0xA9C6E0)
            context.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(water.opacity(0.75)))
            // Rings that grow and fade, each from its own drop.
            for ring in 0..<2 {
                let age = (t * 0.8 + Double(ring) * 0.5).truncatingRemainder(dividingBy: 1)
                let centre = CGPoint(x: size.width * (ring == 0 ? 0.35 : 0.68), y: size.height * 0.5)
                let reach = CGFloat(age) * size.width * 0.28
                let rim = CGRect(x: centre.x - reach, y: centre.y - reach * 0.3, width: reach * 2, height: reach * 0.6)
                context.stroke(Path(ellipseIn: rim), with: .color(Color.white.opacity((1 - age) * 0.7)), lineWidth: 1.2)
            }
        }
    }
}

/// Close by Puggle: her breath on a cold day.
struct WeatherNear: View {
    let weather: Weather
    let t: Double

    var body: some View {
        if weather == .cold || weather == .snow {
            GeometryReader { geometry in
                let w = geometry.size.width, h = geometry.size.height
                // A puff every few seconds, rising and fading.
                let age = t.truncatingRemainder(dividingBy: 4.2) / 1.6
                if age < 1 {
                    Cloud(width: 20 + CGFloat(age) * 12, tint: Color.white.opacity(0.75 * (1 - age)))
                        .position(x: w * 0.5 + 40 + CGFloat(age) * 10, y: h - 96 - CGFloat(age) * 16)
                }
            }
        }
    }
}

/// In front of everything: rain, snow, blowing leaves, heat rising, a far-off flash.
struct WeatherFront: View {
    let weather: Weather
    let night: Bool
    let t: Double
    /// The height of the scene at the bottom, so heat rises from its ground and not from the pulled-down sky.
    let sceneHeight: CGFloat

    var body: some View {
        Canvas { context, size in
            switch weather {
            case .rain, .storm:
                let heavy = weather == .storm
                let lean: CGFloat = heavy ? 0.34 : 0.14
                let colour = (night ? Color(hex: 0xB9BEEA) : Color.white).opacity(heavy ? 0.5 : 0.42)
                var streaks = Path()
                for i in 0..<(heavy ? 110 : 70) {
                    var random = SeededRandom(UInt64(i) &* 9973 &+ 5)
                    let speed = random.range(heavy ? 520 : 380, heavy ? 700 : 520)
                    let length = CGFloat(random.range(9, 16))
                    let span = Double(size.height + 40)
                    let y = CGFloat((random.range(0, 1) * span + speed * t).truncatingRemainder(dividingBy: span)) - 20
                    let x = CGFloat(random.range(-0.1, 1.1)) * size.width - y * lean
                    streaks.move(to: CGPoint(x: x, y: y))
                    streaks.addLine(to: CGPoint(x: x - length * lean, y: y + length))
                }
                context.stroke(streaks, with: .color(colour), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                if heavy {
                    // Lightning a long way off: a soft glow in the clouds, never a flash of the whole screen.
                    let since = t.truncatingRemainder(dividingBy: 8.5)
                    let glow = since < 0.5 ? sin(since / 0.5 * .pi) * 0.22 : 0
                    if glow > 0 {
                        let centre = CGPoint(x: size.width * 0.72, y: size.height - sceneHeight * 0.7)
                        context.fill(Path(ellipseIn: CGRect(x: centre.x - 130, y: centre.y - 70, width: 260, height: 140)),
                                     with: .radialGradient(Gradient(colors: [Color.white.opacity(glow), Color.white.opacity(0)]),
                                                           center: centre, startRadius: 0, endRadius: 130))
                    }
                }
            case .snow:
                for i in 0..<64 {
                    var random = SeededRandom(UInt64(i) &* 6151 &+ 3)
                    let speed = random.range(22, 46)
                    let flake = CGFloat(random.range(1.6, 3.6))
                    let span = Double(size.height + 20)
                    let y = CGFloat((random.range(0, 1) * span + speed * t).truncatingRemainder(dividingBy: span)) - 10
                    let drift = CGFloat(sin(t * random.range(0.5, 1.1) + Double(i))) * 9
                    let x = CGFloat(random.range(0, 1)) * size.width + drift
                    context.fill(Path(ellipseIn: CGRect(x: x - flake / 2, y: y - flake / 2, width: flake, height: flake)),
                                 with: .color(Color.white.opacity(random.range(0.6, 0.95))))
                }
            case .windy:
                // Leaves tumbling across, low over the ground.
                let ground = size.height - sceneHeight
                for i in 0..<9 {
                    var random = SeededRandom(UInt64(i) &* 4421 &+ 11)
                    let speed = random.range(90, 170)
                    let span = Double(size.width + 60)
                    let x = CGFloat((random.range(0, 1) * span + speed * t).truncatingRemainder(dividingBy: span)) - 30
                    let lane = CGFloat(random.range(0.3, 0.92))
                    let y = ground + sceneHeight * lane + CGFloat(sin(t * random.range(2, 4) + Double(i))) * 9
                    let turn = t * random.range(3, 6) + Double(i)
                    let leaf = Path(ellipseIn: CGRect(x: -5, y: -2.4, width: 10, height: 4.8))
                        .applying(CGAffineTransform(translationX: x, y: y).rotated(by: turn))
                    let colours: [UInt32] = night ? [0x44608A, 0x5A5C8C, 0x3E5A7A] : [0xD99A5B, 0xB7C98A, 0xE0B25E]
                    context.fill(leaf, with: .color(Color(hex: colours[i % 3])))
                }
            case .hot where !night:
                // Heat rising off the ground: faint wavering lines.
                let ground = size.height - sceneHeight * 0.42
                for line in 0..<3 {
                    var shimmer = Path()
                    let lift = CGFloat((t * 9 + Double(line) * 11).truncatingRemainder(dividingBy: 30))
                    let y = ground - lift
                    shimmer.move(to: CGPoint(x: 0, y: y))
                    var x: CGFloat = 0
                    while x < size.width {
                        shimmer.addQuadCurve(to: CGPoint(x: x + 26, y: y),
                                             control: CGPoint(x: x + 13, y: y + (Int(x / 26) % 2 == 0 ? 4 : -4) * CGFloat(sin(t * 2 + Double(line)))))
                        x += 26
                    }
                    context.stroke(shimmer, with: .color(Color.white.opacity(0.28 * Double(1 - lift / 30))), lineWidth: 1.4)
                }
            default:
                break
            }
        }
        .allowsHitTesting(false)
    }
}
