import SwiftUI

/// The scenes Puggle stands in at the top of Today, one a day in turn, each
/// with a friend. The sky follows the time of day; after dark it is navy with
/// stars. The ground at the front is always the page colour, so the scene
/// runs into Today. Friends are drawn in code until the real drawings arrive:
/// they have Puggle's dark outline, and the scenery behind has none.
enum SceneKind: Int, CaseIterable {
    case hills, beach, backyard, bush

    /// A different scene each day, in turn.
    static var today: SceneKind {
        #if DEBUG
        // For checking each scene: launch with "-debugScene 2".
        if let forced = UserDefaults.standard.string(forKey: "debugScene").flatMap(Int.init), let kind = SceneKind(rawValue: forced) { return kind }
        #endif
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return allCases[day % allCases.count]
    }

    /// Where the sun or moon sits, clear of the tree, the washing and the You button.
    var lightSpot: CGFloat {
        switch self {
        case .hills, .beach: 0.16
        case .backyard: 0.72
        case .bush: 0.66
        }
    }

    /// Clouds: across, down (as fractions) and width.
    var clouds: [(x: CGFloat, y: CGFloat, width: CGFloat)] {
        switch self {
        case .hills, .beach: [(0.25, 0.45, 72), (0.47, 0.27, 54), (0.80, 0.42, 88)]
        case .backyard: [(0.27, 0.28, 66), (0.52, 0.42, 50), (0.84, 0.47, 80)]
        case .bush: [(0.45, 0.28, 56), (0.80, 0.44, 84)]
        }
    }
}

/// The part of the day the sky is showing.
enum SkyPhase { case dawn, day, dusk, night }

struct PuggleScene: View {
    let kind: SceneKind
    let dark: Bool
    /// False until Today first appears; the clouds drift in and the friend pops up.
    var appeared = true
    /// How far Today has been pulled down. The sky grows upwards by this much,
    /// and the further it goes, the more turns up in it.
    var pull: CGFloat = 0
    /// For the scene gallery: show this hour rather than the clock's.
    var hourOverride: Int?

    private var hour: Int {
        if let hourOverride { return hourOverride }
        #if DEBUG
        // For checking: Developer menu, or launch with "-debugHour 22".
        if let forced = UserDefaults.standard.string(forKey: "debugHour").flatMap(Int.init) { return forced }
        #endif
        return Calendar.current.component(.hour, from: .now)
    }

    private var phase: SkyPhase {
        if dark { return .night }
        switch hour {
        case 5..<9: return .dawn
        case 9..<17: return .day
        case 17..<21: return .dusk
        default: return .night
        }
    }

    private var starry: Bool { phase == .night }

    /// Where a warm lamp sits beside Puggle in this scene after dark, on her own box. Nil when there is none.
    static func lamp(for kind: SceneKind, night: Bool) -> UnitPoint? {
        kind == .backyard && night ? UnitPoint(x: -0.15, y: 0.3) : nil
    }

    /// Whether the scene on Today is showing night just now, so Puggle can take its light.
    static func isNight(dark: Bool, hour: Int? = nil) -> Bool {
        PuggleScene(kind: .hills, dark: dark, hourOverride: hour).starry
    }

    private var sky: [Color] {
        if dark { return [Color(hex: 0x14163C), Color(hex: 0x25275C), Palette.sand] }
        switch phase {
        case .dawn: return [Color(hex: 0xF6CDB4), Color(hex: 0xF8E3CF), Palette.sand]
        case .dusk: return [Color(hex: 0xC9B6D9), Color(hex: 0xF4CDB0), Palette.sand]
        case .night: return [Color(hex: 0x2B2F6B), Color(hex: 0x4C4892), Palette.sand]
        case .day: return [Color(hex: 0xBFDDF0), Color(hex: 0xE3EEF1), Palette.sand]
        }
    }

    /// Scenery colours, dimmed after dark.
    private func tone(_ day: UInt32, _ night: UInt32) -> Color { Color(hex: starry ? night : day) }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = max(geometry.size.height - pull, 1)
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [sky[0]] + sky, startPoint: .top, endPoint: .bottom)
                // One sky from the top of the pull to the horizon, so nothing is left bare.
                if starry {
                    StarField(sceneHeight: h, moon: CGPoint(x: w * kind.lightSpot, y: pull + h * 0.36))
                        .opacity(appeared ? 1 : 0)
                }
                // The scene itself keeps its height and sits at the bottom.
                ZStack {
                    light(w, h)
                    clouds(w, h)
                    scenery(w, h)
                    ground
                    details(w, h)
                    // Puggle's shadow, so she stands on the hill.
                    Ellipse().fill(starry ? Color(hex: 0x15163A).opacity(0.32) : Palette.fixedInk.opacity(0.1))
                        .frame(width: 72, height: 9).position(x: w / 2, y: h - 27)
                    friend(w, h)
                }
                .frame(width: w, height: h)
                surprises(w)
                    .frame(width: w, height: geometry.size.height, alignment: .top)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Sky

    /// The sun by day, low and warm at each end of it; the moon after dark.
    @ViewBuilder private func light(_ w: CGFloat, _ h: CGFloat) -> some View {
        let x = w * kind.lightSpot
        switch phase {
        case .night:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: 0xF3E0B8).opacity(0.22), Color(hex: 0xF3E0B8).opacity(0)],
                                             center: .center, startRadius: 8, endRadius: 46))
                    .frame(width: 92, height: 92)
                Crescent().fill(Color(hex: 0xF3E0B8)).frame(width: 28, height: 28)
            }
            .position(x: x, y: h * 0.36)
            .opacity(appeared ? 1 : 0)
        case .day:
            Sun(colour: Color(hex: 0xFFD666), size: 42).position(x: x, y: h * 0.36)
        case .dawn:
            Sun(colour: Color(hex: 0xFFC36B), size: 46).position(x: x, y: h * 0.5)
        case .dusk:
            Sun(colour: Color(hex: 0xF79A72), size: 46).position(x: x, y: h * 0.52)
        }
    }

    private func clouds(_ w: CGFloat, _ h: CGFloat) -> some View {
        let tint: Color = switch phase {
        case .night: Color(hex: 0x9A96E0).opacity(0.2)
        case .dawn: Color(hex: 0xFFF6EC).opacity(0.85)
        case .dusk: Color(hex: 0xFBE4E6).opacity(0.8)
        default: Color.white.opacity(0.8)
        }
        return ZStack {
            ForEach(Array(kind.clouds.enumerated()), id: \.offset) { index, cloud in
                Cloud(width: cloud.width, tint: tint)
                    .position(x: w * cloud.x, y: h * cloud.y)
                    .offset(x: appeared ? 0 : (index.isMultiple(of: 2) ? -30 : 34))
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Ground

    /// The ground in the page colour, with a little shade along the top so the hill has a shape.
    private var ground: some View {
        let shade: Color = if dark { Color(hex: 0x3A3F7A).opacity(0.55) } else {
            switch phase {
            case .dawn: Color(hex: 0xEDB48E).opacity(0.3)
            case .dusk: Color(hex: 0xC9A2C2).opacity(0.34)
            case .night: Color(hex: 0x5F5E9A).opacity(0.5)
            case .day: Color(hex: 0xCDBE98).opacity(0.3)
            }
        }
        let hill = Hill(rise: 0.6, left: 0.8, right: 0.78)
        return ZStack {
            hill.fill(Palette.sand)
            hill.fill(LinearGradient(colors: [shade, shade.opacity(0)],
                                     startPoint: UnitPoint(x: 0.5, y: 0.66), endPoint: UnitPoint(x: 0.5, y: 0.97)))
        }
    }

    // MARK: Scenery behind the ground

    @ViewBuilder private func scenery(_ w: CGFloat, _ h: CGFloat) -> some View {
        switch kind {
        case .hills:
            Hill(rise: 0.34, left: 0.58, right: 0.76, peak: 0.2).fill(tone(0xD7E7C6, 0x2E3468))
            RoundTree(leaf: tone(0xB7D2A4, 0x263A62), trunk: tone(0xB89A78, 0x3A3560)).frame(width: 16, height: 24).position(x: w * 0.1, y: h * 0.47)
            // Someone is home on the far hill: a warm window after dark.
            Cottage(night: starry).frame(width: 26, height: 24).position(x: w * 0.36, y: h * 0.415)
            Hill(rise: 0.44, left: 0.82, right: 0.56, peak: 0.84).fill(tone(0xBFD8AA, 0x272C5A))
            RoundTree(leaf: tone(0x9CC08C, 0x1F3258), trunk: tone(0xA98A68, 0x332E58)).frame(width: 26, height: 38).position(x: w * 0.78, y: h * 0.47)
            RoundTree(leaf: tone(0xA9C998, 0x22365C), trunk: tone(0xA98A68, 0x332E58)).frame(width: 18, height: 27).position(x: w * 0.87, y: h * 0.48)
            Hill(rise: 0.56, left: 0.74, right: 0.72).fill(tone(0xA9CB93, 0x1F2450))
        case .beach:
            // The sea, lighter where it is shallow, with a boat out on it.
            Rectangle().fill(tone(0x86BEE3, 0x232E6C)).frame(height: h * 0.24).position(x: w / 2, y: h * 0.7)
            Rectangle().fill(tone(0xA6D4EE, 0x2B3A80)).frame(height: h * 0.12).position(x: w / 2, y: h * 0.76)
            Waves().stroke(Color.white.opacity(starry ? 0.18 : 0.55), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: w * 0.36, height: 6).position(x: w * 0.36, y: h * 0.635)
            Waves().stroke(Color.white.opacity(starry ? 0.18 : 0.55), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: w * 0.22, height: 6).position(x: w * 0.74, y: h * 0.665)
            Sailboat(dark: starry).frame(width: 26, height: 28).position(x: w * 0.84, y: h * 0.555)
            if starry {
                // The moon on the water.
                MoonPath().fill(Color(hex: 0xF3E0B8).opacity(0.4)).frame(width: 34, height: h * 0.1).position(x: w * kind.lightSpot, y: h * 0.635)
            }
            // Foam where the sea meets the sand.
            HillEdge(rise: 0.6, left: 0.8, right: 0.78)
                .stroke(Color.white.opacity(starry ? 0.3 : 0.85), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .offset(y: -1)
        case .backyard:
            Hedge().fill(tone(0xA9CB93, 0x1F2450)).frame(width: w, height: h * 0.22).position(x: w / 2, y: h * 0.56)
            Fence().fill(tone(0xF6EDD9, 0x4B4F8A)).frame(width: w, height: h * 0.2).position(x: w / 2, y: h * 0.62)
            Fence().stroke(tone(0xD8C8A8, 0x363A72), lineWidth: 1).frame(width: w, height: h * 0.2).position(x: w / 2, y: h * 0.62)
            Hill(rise: 0.6, left: 0.73, right: 0.71).fill(tone(0xB9D49E, 0x232858))
            WashingLine(dark: starry).frame(width: w * 0.38, height: h * 0.36).position(x: w * 0.23, y: h * 0.52)
            if starry {
                // A lantern on the post: the one warm light in the yard.
                Lantern().frame(width: 120, height: 120).position(x: w * 0.405, y: h * 0.4)
            }
        case .bush:
            // A far ridge with gums on it, then the nearer rise.
            Hill(rise: 0.46, left: 0.66, right: 0.5, peak: 0.9).fill(tone(0xD9DDBA, 0x2F3266))
            SmallGum(leaf: tone(0xB4C7A6, 0x263A62), trunk: tone(0xD9CDB6, 0x5A5890)).frame(width: 26, height: 34).position(x: w * 0.6, y: h * 0.5)
            SmallGum(leaf: tone(0xA9BF9C, 0x22365C), trunk: tone(0xD9CDB6, 0x5A5890)).frame(width: 34, height: 44).position(x: w * 0.9, y: h * 0.43)
            Hill(rise: 0.54, left: 0.8, right: 0.62, peak: 0.85).fill(tone(0xCBC596, 0x272A56))
            GumTree(dark: starry).frame(width: 120, height: h * 0.78).position(x: w * 0.13, y: h * 0.5)
        }
    }

    /// Small things on the ground at the front.
    @ViewBuilder private func details(_ w: CGFloat, _ h: CGFloat) -> some View {
        let grass = tone(0x9DBB8A, 0x44608A)
        switch kind {
        case .hills:
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10).position(x: w * 0.1, y: h * 0.8)
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 12, height: 9).position(x: w * 0.72, y: h * 0.74)
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10).position(x: w * 0.92, y: h * 0.83)
        case .beach:
            Starfish().fill(tone(0xF2A48E, 0x8C5A86)).frame(width: 15, height: 15).rotationEffect(.degrees(12)).position(x: w * 0.8, y: h * 0.9)
        case .backyard:
            if starry {
                // The lantern's light lying on the ground, reaching Puggle.
                Ellipse().fill(RadialGradient(colors: [Color(hex: 0xFFD98A).opacity(0.3), Color(hex: 0xFFD98A).opacity(0)],
                                              center: .center, startRadius: 4, endRadius: 80))
                    .frame(width: 170, height: 34).position(x: w * 0.44, y: h * 0.84)
            }
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10).position(x: w * 0.09, y: h * 0.8)
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 12, height: 9).position(x: w * 0.9, y: h * 0.8)
        case .bush:
            let dry = tone(0xB0A474, 0x5A5C8C)
            GrassTuft().stroke(dry, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10).position(x: w * 0.7, y: h * 0.75)
            GrassTuft().stroke(dry, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 12, height: 9).position(x: w * 0.9, y: h * 0.81)
        }
    }

    // MARK: Pulling down

    /// Things that turn up in the extra sky as Today is pulled down: a balloon,
    /// then a kite (a shooting star after dark), then a flock of birds.
    private func surprises(_ w: CGFloat) -> some View {
        let balloon = pull > 60, kite = pull > 130, flock = pull > 200
        let sway = Double(pull).truncatingRemainder(dividingBy: 40) / 40 * 8 - 4
        return ZStack(alignment: .topLeading) {
            if starry {
                // Shooting stars, one more at each stretch of the pull.
                ForEach(Array([(150.0, 0.62, 70.0), (250.0, 0.2, 40.0), (340.0, 0.75, 150.0), (430.0, 0.35, 90.0)].enumerated()), id: \.offset) { _, star in
                    if pull > star.0 {
                        StreakingStar()
                            .position(x: w * star.1, y: pull - star.0 + star.2)
                    }
                }
            } else {
                // By day, little clouds drift into the new sky.
                ForEach(0..<6, id: \.self) { i in
                    var random = SeededRandom(UInt64(i) &* 4243 &+ 9)
                    let depth = CGFloat(i) * 70 + 90
                    Cloud(width: random.range(46, 84))
                        .position(x: random.range(0.12, 0.88) * w, y: pull - depth)
                        .offset(x: pull > depth ? 0 : (i.isMultiple(of: 2) ? -40 : 40))
                        .opacity(pull > depth ? 0.9 : 0)
                        .animation(.spring(duration: 0.6), value: pull > depth)
                }
            }
            Balloon(dark: starry)
                .frame(width: 40, height: 60)
                .rotationEffect(.degrees(sway))
                .scaleEffect(balloon ? 1 : 0.3)
                .opacity(balloon ? 1 : 0)
                .animation(.spring(duration: 0.45, bounce: 0.5), value: balloon)
                .position(x: w * 0.72, y: pull - 46)
            Group {
                if starry {
                    ShootingStar().frame(width: 70, height: 20)
                } else {
                    Kite().frame(width: 44, height: 76).rotationEffect(.degrees(-sway * 2))
                }
            }
            .scaleEffect(kite ? 1 : 0.3)
            .opacity(kite ? 1 : 0)
            .animation(.spring(duration: 0.45, bounce: 0.5), value: kite)
            .position(x: w * 0.28, y: pull - 118)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Bird(dark: starry, flying: true).frame(width: 34, height: 26).scaleEffect(0.72).offset(y: i == 1 ? -9 : 0)
                }
            }
            .offset(x: flock ? 0 : w * 0.6)
            .opacity(flock ? 1 : 0)
            .animation(.spring(duration: 0.7, bounce: 0.2), value: flock)
            .position(x: w * 0.55, y: pull - 190)
        }
    }

    // MARK: Friends

    @ViewBuilder private func friend(_ w: CGFloat, _ h: CGFloat) -> some View {
        let pop = appeared ? 1.0 : 0.4
        let shadow = starry ? Color(hex: 0x15163A).opacity(0.3) : Palette.fixedInk.opacity(0.1)
        switch kind {
        case .hills:
            Ellipse().fill(shadow).frame(width: 30, height: 6).position(x: w * 0.26, y: h * 0.868)
            Bird(dark: starry).frame(width: 46, height: 38).position(x: w * 0.26, y: h * 0.8)
                .scaleEffect(pop).offset(y: appeared ? 0 : -20).opacity(appeared ? 1 : 0)
        case .beach:
            Ellipse().fill(shadow).frame(width: 46, height: 7).position(x: w * 0.25, y: h * 0.905)
            Crab(dark: starry).frame(width: 60, height: 40).position(x: w * 0.25, y: h * 0.85)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
        case .backyard:
            Ellipse().fill(shadow).frame(width: 44, height: 6).position(x: w * 0.77, y: h * 0.902)
            Snail(dark: starry).frame(width: 54, height: 38).position(x: w * 0.77, y: h * 0.85)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
            if starry {
                Fireflies().frame(width: 70, height: 50).position(x: w * 0.62, y: h * 0.47)
                    .opacity(appeared ? 1 : 0)
            } else {
                Butterfly(dark: false).frame(width: 36, height: 30).position(x: w * 0.66, y: h * 0.43)
                    .offset(x: appeared ? 0 : 40, y: appeared ? 0 : -24).opacity(appeared ? 1 : 0)
            }
        case .bush:
            Kookaburra(dark: starry).frame(width: 52, height: 54).position(x: w * 0.25, y: h * 0.415)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
        }
    }
}

// MARK: Sky pieces

/// Stars from the top of the sky down to the horizon, in one field: the same
/// stars whether or not Today is pulled down, so pulling only shows more.
struct StarField: View {
    /// The height of the scene at the bottom; stars stop above its ground.
    let sceneHeight: CGFloat
    /// Where the moon is, so no star shows through it.
    let moon: CGPoint

    var body: some View {
        Canvas { context, size in
            let horizon = size.height - sceneHeight * 0.4
            let glow = Color(hex: 0xF3E0B8)
            for i in 0..<150 {
                var random = SeededRandom(UInt64(i) &* 7919 &+ 3)
                let x = random.range(0.02, 0.98) * size.width
                let y = horizon - random.range(0, 1) * 700
                let dot = random.range(1.3, 3)
                let strength = random.range(0.4, 0.95)
                guard y > -8, hypot(x - moon.x, y - moon.y) > 24 else { continue }
                // Fainter close to the horizon, where the sky is paler.
                let fade = min(1, 0.35 + (horizon - y) / 90)
                if i % 11 == 0 {
                    // A few are four-pointed and a little bigger.
                    let r = dot * 2.1
                    var star = Path()
                    star.move(to: CGPoint(x: x, y: y - r))
                    star.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x + r * 0.18, y: y - r * 0.18))
                    star.addQuadCurve(to: CGPoint(x: x, y: y + r), control: CGPoint(x: x + r * 0.18, y: y + r * 0.18))
                    star.addQuadCurve(to: CGPoint(x: x - r, y: y), control: CGPoint(x: x - r * 0.18, y: y + r * 0.18))
                    star.addQuadCurve(to: CGPoint(x: x, y: y - r), control: CGPoint(x: x - r * 0.18, y: y - r * 0.18))
                    context.fill(star, with: .color(Color(hex: 0xFFE7A8).opacity(min(1, strength + 0.2) * fade)))
                } else {
                    context.fill(Path(ellipseIn: CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot)),
                                 with: .color(glow.opacity(strength * fade)))
                }
            }
        }
    }
}

/// A crescent moon: a real cut-out, so the sky shows through whatever its colour.
struct Crescent: Shape {
    func path(in rect: CGRect) -> Path {
        let bite = rect.offsetBy(dx: rect.width * 0.3, dy: -rect.height * 0.16)
        return Path(ellipseIn: rect).subtracting(Path(ellipseIn: bite))
    }
}

struct Sun: View {
    let colour: Color
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(colour.opacity(0.14)).frame(width: size * 1.9, height: size * 1.9)
            Circle().fill(colour.opacity(0.24)).frame(width: size * 1.4, height: size * 1.4)
            Circle().fill(colour).frame(width: size, height: size)
        }
    }
}

struct Cloud: View {
    let width: CGFloat
    var tint = Color.white.opacity(0.8)
    var body: some View {
        // One shape, so the bumps don't show where they overlap.
        CloudShape().fill(tint).frame(width: width, height: width * 0.5)
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path(roundedRect: CGRect(x: rect.minX, y: rect.minY + h * 0.52, width: w, height: h * 0.48), cornerRadius: h * 0.24)
        path = path.union(Path(ellipseIn: CGRect(x: rect.minX + w * 0.14, y: rect.minY + h * 0.2, width: w * 0.36, height: w * 0.36)))
        path = path.union(Path(ellipseIn: CGRect(x: rect.minX + w * 0.36, y: rect.minY, width: w * 0.42, height: w * 0.42)))
        path = path.union(Path(ellipseIn: CGRect(x: rect.minX + w * 0.64, y: rect.minY + h * 0.3, width: w * 0.26, height: w * 0.26)))
        return path
    }
}

// MARK: Scenery shapes

/// A soft hill across the bottom: `rise` is the height of its top, `left` and
/// `right` where it meets the edges, all as fractions of the height.
struct Hill: Shape {
    var rise: CGFloat, left: CGFloat, right: CGFloat
    /// Where along the width the top is, as a fraction.
    var peak: CGFloat = 0.5
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * left))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.height * right), control: CGPoint(x: rect.width * peak, y: rect.height * rise))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Only the top line of a `Hill`, for foam along the shore.
struct HillEdge: Shape {
    var rise: CGFloat, left: CGFloat, right: CGFloat
    var peak: CGFloat = 0.5
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - 4, y: rect.height * left))
        path.addQuadCurve(to: CGPoint(x: rect.maxX + 4, y: rect.height * right), control: CGPoint(x: rect.width * peak, y: rect.height * rise))
        return path
    }
}

struct Waves: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 22
        var x = rect.minX
        path.move(to: CGPoint(x: x, y: rect.midY))
        while x < rect.maxX {
            path.addQuadCurve(to: CGPoint(x: x + step, y: rect.midY), control: CGPoint(x: x + step / 2, y: rect.minY))
            x += step
        }
        return path
    }
}

struct Fence: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gap: CGFloat = 22, board: CGFloat = 16
        var x = rect.minX - 4
        while x < rect.maxX {
            // Each board with a pointed top.
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x, y: rect.minY + 7))
            path.addLine(to: CGPoint(x: x + board / 2, y: rect.minY))
            path.addLine(to: CGPoint(x: x + board, y: rect.minY + 7))
            path.addLine(to: CGPoint(x: x + board, y: rect.maxY))
            path.closeSubpath()
            x += gap
        }
        path.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.36, width: rect.width, height: 5))
        return path
    }
}

/// A row of rounded bushes along the back of the yard.
struct Hedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.45, width: rect.width, height: rect.height * 0.55))
        var random = SeededRandom(41)
        var x = rect.minX - 10
        while x < rect.maxX {
            let size = CGFloat(random.range(40, 62))
            path = path.union(Path(ellipseIn: CGRect(x: x, y: rect.minY + CGFloat(random.range(0, 10)), width: size, height: size * 0.8)))
            x += size * 0.7
        }
        return path
    }
}

/// A small lantern and the glow round it.
struct Lantern: View {
    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            context.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFFD98A).opacity(0.42), Color(hex: 0xFFD98A).opacity(0)]),
                                               center: centre, startRadius: 2, endRadius: size.width / 2))
            let frame = Color(hex: 0x4A3F66)
            context.fill(Path(roundedRect: CGRect(x: centre.x - 5, y: centre.y - 9, width: 10, height: 3), cornerRadius: 1.5), with: .color(frame))
            context.fill(Path(roundedRect: CGRect(x: centre.x - 4, y: centre.y - 6, width: 8, height: 11), cornerRadius: 2.5), with: .color(Color(hex: 0xFFE7A8)))
            context.fill(Path(roundedRect: CGRect(x: centre.x - 5, y: centre.y + 5, width: 10, height: 3), cornerRadius: 1.5), with: .color(frame))
        }
    }
}

/// A little house a long way off. After dark its window is lit, and the light spills a little.
struct Cottage: View {
    let night: Bool
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let wall = Color(hex: night ? 0x4D5296 : 0xFBF3E2), roof = Color(hex: night ? 0x34386E : 0xD9735E)
            context.fill(Path(CGRect(x: w * 0.18, y: h * 0.45, width: w * 0.64, height: h * 0.55)), with: .color(wall))
            var top = Path()
            top.move(to: CGPoint(x: w * 0.08, y: h * 0.48)); top.addLine(to: CGPoint(x: w * 0.5, y: h * 0.08)); top.addLine(to: CGPoint(x: w * 0.92, y: h * 0.48))
            top.closeSubpath()
            context.fill(top, with: .color(roof))
            let window = CGRect(x: w * 0.4, y: h * 0.58, width: w * 0.2, height: h * 0.24)
            if night {
                let centre = CGPoint(x: window.midX, y: window.midY)
                context.fill(Path(ellipseIn: CGRect(x: centre.x - 13, y: centre.y - 13, width: 26, height: 26)),
                             with: .radialGradient(Gradient(colors: [Color(hex: 0xFFD98A).opacity(0.55), Color(hex: 0xFFD98A).opacity(0)]),
                                                   center: centre, startRadius: 1, endRadius: 13))
            }
            context.fill(Path(roundedRect: window, cornerRadius: 1), with: .color(Color(hex: night ? 0xFFDF9E : 0x9CC4E0)))
        }
    }
}

/// The moon's light lying on the sea: a few short strokes, narrowing towards the shore.
struct MoonPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows: [(CGFloat, CGFloat)] = [(0.0, 0.9), (0.28, 0.55), (0.56, 0.7), (0.84, 0.35)]
        for (down, wide) in rows {
            let width = rect.width * wide
            path.addRoundedRect(in: CGRect(x: rect.midX - width / 2, y: rect.minY + rect.height * down, width: width, height: 2.2),
                                cornerSize: CGSize(width: 1.1, height: 1.1))
        }
        return path
    }
}

/// A round tree for the far hills.
struct RoundTree: View {
    let leaf: Color
    let trunk: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 1.5).fill(trunk).frame(width: max(w * 0.16, 3), height: h * 0.45).position(x: w / 2, y: h * 0.78)
                Ellipse().fill(leaf).frame(width: w, height: h * 0.72).position(x: w / 2, y: h * 0.36)
            }
        }
    }
}

/// A gum tree a long way off: a thin trunk and two clumps of leaves.
struct SmallGum: View {
    let leaf: Color
    let trunk: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h))
                    p.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.3), control: CGPoint(x: w * 0.42, y: h * 0.6))
                }
                .stroke(trunk, style: StrokeStyle(lineWidth: max(w * 0.09, 2), lineCap: .round))
                Ellipse().fill(leaf).frame(width: w * 0.7, height: h * 0.34).position(x: w * 0.4, y: h * 0.26)
                Ellipse().fill(leaf).frame(width: w * 0.62, height: h * 0.3).position(x: w * 0.68, y: h * 0.16)
            }
        }
    }
}

struct GumTree: View {
    let dark: Bool
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let trunk = Color(hex: dark ? 0x5F5C96 : 0xE4D7C2)
            let bark = Color(hex: dark ? 0x4A4780 : 0xC9B89C)
            let leaves = Color(hex: dark ? 0x263A62 : 0x9DBB98)
            let lighter = Color(hex: dark ? 0x2E4670 : 0xB4CDAC)
            ZStack {
                // The branch the friend sits on, behind the trunk.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.52))
                    p.addQuadCurve(to: CGPoint(x: w * 1.05, y: h * 0.5), control: CGPoint(x: w * 0.8, y: h * 0.42))
                }
                .stroke(trunk, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                Path { p in
                    p.move(to: CGPoint(x: w * 0.36, y: h))
                    p.addQuadCurve(to: CGPoint(x: w * 0.44, y: h * 0.22), control: CGPoint(x: w * 0.3, y: h * 0.6))
                    p.addLine(to: CGPoint(x: w * 0.56, y: h * 0.22))
                    p.addQuadCurve(to: CGPoint(x: w * 0.58, y: h), control: CGPoint(x: w * 0.49, y: h * 0.6))
                }
                .fill(trunk)
                // Bark, the way a gum sheds it.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.4, y: h * 0.7)); p.addLine(to: CGPoint(x: w * 0.43, y: h * 0.62))
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.84)); p.addLine(to: CGPoint(x: w * 0.49, y: h * 0.76))
                    p.move(to: CGPoint(x: w * 0.47, y: h * 0.44)); p.addLine(to: CGPoint(x: w * 0.49, y: h * 0.36))
                }
                .stroke(bark, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                ForEach(0..<6, id: \.self) { i in
                    let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.28, 0.2, 0.46), (0.64, 0.15, 0.5), (0.46, 0.06, 0.4), (0.12, 0.31, 0.32), (0.84, 0.29, 0.32), (0.5, 0.2, 0.34)]
                    let s = spots[i]
                    Ellipse().fill(i == 2 || i == 5 ? lighter : leaves)
                        .frame(width: w * s.2, height: w * s.2 * 0.62).position(x: w * s.0, y: h * s.1 + 10)
                }
            }
        }
    }
}

/// Washing on a line: a little suit, a pair of socks and a bib.
struct WashingLine: View {
    let dark: Bool
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let post = Color(hex: dark ? 0x4A4276 : 0xA98A68)
            let rope = Color(hex: dark ? 0x7673A6 : 0x8C7B66)
            for x in [w * 0.04, w * 0.96] {
                context.fill(Path(roundedRect: CGRect(x: x - 2, y: h * 0.08, width: 4, height: h * 0.92), cornerRadius: 2), with: .color(post))
            }
            // The line sags a little in the middle.
            let from = CGPoint(x: w * 0.04, y: h * 0.12), to = CGPoint(x: w * 0.96, y: h * 0.12), dip = CGPoint(x: w * 0.5, y: h * 0.26)
            var line = Path()
            line.move(to: from)
            line.addQuadCurve(to: to, control: dip)
            context.stroke(line, with: .color(rope), lineWidth: 1.2)
            func hang(_ t: CGFloat) -> CGPoint {
                let u = 1 - t
                return CGPoint(x: u * u * from.x + 2 * u * t * dip.x + t * t * to.x, y: u * u * from.y + 2 * u * t * dip.y + t * t * to.y)
            }
            let dim = dark ? 0.5 : 1.0
            // A little suit.
            var p = hang(0.24)
            var suit = Path()
            suit.move(to: CGPoint(x: p.x - 5, y: p.y))
            suit.addLine(to: CGPoint(x: p.x + 5, y: p.y))
            suit.addLine(to: CGPoint(x: p.x + 11, y: p.y + 5))
            suit.addLine(to: CGPoint(x: p.x + 8, y: p.y + 9))
            suit.addLine(to: CGPoint(x: p.x + 6, y: p.y + 7))
            suit.addLine(to: CGPoint(x: p.x + 6, y: p.y + 20))
            suit.addLine(to: CGPoint(x: p.x + 1, y: p.y + 20))
            suit.addLine(to: CGPoint(x: p.x, y: p.y + 16))
            suit.addLine(to: CGPoint(x: p.x - 1, y: p.y + 20))
            suit.addLine(to: CGPoint(x: p.x - 6, y: p.y + 20))
            suit.addLine(to: CGPoint(x: p.x - 6, y: p.y + 7))
            suit.addLine(to: CGPoint(x: p.x - 8, y: p.y + 9))
            suit.addLine(to: CGPoint(x: p.x - 11, y: p.y + 5))
            suit.closeSubpath()
            context.fill(suit, with: .color(Color(hex: 0x8FB4E3).opacity(dim)))
            // Two socks.
            p = hang(0.52)
            for dx in [-5.0, 5.0] {
                var sock = Path(roundedRect: CGRect(x: p.x + dx - 2.5, y: p.y, width: 5, height: 11), cornerRadius: 2)
                sock.addRoundedRect(in: CGRect(x: p.x + dx - 2.5, y: p.y + 7, width: 9, height: 5), cornerSize: CGSize(width: 2.5, height: 2.5))
                context.fill(sock, with: .color(Color(hex: 0xF4C95D).opacity(dim)))
            }
            // A bib.
            p = hang(0.78)
            var bib = Path()
            bib.addArc(center: CGPoint(x: p.x, y: p.y + 9), radius: 8.5, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            bib.addLine(to: CGPoint(x: p.x - 8.5, y: p.y))
            bib.addLine(to: CGPoint(x: p.x - 4, y: p.y))
            bib.addArc(center: CGPoint(x: p.x, y: p.y), radius: 4, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            bib.addLine(to: CGPoint(x: p.x + 8.5, y: p.y))
            bib.closeSubpath()
            context.fill(bib, with: .color(Color(hex: 0xEFA3BC).opacity(dim)))
        }
    }
}

struct Sailboat: View {
    let dark: Bool
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var hull = Path()
            hull.move(to: CGPoint(x: w * 0.08, y: h * 0.74))
            hull.addLine(to: CGPoint(x: w * 0.92, y: h * 0.74))
            hull.addQuadCurve(to: CGPoint(x: w * 0.2, y: h), control: CGPoint(x: w * 0.8, y: h))
            hull.closeSubpath()
            context.fill(hull, with: .color(Color(hex: dark ? 0x6A4A7A : 0xD9735E)))
            context.fill(Path(CGRect(x: w * 0.48, y: h * 0.06, width: 1.6, height: h * 0.7)), with: .color(Color(hex: dark ? 0x4A447A : 0x8C7355)))
            var sail = Path()
            sail.move(to: CGPoint(x: w * 0.56, y: h * 0.08))
            sail.addLine(to: CGPoint(x: w * 0.95, y: h * 0.66))
            sail.addLine(to: CGPoint(x: w * 0.56, y: h * 0.66))
            sail.closeSubpath()
            context.fill(sail, with: .color(Color(hex: dark ? 0xA7A4D8 : 0xFFFDF6)))
            var jib = Path()
            jib.move(to: CGPoint(x: w * 0.44, y: h * 0.2))
            jib.addLine(to: CGPoint(x: w * 0.44, y: h * 0.66))
            jib.addLine(to: CGPoint(x: w * 0.12, y: h * 0.66))
            jib.closeSubpath()
            context.fill(jib, with: .color(Color(hex: dark ? 0x908DC4 : 0xF6EDD9)))
        }
    }
}

struct GrassTuft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let base = CGPoint(x: rect.midX, y: rect.maxY)
        path.move(to: base)
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.3), control: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.midY))
        path.move(to: base)
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.04, y: rect.minY))
        path.move(to: base)
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.35), control: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.midY))
        return path
    }
}

struct Starfish: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2, inner = outer * 0.45
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: centre.x + CGFloat(cos(angle)) * radius, y: centre.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path.strokedPath(StrokeStyle(lineWidth: 2.5, lineJoin: .round)).union(path)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: Friends (placeholders until the drawings)

/// Draws a character the way Puggle is drawn: flat colours inside one dark
/// outline. Every part is first stroked dark, then all are filled, so the
/// outline runs round the whole shape and not between its parts.
private func outlined(_ context: inout GraphicsContext, _ parts: [(Path, Color)], line: CGFloat = 4, style: LineStyle = .ink) {
    for (path, colour) in parts {
        // One dark line, or each part's own colour, darker.
        context.stroke(path, with: .color(style == .tinted ? colour.outlineShade : Palette.fixedInk),
                       style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
    }
    for (path, colour) in parts {
        context.fill(path, with: .color(colour))
    }
}

private func dot(_ context: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ colour: Color) {
    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(colour))
}

private func polygon(_ points: [CGPoint]) -> Path {
    var path = Path()
    path.addLines(points)
    path.closeSubpath()
    return path
}

struct Bird: View {
    let dark: Bool
    /// In the air: wing up and no legs.
    var flying = false
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 - (flying ? 0 : 2)
            let body = Color(hex: 0xE79BB8).moonlit(dark)
            let wing = Color(hex: 0xC9718F).moonlit(dark)
            if !flying {
                var legs = Path()
                legs.move(to: CGPoint(x: cx - 3, y: cy + 8)); legs.addLine(to: CGPoint(x: cx - 3, y: cy + 15))
                legs.move(to: CGPoint(x: cx + 4, y: cy + 8)); legs.addLine(to: CGPoint(x: cx + 4, y: cy + 15))
                context.stroke(legs, with: .color(style == .tinted ? wing.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            outlined(&context, [
                (polygon([CGPoint(x: cx - 10, y: cy - 1), CGPoint(x: cx - 21, y: cy - 7), CGPoint(x: cx - 19, y: cy + 4)]), wing),
                (polygon([CGPoint(x: cx + 11, y: cy - 5), CGPoint(x: cx + 20, y: cy - 1.5), CGPoint(x: cx + 11, y: cy + 1.5)]), Color(hex: 0xF2B544).moonlit(dark)),
                (Path(ellipseIn: CGRect(x: cx - 14, y: cy - 11, width: 28, height: 22)), body),
            ], style: style)
            let lift: CGFloat = flying ? -7 : 0
            let wingShape = Path(ellipseIn: CGRect(x: cx - 10, y: cy - 3 + lift, width: 14, height: 9))
                .applying(CGAffineTransform(translationX: cx - 3, y: cy + 1.5 + lift).rotated(by: flying ? -0.9 : -0.35).translatedBy(x: -(cx - 3), y: -(cy + 1.5 + lift)))
            if flying {
                outlined(&context, [(wingShape, wing)], line: 3, style: style)
            } else {
                context.fill(wingShape, with: .color(wing))
            }
            dot(&context, cx + 6, cy - 4, 1.9, Palette.fixedInk)
            dot(&context, cx + 8.5, cy + 1.5, 2.4, Color(hex: 0xF27A8A).opacity(dark ? 0.35 : 0.6))
        }
    }
}

struct Crab: View {
    let dark: Bool
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 + 4
            let shell = Color(hex: 0xE8735E).moonlit(dark)
            let line = style == .tinted ? shell.outlineShade : Palette.fixedInk
            // Legs first, behind everything.
            var legs = Path()
            for side in [-1.0, 1.0] {
                for (i, reach) in [(0, 9.0), (1, 12.0), (2, 9.0)] {
                    let start = CGPoint(x: cx + side * 13, y: cy + 3 + CGFloat(i) * 2.5)
                    legs.move(to: start)
                    legs.addQuadCurve(to: CGPoint(x: start.x + side * reach, y: cy + 9 + CGFloat(i) * 1.5),
                                      control: CGPoint(x: start.x + side * reach * 0.7, y: start.y - 2))
                }
            }
            context.stroke(legs, with: .color(line), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            // Arms up to the claws.
            var arms = Path()
            for side in [-1.0, 1.0] {
                arms.move(to: CGPoint(x: cx + side * 14, y: cy - 1))
                arms.addLine(to: CGPoint(x: cx + side * 21, y: cy - 8))
            }
            context.stroke(arms, with: .color(line), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
            context.stroke(arms, with: .color(shell), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            outlined(&context, [
                (Path(ellipseIn: CGRect(x: cx - 29, y: cy - 17, width: 14, height: 13)), shell),
                (Path(ellipseIn: CGRect(x: cx + 15, y: cy - 17, width: 14, height: 13)), shell),
                (Path(roundedRect: CGRect(x: cx - 7.5, y: cy - 15, width: 3, height: 9), cornerRadius: 1.5), shell),
                (Path(roundedRect: CGRect(x: cx + 4.5, y: cy - 15, width: 3, height: 9), cornerRadius: 1.5), shell),
                (Path(ellipseIn: CGRect(x: cx - 17, y: cy - 8, width: 34, height: 20)), shell),
                (Path(ellipseIn: CGRect(x: cx - 10, y: cy - 20, width: 8, height: 8)), Color(hex: 0xFFFDF6).moonlit(dark)),
                (Path(ellipseIn: CGRect(x: cx + 2, y: cy - 20, width: 8, height: 8)), Color(hex: 0xFFFDF6).moonlit(dark)),
            ], style: style)
            // The nick in each claw.
            for side in [-1.0, 1.0] {
                var nick = Path()
                nick.move(to: CGPoint(x: cx + side * 22, y: cy - 17))
                nick.addLine(to: CGPoint(x: cx + side * 22, y: cy - 11.5))
                context.stroke(nick, with: .color(line), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
            dot(&context, cx - 5.6, cy - 15.6, 1.9, Palette.fixedInk)
            dot(&context, cx + 6.4, cy - 15.6, 1.9, Palette.fixedInk)
            var smile = Path()
            smile.addArc(center: CGPoint(x: cx, y: cy + 1), radius: 4, startAngle: .degrees(25), endAngle: .degrees(155), clockwise: false)
            context.stroke(smile, with: .color(Palette.fixedInk), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            dot(&context, cx - 10, cy + 2.5, 2.4, Color(hex: 0xF9B7A6).opacity(dark ? 0.4 : 0.8))
            dot(&context, cx + 10, cy + 2.5, 2.4, Color(hex: 0xF9B7A6).opacity(dark ? 0.4 : 0.8))
        }
    }
}

struct Snail: View {
    let dark: Bool
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 + 2
            let skin = Color(hex: 0xE3D1B0).moonlit(dark)
            let shell = Color(hex: 0xE0A062).moonlit(dark)
            let line = style == .tinted ? skin.outlineShade : Palette.fixedInk
            // Feelers, with a knob on each.
            var feelers = Path()
            feelers.move(to: CGPoint(x: cx + 16, y: cy - 2)); feelers.addLine(to: CGPoint(x: cx + 14, y: cy - 12))
            feelers.move(to: CGPoint(x: cx + 20, y: cy - 2)); feelers.addLine(to: CGPoint(x: cx + 23, y: cy - 11))
            context.stroke(feelers, with: .color(line), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            dot(&context, cx + 14, cy - 12.5, 2.4, line)
            dot(&context, cx + 23, cy - 11.5, 2.4, line)
            outlined(&context, [
                (Path(roundedRect: CGRect(x: cx - 23, y: cy + 5, width: 44, height: 9), cornerRadius: 4.5), skin),
                (Path(ellipseIn: CGRect(x: cx + 10, y: cy - 5, width: 15, height: 16)), skin),
                (Path(ellipseIn: CGRect(x: cx - 18, y: cy - 16, width: 27, height: 27)), shell),
            ], style: style)
            // The curl of the shell.
            var curl = Path()
            curl.addArc(center: CGPoint(x: cx - 4.5, y: cy - 2.5), radius: 7.5, startAngle: .degrees(-30), endAngle: .degrees(250), clockwise: false)
            curl.addArc(center: CGPoint(x: cx - 4.5, y: cy - 1.5), radius: 3, startAngle: .degrees(250), endAngle: .degrees(80), clockwise: false)
            context.stroke(curl, with: .color(Color(hex: 0xA86A35).moonlit(dark)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            dot(&context, cx + 19.5, cy + 1.5, 1.7, Palette.fixedInk)
            dot(&context, cx + 17, cy + 5.5, 2, Color(hex: 0xF2A48E).opacity(dark ? 0.35 : 0.7))
        }
    }
}

struct Butterfly: View {
    let dark: Bool
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2
            let wing = Color(hex: 0xB9A0EA).moonlit(dark)
            let lower = Color(hex: 0xD3C2F4).moonlit(dark)
            func tilted(_ rect: CGRect, _ angle: CGFloat) -> Path {
                Path(ellipseIn: rect).applying(CGAffineTransform(translationX: rect.midX, y: rect.midY).rotated(by: angle).translatedBy(x: -rect.midX, y: -rect.midY))
            }
            outlined(&context, [
                (tilted(CGRect(x: cx - 14, y: cy + 1, width: 11, height: 11), 0.3), lower),
                (tilted(CGRect(x: cx + 3, y: cy + 1, width: 11, height: 11), -0.3), lower),
                (tilted(CGRect(x: cx - 16, y: cy - 12, width: 14, height: 17), -0.4), wing),
                (tilted(CGRect(x: cx + 2, y: cy - 12, width: 14, height: 17), 0.4), wing),
            ], line: 3.4, style: style)
            context.fill(Path(roundedRect: CGRect(x: cx - 1.7, y: cy - 9, width: 3.4, height: 19), cornerRadius: 1.7), with: .color(Palette.fixedInk))
            var feelers = Path()
            feelers.move(to: CGPoint(x: cx - 0.5, y: cy - 8)); feelers.addQuadCurve(to: CGPoint(x: cx - 5, y: cy - 14), control: CGPoint(x: cx - 1.5, y: cy - 13))
            feelers.move(to: CGPoint(x: cx + 0.5, y: cy - 8)); feelers.addQuadCurve(to: CGPoint(x: cx + 5, y: cy - 14), control: CGPoint(x: cx + 1.5, y: cy - 13))
            context.stroke(feelers, with: .color(Palette.fixedInk), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            dot(&context, cx - 9, cy - 4, 2, Color.white.opacity(0.6))
            dot(&context, cx + 9, cy - 4, 2, Color.white.opacity(0.6))
        }
    }
}

/// After dark the butterfly has gone to bed; fireflies come out instead.
struct Fireflies: View {
    var body: some View {
        Canvas { context, size in
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.2, 0.6, 1), (0.52, 0.22, 0.8), (0.82, 0.7, 0.9), (0.66, 0.5, 0.6)]
            for spot in spots {
                let centre = CGPoint(x: size.width * spot.0, y: size.height * spot.1)
                let glow = 9 * spot.2
                context.fill(Path(ellipseIn: CGRect(x: centre.x - glow, y: centre.y - glow, width: glow * 2, height: glow * 2)),
                             with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE98A).opacity(0.5), Color(hex: 0xFFE98A).opacity(0)]),
                                                   center: centre, startRadius: 0, endRadius: glow))
                dot(&context, centre.x, centre.y, 1.8 * spot.2, Color(hex: 0xFFF3B8))
            }
        }
    }
}

struct Kookaburra: View {
    let dark: Bool
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2 - 2, cy = size.height / 2 + 2
            let cream = Color(hex: 0xF4EAD6).moonlit(dark)
            let brown = Color(hex: 0x9C7451).moonlit(dark)
            let beak = Color(hex: 0x4A545C).moonlit(dark)
            // Feet round the branch.
            var feet = Path()
            feet.move(to: CGPoint(x: cx - 3, y: cy + 17)); feet.addLine(to: CGPoint(x: cx - 3, y: cy + 22))
            feet.move(to: CGPoint(x: cx + 5, y: cy + 17)); feet.addLine(to: CGPoint(x: cx + 5, y: cy + 22))
            context.stroke(feet, with: .color(style == .tinted ? brown.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            outlined(&context, [
                (polygon([CGPoint(x: cx - 12, y: cy + 8), CGPoint(x: cx - 19, y: cy + 24), CGPoint(x: cx - 11, y: cy + 23), CGPoint(x: cx - 5, y: cy + 13)]), brown),
                (polygon([CGPoint(x: cx + 8, y: cy - 19), CGPoint(x: cx + 27, y: cy - 13.5), CGPoint(x: cx + 8, y: cy - 9)]), beak),
                (Path(ellipseIn: CGRect(x: cx - 13, y: cy - 10, width: 27, height: 29)), cream),
                (Path(ellipseIn: CGRect(x: cx - 12, y: cy - 26, width: 24, height: 23)), cream),
            ], style: style)
            // Wing, the stripe through the eye and the flash of blue.
            context.fill(Path(ellipseIn: CGRect(x: cx - 13, y: cy - 6, width: 14, height: 23)), with: .color(brown))
            context.fill(Path(roundedRect: CGRect(x: cx - 9, y: cy - 17.5, width: 18, height: 5), cornerRadius: 2.5), with: .color(brown))
            context.fill(Path(roundedRect: CGRect(x: cx - 10, y: cy + 1, width: 8, height: 4), cornerRadius: 2), with: .color(Color(hex: 0x6C93C4).moonlit(dark)))
            context.fill(Path(roundedRect: CGRect(x: cx - 6, y: cy - 27, width: 10, height: 4), cornerRadius: 2), with: .color(brown.opacity(0.7)))
            dot(&context, cx + 4.5, cy - 15, 1.9, Palette.fixedInk)
            // The line where the beak closes.
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx + 10, y: cy - 13.5)); mouth.addLine(to: CGPoint(x: cx + 22, y: cy - 13.5))
            context.stroke(mouth, with: .color(Palette.fixedInk.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }
}

// MARK: Things in the pulled-down sky

struct Balloon: View {
    let dark: Bool
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2
            let red = Color(hex: 0xE8735E).moonlit(dark)
            let yellow = Color(hex: 0xFFD666).moonlit(dark)
            let envelope = CGRect(x: cx - 17, y: 3, width: 34, height: 38)
            // Ropes down to the basket.
            var ropes = Path()
            ropes.move(to: CGPoint(x: cx - 9, y: 38)); ropes.addLine(to: CGPoint(x: cx - 4.5, y: 48))
            ropes.move(to: CGPoint(x: cx + 9, y: 38)); ropes.addLine(to: CGPoint(x: cx + 4.5, y: 48))
            context.stroke(ropes, with: .color(Palette.fixedInk), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            outlined(&context, [
                (Path(ellipseIn: envelope), red),
                (Path(roundedRect: CGRect(x: cx - 5.5, y: 47, width: 11, height: 8), cornerRadius: 2), Color(hex: 0xB08A5E).moonlit(dark)),
            ], line: 3.6, style: style)
            // Stripes that follow the round of the balloon.
            context.fill(Path(ellipseIn: CGRect(x: cx - 6, y: 3, width: 12, height: 38)), with: .color(yellow))
            var seams = Path()
            seams.addEllipse(in: CGRect(x: cx - 12, y: 3, width: 24, height: 38))
            context.stroke(seams, with: .color(Palette.fixedInk.opacity(0.18)), lineWidth: 1)
            dot(&context, cx - 8, 13, 2.6, Color.white.opacity(dark ? 0.15 : 0.45))
        }
    }
}

struct Kite: View {
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2
            let top = CGPoint(x: cx, y: 3), right = CGPoint(x: cx + 17, y: 21), bottom = CGPoint(x: cx, y: 46), left = CGPoint(x: cx - 17, y: 21)
            // The tail, with two bows.
            var tail = Path()
            tail.move(to: bottom)
            tail.addCurve(to: CGPoint(x: cx + 6, y: 72), control1: CGPoint(x: cx - 10, y: 54), control2: CGPoint(x: cx + 12, y: 62))
            context.stroke(tail, with: .color(Palette.fixedInk), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            for (point, colour) in [(CGPoint(x: cx - 2.5, y: 55), Color(hex: 0xE8735E)), (CGPoint(x: cx + 6, y: 65), Color(hex: 0xFFD666))] {
                let bow = polygon([CGPoint(x: point.x - 5, y: point.y - 3), CGPoint(x: point.x + 5, y: point.y + 3),
                                   CGPoint(x: point.x + 5, y: point.y - 3), CGPoint(x: point.x - 5, y: point.y + 3)])
                outlined(&context, [(bow, colour)], line: 2.4, style: style)
            }
            outlined(&context, [(polygon([top, right, bottom, left]), Color(hex: 0x6C93C4))], line: 3.6, style: style)
            // Two lighter panels and the sticks.
            context.fill(polygon([top, right, CGPoint(x: cx, y: 21)]), with: .color(Color(hex: 0x8FB4E3)))
            context.fill(polygon([left, CGPoint(x: cx, y: 21), bottom]), with: .color(Color(hex: 0x8FB4E3)))
            var sticks = Path()
            sticks.move(to: top); sticks.addLine(to: bottom)
            sticks.move(to: left); sticks.addLine(to: right)
            context.stroke(sticks, with: .color(Palette.fixedInk.opacity(0.55)), lineWidth: 1.2)
        }
    }
}

struct ShootingStar: View {
    var body: some View {
        ZStack(alignment: .trailing) {
            Capsule().fill(LinearGradient(colors: [Color(hex: 0xF3E0B8).opacity(0), Color(hex: 0xF3E0B8)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 60, height: 3)
            Image(systemName: "sparkle").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: 0xFFE7A8))
        }
        .rotationEffect(.degrees(-18))
    }
}

/// A shooting star that streaks across once when it appears, then fades.
struct StreakingStar: View {
    @State private var gone = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ShootingStar()
            .frame(width: 70, height: 20)
            .offset(x: gone ? 90 : -40, y: gone ? -30 : 12)
            .opacity(gone ? 0 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 1.1).delay(0.05)) { gone = true }
            }
    }
}
