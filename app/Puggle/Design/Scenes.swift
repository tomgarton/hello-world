import SwiftUI

/// The scenes Puggle stands in at the top of Today, one a day in turn, each
/// with a friend. The sky follows the time of day; after dark it is navy with
/// stars. The ground at the front is always the page colour, so the scene
/// runs into Today. Friends are drawn in code until the real drawings arrive.
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
}

struct PuggleScene: View {
    let kind: SceneKind
    let dark: Bool
    /// False until Today first appears; the clouds drift in and the friend pops up.
    var appeared = true
    /// How far Today has been pulled down. The sky grows upwards by this much,
    /// and the further it goes, the more turns up in it.
    var pull: CGFloat = 0

    private var hour: Int { Calendar.current.component(.hour, from: .now) }
    private var starry: Bool { dark || hour >= 21 || hour < 5 }

    private var sky: [Color] {
        if dark { return [Color(hex: 0x101A2E), Color(hex: 0x1E2236), Palette.sand] }
        switch hour {
        case 5..<9: return [Color(hex: 0xF6CDB4), Color(hex: 0xF8E3CF), Palette.sand]
        case 17..<21: return [Color(hex: 0xC9B6D9), Color(hex: 0xF4CDB0), Palette.sand]
        case 21..<24, 0..<5: return [Color(hex: 0x2A3556), Color(hex: 0x4A4870), Palette.sand]
        default: return [Color(hex: 0xBFDDF0), Color(hex: 0xE3EEF1), Palette.sand]
        }
    }

    /// Scenery colours, dimmed after dark.
    private func tone(_ day: UInt32, _ night: UInt32) -> Color { Color(hex: starry ? night : day) }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = max(geometry.size.height - pull, 1)
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [sky[0]] + sky, startPoint: .top, endPoint: .bottom)
                // The scene itself keeps its height and sits at the bottom.
                ZStack {
                    if starry { stars(w, h) } else { clouds(w, h) }
                    scenery(w, h)
                    // The ground in the page colour.
                    Hill(rise: 0.6, left: 0.8, right: 0.78).fill(Palette.sand)
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

    private func stars(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                var random = SeededRandom(UInt64(i) &* 977 &+ 11)
                let size = random.range(1.5, 3.2)
                Circle().fill(Color(hex: 0xF3E0B8).opacity(random.range(0.35, 0.8)))
                    .frame(width: size, height: size)
                    .position(x: random.range(0.04, 0.96) * w, y: random.range(0.25, 0.6) * h)
            }
            Circle().fill(Color(hex: 0xF3E0B8).opacity(0.85)).frame(width: 26, height: 26)
                .overlay(Circle().fill(sky[0]).frame(width: 22, height: 22).offset(x: 8, y: -5))
                .position(x: w * 0.18, y: h * 0.36)
        }
        .opacity(appeared ? 1 : 0)
    }

    private func clouds(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Cloud(width: 92).position(x: w * 0.2, y: h * 0.38).offset(x: appeared ? 0 : -30)
            Cloud(width: 120).position(x: w * 0.8, y: h * 0.5).offset(x: appeared ? 0 : 36)
            Cloud(width: 60).position(x: w * 0.55, y: h * 0.3).offset(x: appeared ? 0 : -18)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Scenery behind the ground

    @ViewBuilder private func scenery(_ w: CGFloat, _ h: CGFloat) -> some View {
        switch kind {
        case .hills:
            Hill(rise: 0.42, left: 0.62, right: 0.8, peak: 0.25).fill(tone(0xC9DDB4, 0x24302A))
            Hill(rise: 0.48, left: 0.8, right: 0.6, peak: 0.8).fill(tone(0xB5D0A0, 0x1E2A24))
        case .beach:
            if !starry {
                Circle().fill(Color(hex: 0xFFD666)).frame(width: 44, height: 44).position(x: w * 0.14, y: h * 0.34)
            }
            // The sea, with a line of foam.
            Rectangle().fill(tone(0x8DC3E6, 0x1C2C48)).frame(height: h * 0.2).position(x: w / 2, y: h * 0.7)
            Waves().stroke(Color.white.opacity(starry ? 0.25 : 0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: w, height: 10).position(x: w / 2, y: h * 0.64)
        case .backyard:
            Fence().fill(tone(0xEFE3CC, 0x2E2822)).frame(width: w, height: h * 0.18).position(x: w / 2, y: h * 0.66)
            Hill(rise: 0.68, left: 0.76, right: 0.74).fill(tone(0xBFD6A5, 0x1E2A24))
        case .bush:
            GumTree(dark: starry).frame(width: 120, height: h * 0.78).position(x: w * 0.13, y: h * 0.5)
            Hill(rise: 0.52, left: 0.8, right: 0.62, peak: 0.85).fill(tone(0xD2C9A4, 0x2A2820))
        }
    }

    // MARK: Pulling down

    /// Things that turn up in the extra sky as Today is pulled down: a balloon,
    /// then a kite (a shooting star after dark), then a flock of birds.
    private func surprises(_ w: CGFloat) -> some View {
        let balloon = pull > 60, kite = pull > 130, flock = pull > 200
        let sway = Double(pull).truncatingRemainder(dividingBy: 40) / 40 * 8 - 4
        return ZStack(alignment: .topLeading) {
            // The further it is pulled, the more of the sky there is to see.
            if starry {
                // Stars fill the new sky, each fading in as the pull reaches it.
                ForEach(0..<46, id: \.self) { i in
                    var random = SeededRandom(UInt64(i) &* 7919 &+ 3)
                    let depth = CGFloat(random.range(0.04, 1)) * 420
                    let size = random.range(1.4, 3.4)
                    Circle().fill(Color(hex: 0xF3E0B8).opacity(random.range(0.45, 0.95)))
                        .frame(width: size, height: size)
                        .position(x: random.range(0.03, 0.97) * w, y: pull - depth)
                        .opacity(pull > depth + 10 ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: pull > depth + 10)
                }
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
                .frame(width: 34, height: 52)
                .rotationEffect(.degrees(sway))
                .scaleEffect(balloon ? 1 : 0.3)
                .opacity(balloon ? 1 : 0)
                .animation(.spring(duration: 0.45, bounce: 0.5), value: balloon)
                .position(x: w * 0.72, y: pull - 46)
            Group {
                if starry {
                    ShootingStar().frame(width: 70, height: 20)
                } else {
                    Kite().frame(width: 40, height: 70).rotationEffect(.degrees(-sway * 2))
                }
            }
            .scaleEffect(kite ? 1 : 0.3)
            .opacity(kite ? 1 : 0)
            .animation(.spring(duration: 0.45, bounce: 0.5), value: kite)
            .position(x: w * 0.28, y: pull - 118)
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Bird(dark: starry).frame(width: 22, height: 17).offset(y: i == 1 ? -8 : 0)
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
        switch kind {
        case .hills:
            Bird(dark: starry).frame(width: 34, height: 26).position(x: w * 0.3, y: h * 0.56)
                .scaleEffect(pop).offset(y: appeared ? 0 : -20).opacity(appeared ? 1 : 0)
        case .beach:
            Crab(dark: starry).frame(width: 48, height: 30).position(x: w * 0.27, y: h * 0.86)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
        case .backyard:
            Snail(dark: starry).frame(width: 42, height: 28).position(x: w * 0.76, y: h * 0.86)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
            Butterfly(dark: starry).frame(width: 30, height: 24).position(x: w * 0.66, y: h * 0.48)
                .offset(x: appeared ? 0 : 40, y: appeared ? 0 : -24).opacity(appeared ? 1 : 0)
        case .bush:
            Kookaburra(dark: starry).frame(width: 40, height: 44).position(x: w * 0.25, y: h * 0.42)
                .scaleEffect(pop).opacity(appeared ? 1 : 0)
        }
    }
}

// MARK: Shapes

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

struct Waves: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 26
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
            path.addRoundedRect(in: CGRect(x: x, y: rect.minY + 6, width: board, height: rect.height - 6), cornerSize: CGSize(width: 3, height: 3))
            path.move(to: CGPoint(x: x, y: rect.minY + 6))
            path.addLine(to: CGPoint(x: x + board / 2, y: rect.minY))
            path.addLine(to: CGPoint(x: x + board, y: rect.minY + 6))
            x += gap
        }
        path.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.35, width: rect.width, height: 5))
        return path
    }
}

struct Cloud: View {
    let width: CGFloat
    var body: some View {
        let fill = Color.white.opacity(0.75)
        ZStack(alignment: .bottom) {
            Capsule().fill(fill).frame(width: width, height: width * 0.32)
            Circle().fill(fill).frame(width: width * 0.45).offset(x: -width * 0.12, y: -width * 0.1)
            Circle().fill(fill).frame(width: width * 0.36).offset(x: width * 0.16, y: -width * 0.06)
        }
        .frame(width: width, height: width * 0.6, alignment: .bottom)
    }
}

struct GumTree: View {
    let dark: Bool
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let trunk = Color(hex: dark ? 0x4A4238 : 0xE8DDCB)
            let leaves = Color(hex: dark ? 0x26352E : 0x9DBB98)
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.38, y: h))
                    p.addQuadCurve(to: CGPoint(x: w * 0.45, y: h * 0.25), control: CGPoint(x: w * 0.3, y: h * 0.6))
                    p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.25))
                    p.addQuadCurve(to: CGPoint(x: w * 0.56, y: h), control: CGPoint(x: w * 0.48, y: h * 0.6))
                }
                .fill(trunk)
                // The branch the friend sits on.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.52))
                    p.addQuadCurve(to: CGPoint(x: w * 1.05, y: h * 0.5), control: CGPoint(x: w * 0.8, y: h * 0.42))
                }
                .stroke(trunk, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                ForEach(0..<5, id: \.self) { i in
                    let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.3, 0.2, 0.42), (0.62, 0.14, 0.46), (0.48, 0.05, 0.36), (0.15, 0.32, 0.3), (0.8, 0.3, 0.3)]
                    let s = spots[i]
                    Ellipse().fill(leaves).frame(width: w * s.2, height: w * s.2 * 0.62).position(x: w * s.0, y: h * s.1 + 10)
                }
            }
        }
    }
}

// MARK: Friends (placeholders until the drawings)

struct Bird: View {
    let dark: Bool
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: dark ? 0xB57A92 : 0xE79BB8)).frame(width: 26, height: 20)
            Ellipse().fill(Color(hex: dark ? 0x8E5C74 : 0xC9718F)).frame(width: 14, height: 9).rotationEffect(.degrees(-25)).offset(x: -3, y: -3)
            Circle().fill(Palette.fixedInk).frame(width: 3, height: 3).offset(x: 6, y: -3)
            Triangle().fill(Color(hex: 0xF2B544)).frame(width: 7, height: 5).rotationEffect(.degrees(90)).offset(x: 15, y: -1)
        }
    }
}

struct Crab: View {
    let dark: Bool
    var body: some View {
        let shell = Color(hex: dark ? 0xB8584A : 0xE8735E)
        ZStack {
            Capsule().fill(shell).frame(width: 34, height: 18).offset(y: 4)
            Circle().fill(shell).frame(width: 12).offset(x: -20, y: -2)
            Circle().fill(shell).frame(width: 12).offset(x: 20, y: -2)
            ForEach([-6.0, 6.0], id: \.self) { x in
                Capsule().fill(shell).frame(width: 2.5, height: 9).offset(x: x, y: -7)
                Circle().fill(Palette.fixedInk).frame(width: 5).offset(x: x, y: -12)
            }
        }
    }
}

struct Snail: View {
    let dark: Bool
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: dark ? 0x8C8070 : 0xD9C7A8)).frame(width: 40, height: 10).offset(y: 9)
            Circle().fill(Color(hex: dark ? 0x9C6A44 : 0xD99A5B)).frame(width: 24).offset(x: -3)
            Circle().stroke(Color(hex: dark ? 0x6E4A30 : 0xA86A35), lineWidth: 2.5).frame(width: 12).offset(x: -3)
            Capsule().fill(Color(hex: dark ? 0x8C8070 : 0xD9C7A8)).frame(width: 2.5, height: 10).rotationEffect(.degrees(20)).offset(x: 17, y: -1)
            Circle().fill(Palette.fixedInk).frame(width: 4).offset(x: 19, y: -6)
        }
    }
}

struct Butterfly: View {
    let dark: Bool
    var body: some View {
        let wing = Color(hex: dark ? 0x8A75B8 : 0xB9A0EA)
        ZStack {
            Ellipse().fill(wing).frame(width: 13, height: 16).rotationEffect(.degrees(-20)).offset(x: -7, y: -3)
            Ellipse().fill(wing).frame(width: 13, height: 16).rotationEffect(.degrees(20)).offset(x: 7, y: -3)
            Ellipse().fill(wing.opacity(0.8)).frame(width: 9, height: 10).offset(x: -6, y: 7)
            Ellipse().fill(wing.opacity(0.8)).frame(width: 9, height: 10).offset(x: 6, y: 7)
            Capsule().fill(Palette.fixedInk).frame(width: 3, height: 18)
        }
    }
}

struct Kookaburra: View {
    let dark: Bool
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: dark ? 0xA89A84 : 0xF1E6D0)).frame(width: 30, height: 34).offset(y: 5)
            Ellipse().fill(Color(hex: dark ? 0x6E5440 : 0x9C7451)).frame(width: 16, height: 26).offset(x: -10, y: 6)
            Circle().fill(Color(hex: dark ? 0xA89A84 : 0xF1E6D0)).frame(width: 22).offset(y: -12)
            Capsule().fill(Color(hex: dark ? 0x6E5440 : 0x9C7451)).frame(width: 18, height: 4).offset(y: -14)
            Circle().fill(Palette.fixedInk).frame(width: 3.5).offset(x: 4, y: -12)
            Triangle().fill(Color(hex: dark ? 0x5C5A55 : 0x3F4A52)).frame(width: 9, height: 16).rotationEffect(.degrees(90)).offset(x: 16, y: -9)
            Capsule().fill(Color(hex: dark ? 0x4A5E78 : 0x6C93C4)).frame(width: 7, height: 4).offset(x: -6, y: 4)
        }
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

struct Balloon: View {
    let dark: Bool
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Ellipse().fill(Color(hex: dark ? 0xB8584A : 0xE8735E)).frame(width: 34, height: 40)
                Ellipse().fill(Color(hex: dark ? 0xC9A548 : 0xFFD666)).frame(width: 12, height: 40)
            }
            Path { p in
                p.move(to: CGPoint(x: 10, y: 0)); p.addLine(to: CGPoint(x: 14, y: 6))
                p.move(to: CGPoint(x: 24, y: 0)); p.addLine(to: CGPoint(x: 20, y: 6))
            }
            .stroke(Palette.fixedInk.opacity(0.6), lineWidth: 1)
            .frame(width: 34, height: 6)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: dark ? 0x6E5440 : 0x9C7451)).frame(width: 9, height: 7)
        }
    }
}

struct Kite: View {
    var body: some View {
        ZStack(alignment: .top) {
            Path { p in
                p.move(to: CGPoint(x: 20, y: 0)); p.addLine(to: CGPoint(x: 38, y: 20))
                p.addLine(to: CGPoint(x: 20, y: 46)); p.addLine(to: CGPoint(x: 2, y: 20)); p.closeSubpath()
            }
            .fill(Color(hex: 0x6C93C4))
            Path { p in
                p.move(to: CGPoint(x: 20, y: 0)); p.addLine(to: CGPoint(x: 20, y: 46))
                p.move(to: CGPoint(x: 2, y: 20)); p.addLine(to: CGPoint(x: 38, y: 20))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
            Path { p in
                p.move(to: CGPoint(x: 20, y: 46))
                p.addCurve(to: CGPoint(x: 26, y: 70), control1: CGPoint(x: 10, y: 54), control2: CGPoint(x: 32, y: 60))
            }
            .stroke(Palette.fixedInk.opacity(0.5), lineWidth: 1.2)
        }
        .frame(width: 40, height: 70)
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
