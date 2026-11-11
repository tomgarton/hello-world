import SwiftUI
import UIKit

// Potty stamp cards. Each wee, poo or try earns one ink stamp on a kraft
// paper card; the sixth space takes a shiny sticker. Finished cards are kept
// in the stamp book. It only ever adds up: an accident never appears here.

/// An ink stamp. The raw value is what is saved on the potty entry.
/// The Australiana set is offered; earlier stamps still draw.
enum Stamp: String, CaseIterable, Identifiable {
    case thong, esky, hoist, lamington, fairybread, pavlova, surfboard, zinc
    case clip, fish, leaf, sun, moon, heart, star, bird, tortoise, ladybird

    static let offered: [Stamp] = [.thong, .esky, .hoist, .lamington, .fairybread, .pavlova, .surfboard, .zinc]
    static let perCard = 5

    var id: String { rawValue }

    /// A drawing from the Australiana set (`design/canvas/gen/world_style.py`), as a one-colour image.
    var art: String? {
        switch self {
        case .thong: "stamp-thong"
        case .esky: "stamp-esky"
        case .hoist: "stamp-hills-hoist"
        case .lamington: "stamp-lamington"
        case .fairybread: "stamp-fairy-bread"
        case .pavlova: "stamp-pavlova"
        case .surfboard: "stamp-surfboard"
        case .zinc: "stamp-zinc-stick"
        default: nil
        }
    }

    /// For the first stamp set. Nil for Puggle's clip, which is drawn as a quatrefoil.
    var symbol: String? {
        switch self {
        case .fish: "fish.fill"
        case .leaf: "leaf.fill"
        case .sun: "sun.max.fill"
        case .moon: "moon.fill"
        case .heart: "heart.fill"
        case .star: "star.fill"
        case .bird: "bird.fill"
        case .tortoise: "tortoise.fill"
        case .ladybird: "ladybug.fill"
        default: nil
        }
    }

    /// One ink colour each, like a station stamp.
    var ink: Color {
        switch self {
        case .esky, .lamington, .pavlova, .clip, .sun, .star, .ladybird: Color(hex: 0xD9482F)
        case .thong, .hoist, .surfboard, .fish, .moon, .bird: Color(hex: 0x2A62B8)
        case .fairybread, .zinc, .leaf, .heart, .tortoise: Color(hex: 0x3C8A55)
        }
    }

    var name: String {
        switch self {
        case .clip: "Puggle's clip"
        case .hoist: "Hills Hoist"
        case .fairybread: "Fairy bread"
        case .zinc: "Zinc stick"
        default: rawValue.capitalized
        }
    }
}

/// Puggle's hair clip: four round lobes. The app's sparkle and sticker shape.
struct Quatrefoil: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.275, d = r * 0.82
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for (dx, dy) in [(-d, 0.0), (d, 0.0), (0.0, -d), (0.0, d), (0.0, 0.0)] {
            path.addEllipse(in: CGRect(x: c.x + dx - r, y: c.y + dy - r, width: r * 2, height: r * 2))
        }
        return path
    }
}

/// Grain, drawn once and tiled: paper fibre, and the gaps in a stamp's ink.
enum Grain {
    static let image: UIImage = {
        let size = CGSize(width: 96, height: 96)
        return UIGraphicsImageRenderer(size: size).image { context in
            for _ in 0..<1500 {
                UIColor(white: 0, alpha: .random(in: 0.25...1)).setFill()
                let side = CGFloat.random(in: 0.6...1.8)
                context.fill(CGRect(x: .random(in: 0..<96), y: .random(in: 0..<96), width: side, height: side))
            }
        }.withRenderingMode(.alwaysTemplate)
    }()
}

/// One impression: two rings, the picture and the date, a little uneven.
struct StampMark: View {
    let stamp: Stamp
    var date: Date?
    var size: CGFloat = 54

    var body: some View {
        let k = size / 54
        ZStack {
            Circle().stroke(lineWidth: 2.2 * k).frame(width: 48 * k, height: 48 * k)
            Circle().stroke(lineWidth: 0.9 * k).frame(width: 41 * k, height: 41 * k)
            Group {
                if let art = stamp.art {
                    Image(art).resizable().scaledToFit().scaleEffect(1.25)
                } else if let symbol = stamp.symbol {
                    Image(systemName: symbol).resizable().scaledToFit()
                } else {
                    Quatrefoil()
                }
            }
            .frame(width: 22 * k, height: 22 * k)
            .offset(y: date == nil ? 0 : -3 * k)
            if let date {
                Text(date.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                    .font(.system(size: 5.6 * k, weight: .bold))
                    .kerning(0.6 * k)
                    .offset(y: 16.5 * k)
            }
        }
        .foregroundStyle(stamp.ink)
        .frame(width: size, height: size)
        // Specks of bare paper where the ink did not take.
        .overlay {
            Image(uiImage: Grain.image).resizable(resizingMode: .tile)
                .foregroundStyle(Palette.stampSpace)
                .opacity(0.55)
                .clipShape(Circle())
        }
        .accessibilityHidden(true)
    }
}

/// How a sticker's surface catches the light.
enum Foil: CaseIterable {
    case rainbow, sea, sunset, pearl, gold

    var colours: [Color] {
        switch self {
        case .rainbow: [0xF9C6D8, 0xFBE9A6, 0xB9F0D2, 0xB5D8FA, 0xDCC3F7].map { Color(hex: $0) }
        case .sea: [0xB5F0E4, 0x8FD3F4, 0xC2C7FA, 0xA8EDD0].map { Color(hex: $0) }
        case .sunset: [0xFFD3A5, 0xFD9BB0, 0xF7B2E0, 0xFFE29A].map { Color(hex: $0) }
        case .pearl: [0xFFFFFF, 0xF3E3EE, 0xE2EEF9, 0xFBF3E0].map { Color(hex: $0) }
        case .gold: [0xFBE59A, 0xF4BE2C, 0xFFF1C2, 0xE9A917].map { Color(hex: $0) }
        }
    }
}

/// What a sticker looks like: one of the soft shapes, a surface, and a picture.
struct StickerStyle {
    /// A soft shape from the asset catalogue: "shape-quatrefoil", "shape-blossom" and so on.
    var shape = "shape-quatrefoil"
    var foil: Foil? = .rainbow
    /// A flat colour in place of foil.
    var colour: Color?
    /// The picture in the middle, if any.
    var emblem: String?

    private static let shapes = ["shape-quatrefoil", "shape-blossom", "shape-soft-hexagon", "shape-scallop", "shape-pebble", "shape-soft-square"]

    /// The shiny sticker for a finished card. Each card's is a different shape and foil, with Puggle on it.
    static func card(_ index: Int) -> StickerStyle {
        StickerStyle(shape: shapes[index % shapes.count], foil: Foil.allCases[index % Foil.allCases.count], emblem: "PuggleFace")
    }
}

/// A sticker: die-cut white edge, foil or colour inside, sitting on the paper.
/// The foil carries a faint quatrefoil repeat, the way printed foil has a pattern in it.
struct StickerView: View {
    var style = StickerStyle()
    var size: CGFloat = 62

    private var mask: some View { Image(style.shape).resizable().scaledToFit() }

    var body: some View {
        ZStack {
            mask.foregroundStyle(.white)
            ZStack {
                if let colour = style.colour {
                    colour
                } else {
                    LinearGradient(colors: (style.foil ?? .rainbow).colours, startPoint: .topLeading, endPoint: .bottomTrailing)
                    // The repeat pattern, pressed into the foil.
                    VStack(spacing: size * 0.03) {
                        ForEach(0..<5, id: \.self) { row in
                            HStack(spacing: size * 0.03) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Quatrefoil().fill(.white.opacity(0.38)).frame(width: size * 0.17, height: size * 0.17)
                                }
                            }
                            .offset(x: row.isMultiple(of: 2) ? 0 : size * 0.1)
                        }
                    }
                    .rotationEffect(.degrees(-20))
                }
                LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0)], startPoint: .top, endPoint: .center)
            }
            .mask(mask)
            .scaleEffect(0.86)
            if let emblem = style.emblem {
                Image(emblem).resizable().scaledToFit()
                    .frame(width: size * 0.46, height: size * 0.46)
                    // The pictures are drawn for light paper, whatever the phone is set to.
                    .environment(\.colorScheme, .light)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.28), radius: 2.5, y: 2)
        .accessibilityHidden(true)
    }
}

/// The edge of a card: nearly a rounded rectangle, but cut by hand.
struct PaperEdge: Shape {
    func path(in rect: CGRect) -> Path {
        let count = 150, power = 2.0 / 9.0
        var points: [CGPoint] = []
        for i in 0..<count {
            let angle = Double(i) / Double(count) * 2 * .pi
            let c = cos(angle), s = sin(angle)
            // A squircle, with each point nudged in or out a little.
            let noise = (sin(Double(i) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
            let wobble = 1 - abs(noise) * 0.011 - (i % 23 == 0 ? 0.008 : 0)
            let x = rect.midX + rect.width / 2 * CGFloat((c < 0 ? -1 : 1) * pow(abs(c), power) * wobble)
            let y = rect.midY + rect.height / 2 * CGFloat((s < 0 ? -1 : 1) * pow(abs(s), power) * wobble)
            points.append(CGPoint(x: x, y: y))
        }
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }
}

/// Paper that moves: a ring running out from a stamp, and a corner that folds over.
struct PaperEffects: ViewModifier, Animatable {
    /// False while `Design/Paper.metal` is left out of the build (see project.yml).
    /// The card then moves as a flat sheet: no ripple and no folded corner.
    static let shadersBuilt = false

    /// How far the corner is folded in, in points.
    var curl: CGFloat
    var corner: CGPoint
    var rippleOrigin: CGPoint
    var rippleStart: Date?
    var size = StampCard.size
    var back = Color(hex: 0xE6D9B8)

    var animatableData: CGFloat {
        get { curl }
        set { curl = newValue }
    }

    @ViewBuilder func body(content: Content) -> some View {
        if Self.shadersBuilt { moving(content) } else { content }
    }

    private func moving(_ content: Content) -> some View {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let length = max(hypot(centre.x - corner.x, centre.y - corner.y), 1)
        let pull = CGPoint(x: (centre.x - corner.x) / length * curl, y: (centre.y - corner.y) / length * curl)
        return TimelineView(.animation(paused: rippleStart == nil)) { timeline in
            let elapsed = rippleStart.map { timeline.date.timeIntervalSince($0) } ?? 0
            content
                .distortionEffect(ShaderLibrary.paperRipple(.float2(rippleOrigin), .float(elapsed)),
                                  maxSampleOffset: CGSize(width: 12, height: 12),
                                  isEnabled: rippleStart != nil)
                .layerEffect(ShaderLibrary.paperCurl(.float2(size), .float2(corner), .float2(pull), .color(back)),
                             maxSampleOffset: CGSize(width: 120, height: 120),
                             isEnabled: curl > 0.5)
        }
    }
}

/// The picture on a card. They take turns.
enum CardTheme: CaseIterable {
    case beach, backyard, night

    static func forCard(_ index: Int) -> CardTheme { allCases[index % allCases.count] }

    var name: String {
        switch self {
        case .beach: "Beach"
        case .backyard: "Backyard"
        case .night: "Night"
        }
    }

    var paper: Color {
        switch self {
        case .beach: Color(hex: 0xD2BF92)
        case .backyard: Color(hex: 0xCDBB8E)
        case .night: Color(hex: 0x1F2A4D)
        }
    }

    var trail: Color {
        switch self {
        case .beach: Color(hex: 0x2A62B8)
        case .backyard: Color(hex: 0x3D7A45)
        case .night: Color(hex: 0xF3E0B8)
        }
    }

    private static let red = Color(hex: 0xD9482F), blue = Color(hex: 0x2A62B8), green = Color(hex: 0x3C8A55)
    private static let yellow = Color(hex: 0xE9AE1C), pink = Color(hex: 0xD9727C), cream = Color(hex: 0xF3E0B8)

    private static func lines(_ points: [(CGFloat, CGFloat)], closed: Bool = false) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
        if closed { path.closeSubpath() }
        return path
    }

    private static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    private static func grass(_ x: CGFloat) -> Path {
        lines([(x, 198), (x + 7, 185), (x + 14, 198), (x + 21, 185), (x + 28, 198)])
    }

    /// A child's crayon drawing, as strokes: the shape, its colour and how thick.
    var strokes: [(Path, Color, CGFloat)] {
        switch self {
        case .beach:
            var waves = Path()
            waves.move(to: CGPoint(x: 18, y: 62))
            for i in 0..<6 {
                let x = 18 + CGFloat(i) * 26
                waves.addQuadCurve(to: CGPoint(x: x + 26, y: 62), control: CGPoint(x: x + 13, y: i.isMultiple(of: 2) ? 49 : 75))
            }
            var rays = Path()
            let ends: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(236, 12, 236, 6), (258, 36, 265, 36), (252, 20, 257, 15), (220, 20, 215, 15), (214, 36, 207, 36)]
            for end in ends {
                rays.move(to: CGPoint(x: end.0, y: end.1))
                rays.addLine(to: CGPoint(x: end.2, y: end.3))
            }
            return [(waves, Self.blue, 6),
                    (Self.lines([(58, 48), (102, 48), (93, 60), (67, 60)], closed: true), Self.red, 5),
                    (Self.lines([(80, 46), (80, 16), (100, 42)], closed: true), Self.red, 5),
                    (Self.circle(236, 36, 13), Self.yellow, 6), (rays, Self.yellow, 5),
                    (Self.grass(150), Self.green, 5)]
        case .backyard:
            var flower = Path()
            for i in 0..<5 {
                let a = Double(i) / 5 * 2 * .pi - .pi / 2
                flower.addPath(Self.circle(40 + CGFloat(cos(a)) * 12, 42 + CGFloat(sin(a)) * 12, 8))
            }
            var leaf = Path()
            leaf.move(to: CGPoint(x: 236, y: 32))
            leaf.addQuadCurve(to: CGPoint(x: 272, y: 34), control: CGPoint(x: 254, y: 10))
            leaf.addQuadCurve(to: CGPoint(x: 236, y: 32), control: CGPoint(x: 254, y: 50))
            return [(flower, Self.pink, 4), (Self.circle(40, 42, 4), Self.yellow, 5),
                    (Self.circle(150, 43, 17), Self.yellow, 5), (Self.circle(150, 43, 7), Self.yellow, 5),
                    (Self.lines([(118, 62), (178, 62), (184, 48)]), Self.red, 5),
                    (Self.lines([(184, 48), (188, 36)]), Self.red, 4), (Self.lines([(184, 48), (196, 42)]), Self.red, 4),
                    (leaf, Self.green, 5), (Self.grass(18), Self.green, 5), (Self.grass(200), Self.green, 5)]
        case .night:
            var moon = Path()
            moon.move(to: CGPoint(x: 66, y: 18))
            moon.addCurve(to: CGPoint(x: 82, y: 56), control1: CGPoint(x: 34, y: 22), control2: CGPoint(x: 42, y: 68))
            moon.addCurve(to: CGPoint(x: 66, y: 18), control1: CGPoint(x: 62, y: 54), control2: CGPoint(x: 54, y: 34))
            func twinkle(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) -> Path {
                var path = Self.lines([(x - s, y), (x + s, y)])
                path.addPath(Self.lines([(x, y - s), (x, y + s)]))
                return path
            }
            return [(moon, Self.cream, 5), (twinkle(132, 38, 9), Self.yellow, 4), (twinkle(200, 30, 7), Self.yellow, 4),
                    (twinkle(250, 48, 5), Self.cream, 4), (twinkle(26, 100, 4), Self.cream, 4)]
        }
    }
}

/// Lays a card out on a fixed 360 by 215 sheet and scales it to the width it is given.
struct CardCanvas<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) { content }
                .frame(width: StampCard.size.width, height: StampCard.size.height, alignment: .topLeading)
                .scaleEffect(geometry.size.width / StampCard.size.width, anchor: .topLeading)
        }
        .aspectRatio(StampCard.size.width / StampCard.size.height, contentMode: .fit)
    }
}

/// One stamp on a card.
struct Impression: Identifiable {
    let id: String
    let stamp: Stamp
    let date: Date?

    init(_ event: Event) {
        id = event.objectID.uriRepresentation().absoluteString
        stamp = Stamp(rawValue: event.sticker ?? "") ?? .clip
        date = event.startedAt
    }

    /// Each lands a little crooked, and the same way every time it is drawn.
    var tilt: Double {
        let sum = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 1800 }
        return Double(sum % 180) / 10 - 9
    }
}

enum StampCard {
    static let size = CGSize(width: 360, height: 215)
    static let spaces: [CGPoint] = [CGPoint(x: 48, y: 165), CGPoint(x: 104, y: 110), CGPoint(x: 162, y: 165),
                                    CGPoint(x: 220, y: 110), CGPoint(x: 278, y: 165)]
    static let last = CGPoint(x: 318, y: 86)
}

/// The card itself: kraft paper, a crayon picture, a trail of five spaces
/// and a quatrefoil space at the end for the sticker.
struct StampCardFace: View {
    let theme: CardTheme
    let impressions: [Impression]
    /// The shiny sticker that goes on the last space of this card.
    var sticker = StickerStyle()
    var hasSticker = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            PaperEdge().fill(theme.paper)
            // Matte paper: fibres, no sheen.
            Image(uiImage: Grain.image).resizable(resizingMode: .tile)
                .foregroundStyle(theme == .night ? Color.white : Color(hex: 0x5A4320))
                .opacity(theme == .night ? 0.05 : 0.13)
                .clipShape(PaperEdge())
            // The cut edge is a touch darker, as card is.
            PaperEdge().stroke(.black.opacity(0.14), lineWidth: 1.2)

            Path { path in
                path.move(to: CGPoint(x: -10, y: 165))
                path.addLines(StampCard.spaces + [StampCard.last])
            }
            .stroke(theme.trail, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            .opacity(0.9)
            ForEach(Array(theme.strokes.enumerated()), id: \.offset) { _, stroke in
                stroke.0.stroke(stroke.1, style: StrokeStyle(lineWidth: stroke.2, lineCap: .round, lineJoin: .round))
                    .opacity(0.9)
            }

            ForEach(Array(StampCard.spaces.enumerated()), id: \.offset) { index, point in
                Circle().fill(Palette.stampSpace).frame(width: 54, height: 54).position(point)
                if index < impressions.count {
                    StampMark(stamp: impressions[index].stamp, date: impressions[index].date)
                        .rotationEffect(.degrees(impressions[index].tilt))
                        .position(point)
                }
            }
            Image(sticker.shape).resizable().scaledToFit().foregroundStyle(Palette.stampSpace)
                .frame(width: 70, height: 70).position(StampCard.last)
            if hasSticker {
                StickerView(style: sticker, size: 68).rotationEffect(.degrees(-8)).position(StampCard.last)
            }
        }
        .frame(width: StampCard.size.width, height: StampCard.size.height)
        .clipShape(PaperEdge())
        .accessibilityElement()
        .accessibilityLabel("\(theme.name) card, \(impressions.count) of \(Stamp.perCard) stamps\(hasSticker ? ", with its shiny sticker" : "")")
    }
}

extension Palette {
    /// The blank spaces on a card. The same in light and dark: it is paper.
    static let stampSpace = Color(hex: 0xF4ECDA)
}

extension FamilyStore {
    /// A child's stamps in order, split into cards of five. The last may be part filled.
    func stampCards(for child: Child) -> [[Impression]] {
        let all = stickers(for: child).map(Impression.init)
        guard !all.isEmpty else { return [] }
        return stride(from: 0, to: all.count, by: Stamp.perCard).map { Array(all[$0..<min($0 + Stamp.perCard, all.count)]) }
    }
}
