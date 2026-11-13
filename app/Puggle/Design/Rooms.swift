import SwiftUI

/// Where Puggle is when it is too late to be out. She is two and a half: after tea
/// time she is indoors, at the table, then in the living room or the play room,
/// then in her bedroom until morning.
enum Room: Int, CaseIterable {
    case dining, living, playroom, bedroom

    /// The hour the scenes are showing: the clock's, or the Developer menu's.
    static var hourNow: Int {
        #if DEBUG
        // For checking: launch with "-debugHour 19".
        if let forced = UserDefaults.standard.string(forKey: "debugHour").flatMap(Int.init) { return forced }
        #endif
        return Calendar.current.component(.hour, from: .now)
    }

    /// The room for this hour, or nil while she is outdoors. `dark` is the dark or night look:
    /// by day it keeps her in, since the scene outside would be drawn as night.
    static func at(hour: Int, dark: Bool) -> Room? {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let evening: Room = day.isMultiple(of: 2) ? .living : .playroom
        #if DEBUG
        // For checking a room at any hour: launch with "-debugRoom 0" to "3".
        if let forced = UserDefaults.standard.string(forKey: "debugRoom").flatMap(Int.init), let room = Room(rawValue: forced) { return room }
        #endif
        switch hour {
        case 18: return .dining
        case 19: return evening
        case 20...23, 0..<6: return .bedroom
        default: return dark ? evening : nil
        }
    }

    /// Where the room's lamp is, on Puggle's own box, so its light falls on her.
    var lamp: UnitPoint? {
        switch self {
        case .dining: UnitPoint(x: 0.5, y: -0.35)
        case .bedroom: UnitPoint(x: 1.45, y: 0.35)
        case .living: UnitPoint(x: -1.2, y: 0.1)
        case .playroom: nil
        }
    }

    /// What she wears there: pyjamas at bedtime, her dress otherwise. Never a coat indoors.
    var outfit: String { self == .bedroom ? "night" : "none" }
}

/// A room, behind Puggle. Flat shapes with no outline, like the world outdoors; only the cast has a line.
/// The floor is the page colour, so the room runs into Today as the ground does. Pulling Today down
/// shows more of the wall, and things hung higher up it.
struct RoomFrame: View {
    let room: Room
    let dark: Bool
    var appeared = true
    var pull: CGFloat = 0
    var t = 0.0
    var hour = 20
    var weather: Weather = .clear
    var puggleX: CGFloat = 0
    @Environment(\.lineStyle) private var lineStyle

    var body: some View {
        let style = lineStyle
        return Canvas { context, size in
            var painter = RoomPainter(context: &context, w: size.width, top: size.height - 250, dark: dark, t: t, hour: hour, weather: weather, style: style)
            painter.puggleX = puggleX
            painter.paint(room)
        }
        .opacity(appeared ? 1 : 0.6)
        .accessibilityHidden(true)
    }
}

/// What stands in front of Puggle in a room: the table she sits behind at tea time.
struct RoomFront: View {
    let room: Room
    let dark: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if room == .dining {
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    RoomPainter(context: &context, w: size.width, top: size.height - 250, dark: dark,
                                t: timeline.date.timeIntervalSince(SceneClock.start), hour: 18, weather: .clear, style: .ink)
                        .table()
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Draws the rooms. Measurements are in points on a scene 250 high, with `top` added
/// so the scene stays at the bottom while the wall grows above it.
struct RoomPainter {
    /// Where the wall meets the floor.
    static let floor: CGFloat = 166

    /// A copy draws to the same canvas.
    private let context: GraphicsContext
    let w: CGFloat, top: CGFloat, dark: Bool, t: Double, hour: Int, weather: Weather, style: LineStyle
    /// How far Puggle stands from the middle of the room.
    var puggleX: CGFloat = 0

    init(context: inout GraphicsContext, w: CGFloat, top: CGFloat, dark: Bool, t: Double, hour: Int, weather: Weather, style: LineStyle) {
        self.context = context
        self.w = w; self.top = top; self.dark = dark; self.t = t; self.hour = hour; self.weather = weather; self.style = style
    }

    private var night: Bool { dark || hour >= 21 || hour < 5 }
    private var pull: CGFloat { top }

    // MARK: Small tools

    private func col(_ light: UInt32, _ darker: UInt32) -> Color { Color(hex: dark ? darker : light) }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat = 0, _ colour: Color) {
        context.fill(Path(roundedRect: CGRect(x: x, y: top + y, width: width, height: height), cornerRadius: radius, style: .continuous), with: .color(colour))
    }

    private func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ colour: Color) {
        context.fill(Path(ellipseIn: CGRect(x: cx - rx, y: top + cy - ry, width: rx * 2, height: ry * 2)), with: .color(colour))
    }

    private func glow(_ cx: CGFloat, _ cy: CGFloat, _ radius: CGFloat, _ colour: UInt32, _ strength: Double) {
        let centre = CGPoint(x: cx, y: top + cy)
        context.fill(Path(ellipseIn: CGRect(x: cx - radius, y: top + cy - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(hex: colour).opacity(strength), Color(hex: colour).opacity(0)]), center: centre, startRadius: 2, endRadius: radius))
    }

    private func line(_ points: [CGPoint], _ colour: Color, _ width: CGFloat) {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.x, y: top + $0.y) })
        context.stroke(path, with: .color(colour), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    /// One of the brand's soft shapes, in a colour, turned.
    private func soft(_ name: String, _ cx: CGFloat, _ cy: CGFloat, _ size: CGFloat, _ colour: Color, turn: Double = 0, opacity: Double = 1) {
        // The shapes are template images, so they take whatever colour they are given.
        let image = context.resolve(Image("shape-\(name)"))
        var copy = context
        copy.translateBy(x: cx, y: top + cy)
        copy.rotate(by: .degrees(turn))
        copy.opacity = opacity
        let box = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        copy.drawLayer { layer in
            layer.draw(image, in: box)
            layer.blendMode = .sourceIn
            layer.fill(Path(box), with: .color(colour))
        }
    }

    /// How much of something hung `depth` up the wall has come into view.
    private func shown(_ depth: CGFloat) -> Double { Double(min(max((pull - depth + 30) / 30, 0), 1)) }

    // MARK: Walls, floor and window

    private func walls(_ wall: Color, pattern: String, tint: Color) {
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: top + Self.floor)), with: .color(wall))
        // A quiet repeat of one brand shape, tone on tone, all the way up.
        var row = 0
        var y = Self.floor - 34
        while top + y > -30 {
            var x: CGFloat = row.isMultiple(of: 2) ? 30 : 64
            while x < w + 20 {
                soft(pattern, x, y, 18, tint, turn: row.isMultiple(of: 2) ? 0 : 20)
                x += 68
            }
            y -= 46
            row += 1
        }
        // The skirting board, then the floor in the page's own colour with a little shade by the wall.
        rect(0, Self.floor - 7, w, 7, 0, tint.opacity(dark ? 0.9 : 0.75))
        context.fill(Path(CGRect(x: 0, y: top + Self.floor, width: w, height: 250 - Self.floor)), with: .color(Palette.sand))
        let shade = dark ? Color(hex: 0x000000).opacity(0.3) : Color(hex: 0xB8A27E).opacity(0.3)
        context.fill(Path(CGRect(x: 0, y: top + Self.floor, width: w, height: 40)),
                     with: .linearGradient(Gradient(colors: [shade, shade.opacity(0)]), startPoint: CGPoint(x: 0, y: top + Self.floor), endPoint: CGPoint(x: 0, y: top + Self.floor + 40)))
    }

    private func rug(_ colour: Color, _ edge: Color) {
        oval(w / 2, 228, 96, 15, edge)
        oval(w / 2, 228, 86, 11.5, colour)
        // Her shadow on it.
        oval(w / 2 + puggleX, 224, 36, 4.5, Palette.fixedInk.opacity(dark ? 0.3 : 0.12))
    }

    /// A window with whatever is outside: the evening sky, or the moon and stars, and rain on the glass.
    private func window(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, curtain: Color) {
        let frame = col(0xFFFCF6, 0x4B4F8A)
        rect(x - 5, y - 5, width + 10, height + 10, 12, frame)
        let glass = CGRect(x: x, y: top + y, width: width, height: height)
        let sky: [Color] = night ? [Color(hex: 0x1C1F52), Color(hex: 0x3A3C82)]
            : (hour >= 17 ? [Color(hex: 0xC9B6D9), Color(hex: 0xF4CDB0)] : [Color(hex: 0xBFDDF0), Color(hex: 0xE3EEF1)])
        context.fill(Path(roundedRect: glass, cornerRadius: 8, style: .continuous),
                     with: .linearGradient(Gradient(colors: weather.overcast ? [Color(hex: night ? 0x2A2D4C : 0x9BA6B8), Color(hex: night ? 0x3A3E60 : 0xC3CAD4)] : sky),
                                           startPoint: CGPoint(x: x, y: glass.minY), endPoint: CGPoint(x: x, y: glass.maxY)))
        if !weather.overcast {
            if night {
                let moon = Crescent().path(in: CGRect(x: x + width * 0.56, y: top + y + height * 0.18, width: 18, height: 18))
                glow(x + width * 0.56 + 9, y + height * 0.18 + 9, 26, 0xF3E0B8, 0.3)
                context.fill(moon, with: .color(Color(hex: 0xF3E0B8)))
                for (index, star) in [(0.2, 0.3), (0.36, 0.62), (0.82, 0.7), (0.16, 0.78), (0.44, 0.16)].enumerated() {
                    let twinkle = 0.6 + 0.4 * sin(t * 1.7 + Double(index) * 2.1)
                    oval(x + width * star.0, y + height * star.1, 1.3, 1.3, Color(hex: 0xFFF6DC).opacity(twinkle))
                }
            } else if hour >= 17 {
                // The last of the sun, low in the window.
                glow(x + width * 0.3, y + height * 0.86, 30, 0xF79A72, 0.6)
            }
        } else if weather.wet {
            for index in 0..<7 {
                var random = SeededRandom(UInt64(index) &* 131 &+ 7)
                let fall = (t * random.range(0.7, 1.1) + random.unit()).truncatingRemainder(dividingBy: 1)
                let at = CGPoint(x: x + width * random.range(0.08, 0.92), y: y + height * fall)
                line([at, CGPoint(x: at.x - 1.5, y: min(at.y + 9, y + height))], Color.white.opacity(0.5), 1.4)
            }
        }
        // Glazing bars and curtains either side.
        rect(x + width / 2 - 1.5, y, 3, height, 0, frame)
        rect(x, y + height / 2 - 1.5, width, 3, 0, frame)
        rect(x - 12, y - 9, 18, height + 20, 9, curtain)
        rect(x + width - 6, y - 9, 18, height + 20, 9, curtain)
        rect(x - 16, y - 13, width + 32, 5, 2.5, col(0xB89A78, 0x6A5878))
    }

    // MARK: The rooms

    func paint(_ room: Room) {
        switch room {
        case .dining: dining()
        case .living: living()
        case .playroom: playroom()
        case .bedroom: bedroom()
        }
    }

    /// Tea time: a lamp over the table, a sideboard, the evening in the window.
    private func dining() {
        walls(col(0xDDE9D8, 0x232B3A), pattern: "quatrefoil", tint: col(0xCFDFC9, 0x2B3546))
        window(30, 62, 86, 70, curtain: col(0xF4BE2C, 0x8A6F2A))
        // The sideboard, with a jug of gum leaves and a bowl of fruit.
        let wood = col(0xD9B48A, 0x5E4A3C)
        rect(w - 128, 118, 108, 48, 8, wood)
        rect(w - 122, 126, 46, 32, 5, col(0xCBA377, 0x524032))
        rect(w - 72, 126, 46, 32, 5, col(0xCBA377, 0x524032))
        rect(w - 108, 96, 16, 22, 6, col(0xBFD9F5, 0x4A5F8A))
        for (lean, colour) in [(-9.0, 0x8FAE8B), (0, 0xA9BF9C), (9, 0x8FAE8B)] as [(CGFloat, UInt32)] {
            line([CGPoint(x: w - 100, y: 98), CGPoint(x: w - 100 + lean, y: 72)], Color(hex: colour).opacity(dark ? 0.7 : 1), 4)
        }
        oval(w - 52, 114, 18, 6, col(0xF3D9C9, 0x6A5560))
        oval(w - 58, 107, 6.5, 6.5, Color(hex: 0xE5553B).opacity(dark ? 0.75 : 1))
        oval(w - 47, 106, 6.5, 6.5, Color(hex: 0xF4BE2C).opacity(dark ? 0.75 : 1))
        // A picture over it.
        rect(w - 150, 64, 40, 34, 5, col(0xFFFCF6, 0x4B4F8A))
        soft("blossom", w - 130, 81, 22, Color(hex: 0xE5553B), opacity: dark ? 0.7 : 1)
        // The lamp over the table. Its cord runs to the ceiling, however far that is.
        let x = w / 2 + CGFloat(sin(t * 0.7)) * 1.2
        context.stroke(Path { $0.move(to: CGPoint(x: w / 2, y: 0)); $0.addLine(to: CGPoint(x: x, y: top + 66)) },
                       with: .color(col(0x6B5E52, 0x8A80A0)), lineWidth: 1.6)
        glow(x, 88, 96, 0xFFD98A, dark ? 0.42 : 0.3)
        var shade = Path()
        shade.move(to: CGPoint(x: x - 9, y: top + 64)); shade.addLine(to: CGPoint(x: x + 9, y: top + 64))
        shade.addQuadCurve(to: CGPoint(x: x + 30, y: top + 86), control: CGPoint(x: x + 28, y: top + 66))
        shade.addLine(to: CGPoint(x: x - 30, y: top + 86))
        shade.addQuadCurve(to: CGPoint(x: x - 9, y: top + 64), control: CGPoint(x: x - 28, y: top + 66))
        context.fill(shade, with: .color(Color(hex: 0xE5553B).opacity(dark ? 0.85 : 1)))
        oval(x, 86, 9, 4, Color(hex: 0xFFF3B8))
        rug(col(0xF3D9C9, 0x4A3A48), col(0xE5553B, 0x7A3A34).opacity(0.55))
        // Higher up the wall: a clock that tells the time, a shelf, and paper stars on a string.
        if shown(64) > 0 { clock(w * 0.76, -64, shown(64)) }
        if shown(136) > 0 {
            let alpha = shown(136)
            rect(w * 0.12, -128, 110, 6, 3, wood.opacity(alpha))
            rect(w * 0.12 + 10, -152, 18, 24, 5, Color(hex: 0xF4BE2C).opacity(alpha * (dark ? 0.7 : 1)))
            rect(w * 0.12 + 34, -146, 16, 18, 5, Color(hex: 0x2A62B8).opacity(alpha * (dark ? 0.7 : 1)))
            soft("soft-hexagon", w * 0.12 + 84, -142, 28, Color(hex: 0x3C9A5F), opacity: alpha * (dark ? 0.7 : 1))
        }
        if shown(204) > 0 { stars(on: -204, shown(204)) }
    }

    /// After tea: the sofa, the cat, and something on the television.
    private func living() {
        walls(col(0xF2E0D2, 0x2C2438), pattern: "pebble", tint: col(0xEAD3C2, 0x362C44))
        // A standing lamp in the corner.
        rect(18, 62, 3, 104, 1.5, col(0x6B5E52, 0x8A80A0))
        glow(20, 60, 84, 0xFFD98A, dark ? 0.4 : 0.26)
        var lampShade = Path()
        lampShade.move(to: CGPoint(x: 8, y: top + 40)); lampShade.addLine(to: CGPoint(x: 32, y: top + 40))
        lampShade.addLine(to: CGPoint(x: 40, y: top + 66)); lampShade.addLine(to: CGPoint(x: 0, y: top + 66)); lampShade.closeSubpath()
        context.fill(lampShade, with: .color(col(0xF4E7B0, 0xD9C27A)))
        // The sofa, with two cushions in the brand's shapes.
        let sofa = col(0x9DB7D9, 0x34446E), sofaDeep = col(0x86A3CB, 0x2B3A60)
        rect(34, 92, 208, 76, 26, sofa)
        rect(22, 120, 34, 58, 15, sofaDeep)
        rect(220, 120, 34, 58, 15, sofaDeep)
        rect(44, 134, 188, 44, 14, sofaDeep)
        rect(40, 172, 8, 12, 3, col(0xB89A78, 0x5E4A3C)); rect(228, 172, 8, 12, 3, col(0xB89A78, 0x5E4A3C))
        soft("quatrefoil", 84, 126, 36, Color(hex: 0xF4BE2C), turn: -8, opacity: dark ? 0.75 : 1)
        soft("blossom", 122, 130, 30, Color(hex: 0xE5553B), turn: 12, opacity: dark ? 0.75 : 1)
        cat(64, 86)
        // The television on its cabinet: a little cartoon of a ball bouncing over a hill.
        let wood = col(0xD9B48A, 0x5E4A3C)
        rect(w - 142, 156, 116, 22, 7, wood)
        rect(w - 88, 148, 8, 10, 0, col(0x6B5E52, 0x3A3448))
        let screen = CGRect(x: w - 130, y: top + 92, width: 92, height: 56)
        glow(w - 84, 120, 92, 0xBFD9F5, dark ? 0.32 : 0.16)
        rect(w - 135, 87, 102, 66, 10, col(0x4A4038, 0x15131C))
        var picture = context
        picture.clip(to: Path(roundedRect: screen, cornerRadius: 6, style: .continuous))
        picture.fill(Path(screen), with: .color(Color(hex: 0xBFDDF0)))
        picture.fill(Path(ellipseIn: CGRect(x: screen.minX - 20, y: screen.maxY - 22, width: 130, height: 60)), with: .color(Color(hex: 0xA9CB93)))
        let bounce = abs(sin(t * 2.2)), across = (t * 0.22).truncatingRemainder(dividingBy: 1)
        picture.fill(Path(ellipseIn: CGRect(x: screen.minX + CGFloat(across) * 100 - 14, y: screen.maxY - 34 - CGFloat(bounce) * 22, width: 12, height: 12)), with: .color(Color(hex: 0xE5553B)))
        picture.fill(Path(ellipseIn: CGRect(x: screen.minX + 62, y: screen.minY + 8, width: 14, height: 14)), with: .color(Color(hex: 0xFFD666)))
        // Its light on the floor.
        oval(w - 84, 196, 70, 11, Color(hex: 0xBFD9F5).opacity(dark ? 0.16 : 0.2))
        rug(col(0xF4E7B0, 0x4A4438), col(0x2A62B8, 0x34446E).opacity(0.5))
        // Higher up: pictures, a plant in a hanging pot, and a paper shade.
        if shown(70) > 0 {
            let alpha = shown(70) * (dark ? 0.75 : 1)
            let pictures: [(String, UInt32)] = [("scallop", 0xF4BE2C), ("pebble", 0x3C9A5F), ("half-pill", 0x2A62B8)]
            for (index, item) in pictures.enumerated() {
                let x = w * 0.2 + CGFloat(index) * 62
                rect(x - 22, -92 + CGFloat(index % 2) * 10, 44, 50, 5, col(0xFFFCF6, 0x4B4F8A).opacity(shown(70)))
                soft(item.0, x, -67 + CGFloat(index % 2) * 10, 26, Color(hex: item.1), opacity: alpha)
            }
        }
        if shown(140) > 0 { hangingPlant(w * 0.78, -140, shown(140)) }
        if shown(208) > 0 {
            let alpha = shown(208)
            context.stroke(Path { $0.move(to: CGPoint(x: w * 0.42, y: 0)); $0.addLine(to: CGPoint(x: w * 0.42, y: top - 226)) }, with: .color(col(0x6B5E52, 0x8A80A0).opacity(alpha)), lineWidth: 1.4)
            glow(w * 0.42, -204, 60, 0xFFD98A, 0.3 * alpha)
            oval(w * 0.42, -204, 24, 22, col(0xFFFCF6, 0xE9DDBE).opacity(alpha))
        }
    }

    /// Before bed: blocks in the brand's shapes, a shelf of toys, a ball that will not stay put.
    private func playroom() {
        walls(col(0xD7E7F4, 0x222E4C), pattern: "soft-square", tint: col(0xC8DCEE, 0x2A3858))
        window(w - 196, 78, 74, 60, curtain: col(0xE5553B, 0x7A3A34))
        bunting(54, 1)
        // A low shelf: books standing, and things on top.
        let wood = col(0xE9D7B8, 0x5A4A44)
        rect(16, 108, 122, 60, 8, wood)
        rect(22, 114, 110, 22, 4, col(0xDCC8A6, 0x4E4038)); rect(22, 140, 110, 22, 4, col(0xDCC8A6, 0x4E4038))
        for (index, colour) in ([0xE5553B, 0xF4BE2C, 0x2A62B8, 0x3C9A5F, 0xF4BE2C, 0xE5553B, 0x2A62B8] as [UInt32]).enumerated() {
            rect(26 + CGFloat(index) * 8.5, 117 + CGFloat(index % 3), 6.5, 19 - CGFloat(index % 3), 2, Color(hex: colour).opacity(dark ? 0.7 : 1))
        }
        soft("pill", 110, 151, 34, Color(hex: 0xBFD9F5), opacity: dark ? 0.7 : 1)
        soft("soft-hexagon", 52, 151, 20, Color(hex: 0xF3D9C9), opacity: dark ? 0.7 : 1)
        // Stacking rings on top of it.
        for (index, colour) in ([0x2A62B8, 0x3C9A5F, 0xF4BE2C, 0xE5553B] as [UInt32]).enumerated() {
            oval(48, 104 - CGFloat(index) * 7, 17 - CGFloat(index) * 3.2, 4.5, Color(hex: colour).opacity(dark ? 0.75 : 1))
        }
        soft("blossom", 104, 96, 26, Color(hex: 0xF4BE2C), turn: t * 8, opacity: dark ? 0.75 : 1)
        rug(col(0xF3D9C9, 0x473A48), col(0xF4BE2C, 0x8A6F2A).opacity(0.6))
        // Blocks, built up. The top one rocks now and then, as if it might go.
        let dim = dark ? 0.78 : 1.0
        let rock = t.truncatingRemainder(dividingBy: 7) < 1.2 ? 5 * sin(t * 9) * (1 - t.truncatingRemainder(dividingBy: 7) / 1.2) : 0
        soft("soft-square", w - 72, 206, 52, Color(hex: 0x2A62B8), opacity: dim)
        soft("soft-hexagon", w - 28, 212, 40, Color(hex: 0xF4BE2C), turn: 30, opacity: dim)
        soft("half-pill", w - 72, 173, 48, Color(hex: 0x3C9A5F), opacity: dim)
        soft("quatrefoil", w - 72, 146, 36, Color(hex: 0xE5553B), turn: rock, opacity: dim)
        soft("pebble", w - 112, 230, 26, Color(hex: 0xCFE5D2), turn: -12, opacity: dim)
        // The ball rolls a little way and back.
        let roll = sin(t * 0.45)
        ball(86 + CGFloat(roll) * 34, 222, 15, turn: roll * 130)
        // Higher up: more bunting, paper planes on strings, and balloons against the ceiling.
        if shown(72) > 0 { bunting(-74, shown(72)) }
        if shown(140) > 0 {
            let alpha = shown(140)
            for (index, x) in [w * 0.3, w * 0.62].enumerated() {
                let swing = CGFloat(sin(t * 1.1 + Double(index) * 2)) * 6
                context.stroke(Path { $0.move(to: CGPoint(x: x, y: 0)); $0.addLine(to: CGPoint(x: x + swing, y: top - 150 + CGFloat(index) * 14)) }, with: .color(col(0x6B5E52, 0x8A80A0).opacity(0.6 * alpha)), lineWidth: 1)
                let nose = CGPoint(x: x + swing + 20, y: -146 + CGFloat(index) * 14)
                var plane = Path()
                plane.addLines([CGPoint(x: nose.x, y: top + nose.y), CGPoint(x: nose.x - 38, y: top + nose.y - 10), CGPoint(x: nose.x - 26, y: top + nose.y + 2), CGPoint(x: nose.x - 30, y: top + nose.y + 12)])
                plane.closeSubpath()
                context.fill(plane, with: .color(col(0xFFFCF6, 0xD8D2E8).opacity(alpha)))
            }
        }
        if shown(210) > 0 {
            let alpha = shown(210) * (dark ? 0.8 : 1)
            for (index, colour) in ([0xE5553B, 0xF4BE2C, 0x2A62B8] as [UInt32]).enumerated() {
                let x = w * 0.44 + CGFloat(index) * 26, bob = CGFloat(sin(t * 1.3 + Double(index))) * 2.5
                line([CGPoint(x: x, y: -206 + bob), CGPoint(x: w * 0.44 + 26, y: -150)], col(0x6B5E52, 0x8A80A0).opacity(0.5 * alpha), 1)
                oval(x, -222 + bob, 14, 17, Color(hex: colour).opacity(alpha))
                oval(x - 4.5, -229 + bob, 3, 4.5, Color.white.opacity(0.4 * alpha))
            }
        }
    }

    /// Bedtime: her bed, a lamp left on, the moon in the window.
    private func bedroom() {
        walls(col(0xDCD5EE, 0x1B1E42), pattern: "blossom", tint: col(0xCFC6E6, 0x232751))
        window(38, 58, 86, 50, curtain: col(0x9DB7D9, 0x34446E))
        // Stars stuck on the wall over the bed, that glow when it is dark.
        for (index, star) in [(196.0, 66.0), (228, 86), (258, 62), (286, 90), (176, 92)].enumerated() {
            let twinkle = dark ? 0.6 + 0.4 * sin(t * 1.3 + Double(index) * 1.7) : 0.7
            if dark { glow(star.0, star.1, 9, 0xE8F0A8, 0.35 * twinkle) }
            soft("quatrefoil", star.0, star.1, 9, col(0xF4E7B0, 0xE8F0A8), turn: Double(index) * 20, opacity: twinkle)
        }
        // The bed: headboard, pillow, and a blanket with the brand's flowers on it.
        rect(10, 116, 148, 52, 20, col(0xF3D9C9, 0x54405A))
        rect(4, 138, 172, 54, 16, col(0xFFFCF6, 0x6A6890))
        rect(26, 126, 70, 24, 12, col(0xFFFFFF, 0x8A88B0))
        rect(4, 150, 172, 46, 16, col(0x2A62B8, 0x2B3F7A))
        for (index, x) in [28.0, 66, 104, 142].enumerated() {
            soft("blossom", x, 172 + CGFloat(index % 2) * 8 - 4, 13, col(0xBFD9F5, 0x5A78B8), turn: Double(index) * 25)
        }
        rect(8, 190, 8, 14, 3, col(0xB89A78, 0x5E4A3C)); rect(164, 190, 8, 14, 3, col(0xB89A78, 0x5E4A3C))
        rabbit(60, 122)
        // The table by the bed: a lamp left on, and tonight's book.
        let wood = col(0xD9B48A, 0x5E4A3C)
        rect(w - 138, 128, 58, 40, 7, wood)
        rect(w - 132, 136, 46, 12, 4, col(0xCBA377, 0x524032))
        rect(w - 122, 120, 26, 7, 2, Color(hex: 0xE5553B).opacity(dark ? 0.7 : 1))
        let flicker = 0.94 + 0.06 * sin(t * 5.3) * sin(t * 1.9)
        glow(w - 104, 96, 104, 0xFFD98A, (dark ? 0.5 : 0.3) * flicker)
        rect(w - 92, 108, 5, 20, 2, col(0x6B5E52, 0x8A80A0))
        var shade = Path()
        shade.move(to: CGPoint(x: w - 102, y: top + 86)); shade.addLine(to: CGPoint(x: w - 77, y: top + 86))
        shade.addLine(to: CGPoint(x: w - 70, y: top + 110)); shade.addLine(to: CGPoint(x: w - 109, y: top + 110)); shade.closeSubpath()
        context.fill(shade, with: .color(col(0xF4E7B0, 0xF0D890)))
        // The lamp's light lying on the floor, reaching her.
        oval(w / 2 + 44, 214, 100, 20, Color(hex: 0xFFD98A).opacity(dark ? 0.16 : 0.12))
        rug(col(0xCFE5D2, 0x35485A), col(0x3C9A5F, 0x2A5A48).opacity(0.5))
        // Higher up: more stars, a mobile turning, and clouds painted near the ceiling.
        if shown(66) > 0 {
            for (index, star) in [(0.2, -60.0), (0.5, -84), (0.8, -66), (0.36, -104), (0.66, -110)].enumerated() {
                let twinkle = (dark ? 0.6 + 0.4 * sin(t * 1.5 + Double(index) * 2.3) : 0.7) * shown(66)
                if dark { glow(w * star.0, star.1, 11, 0xE8F0A8, 0.35 * twinkle) }
                soft("quatrefoil", w * star.0, star.1, 11, col(0xF4E7B0, 0xE8F0A8), turn: Double(index) * 31, opacity: twinkle)
            }
        }
        if shown(150) > 0 { mobile(w * 0.36, -176, shown(150)) }
        if shown(214) > 0 {
            let alpha = shown(214) * (dark ? 0.35 : 0.9)
            for (x, y, size) in [(w * 0.24, -226.0, 1.0), (w * 0.7, -214, 1.25)] as [(CGFloat, CGFloat, CGFloat)] {
                let cloud = CloudShape().path(in: CGRect(x: x - 34 * size, y: top + y - 12 * size, width: 68 * size, height: 26 * size))
                context.fill(cloud, with: .color(Color.white.opacity(alpha)))
            }
        }
    }

    // MARK: Things in the rooms

    /// The tea table, in front of her: a cloth with a scalloped edge, her bowl, steam, and her cup.
    func table() {
        let cloth = col(0xFFFCF6, 0x6A6890), wood = col(0xD9B48A, 0x5E4A3C)
        let left = w / 2 - 122, width: CGFloat = 244
        rect(left + 14, 214, 10, 32, 4, wood); rect(left + width - 24, 214, 10, 32, 4, wood)
        rect(left, 200, width, 14, 7, wood)
        // The cloth hangs down in scallops.
        rect(left + 8, 198, width - 16, 26, 4, cloth)
        let scallops = 9
        for index in 0..<scallops {
            let each = (width - 16) / CGFloat(scallops)
            oval(left + 8 + each * (CGFloat(index) + 0.5), 224, each / 2, 9, cloth)
        }
        rect(left + 8, 198, width - 16, 5, 2.5, Color(hex: 0xE5553B).opacity(dark ? 0.6 : 0.85))
        // Her bowl and spoon, with steam coming off, and her cup.
        let x = w / 2 - 74
        oval(x, 195, 25, 6, col(0xA6C6EC, 0x4A5F8A))
        var bowl = Path()
        bowl.move(to: CGPoint(x: x - 25, y: top + 195))
        bowl.addQuadCurve(to: CGPoint(x: x + 25, y: top + 195), control: CGPoint(x: x, y: top + 222))
        bowl.closeSubpath()
        context.fill(bowl, with: .color(col(0xBFD9F5, 0x56709E)))
        oval(x, 195, 20, 4, col(0xF4E7B0, 0xA8985E))
        line([CGPoint(x: x + 12, y: 194), CGPoint(x: x + 34, y: 182)], col(0xB9B4AC, 0x8A88A0), 3)
        for index in 0..<3 {
            let rise = (t * 0.35 + Double(index) * 0.33).truncatingRemainder(dividingBy: 1)
            var wisp = Path()
            let base = CGPoint(x: x - 10 + CGFloat(index) * 9, y: top + 188 - CGFloat(rise) * 26)
            wisp.move(to: base)
            wisp.addQuadCurve(to: CGPoint(x: base.x + 2, y: base.y - 10), control: CGPoint(x: base.x + 5 * CGFloat(sin(rise * 6 + Double(index))), y: base.y - 5))
            context.stroke(wisp, with: .color(Color.white.opacity((dark ? 0.35 : 0.7) * sin(rise * .pi))), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        let cup = w / 2 + 76
        rect(cup - 9, 174, 18, 24, 6, Color(hex: 0xF4BE2C).opacity(dark ? 0.75 : 1))
        rect(cup - 10, 171, 20, 6, 3, Color(hex: 0xE5553B).opacity(dark ? 0.75 : 1))
        rect(cup - 2.5, 164, 5, 9, 2.5, Color(hex: 0xE5553B).opacity(dark ? 0.75 : 1))
    }

    /// A clock on the wall, showing the real time.
    private func clock(_ x: CGFloat, _ y: CGFloat, _ alpha: Double) {
        oval(x, y, 22, 22, col(0xB89A78, 0x6A5878).opacity(alpha))
        oval(x, y, 18.5, 18.5, col(0xFFFCF6, 0xD8D2E8).opacity(alpha))
        let parts = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let minute = Double(parts.minute ?? 0), hourHand = Double((parts.hour ?? 0) % 12) + minute / 60
        for (turn, reach, width) in [(hourHand / 12, 9.0, 2.6), (minute / 60, 14.0, 1.8)] {
            let angle = turn * 2 * .pi - .pi / 2
            line([CGPoint(x: x, y: y), CGPoint(x: x + CGFloat(cos(angle) * reach), y: y + CGFloat(sin(angle) * reach))], Palette.fixedInk.opacity(alpha), width)
        }
        oval(x, y, 2, 2, Color(hex: 0xE5553B).opacity(alpha))
    }

    /// Paper stars on a string across the wall.
    private func stars(on y: CGFloat, _ alpha: Double) {
        var string = Path()
        string.move(to: CGPoint(x: -4, y: top + y - 12))
        string.addQuadCurve(to: CGPoint(x: w + 4, y: top + y - 12), control: CGPoint(x: w / 2, y: top + y + 22))
        context.stroke(string, with: .color(col(0x6B5E52, 0x8A80A0).opacity(0.6 * alpha)), lineWidth: 1)
        for index in 0..<6 {
            let along = (CGFloat(index) + 0.5) / 6
            let drop = 4 * along * (1 - along) * 17 - 12
            soft("quatrefoil", w * along, y + drop + 9, 18, Color(hex: [0xF4BE2C, 0xFFFCF6, 0xE5553B][index % 3]),
                 turn: 8 * sin(t * 1.2 + Double(index)), opacity: alpha * (dark ? 0.75 : 1))
        }
    }

    /// Flags on a string.
    private func bunting(_ y: CGFloat, _ alpha: Double) {
        var string = Path()
        string.move(to: CGPoint(x: -4, y: top + y))
        string.addQuadCurve(to: CGPoint(x: w + 4, y: top + y), control: CGPoint(x: w / 2, y: top + y + 30))
        context.stroke(string, with: .color(col(0x6B5E52, 0x8A80A0).opacity(0.6 * alpha)), lineWidth: 1)
        let colours: [UInt32] = [0xE5553B, 0xF4BE2C, 0x2A62B8, 0x3C9A5F, 0xF3D9C9]
        for index in 0..<9 {
            let along = (CGFloat(index) + 0.5) / 9
            let x = w * along, drop = 4 * along * (1 - along) * 15
            var flag = Path()
            flag.addLines([CGPoint(x: x - 9, y: top + y + drop), CGPoint(x: x + 9, y: top + y + drop), CGPoint(x: x, y: top + y + drop + 17)])
            flag.closeSubpath()
            context.fill(flag, with: .color(Color(hex: colours[index % colours.count]).opacity(alpha * (dark ? 0.72 : 1))))
        }
    }

    private func hangingPlant(_ x: CGFloat, _ y: CGFloat, _ alpha: Double) {
        let swing = CGFloat(sin(t * 0.8)) * 3
        context.stroke(Path { $0.move(to: CGPoint(x: x, y: 0)); $0.addLine(to: CGPoint(x: x + swing, y: top + y)) }, with: .color(col(0x6B5E52, 0x8A80A0).opacity(0.7 * alpha)), lineWidth: 1.2)
        for (index, reach) in [(0, -22.0), (1, -10), (2, 6), (3, 20)] as [(Int, CGFloat)] {
            var frond = Path()
            frond.move(to: CGPoint(x: x + swing, y: top + y + 4))
            frond.addQuadCurve(to: CGPoint(x: x + swing + reach + CGFloat(sin(t + Double(index))) * 2, y: top + y + 38 + CGFloat(index % 2) * 10),
                               control: CGPoint(x: x + swing + reach * 1.2, y: top + y + 6))
            context.stroke(frond, with: .color(Color(hex: index.isMultiple(of: 2) ? 0x3C9A5F : 0x8FAE8B).opacity(alpha * (dark ? 0.7 : 1))), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
        rect(x + swing - 13, y, 26, 18, 7, Color(hex: 0xE5553B).opacity(alpha * (dark ? 0.75 : 1)))
    }

    /// A mobile over the bed: a moon and stars going slowly round.
    private func mobile(_ x: CGFloat, _ y: CGFloat, _ alpha: Double) {
        let thread = col(0x6B5E52, 0x8A80A0).opacity(0.7 * alpha)
        context.stroke(Path { $0.move(to: CGPoint(x: x, y: 0)); $0.addLine(to: CGPoint(x: x, y: top + y)) }, with: .color(thread), lineWidth: 1.2)
        let turn = sin(t * 0.5)
        let span: CGFloat = 46 * CGFloat(abs(turn) * 0.5 + 0.5)
        line([CGPoint(x: x - span, y: y), CGPoint(x: x + span, y: y)], col(0xB89A78, 0x8A80A0).opacity(alpha), 2.4)
        let hung: [CGFloat] = [-1, 0, 1]
        for (index, offset) in hung.enumerated() {
            let at = CGPoint(x: x + offset * span, y: y + 22 + CGFloat(index % 2) * 12)
            line([CGPoint(x: at.x, y: y), at], thread, 1)
            if index == 1 {
                let moon = Crescent().path(in: CGRect(x: at.x - 9, y: top + at.y, width: 18, height: 18))
                context.fill(moon, with: .color(col(0xF4BE2C, 0xF3E0B8).opacity(alpha)))
            } else {
                soft("quatrefoil", at.x, at.y + 8, 15, col(0x2A62B8, 0xBFD9F5), turn: t * 20 + Double(index) * 40, opacity: alpha)
            }
        }
    }

    private func ball(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, turn: Double) {
        oval(x, y + radius - 1, radius * 0.9, 2.5, Palette.fixedInk.opacity(dark ? 0.3 : 0.1))
        oval(x, y, radius, radius, col(0xFFFCF6, 0xC9C2D8))
        let centre = CGPoint(x: x, y: top + y)
        for (index, colour) in ([0xE5553B, 0xF4BE2C, 0x2A62B8] as [UInt32]).enumerated() {
            var panel = Path()
            panel.move(to: centre)
            panel.addArc(center: centre, radius: radius, startAngle: .degrees(turn + Double(index) * 120), endAngle: .degrees(turn + Double(index) * 120 + 60), clockwise: false)
            panel.closeSubpath()
            context.fill(panel, with: .color(Color(hex: colour).opacity(dark ? 0.75 : 1)))
        }
    }

    // MARK: The cast indoors (outlined, like Puggle)

    private func outlined(_ parts: [(Path, Color)], line: CGFloat = 3.6) {
        for (path, colour) in parts {
            context.stroke(path, with: .color(style == .tinted ? colour.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
        }
        for (path, colour) in parts { context.fill(path, with: .color(colour)) }
    }

    /// The cat, curled on the back of the sofa. Her tail flicks; now and then an ear turns.
    private func cat(_ x: CGFloat, _ y: CGFloat) {
        let fur = Color(hex: 0xE0A062).moonlit(dark), y = top + y
        let flick = CGFloat(sin(t * 1.3)) * (t.truncatingRemainder(dividingBy: 6) < 2.5 ? 7 : 1.5)
        var tail = Path()
        tail.move(to: CGPoint(x: x + 20, y: y + 6))
        tail.addQuadCurve(to: CGPoint(x: x + 40, y: y - 6 + flick), control: CGPoint(x: x + 36, y: y + 10))
        context.stroke(tail, with: .color(style == .tinted ? fur.outlineShade : Palette.fixedInk), style: StrokeStyle(lineWidth: 8.5, lineCap: .round))
        context.stroke(tail, with: .color(fur), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        let breathe = CGFloat(sin(t * 1.1)) * 0.7
        func ear(_ dx: CGFloat) -> Path {
            var path = Path()
            path.addLines([CGPoint(x: x - 16 + dx, y: y - 4), CGPoint(x: x - 13 + dx, y: y - 14), CGPoint(x: x - 7 + dx, y: y - 6)])
            path.closeSubpath()
            return path
        }
        outlined([
            (Path(ellipseIn: CGRect(x: x - 14, y: y - 8 - breathe, width: 40, height: 22 + breathe)), fur),
            (ear(0), fur), (ear(11), fur),
            (Path(ellipseIn: CGRect(x: x - 20, y: y - 8, width: 22, height: 19)), fur),
        ])
        // Asleep: two closed eyes and a nose.
        for dx in [-13.0, -5.0] as [CGFloat] {
            var lid = Path()
            lid.move(to: CGPoint(x: x + dx - 2, y: y + 1))
            lid.addQuadCurve(to: CGPoint(x: x + dx + 2, y: y + 1), control: CGPoint(x: x + dx, y: y + 3))
            context.stroke(lid, with: .color(Palette.fixedInk), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
        context.fill(Path(ellipseIn: CGRect(x: x - 10.2, y: y + 3.6, width: 2.6, height: 2)), with: .color(Color(hex: 0xF2A48E)))
    }

    /// Her toy rabbit, on the pillow.
    private func rabbit(_ x: CGFloat, _ y: CGFloat) {
        let cloth = Color(hex: 0xF3D9C9).moonlit(dark), y = top + y
        outlined([
            (Path(roundedRect: CGRect(x: x - 9, y: y - 24, width: 6.5, height: 18), cornerRadius: 3.2), cloth),
            (Path(roundedRect: CGRect(x: x + 2.5, y: y - 23, width: 6.5, height: 17), cornerRadius: 3.2).applying(CGAffineTransform(translationX: x + 6, y: y - 8).rotated(by: 0.3).translatedBy(x: -(x + 6), y: -(y - 8))), cloth),
            (Path(ellipseIn: CGRect(x: x - 11, y: y + 2, width: 22, height: 16)), cloth),
            (Path(ellipseIn: CGRect(x: x - 10, y: y - 10, width: 20, height: 17)), cloth),
        ], line: 3)
        context.fill(Path(ellipseIn: CGRect(x: x - 5.4, y: y - 3, width: 2.4, height: 2.4)), with: .color(Palette.fixedInk))
        context.fill(Path(ellipseIn: CGRect(x: x + 3, y: y - 3, width: 2.4, height: 2.4)), with: .color(Palette.fixedInk))
        context.fill(Path(ellipseIn: CGRect(x: x - 1.4, y: y + 0.6, width: 2.8, height: 2)), with: .color(Color(hex: 0xF2A48E)))
    }
}
