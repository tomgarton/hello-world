import SwiftUI

// Puggle's repeat patterns: the brand's eight soft shapes, evenly spaced, large and all one size,
// tone on tone on a soft field. Designed in docs/tools/make_patterns.py; this draws the same tiles.
// In dark mode and the night look each field is deep and muted. Nothing is dark in light mode.

/// The soft fields a pattern comes in.
enum PatternColour: Int, CaseIterable {
    case sun, sky, shell, mint, lilac, sand, rose, sea

    /// The field, then shapes a little darker (d), darker again (dd), and lighter (l).
    private var light: [UInt32] {
        switch self {
        case .sun: [0xF4E7B0, 0xEDDB93, 0xE6CF78, 0xFAF1CC]
        case .sky: [0xBFD9F5, 0xABCBEE, 0x97BCE6, 0xD5E6F9]
        case .shell: [0xF3D9C9, 0xECC9B5, 0xE4B89F, 0xF9E7DC]
        case .mint: [0xCFE5D2, 0xBBD9BF, 0xA6CCAB, 0xE0EFE2]
        case .lilac: [0xE0D3EE, 0xD2C2E6, 0xC3B0DC, 0xECE3F5]
        case .sand: [0xEFE7D4, 0xE4D9C0, 0xD8CBAC, 0xF8F2E4]
        case .rose: [0xF6CFDC, 0xEFBDCD, 0xE7A9BD, 0xFAE1E9]
        case .sea: [0xC4E6E4, 0xAFDAD7, 0x99CDC9, 0xDAF0EE]
        }
    }

    /// Deep and muted, with shapes a little lighter, lighter again, and deeper.
    private var dark: [UInt32] {
        switch self {
        case .sun: [0x3A3116, 0x483D1D, 0x584B25, 0x2F2811]
        case .sky: [0x1C2B42, 0x253752, 0x304564, 0x162338]
        case .shell: [0x3F2A20, 0x4D3428, 0x5C4032, 0x34221A]
        case .mint: [0x1E3226, 0x283F30, 0x334E3C, 0x182A1F]
        case .lilac: [0x2B2440, 0x372E50, 0x453A62, 0x231D35]
        case .sand: [0x2A2420, 0x352E29, 0x413932, 0x221D19]
        case .rose: [0x3F2630, 0x4E303C, 0x5E3B49, 0x341F28]
        case .sea: [0x1B3331, 0x24403E, 0x2E4F4C, 0x162B29]
        }
    }

    func tones(dark isDark: Bool) -> [Color] { (isDark ? dark : light).map { Color(hex: $0) } }

    /// The field that goes with a child's colour, in the order of `Palette.childColours`.
    static func forChild(_ index: Int) -> PatternColour {
        [.sky, .shell, .mint, .sun, .lilac, .rose, .sea, .sand][index % 8]
    }
}

/// One repeat: a tile, and the shapes on it.
struct PatternTile {
    struct Mark {
        var shape: String
        var x: CGFloat, y: CGFloat
        /// Times the shape's own 24-point box.
        var size: CGFloat
        /// Degrees.
        var turn: CGFloat = 0
        /// 1 a little darker, 2 darker again, 3 lighter.
        var tone: Int = 1
    }

    var width: CGFloat, height: CGFloat
    var marks: [Mark]

    /// A shape at every corner of a square grid and another in the middle of every square, so each is the same
    /// distance from its neighbours.
    static func lattice(cell: CGFloat, corners: [String], middles: [String], size: CGFloat, middleSize: CGFloat? = nil,
                        turns: (CGFloat, CGFloat) = (0, 0), cols: Int = 1, rows: Int = 1) -> PatternTile {
        var marks: [Mark] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let i = c + r * 2
                marks.append(Mark(shape: corners[i % corners.count], x: CGFloat(c) * cell, y: CGFloat(r) * cell, size: size, turn: turns.0, tone: 1))
                marks.append(Mark(shape: middles[i % middles.count], x: CGFloat(c) * cell + cell / 2, y: CGFloat(r) * cell + cell / 2,
                                  size: middleSize ?? size, turn: turns.1, tone: 3))
            }
        }
        return PatternTile(width: cell * CGFloat(cols), height: cell * CGFloat(rows), marks: marks)
    }

    /// All eight shapes in turn.
    static let mix = lattice(cell: 84, corners: ["quatrefoil", "pebble", "soft-square", "blossom"],
                             middles: ["pill", "soft-hexagon", "half-pill", "scallop"], size: 2.15, cols: 4, rows: 2)
    /// Pills lying down and standing up in turn.
    static let pills = lattice(cell: 84, corners: ["pill"], middles: ["pill"], size: 2.25, turns: (0, 90))
    /// Blossoms and pebbles in turn.
    static let bloom = lattice(cell: 84, corners: ["blossom"], middles: ["pebble"], size: 2.25)
    /// Quatrefoils, large and small in turn: the brand's stars.
    static let sparkle = lattice(cell: 84, corners: ["quatrefoil"], middles: ["quatrefoil"], size: 2.25, middleSize: 1.0)
    /// Soft hexagons set out like honeycomb, with clear gaps.
    static let comb: PatternTile = {
        var marks: [Mark] = []
        for (c, column) in [[1, 3, 1], [1, 1, 3], [3, 1, 1], [1, 3, 1]].enumerated() {
            for (r, tone) in column.enumerated() {
                marks.append(Mark(shape: "soft-hexagon", x: CGFloat(c) * 39, y: CGFloat(r) * 46 + (c % 2 == 1 ? 23 : 0), size: 2.2, tone: tone))
            }
        }
        return PatternTile(width: 156, height: 138, marks: marks)
    }()
    /// Soft squares in a check.
    static let check = PatternTile(width: 104, height: 104, marks: [
        Mark(shape: "soft-square", x: 26, y: 26, size: 2.5, tone: 1), Mark(shape: "soft-square", x: 78, y: 78, size: 2.5, tone: 1),
        Mark(shape: "soft-square", x: 78, y: 26, size: 2.5, tone: 3), Mark(shape: "soft-square", x: 26, y: 78, size: 2.5, tone: 3),
    ])
    /// Scallops in overlapping rows, each row drawn over the foot of the one above.
    static let scales = PatternTile(width: 57.6, height: 38, marks: [
        Mark(shape: "scallop", x: 0, y: 0, size: 3.2, tone: 1), Mark(shape: "scallop", x: 9.6, y: 19, size: 3.2, tone: 3),
    ])
}

/// A field of one pattern. It drifts slowly down and to the right, about six points a second, and rests while
/// `resting` is true, with Reduce Motion, and in the night look.
struct PatternField: View {
    let tile: PatternTile
    let colour: PatternColour
    var scale: CGFloat = 0.75
    var resting = false

    @Environment(\.colorScheme) private var scheme
    @Environment(\.puggleNight) private var night
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How far it has drifted, kept so that a rest does not make it jump.
    @State private var drifted: CGFloat = 0
    @State private var last: Date?

    var body: some View {
        let still = resting || reduceMotion || night
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { timeline in
            Canvas { context, size in
                draw(&context, size: size, drift: distance(at: timeline.date, still: still))
            }
        }
        .accessibilityHidden(true)
    }

    private func distance(at date: Date, still: Bool) -> CGFloat {
        // Canvas redraws on the main thread; the state is only a running total.
        DispatchQueue.main.async {
            if !still, let last { drifted += CGFloat(min(date.timeIntervalSince(last), 0.1)) * 6 }
            last = still ? nil : date
        }
        return drifted
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize, drift: CGFloat) {
        let dark = scheme == .dark || night
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(colour.tones(dark: dark)[0]))
        guard let image = PatternTile.image(tile, colour: colour, dark: dark, scale: scale) else { return }
        let w = image.size.width, h = image.size.height
        // Down and to the right along the tile's own diagonal, so one whole tile later it is where it began.
        let along = drift / hypot(w, h)
        let dx = (along * w).truncatingRemainder(dividingBy: w), dy = (along * h).truncatingRemainder(dividingBy: h)
        let resolved = context.resolve(Image(uiImage: image))
        for row in -1...Int(size.height / h) {
            for column in -1...Int(size.width / w) {
                context.draw(resolved, in: CGRect(x: CGFloat(column) * w + dx, y: CGFloat(row) * h + dy, width: w, height: h))
            }
        }
    }
}

extension PatternTile {
    private static var made: [String: UIImage] = [:]

    /// One tile as a picture, made once for each pattern, colour and look. It is a whole number of points each way,
    /// so tiles meet without a seam, and a shape that crosses an edge comes back in on the far side.
    static func image(_ tile: PatternTile, colour: PatternColour, dark: Bool, scale: CGFloat) -> UIImage? {
        let w = (tile.width * scale).rounded(), h = (tile.height * scale).rounded()
        let key = "\(tile.marks.count)-\(tile.marks.first?.shape ?? "")-\(tile.width)-\(colour.rawValue)-\(dark)-\(scale)"
        if let image = made[key] { return image }
        let sx = w / tile.width, sy = h / tile.height
        let tones = colour.tones(dark: dark).map { UIColor($0) }
        var shapes: [String: UIImage] = [:]
        // Top to bottom, so rows that overlap layer as they should.
        var places: [(mark: Mark, x: CGFloat, y: CGFloat)] = []
        for mark in tile.marks {
            for dx in [-tile.width, 0, tile.width] {
                for dy in [-tile.height, 0, tile.height] {
                    let reach = 14 * mark.size
                    let x = mark.x + dx, y = mark.y + dy
                    if x + reach < 0 || x - reach > tile.width || y + reach < 0 || y - reach > tile.height { continue }
                    places.append((mark, x, y))
                }
            }
        }
        places.sort { $0.y < $1.y }
        let image = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { renderer in
            tones[0].setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for place in places {
                let name = "\(place.mark.shape)-\(place.mark.tone)"
                guard let shape = shapes[name] ?? UIImage(named: "shape-\(place.mark.shape)")?
                    .withTintColor(tones[place.mark.tone], renderingMode: .alwaysOriginal) else { continue }
                shapes[name] = shape
                let side = 24 * place.mark.size
                let context = renderer.cgContext
                context.saveGState()
                context.translateBy(x: place.x * sx, y: place.y * sy)
                context.scaleBy(x: sx, y: sy)
                context.rotate(by: place.mark.turn * .pi / 180)
                shape.draw(in: CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
                context.restoreGState()
            }
        }
        made[key] = image
        return image
    }
}
