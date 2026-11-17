import SwiftUI

// The seasons and the sky's own events in the scenes (Tom, 17 November 2026). Flat shapes with no outline,
// like the rest of the scenery; the cicada is scenery too, so she has none either.

/// What the real calendar brings to the night sky: a full moon, and the nights the meteor showers peak.
enum SkyEvents {
    /// How far through the moon's month a moment is: 0 is new, 0.5 full.
    static func moonAge(_ date: Date) -> Double {
        // A new moon at 18:14 UTC on 6 January 2000, and the average length of the moon's month.
        let known = Date(timeIntervalSince1970: 947_182_440)
        let month = 29.530_588_853 * 86_400
        let months = date.timeIntervalSince(known) / month
        return months - months.rounded(.down)
    }

    /// The moon is drawn full for about a day and a half each side of full. "-debugMoon full" or "crescent" to check.
    static func fullMoon(_ date: Date = .now) -> Bool {
        #if DEBUG
        if let forced = UserDefaults.standard.string(forKey: "debugMoon") { return forced == "full" }
        #endif
        return abs(moonAge(date) - 0.5) < 0.05
    }

    /// The peaks of the year's main meteor showers, as month and day. The Eta Aquariids in May are the best
    /// in the south of the world, the Geminids in December the best in the north.
    static let showerPeaks: [(month: Int, day: Int)] = [(1, 3), (4, 22), (5, 6), (7, 30), (8, 12), (10, 21), (11, 17), (12, 14)]

    /// Shooting stars on the night of a peak and the nights either side. "-debugMeteors 1" to check.
    static func meteors(_ date: Date = .now, calendar: Calendar = .current) -> Bool {
        #if DEBUG
        if let forced = UserDefaults.standard.string(forKey: "debugMeteors") { return forced == "1" }
        #endif
        let year = calendar.component(.year, from: date)
        // Late at night still counts as the evening before.
        let evening = date.addingTimeInterval(-6 * 3600)
        for peak in showerPeaks {
            for y in [year - 1, year, year + 1] {
                guard let day = calendar.date(from: DateComponents(year: y, month: peak.month, day: peak.day)) else { continue }
                let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: day), to: calendar.startOfDay(for: evening)).day ?? 99
                if abs(days) <= 1 { return true }
            }
        }
        return false
    }
}

/// A full moon: round, with two faint seas on it and a wider glow.
struct FullMoon: View {
    var body: some View {
        Canvas { context, size in
            let moon = Color(hex: 0xF3E0B8)
            let r = min(size.width, size.height) / 2
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            context.fill(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)), with: .color(moon))
            let sea = Color(hex: 0xDCC59A).opacity(0.7)
            context.fill(Path(ellipseIn: CGRect(x: centre.x - r * 0.5, y: centre.y - r * 0.45, width: r * 0.55, height: r * 0.42)), with: .color(sea))
            context.fill(Path(ellipseIn: CGRect(x: centre.x + r * 0.05, y: centre.y + r * 0.1, width: r * 0.38, height: r * 0.3)), with: .color(sea))
            context.fill(Path(ellipseIn: CGRect(x: centre.x - r * 0.15, y: centre.y + r * 0.35, width: r * 0.2, height: r * 0.16)), with: .color(sea))
        }
        .background(Circle().fill(Color(hex: 0xF3E0B8).opacity(0.16)).scaleEffect(1.9))
    }
}

/// Shooting stars on the night of a meteor shower: one every second or two, short, each in its own place.
struct Meteors: View {
    var t = 0.0
    /// The scene's height at the bottom: the meteors stay in the sky above its hills.
    let sceneHeight: CGFloat

    var body: some View {
        Canvas { context, size in
            let sky = max(size.height - sceneHeight * 0.5, 40)
            for lane in 0..<3 {
                let every = 2.3 + Double(lane) * 0.85
                let shifted = t + Double(lane) * 1.1
                let number = Int((shifted / every).rounded(.down))
                let life = (shifted - Double(number) * every) / 0.7
                guard life < 1 else { continue }
                var random = SeededRandom(UInt64(max(number, 0)) &* 131 &+ UInt64(lane) &* 7 &+ 1)
                let start = CGPoint(x: random.range(0.25, 1.0) * size.width, y: random.range(0.05, 0.75) * sky)
                let reach = CGFloat(random.range(50, 90))
                let along = CGFloat(life) * reach
                let head = CGPoint(x: start.x - along, y: start.y + along * 0.5)
                let tail = CGPoint(x: head.x + min(along, 30), y: head.y - min(along, 30) * 0.5)
                var streak = Path()
                streak.move(to: tail)
                streak.addLine(to: head)
                let fade = life < 0.7 ? 1 : (1 - life) / 0.3
                context.stroke(streak, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF6DC).opacity(0), Color(hex: 0xFFF6DC).opacity(0.9 * fade)]),
                                                             startPoint: tail, endPoint: head),
                               style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

/// A willy-willy: a little whirl of dust that spins across the far paddock now and then, on a hot or windy day.
struct WillyWilly: View {
    var t = 0.0
    static let every = 26.0
    static let crossing = 8.0

    var body: some View {
        Canvas { context, size in
            let since = t.truncatingRemainder(dividingBy: Self.every)
            guard since < Self.crossing else { return }
            let progress = since / Self.crossing
            // It builds, spins across and dies away.
            let strength = sin(progress * .pi)
            let x = -30 + CGFloat(progress) * (size.width + 60)
            let base = size.height * 0.66
            let tall = 70 * CGFloat(0.6 + 0.4 * strength)
            let dust = Color(hex: 0xCDB27E)
            for ring in 0..<10 {
                let up = CGFloat(ring) / 9
                let width = 6 + up * 30
                let sway = CGFloat(sin(t * 5 + Double(up) * 3.5)) * 5 * up
                let y = base - up * tall
                let rect = CGRect(x: x + sway - width / 2, y: y - 2.5, width: width, height: 5)
                context.stroke(Path(ellipseIn: rect), with: .color(dust.opacity(0.8 * strength * Double(1 - up * 0.4))), lineWidth: 2.6)
            }
            // Grit and a leaf or two, going round.
            for speck in 0..<6 {
                let turn = t * 7 + Double(speck) * 1.05
                let up = CGFloat(speck) / 5
                let y = base - up * tall * 0.9
                let sx = x + CGFloat(sin(turn)) * (4 + up * 15)
                context.fill(Path(ellipseIn: CGRect(x: sx - 1.5, y: y - 1.5, width: 3, height: 3)), with: .color(Color(hex: 0xB0965F).opacity(0.7 * strength)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Jacaranda and blossom petals drifting down in spring, a few at a time.
struct Petals: View {
    var t = 0.0
    let colours: [Color]
    var gust = 1.0

    var body: some View {
        Canvas { context, size in
            for i in 0..<20 {
                var random = SeededRandom(UInt64(i) &* 5_087 &+ 21)
                let fall = random.range(14, 26)
                let span = Double(size.height + 20)
                let y = CGFloat((random.range(0, 1) * span + fall * t).truncatingRemainder(dividingBy: span)) - 10
                let drift = CGFloat(sin(t * random.range(0.6, 1.2) + Double(i))) * 14 + CGFloat(t * 6 * gust).truncatingRemainder(dividingBy: size.width)
                let x = (CGFloat(random.range(0, 1)) * size.width + drift).truncatingRemainder(dividingBy: size.width)
                let turn = t * random.range(1, 2.4) + Double(i)
                let petal = Path(ellipseIn: CGRect(x: -4, y: -2.4, width: 8, height: 4.8))
                    .applying(CGAffineTransform(translationX: x, y: y).rotated(by: turn))
                context.fill(petal, with: .color(colours[i % colours.count].opacity(0.85)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// A clump of long summer grass, five blades.
struct LongGrass: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let blades: [(CGFloat, CGFloat, CGFloat)] = [(0.5, 0.0, 0.62), (0.35, 0.18, 0.1), (0.62, 0.12, 0.9), (0.42, 0.34, 0.0), (0.58, 0.3, 1.0)]
        for blade in blades {
            let foot = CGPoint(x: rect.minX + rect.width * blade.0, y: rect.maxY)
            let tip = CGPoint(x: rect.minX + rect.width * blade.2, y: rect.minY + rect.height * blade.1)
            path.move(to: foot)
            path.addQuadCurve(to: tip, control: CGPoint(x: foot.x, y: rect.midY))
        }
        return path
    }
}

/// A cicada, side on, clinging to a stalk: a green-brown body and clear wings that shimmer as she sings.
struct Cicada: View {
    var shimmer = 0.5
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.2, width: w * 0.72, height: h * 0.7)), with: .color(Color(hex: 0x6F7A4A)))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: 0, width: w * 0.6, height: h * 0.32)), with: .color(Color(hex: 0x5B643A)))
            let wing = Color.white.opacity(0.45 + 0.3 * shimmer)
            context.fill(Path(ellipseIn: CGRect(x: -w * 0.1, y: h * 0.25, width: w * 0.55, height: h * 0.8)), with: .color(wing))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.25, width: w * 0.55, height: h * 0.8)), with: .color(wing))
        }
    }
}

/// A beach umbrella along the sand on a summer's day.
struct BeachUmbrella: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var pole = Path()
            pole.move(to: CGPoint(x: w * 0.52, y: h * 0.3))
            pole.addLine(to: CGPoint(x: w * 0.46, y: h))
            context.stroke(pole, with: .color(Color(hex: 0xC9B48E)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            // A flattened half circle in five stripes.
            let centre = CGPoint(x: w / 2, y: h * 0.4)
            var squashed = context
            squashed.translateBy(x: 0, y: centre.y)
            squashed.scaleBy(x: 1, y: 0.62)
            squashed.translateBy(x: 0, y: -centre.y)
            let colours: [UInt32] = [0xF58A70, 0xFFF6EC, 0xF58A70, 0xFFF6EC, 0xF58A70]
            for (index, colour) in colours.enumerated() {
                var slice = Path()
                slice.move(to: centre)
                slice.addArc(center: centre, radius: w / 2, startAngle: .degrees(180 + Double(index) * 36),
                             endAngle: .degrees(180 + Double(index + 1) * 36), clockwise: false)
                slice.closeSubpath()
                squashed.fill(slice, with: .color(Color(hex: colour)))
            }
        }
        .rotationEffect(.degrees(-6))
    }
}

/// Fallen leaves lying on the ground in autumn, away from where Puggle stands.
struct GroundLeaves: View {
    let dark: Bool
    var body: some View {
        Canvas { context, size in
            let colours: [UInt32] = dark ? [0x5A4A7A, 0x6A5470, 0x4E5478] : [0xE0A062, 0xC9703F, 0xE8C25A, 0xD98B5A]
            for i in 0..<11 {
                var random = SeededRandom(UInt64(i) &* 3_301 &+ 7)
                var across = random.range(0.03, 0.97)
                // Not under her feet, so she still stands on clear ground.
                if across > 0.36 && across < 0.64 { across = across < 0.5 ? across - 0.22 : across + 0.22 }
                let x = CGFloat(across) * size.width
                let y = size.height * CGFloat(random.range(0.8, 0.95))
                let leaf = Path(ellipseIn: CGRect(x: -4, y: -2, width: 8, height: 4))
                    .applying(CGAffineTransform(translationX: x, y: y).rotated(by: random.range(0, .pi)))
                context.fill(leaf, with: .color(Color(hex: colours[i % colours.count]).opacity(0.9)))
            }
        }
        .allowsHitTesting(false)
    }
}
