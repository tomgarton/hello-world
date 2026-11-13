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
}

/// The part of the day the sky is showing.
enum SkyPhase { case dawn, day, dusk, night }

/// When the scene started, and what makes today's clouds unlike yesterday's.
enum SceneClock {
    static let start = Date.now
    /// Changes each day and each time the app is opened.
    static let seed: UInt64 = UInt64(Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0) &* 2_654_435_761 &+ UInt64.random(in: 0..<1_000_000)
}

/// The scene at the top of Today. It keeps time for everything that moves in
/// it: clouds, water, washing, grass and the friends. Still with Reduce Motion.
struct PuggleScene: View {
    let kind: SceneKind
    let dark: Bool
    var appeared = true
    var pull: CGFloat = 0
    var hourOverride: Int?
    /// Drawn at one moment, for pictures of it.
    var still = false
    /// The weather to show. Nil means the one chosen in the Developer menu (later, the real one).
    var weather: Weather?
    /// Today only: after tea time she is indoors, in the room for the hour.
    var rooms = false
    /// How far Puggle stands from the middle, so her shadow is under her.
    var puggleX: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("debugWeather") private var chosenWeather = ""
    @AppStorage(WeatherWatch.liveKey) private var liveWeather = ""
    @AppStorage(WeatherWatch.onKey) private var weatherOn = false

    var body: some View {
        let weather = weather ?? WeatherWatch.resolve(chosen: chosenWeather, live: liveWeather, on: weatherOn)
        if still || reduceMotion {
            // Half a second in, so rain and snow are already falling in a still picture.
            SceneFrame(kind: kind, dark: dark, appeared: appeared, pull: pull, hourOverride: hourOverride, t: 0.5, weather: weather, rooms: rooms, puggleX: puggleX)
        } else {
            // Thirty times a second is plenty for things that drift and sway.
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                SceneFrame(kind: kind, dark: dark, appeared: appeared, pull: pull, hourOverride: hourOverride,
                           t: timeline.date.timeIntervalSince(SceneClock.start), weather: weather, rooms: rooms, puggleX: puggleX)
            }
        }
    }

    /// Where a warm lamp sits beside Puggle in this scene after dark, on her own box. Nil when there is none.
    static func lamp(for kind: SceneKind, night: Bool) -> UnitPoint? {
        kind == .backyard && night ? UnitPoint(x: -0.15, y: 0.3) : nil
    }

    /// Where she stands when Today opens, as a share of the width from the middle: a little to one side,
    /// away from the scene's friend, so the picture is not symmetrical. She can be walked anywhere from there.
    static func stand(for kind: SceneKind) -> CGFloat {
        switch kind {
        case .hills: 0.06
        case .beach: 0.08
        case .backyard: -0.07
        case .bush: 0.08
        }
    }

    /// The room Today is showing just now, or nil while she is outdoors.
    static func room(dark: Bool) -> Room? { Room.at(hour: Room.hourNow, dark: dark) }

    /// Whether the scene on Today is showing night just now, so Puggle can take its light.
    static func isNight(dark: Bool, hour: Int? = nil) -> Bool {
        SceneFrame(kind: .hills, dark: dark, hourOverride: hour).starry
    }
}

/// One moment of the scene. `t` is seconds since it started.
struct SceneFrame: View {
    let kind: SceneKind
    let dark: Bool
    /// False until Today first appears; the clouds drift in and the friend pops up.
    var appeared = true
    /// How far Today has been pulled down. The sky grows upwards by this much,
    /// and the further it goes, the more turns up in it.
    var pull: CGFloat = 0
    /// For the scene gallery: show this hour rather than the clock's.
    var hourOverride: Int?
    var t: Double = 0
    var weather: Weather = .clear
    var rooms = false
    var puggleX: CGFloat = 0

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

    fileprivate var starry: Bool { phase == .night }

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
        if rooms, let room = Room.at(hour: hour, dark: dark) {
            RoomFrame(room: room, dark: dark, appeared: appeared, pull: pull, t: t, hour: hour, weather: weather, puggleX: puggleX)
        } else {
            outdoors
        }
    }

    private var outdoors: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = max(geometry.size.height - pull, 1)
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [sky[0]] + sky, startPoint: .top, endPoint: .bottom)
                // The weather turns the sky grey, pale or warm, down to the horizon.
                if let wash = weather.skyWash(night: starry) {
                    wash
                }
                // One sky from the top of the pull to the horizon, so nothing is left bare.
                if starry && !weather.overcast {
                    StarField(sceneHeight: h, moon: CGPoint(x: w * kind.lightSpot, y: pull + h * 0.36), t: t)
                        .opacity(appeared ? 1 : 0)
                }
                // The scene itself keeps its height and sits at the bottom.
                ZStack {
                    if !weather.overcast { light(w, h) }
                    clouds(w, h)
                    scenery(w, h)
                    // The same light falls on the far scenery, or it would glow under a dark sky.
                    if weather.overcast, let wash = weather.skyWash(night: starry) { wash.opacity(0.55) }
                    WeatherBehind(weather: weather, night: starry, t: t)
                    ground
                    WeatherGround(weather: weather, night: starry, t: t)
                    details(w, h)
                    // Puggle's shadow, so she stands on the hill.
                    Ellipse().fill(starry ? Color(hex: 0x15163A).opacity(0.32) : Palette.fixedInk.opacity(0.1))
                        .frame(width: 72, height: 9).position(x: w / 2 + puggleX, y: h - 27)
                    friend(w, h)
                    WeatherNear(weather: weather, t: t)
                }
                .frame(width: w, height: h)
                surprises(w)
                    .frame(width: w, height: geometry.size.height, alignment: .top)
                WeatherFront(weather: weather, night: starry, t: t, sceneHeight: h)
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
        let plain: Color = switch phase {
        case .night: Color(hex: 0x9A96E0).opacity(0.2)
        case .dawn: Color(hex: 0xFFF6EC).opacity(0.85)
        case .dusk: Color(hex: 0xFBE4E6).opacity(0.8)
        default: Color.white.opacity(0.8)
        }
        let tint = weather.cloudTint(night: starry) ?? plain
        // Different each day and each time the app is opened, and drifting on the day's wind.
        var random = SeededRandom(SceneClock.seed &+ UInt64(kind.rawValue) &* 7_919)
        let count = 2 + Int(random.unit() * 2.99) + weather.extraClouds
        let wind = (random.unit() < 0.5 ? -1.0 : 1.0) * random.range(2.5, 5.5) * weather.windiness
        var drifting: [(x: CGFloat, y: CGFloat, width: CGFloat)] = []
        for _ in 0..<count {
            let width = CGFloat(random.range(46, 96))
            let span = Double(w + width * 2)
            // Bigger clouds are nearer, so they pass a little faster.
            let travelled = random.range(0, 1) * span + wind * Double(width / 70) * t
            let x = CGFloat((travelled.truncatingRemainder(dividingBy: span) + span).truncatingRemainder(dividingBy: span)) - width
            drifting.append((x, CGFloat(random.range(0.22, 0.47)) * h, width))
        }
        return ZStack {
            ForEach(Array(drifting.enumerated()), id: \.offset) { _, cloud in
                Cloud(width: cloud.width, tint: tint).position(x: cloud.x, y: cloud.y)
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
            // Ripples slide along and rise and fall a little.
            Waves(phase: CGFloat(t * 5)).stroke(Color.white.opacity(starry ? 0.18 : 0.55), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: w * 0.36, height: 6).clipped().position(x: w * 0.36, y: h * 0.635 + CGFloat(sin(t * 0.9)) * 1.2)
            Waves(phase: CGFloat(-t * 4)).stroke(Color.white.opacity(starry ? 0.18 : 0.55), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: w * 0.22, height: 6).clipped().position(x: w * 0.74, y: h * 0.665 + CGFloat(sin(t * 0.9 + 1.4)) * 1.2)
            // The boat rocks and wanders a little way along the horizon.
            Sailboat(dark: starry).frame(width: 26, height: 28)
                .rotationEffect(.degrees(3 * sin(t * 0.8)), anchor: .bottom)
                .position(x: w * 0.8 + CGFloat(sin(t / 23)) * 20, y: h * 0.555 + CGFloat(sin(t * 1.1)) * 1.2)
            if starry && !weather.overcast {
                // The moon on the water.
                MoonPath().fill(Color(hex: 0xF3E0B8).opacity(0.4)).frame(width: 34, height: h * 0.1)
                    .scaleEffect(x: 1 + 0.14 * sin(t * 1.7))
                    .position(x: w * kind.lightSpot, y: h * 0.635)
            }
            // Foam where the sea meets the sand.
            // The wash runs up the sand and slips back, a thinner line after it.
            HillEdge(rise: 0.6, left: 0.8, right: 0.78)
                .stroke(Color.white.opacity(starry ? 0.16 : 0.45), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .offset(y: -7 + CGFloat(sin(t * 0.8 - 1.3)) * 2.5)
            HillEdge(rise: 0.6, left: 0.8, right: 0.78)
                .stroke(Color.white.opacity(starry ? 0.3 : 0.85), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .offset(y: -1 + CGFloat(sin(t * 0.8)) * 1.6)
        case .backyard:
            Hedge().fill(tone(0xA9CB93, 0x1F2450)).frame(width: w, height: h * 0.22).position(x: w / 2, y: h * 0.56)
            Fence().fill(tone(0xF6EDD9, 0x4B4F8A)).frame(width: w, height: h * 0.2).position(x: w / 2, y: h * 0.62)
            Fence().stroke(tone(0xD8C8A8, 0x363A72), lineWidth: 1).frame(width: w, height: h * 0.2).position(x: w / 2, y: h * 0.62)
            Hill(rise: 0.6, left: 0.73, right: 0.71).fill(tone(0xB9D49E, 0x232858))
            WashingLine(dark: starry, t: t, gust: weather.sway).frame(width: w * 0.38, height: h * 0.36).position(x: w * 0.23, y: h * 0.52)
            if starry {
                // A lantern on the post: the one warm light in the yard.
                Lantern().frame(width: 120, height: 120).opacity(0.93 + 0.07 * sin(t * 6.3) * sin(t * 2.1)).position(x: w * 0.405, y: h * 0.4)
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
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.1 * 9)), anchor: .bottom).position(x: w * 0.1, y: h * 0.8)
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 12, height: 9)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.72 * 9)), anchor: .bottom).position(x: w * 0.72, y: h * 0.74)
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.92 * 9)), anchor: .bottom).position(x: w * 0.92, y: h * 0.83)
        case .beach:
            Starfish().fill(tone(0xF2A48E, 0x8C5A86)).frame(width: 15, height: 15).rotationEffect(.degrees(12)).position(x: w * 0.8, y: h * 0.9)
        case .backyard:
            if starry {
                // The lantern's light lying on the ground, reaching Puggle.
                Ellipse().fill(RadialGradient(colors: [Color(hex: 0xFFD98A).opacity(0.3), Color(hex: 0xFFD98A).opacity(0)],
                                              center: .center, startRadius: 4, endRadius: 80))
                    .frame(width: 170, height: 34).position(x: w * 0.44, y: h * 0.84)
            }
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.09 * 9)), anchor: .bottom).position(x: w * 0.09, y: h * 0.8)
            GrassTuft().stroke(grass, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 12, height: 9)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.9 * 9)), anchor: .bottom).position(x: w * 0.9, y: h * 0.8)
        case .bush:
            let dry = tone(0xB0A474, 0x5A5C8C)
            GrassTuft().stroke(dry, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 14, height: 10)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.7 * 9)), anchor: .bottom).position(x: w * 0.7, y: h * 0.75)
            GrassTuft().stroke(dry, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 12, height: 9)
                .rotationEffect(.degrees(6 * weather.sway * sin(t * 1.3 * min(weather.sway, 2) + 0.9 * 9)), anchor: .bottom).position(x: w * 0.9, y: h * 0.81)
        }
    }

    // MARK: Pulling down

    /// Things that turn up in the extra sky as Today is pulled down, one more at each stretch.
    /// Each scene has its own three by day and its own three after dark, so the pull is worth trying everywhere.
    private func surprises(_ w: CGFloat) -> some View {
        let first = pull > 60, second = pull > 130, third = pull > 200
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
            switch kind {
            case .hills:
                // A hot-air balloon, a kite, and her friends flying over. After dark: an owl out hunting.
                turnsUp(first, x: w * 0.72, y: pull - 46 + CGFloat(sin(t * 0.9)) * 3) {
                    Balloon(dark: starry).frame(width: 40, height: 60).rotationEffect(.degrees(sway))
                }
                turnsUp(second, x: starry ? w * 0.5 : w * 0.28, y: pull - 118) {
                    if starry { Aurora(t: t).frame(width: w * 0.9, height: 86) }
                    else { Kite().frame(width: 44, height: 76).rotationEffect(.degrees(-sway * 2)) }
                }
                turnsUp(third, x: w * 0.55, y: pull - 190, from: CGSize(width: -w * 0.7, height: 0)) {
                    if starry {
                        Owl(flap: sin(t * 5)).frame(width: 62, height: 40).offset(y: CGFloat(sin(t * 1.4)) * 4)
                    } else {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                Bird(dark: false, flying: true, flap: 0.55 * sin(t * 13 + Double(i) * 1.7)).frame(width: 34, height: 26).scaleEffect(0.72)
                                    .offset(y: (i == 1 ? -9 : 0) + CGFloat(sin(t * 2.2 + Double(i))) * 2.5)
                            }
                        }
                    }
                }
            case .beach:
                // A beach ball, a little plane trailing a streamer, then a rainbow. After dark: the Southern Cross and fireworks.
                turnsUp(first, x: w * 0.3, y: pull - 50 - (starry ? 0 : abs(CGFloat(sin(t * 2.6))) * 12)) {
                    if starry { SouthernCross(t: t).frame(width: 84, height: 96) }
                    else { BeachBall().frame(width: 34, height: 34).rotationEffect(.degrees(t * 70)) }
                }
                turnsUp(second, x: starry ? w * 0.5 : w * 0.6, y: pull - 122 + (starry ? 0 : CGFloat(sin(t * 1.1)) * 3), from: starry ? .zero : CGSize(width: w * 0.8, height: 0)) {
                    if starry { Fireworks(t: t).frame(width: w * 0.86, height: 110) }
                    else { StreamerPlane(t: t).frame(width: 118, height: 34) }
                }
                turnsUp(third, x: w * 0.5, y: pull - 204) {
                    // The finale: one that opens into her face.
                    if starry { PuggleFirework(t: t).frame(width: 150, height: 130) }
                    else { Rainbow().frame(width: w * 0.72, height: w * 0.36) }
                }
            case .backyard:
                // Bubbles, a paper plane and dandelion seeds. After dark: fireflies, a shooting star and a lantern let go.
                turnsUp(first, x: w * 0.3, y: pull - 56) {
                    if starry { Fireflies(t: t).frame(width: 90, height: 64) }
                    else { Bubbles(t: t).frame(width: 96, height: 84) }
                }
                turnsUp(second, x: w * 0.68 + CGFloat(sin(t * 0.8)) * (starry ? 4 : 14), y: pull - 124 + CGFloat(sin(t * 1.6)) * (starry ? 3 : 6), from: starry ? .zero : CGSize(width: -w * 0.8, height: 30)) {
                    if starry { SkyLantern(t: t).frame(width: 44, height: 64) }
                    else { PaperPlane().frame(width: 46, height: 30).rotationEffect(.degrees(-8 + 10 * sin(t * 1.6))) }
                }
                turnsUp(third, x: w * 0.5, y: pull - 196) {
                    if starry {
                        // More lanterns, further off.
                        HStack(spacing: 34) {
                            ForEach(0..<3, id: \.self) { i in
                                SkyLantern(t: t + Double(i) * 1.7).frame(width: 44, height: 64)
                                    .scaleEffect(i == 1 ? 0.5 : 0.68)
                                    .offset(y: (i == 1 ? -14 : 6) + CGFloat(sin(t * 0.7 + Double(i))) * 4)
                            }
                        }
                    } else { DandelionSeeds(t: t).frame(width: w * 0.7, height: 70) }
                }
            case .bush:
                // Gum leaves on the wind, cockatoos, and a sugar glider. After dark: flying foxes, and the glider again.
                turnsUp(first, x: w * 0.32, y: pull - 54) {
                    if starry { FlyingFoxes(t: t).frame(width: 120, height: 60) }
                    else { GumLeaves(t: t).frame(width: 96, height: 76) }
                }
                turnsUp(second, x: w * 0.62, y: pull - 122, from: starry ? .zero : CGSize(width: -w * 0.7, height: 0)) {
                    if starry { SouthernCross(t: t).frame(width: 84, height: 96) } else {
                        HStack(spacing: 10) {
                            ForEach(0..<2, id: \.self) { i in
                                Bird(dark: false, flying: true, flap: 0.5 * sin(t * 9 + Double(i) * 2), colours: (0xFBF7EC, 0xE4DCC6, 0x5A5F66), crest: 0xF4D03F)
                                    .frame(width: 40, height: 34).offset(y: (i == 1 ? -10 : 0) + CGFloat(sin(t * 2 + Double(i))) * 3)
                            }
                        }
                    }
                }
                turnsUp(third, x: w * 0.5 + CGFloat(sin(t * 0.5)) * 16, y: pull - 196 + CGFloat(sin(t * 0.9)) * 5, from: CGSize(width: -w * 0.7, height: -40)) {
                    SugarGlider(dark: starry).frame(width: 74, height: 44).rotationEffect(.degrees(10 + 3 * sin(t * 0.9)))
                }
            }
        }
    }

    /// Something that pops into the pulled-down sky, or comes in from one side.
    private func turnsUp<V: View>(_ shown: Bool, x: CGFloat, y: CGFloat, from: CGSize = .zero, @ViewBuilder _ content: () -> V) -> some View {
        let pops = from == .zero
        return content()
            .scaleEffect(shown || !pops ? 1 : 0.3)
            .offset(shown ? .zero : from)
            .opacity(shown ? 1 : 0)
            .animation(.spring(duration: pops ? 0.45 : 0.8, bounce: pops ? 0.5 : 0.2), value: shown)
            .position(x: x, y: y)
    }

    // MARK: Friends

    /// What a friend is doing changes with the time of day, the season and the weather,
    /// so the same scene is not the same picture all year.
    private var season: SplashLook.Season { SplashLook.now.season }
    private var chilly: Bool { season == .winter || weather == .cold || weather == .snow }

    /// The bird on the hill: sings at dawn, pecks and hops by day, preens at dusk, sleeps at night.
    private func birdMoves() -> (tilt: Double, hop: Double, sing: Double, asleep: Bool, note: Double?) {
        switch phase {
        case .night:
            return (5 + 1.2 * sin(t * 1.1), 0, 0, true, nil)
        case .dawn where !weather.wet:
            let since = t.truncatingRemainder(dividingBy: 4.4)
            guard since < 1.9 else { return (0, 0, 0, false, nil) }
            return (-15 + 2.5 * sin(t * 17), 0, 0.5 + 0.5 * sin(t * 17), false, since / 1.9)
        case .dusk where !weather.wet:
            let since = t.truncatingRemainder(dividingBy: 6.2)
            let lean = since < 1.7 ? sin(since / 1.7 * .pi) : 0
            // Leans back to her wing and nibbles at it.
            return (-26 * lean + (lean > 0.7 ? 3 * sin(t * 21) : 0), 0, 0, false, nil)
        default:
            if weather.wet {
                // Hunched in the rain, with a shake now and then.
                let since = t.truncatingRemainder(dividingBy: 7)
                return (since < 0.5 ? 7 * sin(since / 0.5 * 6 * .pi) : 0, 0, 0, false, nil)
            }
            let since = t.truncatingRemainder(dividingBy: 5.5)
            let peck = since < 0.9 ? max(0, sin(since / 0.9 * 4 * .pi)) : 0
            // In spring she is busier.
            let hopping = (t + 2).truncatingRemainder(dividingBy: season == .spring ? 6.5 : 13)
            return (26 * peck, hopping < 0.45 ? sin(hopping / 0.45 * .pi) : 0, 0, false, nil)
        }
    }

    /// The crab: scuttles and snaps, and every so often digs herself into the sand until only
    /// her eyes show, then climbs out. After dark, and when it is wet or cold, she stays dug in.
    private func crabMoves() -> (along: Double, stride: Double, pinch: Double, buried: Double, digging: Bool) {
        if starry || weather.wet || chilly { return (0, 0, 0.4, 1, false) }
        let cycle = 34.0, awake = 23.0
        let rounds = (t / cycle).rounded(.down), p = t - rounds * cycle
        // Her walk stops while she is under, and carries on from where she was.
        let walked = (rounds * awake + min(p, awake)) * (phase == .dawn ? 0.26 : 0.42)
        let swing = sin(walked)
        let along = tanh(3.2 * swing)
        var buried = 0.0
        if p > awake {
            let down = min((p - awake) / 1.3, 1), up = max((p - (cycle - 1.1)) / 1.1, 0)
            // She wriggles down, and comes up quicker than she went.
            buried = up > 0 ? 1 - up * up : down
        }
        let stopped = abs(swing) > 0.9 && buried == 0
        // At dusk she waves her claws for longer.
        let snap = phase == .dusk ? 0.5 + 0.5 * sin(t * 5) : (stopped ? 0.5 + 0.5 * sin(t * 9) : 0.4)
        return (along, buried > 0 ? 0 : 1 - along * along, snap, buried, buried > 0 && buried < 1)
    }

    /// The snail: slow by day, out and about after dark and in the rain, shut in her shell when it is hot or cold.
    private func snailMoves() -> (drift: Double, stretch: Double, sway: Double, tucked: Double) {
        if weather == .hot || chilly || (season == .summer && phase == .day && (11..<15).contains(hour)) {
            // A peek out every so often.
            let since = t.truncatingRemainder(dividingBy: 14)
            let peek = since < 2.4 ? sin(since / 2.4 * .pi) : 0
            return (0, 0, 1.2 * sin(t * 1.1), 1 - 0.75 * peek)
        }
        if weather.wet { return (sin(t * 0.22) * 16, 0.07 * sin(t * 1.5), 3.4 * sin(t * 2.1), 0) }
        if starry { return (sin(t * 0.16) * 14, 0.05 * sin(t * 1.1), 2.6 * sin(t * 1.4), 0) }
        return (sin(t * 0.09) * 5, 0.035 * sin(t * 0.7), 2.2 * sin(t * 1.1), 0)
    }

    /// The kookaburra: he laughs at dawn and dusk, as kookaburras do, looks about by day and sleeps at night.
    private func kookaburraMoves() -> (tilt: Double, laugh: Double, shake: Double, asleep: Bool) {
        if starry { return (7 + 1.2 * sin(t * 1.0), 0, 0, true) }
        let every: Double = (phase == .dawn || phase == .dusk) ? 6.5 : 19
        let since = t.truncatingRemainder(dividingBy: every)
        let length = 2.3
        guard since < length, !weather.wet else { return (2.5 * sin(t * 0.6), 0, 0, false) }
        // Head back, beak chattering, the whole of him shaking; it builds and dies away.
        let swell = sin(since / length * .pi)
        return (-15 * swell + 3 * sin(t * 26) * swell, swell * (0.55 + 0.45 * sin(t * 24)), sin(t * 31) * 0.9 * swell, false)
    }

    @ViewBuilder private func friend(_ w: CGFloat, _ h: CGFloat) -> some View {
        let pop = appeared ? 1.0 : 0.4
        let shadow = starry ? Color(hex: 0x15163A).opacity(0.3) : Palette.fixedInk.opacity(0.1)
        switch kind {
        case .hills:
            let moves = birdMoves()
            Ellipse().fill(shadow).frame(width: 30, height: 6).position(x: w * 0.26, y: h * 0.868)
            Bird(dark: starry, asleep: moves.asleep, fluff: moves.asleep || chilly || weather.wet ? 1 : 0, sing: moves.sing)
                .frame(width: 46, height: 38)
                .rotationEffect(.degrees(moves.tilt), anchor: UnitPoint(x: 0.5, y: 0.9))
                .position(x: w * 0.26, y: h * 0.8 - CGFloat(moves.hop) * 7)
                .scaleEffect(pop).offset(y: appeared ? 0 : -20).opacity(appeared ? 1 : 0)
            if let note = moves.note {
                // Her song, drifting up.
                ForEach(0..<2, id: \.self) { i in
                    let along = (note + Double(i) * 0.45).truncatingRemainder(dividingBy: 1)
                    Image(systemName: i == 0 ? "music.note" : "music.quarternote.3")
                        .font(.system(size: i == 0 ? 11 : 9, weight: .bold))
                        .foregroundStyle(Palette.fixedInk.opacity(0.55 * (1 - along)))
                        .position(x: w * 0.26 + 26 + CGFloat(i) * 9 + CGFloat(sin(along * 5)) * 3, y: h * 0.74 - CGFloat(along) * 22)
                }
            }
        case .beach:
            let moves = crabMoves()
            let x = w * 0.25 + CGFloat(moves.along) * 20
            Ellipse().fill(shadow).frame(width: 46, height: 7).position(x: x, y: h * 0.905)
                .opacity(1 - moves.buried)
            // She goes down behind the edge of her own frame, which is the sand.
            Crab(dark: starry, step: t * 16, stride: moves.stride, pinch: moves.pinch, sink: moves.buried,
                 look: moves.buried == 1 ? sin(t * 0.8) : 0)
                .frame(width: 76, height: 44)
                .offset(x: moves.digging ? CGFloat(sin(t * 38)) * 1.6 : 0, y: CGFloat(moves.buried) * 25)
                .frame(width: 76, height: 44).clipped()
                .position(x: x, y: h * 0.85)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
            if moves.buried > 0 {
                // The sand she has pushed up, and a few grains flying while she digs.
                SandMound()
                    .frame(width: 66, height: 20)
                    .scaleEffect(x: 0.5 + 0.5 * min(1, CGFloat(moves.buried) * 1.5), y: min(1, CGFloat(moves.buried) * 1.5), anchor: .bottom)
                    .position(x: x, y: h * 0.85 + 19)
                if moves.digging {
                    ForEach(0..<5, id: \.self) { i in
                        let fling = (t * 2.6 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
                        let side: CGFloat = i.isMultiple(of: 2) ? -1 : 1
                        Circle().fill(Palette.ink.opacity(0.28)).frame(width: 3, height: 3)
                            .position(x: x + side * (10 + CGFloat(fling) * 16 + CGFloat(i)),
                                      y: h * 0.85 + 19 - CGFloat(sin(fling * .pi)) * (9 + CGFloat(i) * 1.5))
                            .opacity(1 - fling)
                    }
                }
            }
        case .backyard:
            let moves = snailMoves()
            Ellipse().fill(shadow).frame(width: 44, height: 6).position(x: w * 0.77 + CGFloat(moves.drift), y: h * 0.902)
            Snail(dark: starry, sway: moves.sway, tucked: moves.tucked).frame(width: 54, height: 38)
                .scaleEffect(x: 1 + moves.stretch, anchor: .leading)
                .position(x: w * 0.77 + CGFloat(moves.drift), y: h * 0.85)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
            let warmMonths = season == .spring || season == .summer
            if starry {
                // Fireflies in the warm months. They stay in when it is wet.
                if warmMonths {
                    Fireflies(t: t).frame(width: 70, height: 50).position(x: w * 0.62, y: h * 0.47)
                        .opacity(appeared && !weather.wet ? 1 : 0)
                }
            } else if !weather.wet && weather != .windy {
                if warmMonths {
                    // Wings beating, wandering in a loose loop.
                    Butterfly(dark: false, open: 0.38 + 0.62 * abs(sin(t * 7))).frame(width: 36, height: 30)
                        .rotationEffect(.degrees(8 * sin(t * 0.9)))
                        .position(x: w * 0.66 + CGFloat(sin(t * 0.43)) * 22, y: h * 0.43 + CGFloat(sin(t * 0.71 + 1)) * 10 + CGFloat(sin(t * 7)) * 1.5)
                        .offset(x: appeared ? 0 : 40, y: appeared ? 0 : -24).opacity(appeared ? 1 : 0)
                } else if season == .autumn {
                    // The butterfly has gone; leaves come down instead.
                    FallingLeaves(t: t, colours: [Color(hex: 0xE0A062), Color(hex: 0xC9703F), Color(hex: 0xE8C25A)])
                        .frame(width: w * 0.5, height: h * 0.5).position(x: w * 0.62, y: h * 0.5)
                        .opacity(appeared ? 1 : 0)
                }
            }
        case .bush:
            let moves = kookaburraMoves()
            Kookaburra(dark: starry, laugh: moves.laugh, asleep: moves.asleep, fluff: moves.asleep || chilly ? 1 : 0)
                .frame(width: 66, height: 54)
                .rotationEffect(.degrees(moves.tilt), anchor: UnitPoint(x: 0.45, y: 0.9))
                .position(x: w * 0.25 + CGFloat(moves.shake), y: h * 0.415)
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
    var t = 0.0

    var body: some View {
        Canvas { context, size in
            let horizon = size.height - sceneHeight * 0.4
            let glow = Color(hex: 0xF3E0B8)
            for i in 0..<150 {
                var random = SeededRandom(UInt64(i) &* 7919 &+ 3)
                let x = random.range(0.02, 0.98) * size.width
                let y = horizon - random.range(0, 1) * 700
                let dot = random.range(1.3, 3)
                var strength = random.range(0.4, 0.95)
                // A few twinkle, each in its own time.
                if i % 6 == 2 { strength *= 0.55 + 0.45 * sin(t * 1.5 + Double(i)) }
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
    /// Slides the ripples along.
    var phase: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 22
        var x = rect.minX - step + (phase.truncatingRemainder(dividingBy: step) + step).truncatingRemainder(dividingBy: step)
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
    var t = 0.0
    /// 1 on a fine day; more when the wind is up, and the washing flies out sideways.
    var gust = 1.0
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
            // Each thing swings from its peg in the breeze, not quite together.
            func swing(_ peg: CGPoint, _ phase: Double) -> CGAffineTransform {
                let angle = (0.13 * sin(t * 1.3 * min(gust, 2) + phase) + 0.07 * sin(t * 0.41 + phase * 2)) * gust + 0.24 * (gust - 1)
                return CGAffineTransform(translationX: peg.x, y: peg.y).rotated(by: angle).translatedBy(x: -peg.x, y: -peg.y)
            }
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
            context.fill(suit.applying(swing(p, 0)), with: .color(Color(hex: 0x8FB4E3).opacity(dim)))
            // Two socks.
            p = hang(0.52)
            for dx in [-5.0, 5.0] {
                var sock = Path(roundedRect: CGRect(x: p.x + dx - 2.5, y: p.y, width: 5, height: 11), cornerRadius: 2)
                sock.addRoundedRect(in: CGRect(x: p.x + dx - 2.5, y: p.y + 7, width: 9, height: 5), cornerSize: CGSize(width: 2.5, height: 2.5))
                context.fill(sock.applying(swing(CGPoint(x: p.x + dx, y: p.y), 1.3 + dx)), with: .color(Color(hex: 0xF4C95D).opacity(dim)))
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
            context.fill(bib.applying(swing(p, 2.6)), with: .color(Color(hex: 0xEFA3BC).opacity(dim)))
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
    /// How far the wing is through a beat, about -0.5 to 0.5.
    var flap = 0.0
    /// Eyes shut.
    var asleep = false
    /// Feathers puffed out against the cold or the wet, 0 to 1.
    var fluff = 0.0
    /// How far her beak is open, 0 to 1.
    var sing = 0.0
    /// Body, wing and beak, for other birds drawn the same way. A crest is drawn if given.
    var colours: (body: UInt32, wing: UInt32, beak: UInt32) = (0xE79BB8, 0xC9718F, 0xF2B544)
    var crest: UInt32?
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 - (flying ? 0 : 2)
            let body = Color(hex: colours.body).moonlit(dark)
            let wing = Color(hex: colours.wing).moonlit(dark)
            let beak = Color(hex: colours.beak).moonlit(dark)
            let puff = CGFloat(fluff)
            if !flying {
                var legs = Path()
                legs.move(to: CGPoint(x: cx - 3, y: cy + 8)); legs.addLine(to: CGPoint(x: cx - 3, y: cy + 15))
                legs.move(to: CGPoint(x: cx + 4, y: cy + 8)); legs.addLine(to: CGPoint(x: cx + 4, y: cy + 15))
                context.stroke(legs, with: .color(style == .tinted ? wing.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            var parts: [(Path, Color)] = [
                (polygon([CGPoint(x: cx - 10, y: cy - 1), CGPoint(x: cx - 21, y: cy - 7), CGPoint(x: cx - 19, y: cy + 4)]), wing),
            ]
            if let crest {
                parts.append((polygon([CGPoint(x: cx + 1, y: cy - 9), CGPoint(x: cx - 6, y: cy - 20), CGPoint(x: cx + 6, y: cy - 12)]), Color(hex: crest).moonlit(dark)))
            }
            let open = CGFloat(sing)
            if open > 0.02 {
                parts.append((polygon([CGPoint(x: cx + 11, y: cy - 5), CGPoint(x: cx + 20, y: cy - 1.5 - 3.5 * open), CGPoint(x: cx + 11, y: cy - 1.7)]), beak))
                parts.append((polygon([CGPoint(x: cx + 11, y: cy - 1.7), CGPoint(x: cx + 19, y: cy - 1.5 + 3 * open), CGPoint(x: cx + 11, y: cy + 1.5)]), beak))
            } else {
                parts.append((polygon([CGPoint(x: cx + 11, y: cy - 5), CGPoint(x: cx + 20, y: cy - 1.5), CGPoint(x: cx + 11, y: cy + 1.5)]), beak))
            }
            parts.append((Path(ellipseIn: CGRect(x: cx - 14 - puff * 2, y: cy - 11 - puff * 1.5, width: 28 + puff * 4, height: 22 + puff * 3)), body))
            outlined(&context, parts, style: style)
            let lift: CGFloat = flying ? -7 : 0
            let wingShape = Path(ellipseIn: CGRect(x: cx - 10, y: cy - 3 + lift, width: 14, height: 9))
                .applying(CGAffineTransform(translationX: cx - 3, y: cy + 1.5 + lift).rotated(by: flying ? -0.9 + flap : -0.35).translatedBy(x: -(cx - 3), y: -(cy + 1.5 + lift)))
            if flying {
                outlined(&context, [(wingShape, wing)], line: 3, style: style)
            } else {
                context.fill(wingShape, with: .color(wing))
            }
            if asleep {
                var lid = Path()
                lid.move(to: CGPoint(x: cx + 4, y: cy - 4.4))
                lid.addQuadCurve(to: CGPoint(x: cx + 8.4, y: cy - 4.4), control: CGPoint(x: cx + 6.2, y: cy - 2.2))
                context.stroke(lid, with: .color(Palette.fixedInk), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            } else {
                dot(&context, cx + 6, cy - 4, 1.9, Palette.fixedInk)
            }
            dot(&context, cx + 8.5, cy + 1.5, 2.4, Color(hex: 0xF27A8A).opacity(dark ? 0.35 : 0.6))
        }
    }
}

struct Crab: View {
    let dark: Bool
    /// Where her legs are in their stepping, and how much they are stepping (0 to 1).
    var step = 0.0
    var stride = 0.0
    /// How far her claws are open, 0 to 1.
    var pinch = 0.4
    /// How far she has dug in, 0 to 1: her claws fold down first, so only her eyes are left showing.
    var sink = 0.0
    /// Where her eyes are looking, -1 to 1.
    var look = 0.0
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 + 4
            let fold = CGFloat(sink) * 16
            let shell = Color(hex: 0xE8735E).moonlit(dark)
            let line = style == .tinted ? shell.outlineShade : Palette.fixedInk
            // Legs first, behind everything.
            var legs = Path()
            for side in [-1.0, 1.0] {
                for (i, reach) in [(0, 9.0), (1, 12.0), (2, 9.0)] {
                    let start = CGPoint(x: cx + side * 13, y: cy + 3 + CGFloat(i) * 2.5)
                    legs.move(to: start)
                    legs.addQuadCurve(to: CGPoint(x: start.x + side * reach + CGFloat(sin(step + Double(i) * 2.1) * 2.2 * stride), y: cy + 9 + CGFloat(i) * 1.5 - CGFloat(max(0, sin(step + Double(i) * 2.1 + side)) * 2.5 * stride)),
                                      control: CGPoint(x: start.x + side * reach * 0.7, y: start.y - 2))
                }
            }
            context.stroke(legs, with: .color(line), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            // A claw: a round with a bite out of the top, which opens and shuts.
            func claw(_ side: CGFloat) -> Path {
                let centre = CGPoint(x: cx + side * 22, y: cy - 10.5 + fold)
                let half = (7 + pinch * 30) * .pi / 180
                var bite = Path()
                bite.move(to: CGPoint(x: centre.x, y: centre.y + 1))
                bite.addLine(to: CGPoint(x: centre.x + CGFloat(sin(-half)) * 14, y: centre.y - CGFloat(cos(half)) * 14))
                bite.addLine(to: CGPoint(x: centre.x + CGFloat(sin(half)) * 14, y: centre.y - CGFloat(cos(half)) * 14))
                bite.closeSubpath()
                return Path(ellipseIn: CGRect(x: centre.x - 7, y: centre.y - 6.5, width: 14, height: 13)).subtracting(bite)
            }
            // Arms up to the claws.
            var arms = Path()
            for side in [-1.0, 1.0] {
                arms.move(to: CGPoint(x: cx + side * 14, y: cy - 1))
                arms.addLine(to: CGPoint(x: cx + side * 21, y: cy - 8 + fold))
            }
            context.stroke(arms, with: .color(line), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
            context.stroke(arms, with: .color(shell), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            outlined(&context, [
                (claw(-1), shell),
                (claw(1), shell),
                (Path(roundedRect: CGRect(x: cx - 7.5, y: cy - 15, width: 3, height: 9), cornerRadius: 1.5), shell),
                (Path(roundedRect: CGRect(x: cx + 4.5, y: cy - 15, width: 3, height: 9), cornerRadius: 1.5), shell),
                (Path(ellipseIn: CGRect(x: cx - 17, y: cy - 8, width: 34, height: 20)), shell),
                (Path(ellipseIn: CGRect(x: cx - 10, y: cy - 20, width: 8, height: 8)), Color(hex: 0xFFFDF6).moonlit(dark)),
                (Path(ellipseIn: CGRect(x: cx + 2, y: cy - 20, width: 8, height: 8)), Color(hex: 0xFFFDF6).moonlit(dark)),
            ], style: style)
            dot(&context, cx - 5.6 + CGFloat(look) * 1.6, cy - 15.6, 1.9, Palette.fixedInk)
            dot(&context, cx + 6.4 + CGFloat(look) * 1.6, cy - 15.6, 1.9, Palette.fixedInk)
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
    /// How far her feelers lean, in points.
    var sway = 0.0
    /// How far she has drawn back into her shell, 0 to 1.
    var tucked = 0.0
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 + 2
            let skin = Color(hex: 0xE3D1B0).moonlit(dark)
            let shell = Color(hex: 0xE0A062).moonlit(dark)
            let line = style == .tinted ? skin.outlineShade : Palette.fixedInk
            let back = CGFloat(tucked) * 17, out = CGFloat(1 - tucked)
            // Feelers, with a knob on each. They shorten as she draws in.
            if out > 0.12 {
                var feelers = Path()
                let left = CGPoint(x: cx + 14 + CGFloat(sway) * out - back, y: cy - 2 - 10 * out)
                let right = CGPoint(x: cx + 23 - CGFloat(sway) * 0.6 * out - back, y: cy - 2 - 9 * out)
                feelers.move(to: CGPoint(x: cx + 16 - back, y: cy - 2)); feelers.addLine(to: left)
                feelers.move(to: CGPoint(x: cx + 20 - back, y: cy - 2)); feelers.addLine(to: right)
                context.stroke(feelers, with: .color(line), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                dot(&context, left.x, left.y - 0.5, 2.4, line)
                dot(&context, right.x, right.y - 0.5, 2.4, line)
            }
            outlined(&context, [
                (Path(roundedRect: CGRect(x: cx - 23, y: cy + 5, width: 44 - back * 0.9, height: 9), cornerRadius: 4.5), skin),
                (Path(ellipseIn: CGRect(x: cx + 10 - back, y: cy - 5, width: 15, height: 16)), skin),
                (Path(ellipseIn: CGRect(x: cx - 18, y: cy - 16, width: 27, height: 27)), shell),
            ], style: style)
            // The curl of the shell.
            var curl = Path()
            curl.addArc(center: CGPoint(x: cx - 4.5, y: cy - 2.5), radius: 7.5, startAngle: .degrees(-30), endAngle: .degrees(250), clockwise: false)
            curl.addArc(center: CGPoint(x: cx - 4.5, y: cy - 1.5), radius: 3, startAngle: .degrees(250), endAngle: .degrees(80), clockwise: false)
            context.stroke(curl, with: .color(Color(hex: 0xA86A35).moonlit(dark)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            if out > 0.45 {
                dot(&context, cx + 19.5 - back, cy + 1.5, 1.7, Palette.fixedInk)
                dot(&context, cx + 17 - back, cy + 5.5, 2, Color(hex: 0xF2A48E).opacity(dark ? 0.35 : 0.7))
            }
        }
    }
}

struct Butterfly: View {
    let dark: Bool
    /// How wide her wings are spread: 1 open, towards 0 closed.
    var open = 1.0
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2
            let wing = Color(hex: 0xB9A0EA).moonlit(dark)
            let lower = Color(hex: 0xD3C2F4).moonlit(dark)
            func tilted(_ rect: CGRect, _ angle: CGFloat) -> Path {
                Path(ellipseIn: rect).applying(CGAffineTransform(translationX: rect.midX, y: rect.midY).rotated(by: angle).translatedBy(x: -rect.midX, y: -rect.midY))
                    .applying(CGAffineTransform(translationX: cx, y: 0).scaledBy(x: CGFloat(open), y: 1).translatedBy(x: -cx, y: 0))
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
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.2, 0.6, 1), (0.52, 0.22, 0.8), (0.82, 0.7, 0.9), (0.66, 0.5, 0.6)]
            for spot in spots {
                // Each wanders a little and glows brighter and dimmer.
                let seed = Double(spot.0 * 10)
                let centre = CGPoint(x: size.width * spot.0 + CGFloat(sin(t * 0.5 + seed)) * 7, y: size.height * spot.1 + CGFloat(sin(t * 0.37 + seed * 2)) * 5)
                let glow = 9 * spot.2 * CGFloat(0.7 + 0.3 * sin(t * 1.9 + seed * 3))
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
    /// How far his beak is open, 0 to 1.
    var laugh = 0.0
    var asleep = false
    /// Feathers puffed out, 0 to 1.
    var fluff = 0.0
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2 - 9, cy = size.height / 2 + 2
            let cream = Color(hex: 0xF4EAD6).moonlit(dark)
            let brown = Color(hex: 0x9C7451).moonlit(dark)
            let beak = Color(hex: 0x4A545C).moonlit(dark)
            let open = CGFloat(laugh), puff = CGFloat(fluff)
            // Feet round the branch.
            var feet = Path()
            feet.move(to: CGPoint(x: cx - 3, y: cy + 17)); feet.addLine(to: CGPoint(x: cx - 3, y: cy + 22))
            feet.move(to: CGPoint(x: cx + 5, y: cy + 17)); feet.addLine(to: CGPoint(x: cx + 5, y: cy + 22))
            context.stroke(feet, with: .color(style == .tinted ? brown.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            // The beak is two halves hinged at his face, so it can open to laugh.
            let hinge = CGPoint(x: cx + 8, y: cy - 13.5)
            outlined(&context, [
                (polygon([CGPoint(x: cx - 12, y: cy + 8), CGPoint(x: cx - 19, y: cy + 24), CGPoint(x: cx - 11, y: cy + 23), CGPoint(x: cx - 5, y: cy + 13)]), brown),
                (polygon([CGPoint(x: cx + 8, y: cy - 19), CGPoint(x: cx + 27, y: hinge.y - 5 * open), hinge]), beak),
                (polygon([hinge, CGPoint(x: cx + 26, y: hinge.y + 8 * open), CGPoint(x: cx + 8, y: cy - 9)]), beak),
                (Path(ellipseIn: CGRect(x: cx - 13 - puff * 2.5, y: cy - 10, width: 27 + puff * 5, height: 29)), cream),
                (Path(ellipseIn: CGRect(x: cx - 12 - puff, y: cy - 26, width: 24 + puff * 2, height: 23)), cream),
            ], style: style)
            // Wing, the stripe through the eye and the flash of blue.
            context.fill(Path(ellipseIn: CGRect(x: cx - 13 - puff * 2, y: cy - 6, width: 14, height: 23)), with: .color(brown))
            context.fill(Path(roundedRect: CGRect(x: cx - 9, y: cy - 17.5, width: 18, height: 5), cornerRadius: 2.5), with: .color(brown))
            context.fill(Path(roundedRect: CGRect(x: cx - 10, y: cy + 1, width: 8, height: 4), cornerRadius: 2), with: .color(Color(hex: 0x6C93C4).moonlit(dark)))
            context.fill(Path(roundedRect: CGRect(x: cx - 6, y: cy - 27, width: 10, height: 4), cornerRadius: 2), with: .color(brown.opacity(0.7)))
            if asleep {
                var lid = Path()
                lid.move(to: CGPoint(x: cx + 2.4, y: cy - 15.4))
                lid.addQuadCurve(to: CGPoint(x: cx + 6.8, y: cy - 15.4), control: CGPoint(x: cx + 4.6, y: cy - 13.2))
                context.stroke(lid, with: .color(Palette.fixedPaper), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            } else {
                dot(&context, cx + 4.5, cy - 15, 1.9, Palette.fixedInk)
            }
            if open < 0.08 {
                // The line where the beak closes.
                var mouth = Path()
                mouth.move(to: CGPoint(x: cx + 10, y: cy - 13.5)); mouth.addLine(to: CGPoint(x: cx + 22, y: cy - 13.5))
                context.stroke(mouth, with: .color(Palette.fixedInk.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            } else {
                // The laugh, as comics draw it: short marks flying off his beak.
                var marks = Path()
                for (angle, reach) in [(-0.55, 6.0), (-0.1, 7.5), (0.4, 6.0)] {
                    let from = CGPoint(x: cx + 31 + CGFloat(cos(angle)) * 2, y: hinge.y + CGFloat(sin(angle)) * 9)
                    marks.move(to: from)
                    marks.addLine(to: CGPoint(x: from.x + CGFloat(cos(angle) * reach) * open, y: from.y + CGFloat(sin(angle) * reach) * open))
                }
                context.stroke(marks, with: .color(Palette.fixedInk.opacity(0.6)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
        }
    }
}

/// Autumn in the yard: a few leaves coming down, turning as they fall. Flat, like the rest of the world.
struct FallingLeaves: View {
    var t = 0.0
    var colours: [Color]
    var body: some View {
        Canvas { context, size in
            for i in 0..<4 {
                var random = SeededRandom(UInt64(i) &* 977 &+ 3)
                let speed = random.range(0.07, 0.11), start = random.unit(), x0 = random.range(0.1, 0.9)
                let fall = (t * speed + start).truncatingRemainder(dividingBy: 1)
                let centre = CGPoint(x: size.width * x0 + CGFloat(sin(fall * 9 + Double(i))) * 14, y: size.height * fall)
                let leaf = Path(ellipseIn: CGRect(x: -5, y: -2.6, width: 10, height: 5.2))
                    .applying(CGAffineTransform(translationX: centre.x, y: centre.y).rotated(by: CGFloat(fall * 11 + Double(i))))
                context.fill(leaf, with: .color(colours[i % colours.count].opacity(fall > 0.85 ? (1 - fall) / 0.15 : 1)))
            }
        }
        .accessibilityHidden(true)
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

/// What the crab pushes up when she digs in: a heap of sand with a lit side, a shaded side and loose grains.
struct SandMound: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, base = size.height - 3
            // Where it meets the beach.
            context.fill(Path(ellipseIn: CGRect(x: w * 0.06, y: base - 3, width: w * 0.88, height: 6)), with: .color(Color(hex: 0x8A6A3C).opacity(0.22)))
            // The heap: higher in the middle, slumping at the sides, with a smaller heap against it.
            var heap = Path()
            heap.move(to: CGPoint(x: w * 0.1, y: base))
            heap.addCurve(to: CGPoint(x: w * 0.44, y: base - 11), control1: CGPoint(x: w * 0.2, y: base - 3), control2: CGPoint(x: w * 0.3, y: base - 11))
            heap.addCurve(to: CGPoint(x: w * 0.7, y: base - 6), control1: CGPoint(x: w * 0.55, y: base - 11), control2: CGPoint(x: w * 0.62, y: base - 7))
            heap.addCurve(to: CGPoint(x: w * 0.92, y: base), control1: CGPoint(x: w * 0.8, y: base - 8), control2: CGPoint(x: w * 0.86, y: base - 3))
            heap.closeSubpath()
            context.fill(heap, with: .color(Palette.sand))
            // Sunlit on one side, in its own shade on the other: sand colours, never grey.
            context.fill(heap, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF3D6).opacity(0.55), Color(hex: 0xB08A52).opacity(0.5)]),
                                                     startPoint: CGPoint(x: w * 0.25, y: base - 14), endPoint: CGPoint(x: w * 0.8, y: base)))
            // Grains: on the heap and rolled off it.
            var random = SeededRandom(41)
            for index in 0..<16 {
                let x = w * CGFloat(random.range(0.04, 0.96)), up = CGFloat(random.range(0, 1))
                let onHeap = x > w * 0.16 && x < w * 0.84
                let y = base - (onHeap ? up * 9 * (1 - abs(x / w - 0.47) * 2) : 0) + (onHeap ? -1 : 1)
                let radius = CGFloat(random.range(0.6, 1.3))
                context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(index.isMultiple(of: 3) ? Color(hex: 0xFFF3D6).opacity(0.8) : Color(hex: 0x8A6A3C).opacity(0.55)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Soft ribbons of light low in the night sky, slowly moving.
struct Aurora: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            for (index, colour) in ([0x7FE0B0, 0x8FB4E3, 0xB9A0EA] as [UInt32]).enumerated() {
                var band = Path()
                let phase = t * 0.35 + Double(index) * 1.9, top = size.height * (0.12 + 0.16 * CGFloat(index))
                let steps = 30
                var upper: [CGPoint] = []
                for step in 0...steps {
                    let along = CGFloat(step) / CGFloat(steps)
                    upper.append(CGPoint(x: size.width * along, y: top + CGFloat(sin(Double(along) * 5 + phase)) * 9 + CGFloat(sin(Double(along) * 11 - phase * 1.3)) * 3))
                }
                band.addLines(upper)
                band.addLines(upper.reversed().map { CGPoint(x: $0.x, y: $0.y + 34) })
                band.closeSubpath()
                context.fill(band, with: .linearGradient(Gradient(colors: [Color(hex: colour).opacity(0.34), Color(hex: colour).opacity(0)]),
                                                         startPoint: CGPoint(x: 0, y: top - 10), endPoint: CGPoint(x: 0, y: top + 40)))
            }
        }
        .mask(LinearGradient(colors: [.clear, .black, .black, .clear], startPoint: .leading, endPoint: .trailing))
    }
}

/// A firework that opens into Puggle's face: her head, eyes, bill, cheeks and clip, in sparks.
struct PuggleFirework: View {
    var t = 0.0
    private static let sparks: [(x: CGFloat, y: CGFloat, colour: UInt32, size: CGFloat)] = {
        var list: [(CGFloat, CGFloat, UInt32, CGFloat)] = []
        func ring(_ count: Int, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, _ colour: UInt32, _ size: CGFloat) {
            for index in 0..<count {
                let angle = Double(index) / Double(count) * 2 * .pi
                list.append((cx + CGFloat(cos(angle)) * rx, cy + CGFloat(sin(angle)) * ry, colour, size))
            }
        }
        ring(30, cx: 0, cy: 0, rx: 34, ry: 29, 0xE2A66C, 2.1)          // her head
        ring(14, cx: 0, cy: 11, rx: 17, ry: 8, 0xA9C4DA, 1.9)          // her bill
        ring(6, cx: 26, cy: -24, rx: 6.5, ry: 6.5, 0xF58A70, 2)        // her clip
        list.append((26, -24, 0xF4D03F, 2.2))
        list.append((-11, -5, 0xFFF6DC, 3)); list.append((11, -5, 0xFFF6DC, 3))   // her eyes
        list.append((-22, 6, 0xF2A0A0, 2.4)); list.append((22, 6, 0xF2A0A0, 2.4)) // her cheeks
        return list
    }()

    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let life = (t / 5).truncatingRemainder(dividingBy: 1)
            // A rocket goes up, the face opens and hangs, then drifts down and fades.
            if life < 0.12 {
                let rise = life / 0.12
                dot(&context, centre.x, size.height - CGFloat(rise) * (size.height / 2), 2, Color(hex: 0xFFF6DC).opacity(0.9))
                return
            }
            let open = 1 - pow(1 - min((life - 0.12) / 0.16, 1), 3)
            let fade = life < 0.7 ? 1 : max(0, 1 - (life - 0.7) / 0.3)
            let droop = CGFloat(max(0, life - 0.55)) * 26
            for (index, spark) in Self.sparks.enumerated() {
                let twinkle = 0.75 + 0.25 * sin(t * 9 + Double(index) * 1.3)
                let at = CGPoint(x: centre.x + spark.x * 1.45 * CGFloat(open), y: centre.y + spark.y * 1.45 * CGFloat(open) + droop)
                context.fill(Path(ellipseIn: CGRect(x: at.x - spark.size * 2.4, y: at.y - spark.size * 2.4, width: spark.size * 4.8, height: spark.size * 4.8)),
                             with: .radialGradient(Gradient(colors: [Color(hex: spark.colour).opacity(0.35 * fade), Color(hex: spark.colour).opacity(0)]), center: at, startRadius: 0, endRadius: spark.size * 2.4))
                dot(&context, at.x, at.y, spark.size, Color(hex: spark.colour).opacity(fade * twinkle))
            }
        }
        .accessibilityHidden(true)
    }
}

struct BeachBall: View {
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2), radius = min(size.width, size.height) / 2 - 3
            let round = Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
            outlined(&context, [(round, Color(hex: 0xFFFDF6))], line: 3.4, style: style)
            // Three coloured panels meeting at the top.
            for (index, colour) in [Color(hex: 0xE5553B), Color(hex: 0xF4BE2C), Color(hex: 0x2A62B8)].enumerated() {
                var panel = Path()
                let start = Angle.degrees(Double(index) * 120 - 90), end = Angle.degrees(Double(index) * 120 - 30)
                panel.move(to: centre)
                panel.addArc(center: centre, radius: radius - 1, startAngle: start, endAngle: end, clockwise: false)
                panel.closeSubpath()
                context.fill(panel, with: .color(colour))
            }
            dot(&context, centre.x, centre.y, 2.6, Color(hex: 0xFFFDF6))
        }
    }
}

/// A small plane, heading left, with a streamer rippling out behind it.
struct StreamerPlane: View {
    var t = 0.0
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cy = size.height / 2
            // The streamer: a flat ribbon, wavier the further back it goes.
            var ribbon = Path()
            let from: CGFloat = 40, length = size.width - 44
            for step in 0...24 {
                let along = CGFloat(step) / 24
                let point = CGPoint(x: from + along * length, y: cy + 1 + CGFloat(sin(Double(along) * 9 - t * 6)) * 5 * along)
                if step == 0 { ribbon.move(to: point) } else { ribbon.addLine(to: point) }
            }
            context.stroke(ribbon, with: .color(Color(hex: 0xE5553B)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            context.stroke(ribbon, with: .color(Palette.fixedInk.opacity(0.5)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            let yellow = Color(hex: 0xF4BE2C)
            outlined(&context, [
                (polygon([CGPoint(x: 34, y: cy - 2), CGPoint(x: 42, y: cy - 12), CGPoint(x: 42, y: cy + 2)]), yellow),
                (Path(roundedRect: CGRect(x: 6, y: cy - 6, width: 36, height: 12), cornerRadius: 6), yellow),
                (Path(roundedRect: CGRect(x: 15, y: cy - 1, width: 14, height: 13), cornerRadius: 3), Color(hex: 0xFBE7A6)),
            ], line: 3.2, style: style)
            context.fill(Path(roundedRect: CGRect(x: 11, y: cy - 4, width: 7, height: 4.5), cornerRadius: 2), with: .color(Color(hex: 0xBFD9F5)))
            // The propeller, a blur.
            let spin = CGFloat(abs(sin(t * 30))) * 8 + 2
            context.fill(Path(ellipseIn: CGRect(x: 3, y: cy - spin, width: 3, height: spin * 2)), with: .color(Palette.fixedInk.opacity(0.55)))
        }
    }
}

/// Flat bands, no line, like the rest of the sky.
struct Rainbow: View {
    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height)
            let colours: [UInt32] = [0xE5553B, 0xF4BE2C, 0x3C9A5F, 0x2A62B8, 0xB9A0EA]
            let band = size.height * 0.085
            for (index, colour) in colours.enumerated() {
                var arc = Path()
                arc.addArc(center: centre, radius: size.height - band * (CGFloat(index) + 0.5) - 2, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                context.stroke(arc, with: .color(Color(hex: colour).opacity(0.8)), style: StrokeStyle(lineWidth: band + 0.5))
            }
        }
        .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
    }
}

/// The Southern Cross and its two pointers, joined with faint lines.
struct SouthernCross: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let stars: [(CGFloat, CGFloat, CGFloat)] = [(0.62, 0.1, 3.2), (0.6, 0.62, 3.6), (0.4, 0.32, 3), (0.82, 0.36, 2.8), (0.7, 0.44, 1.6), (0.14, 0.72, 3), (0.26, 0.92, 3.4)]
            let points = stars.map { CGPoint(x: size.width * $0.0, y: size.height * $0.1) }
            var lines = Path()
            lines.move(to: points[0]); lines.addLine(to: points[1])
            lines.move(to: points[2]); lines.addLine(to: points[3])
            lines.move(to: points[5]); lines.addLine(to: points[6])
            context.stroke(lines, with: .color(Color(hex: 0xF3E0B8).opacity(0.28)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            for (index, star) in stars.enumerated() {
                let twinkle = 0.75 + 0.25 * sin(t * 2.3 + Double(index) * 1.9)
                let glow = star.2 * 3
                context.fill(Path(ellipseIn: CGRect(x: points[index].x - glow, y: points[index].y - glow, width: glow * 2, height: glow * 2)),
                             with: .radialGradient(Gradient(colors: [Color(hex: 0xF3E0B8).opacity(0.35 * twinkle), Color(hex: 0xF3E0B8).opacity(0)]), center: points[index], startRadius: 0, endRadius: glow))
                dot(&context, points[index].x, points[index].y, star.2 * 0.62, Color(hex: 0xFFF6DC).opacity(twinkle))
            }
        }
    }
}

/// Fireworks far off over the water: bursts that open, hang and fade, one after another.
struct Fireworks: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let bursts: [(CGFloat, CGFloat, UInt32, Double)] = [(0.24, 0.5, 0xF4BE2C, 0), (0.56, 0.3, 0xF58A70, 1.1), (0.8, 0.56, 0xBFD9F5, 2.0)]
            for burst in bursts {
                let life = ((t + burst.3) / 3.2).truncatingRemainder(dividingBy: 1)
                let open = 1 - pow(1 - min(life / 0.45, 1), 3), fade = life < 0.45 ? 1 : max(0, 1 - (life - 0.45) / 0.55)
                let centre = CGPoint(x: size.width * burst.0, y: size.height * burst.1)
                for ray in 0..<12 {
                    let angle = Double(ray) / 12 * 2 * .pi
                    for (reach, radius) in [(1.0, 2.0), (0.62, 1.4)] {
                        let distance = 30 * open * reach
                        dot(&context, centre.x + CGFloat(cos(angle)) * distance, centre.y + CGFloat(sin(angle)) * distance + CGFloat(life * life) * 10,
                            radius, Color(hex: burst.2).opacity(fade))
                    }
                }
            }
        }
    }
}

struct Bubbles: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            for i in 0..<7 {
                var random = SeededRandom(UInt64(i) &* 613 &+ 5)
                let radius = CGFloat(random.range(5, 12)), speed = random.range(0.1, 0.17), start = random.unit(), x0 = random.range(0.12, 0.88)
                let rise = (t * speed + start).truncatingRemainder(dividingBy: 1)
                let centre = CGPoint(x: size.width * x0 + CGFloat(sin(rise * 7 + Double(i))) * 6, y: size.height * (1 - rise))
                let round = Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
                let fade = rise > 0.88 ? (1 - rise) / 0.12 : min(1, rise / 0.08)
                context.fill(round, with: .color(Color.white.opacity(0.22 * fade)))
                context.stroke(round, with: .color(Color.white.opacity(0.85 * fade)), lineWidth: 1.4)
                dot(&context, centre.x - radius * 0.35, centre.y - radius * 0.4, radius * 0.2, Color.white.opacity(0.9 * fade))
            }
        }
    }
}

struct PaperPlane: View {
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let w = size.width, h = size.height
            let nose = CGPoint(x: w - 3, y: h * 0.42), tail = CGPoint(x: 4, y: h * 0.2), fold = CGPoint(x: w * 0.36, y: h * 0.56)
            outlined(&context, [
                (polygon([nose, tail, fold]), Color(hex: 0xFFFDF6)),
                (polygon([nose, fold, CGPoint(x: w * 0.3, y: h - 4)]), Color(hex: 0xE9E1CD)),
                (polygon([nose, fold, CGPoint(x: 8, y: h * 0.7)]), Color(hex: 0xFFFDF6)),
            ], line: 2.8, style: style)
        }
    }
}

struct DandelionSeeds: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            for i in 0..<7 {
                var random = SeededRandom(UInt64(i) &* 389 &+ 17)
                let speed = random.range(0.05, 0.09), start = random.unit(), y0 = random.range(0.15, 0.85)
                let drift = (t * speed + start).truncatingRemainder(dividingBy: 1)
                let base = CGPoint(x: size.width * drift, y: size.height * y0 + CGFloat(sin(drift * 8 + Double(i))) * 7)
                let fade = min(1, drift / 0.1, (1 - drift) / 0.1)
                var seed = Path()
                seed.move(to: base); seed.addLine(to: CGPoint(x: base.x - 1.5, y: base.y - 8))
                for ray in 0..<5 {
                    let angle = -Double.pi / 2 + (Double(ray) - 2) * 0.42
                    seed.move(to: CGPoint(x: base.x - 1.5, y: base.y - 8))
                    seed.addLine(to: CGPoint(x: base.x - 1.5 + CGFloat(cos(angle)) * 6, y: base.y - 8 + CGFloat(sin(angle)) * 6))
                }
                context.stroke(seed, with: .color(Color.white.opacity(0.9 * fade)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                dot(&context, base.x, base.y + 1, 1.3, Color(hex: 0xB89A78).opacity(fade))
            }
        }
    }
}

/// A paper lantern let go into the night, glowing.
struct SkyLantern: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2, glow = 0.85 + 0.15 * sin(t * 5.1) * sin(t * 1.7)
            context.fill(Path(ellipseIn: CGRect(x: cx - 30, y: 0, width: 60, height: 60)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFFD98A).opacity(0.42 * glow), Color(hex: 0xFFD98A).opacity(0)]), center: CGPoint(x: cx, y: 30), startRadius: 4, endRadius: 30))
            var paper = Path()
            paper.move(to: CGPoint(x: cx - 9, y: 44)); paper.addLine(to: CGPoint(x: cx - 13, y: 22))
            paper.addQuadCurve(to: CGPoint(x: cx + 13, y: 22), control: CGPoint(x: cx, y: 6))
            paper.addLine(to: CGPoint(x: cx + 9, y: 44)); paper.closeSubpath()
            context.fill(paper, with: .linearGradient(Gradient(colors: [Color(hex: 0xF79A72), Color(hex: 0xFFD98A)]), startPoint: CGPoint(x: cx, y: 10), endPoint: CGPoint(x: cx, y: 44)))
            context.fill(Path(roundedRect: CGRect(x: cx - 9, y: 43, width: 18, height: 3), cornerRadius: 1.5), with: .color(Color(hex: 0x8A5A3C)))
            dot(&context, cx, 40, 3.2, Color(hex: 0xFFF3B8).opacity(glow))
        }
    }
}

/// Gum leaves caught by the wind, going round. Flat, in the bush's own greens.
struct GumLeaves: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<7 {
                let turn = t * (0.9 + Double(i) * 0.07) + Double(i) * 0.9
                let reach = 14 + CGFloat(i) * 4.2
                let at = CGPoint(x: centre.x + CGFloat(cos(turn)) * reach * 1.25, y: centre.y + CGFloat(sin(turn)) * reach * 0.8)
                var leaf = Path()
                leaf.move(to: CGPoint(x: -8, y: 0))
                leaf.addQuadCurve(to: CGPoint(x: 8, y: 0), control: CGPoint(x: 0, y: -5))
                leaf.addQuadCurve(to: CGPoint(x: -8, y: 0), control: CGPoint(x: 0, y: 2))
                let placed = leaf.applying(CGAffineTransform(translationX: at.x, y: at.y).rotated(by: CGFloat(turn * 1.7)))
                context.fill(placed, with: .color(Color(hex: [0x8FAE8B, 0xA9BF9C, 0xC7B98A][i % 3])))
            }
        }
    }
}

/// Flying foxes heading out at dusk: flat shapes against the night, wings beating.
struct FlyingFoxes: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            for (index, spot) in [(0.2, 0.62, 1.0), (0.52, 0.3, 0.8), (0.82, 0.6, 0.9)].enumerated() {
                let scale = CGFloat(spot.2), beat = CGFloat(sin(t * 7 + Double(index) * 1.3))
                let cx = size.width * spot.0, cy = size.height * spot.1 + CGFloat(sin(t * 1.3 + Double(index))) * 3
                var bat = Path()
                let tip = 20 * scale, lift = beat * 7 * scale
                bat.move(to: CGPoint(x: cx, y: cy - 3 * scale))
                bat.addQuadCurve(to: CGPoint(x: cx - tip, y: cy - 4 * scale - lift), control: CGPoint(x: cx - tip * 0.5, y: cy - 9 * scale - lift))
                bat.addQuadCurve(to: CGPoint(x: cx - tip * 0.62, y: cy + 3 * scale - lift * 0.4), control: CGPoint(x: cx - tip * 0.8, y: cy + 1 * scale - lift * 0.6))
                bat.addQuadCurve(to: CGPoint(x: cx - tip * 0.25, y: cy + 4 * scale), control: CGPoint(x: cx - tip * 0.45, y: cy + 1 * scale))
                bat.addQuadCurve(to: CGPoint(x: cx + tip * 0.25, y: cy + 4 * scale), control: CGPoint(x: cx, y: cy + 8 * scale))
                bat.addQuadCurve(to: CGPoint(x: cx + tip * 0.62, y: cy + 3 * scale - lift * 0.4), control: CGPoint(x: cx + tip * 0.45, y: cy + 1 * scale))
                bat.addQuadCurve(to: CGPoint(x: cx + tip, y: cy - 4 * scale - lift), control: CGPoint(x: cx + tip * 0.8, y: cy + 1 * scale - lift * 0.6))
                bat.addQuadCurve(to: CGPoint(x: cx, y: cy - 3 * scale), control: CGPoint(x: cx + tip * 0.5, y: cy - 9 * scale - lift))
                // A little lighter than the sky, as if the moon caught them.
                context.fill(bat, with: .color(Color(hex: 0x6A6CA8).opacity(0.85)))
                // Ears.
                context.fill(polygon([CGPoint(x: cx - 3 * scale, y: cy - 3 * scale), CGPoint(x: cx - 2 * scale, y: cy - 8 * scale), CGPoint(x: cx, y: cy - 4 * scale),
                                      CGPoint(x: cx + 2 * scale, y: cy - 8 * scale), CGPoint(x: cx + 3 * scale, y: cy - 3 * scale)]), with: .color(Color(hex: 0x6A6CA8).opacity(0.85)))
            }
        }
    }
}

/// A sugar glider, legs spread, gliding from tree to tree.
struct SugarGlider: View {
    let dark: Bool
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2
            let grey = Color(hex: 0xA9A8A2).moonlit(dark), cream = Color(hex: 0xF4EAD6).moonlit(dark)
            // Tail first, trailing behind.
            var tail = Path()
            tail.move(to: CGPoint(x: cx - 16, y: cy + 1))
            tail.addQuadCurve(to: CGPoint(x: cx - 34, y: cy - 6), control: CGPoint(x: cx - 26, y: cy + 6))
            context.stroke(tail, with: .color(style == .tinted ? grey.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            context.stroke(tail, with: .color(grey), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            // The stretched skin between her paws, then her body and head.
            var skin = Path()
            skin.move(to: CGPoint(x: cx - 18, y: cy - 13)); skin.addQuadCurve(to: CGPoint(x: cx + 14, y: cy - 14), control: CGPoint(x: cx, y: cy - 8))
            skin.addQuadCurve(to: CGPoint(x: cx + 14, y: cy + 14), control: CGPoint(x: cx + 8, y: cy))
            skin.addQuadCurve(to: CGPoint(x: cx - 18, y: cy + 13), control: CGPoint(x: cx, y: cy + 8))
            skin.addQuadCurve(to: CGPoint(x: cx - 18, y: cy - 13), control: CGPoint(x: cx - 12, y: cy))
            outlined(&context, [
                (skin, cream),
                (Path(ellipseIn: CGRect(x: cx + 12, y: cy - 20, width: 7, height: 9)), grey),
                (Path(ellipseIn: CGRect(x: cx + 12, y: cy + 11, width: 7, height: 9)), grey),
                (Path(roundedRect: CGRect(x: cx - 15, y: cy - 6.5, width: 34, height: 13), cornerRadius: 6.5), grey),
                (Path(ellipseIn: CGRect(x: cx + 12, y: cy - 9, width: 19, height: 18)), grey),
            ], line: 3.4, style: style)
            // The dark stripe down her back, big eyes and a pink nose.
            context.fill(Path(roundedRect: CGRect(x: cx - 12, y: cy - 1.5, width: 30, height: 3), cornerRadius: 1.5), with: .color(Color(hex: 0x5A5856).moonlit(dark)))
            dot(&context, cx + 24, cy - 4.5, 2.6, Palette.fixedInk)
            dot(&context, cx + 24, cy + 4.5, 2.6, Palette.fixedInk)
            dot(&context, cx + 24.8, cy - 5.3, 0.8, Color.white.opacity(0.9))
            dot(&context, cx + 24.8, cy + 3.7, 0.8, Color.white.opacity(0.9))
            dot(&context, cx + 31, cy, 1.7, Color(hex: 0xF2A48E))
        }
    }
}

/// An owl out at night, wings wide.
struct Owl: View {
    /// Where her wings are in a slow beat, -1 to 1.
    var flap = 0.0
    @Environment(\.lineStyle) private var lineStyle
    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            let cx = size.width / 2, cy = size.height / 2 + 3
            let brown = Color(hex: 0xB08A5E).moonlit(true), pale = Color(hex: 0xF4EAD6).moonlit(true)
            let lift = CGFloat(flap) * 5
            func wing(_ side: CGFloat) -> Path {
                var path = Path()
                path.move(to: CGPoint(x: cx + side * 8, y: cy - 4))
                path.addQuadCurve(to: CGPoint(x: cx + side * 28, y: cy - 8 - lift), control: CGPoint(x: cx + side * 18, y: cy - 14 - lift))
                path.addQuadCurve(to: CGPoint(x: cx + side * 9, y: cy + 7), control: CGPoint(x: cx + side * 22, y: cy + 4 - lift * 0.3))
                path.closeSubpath()
                return path
            }
            outlined(&context, [
                (wing(-1), brown), (wing(1), brown),
                (polygon([CGPoint(x: cx - 9, y: cy - 9), CGPoint(x: cx - 8, y: cy - 17), CGPoint(x: cx - 3, y: cy - 12)]), brown),
                (polygon([CGPoint(x: cx + 9, y: cy - 9), CGPoint(x: cx + 8, y: cy - 17), CGPoint(x: cx + 3, y: cy - 12)]), brown),
                (Path(ellipseIn: CGRect(x: cx - 11, y: cy - 13, width: 22, height: 25)), brown),
            ], line: 3.4, style: style)
            context.fill(Path(ellipseIn: CGRect(x: cx - 7, y: cy - 1, width: 14, height: 12)), with: .color(pale))
            for side in [-1.0, 1.0] {
                dot(&context, cx + side * 4.4, cy - 5.5, 4, pale)
                dot(&context, cx + side * 4.4, cy - 5.5, 1.9, Palette.fixedInk)
            }
            context.fill(polygon([CGPoint(x: cx - 1.8, y: cy - 2.5), CGPoint(x: cx + 1.8, y: cy - 2.5), CGPoint(x: cx, y: cy + 1)]), with: .color(Color(hex: 0xF2B544).moonlit(true)))
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
