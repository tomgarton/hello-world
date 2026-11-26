import SwiftUI

// The places in "One Boot", drawn for the board book (17 November 2026). The route and the places come from
// the ChatGPT world pack (handoff/ in the puggle-book repository): Puggle's house, the garden path past the logs, the digging
// patch and the big gum, Nan and Pop's, and the creek. Redrawn here the way the app's scenes are drawn: flat
// shapes, no outline, the scenes' own colours, and eastern Australian plants in place of the pack's tulips
// and daisies. Storyboard quality still: placed by eye, to be drawn properly once the pages are agreed.

/// A place in the book, drawn behind the cast and the flap.
enum BookPlace {
    /// Puggle's house from the garden: the round door, the bench for boots, the gate.
    case frontStep
    /// The garden by the back fence, with the log pile, and a corner of the house.
    case logs
    /// Further down the garden: the digging patch by the path.
    case hole
    /// The big gum where the path leaves the garden, with the creek far off.
    case tree
    /// Nan and Pop's from their garden: the green roof, the veranda and the washing line.
    case washing
    /// Nan and Pop's veranda, close: the rocking chair and the step.
    case veranda
    /// Nan and Pop's outdoor table.
    case table
    /// The path down to the creek, wet, with puddles.
    case path
    /// The creek and the picnic spot: paperbarks, the bridge, the stepping stones.
    case picnic
    /// Close in, on the picnic rug.
    case rug
    /// The creek's edge, at the shallows.
    case shallows

    func draw(_ context: inout GraphicsContext, _ size: CGSize) {
        var s = Sketch(context: context, w: size.width, h: size.height)
        switch self {
        case .frontStep: s.frontStep()
        case .logs: s.logs()
        case .hole: s.hole()
        case .tree: s.tree()
        case .washing: s.washing()
        case .veranda: s.veranda()
        case .table: s.table()
        case .path: s.path()
        case .picnic: s.picnic()
        case .rug: s.rug()
        case .shallows: s.shallows()
        }
    }
}

/// The colours of the places: the scenes' own, by day.
enum PlaceInk {
    static let sky = Color(hex: 0xBFD9F5)
    static let farHill = Color(hex: 0xB4CDAC)
    static let hill = Color(hex: 0xA9C79F)
    static let grass = Color(hex: 0xCFE5D2)
    static let lawn = Color(hex: 0xBFDDB9)
    static let bush = Color(hex: 0x9DBB98)
    static let bushDark = Color(hex: 0x86A882)
    static let path = Color(hex: 0xF1E3C2)
    static let wall = Color(hex: 0xFBF3E2)
    static let wallShade = Color(hex: 0xEFE2C9)
    static let coral = Color(hex: 0xD9735E)
    static let coralDark = Color(hex: 0xC25F4C)
    static let mustard = Color(hex: 0xE8B23A)
    static let glass = Color(hex: 0x9CC4E0)
    static let sage = Color(hex: 0x8FAE8B)
    static let sageDark = Color(hex: 0x7A9A77)
    static let greenDoor = Color(hex: 0x6E9A72)
    static let picket = Color(hex: 0xFFFDF6)
    static let wood = Color(hex: 0xA98A68)
    static let woodDark = Color(hex: 0x8C6E50)
    static let log = Color(hex: 0x9A6B45)
    static let logEnd = Color(hex: 0xD9B98A)
    static let earth = Color(hex: 0xB98A5E)
    static let water = Color(hex: 0x8DB8E8)
    static let waterDeep = Color(hex: 0x7AA8DE)
    static let foam = Color.white.opacity(0.7)
    static let stone = Color(hex: 0xC3BBAE)
    static let paperbark = Color(hex: 0xF2EADB)
    static let paperbarkSpot = Color(hex: 0xDCCBAE)
    static let bottlebrush = Color(hex: 0xE0533F)
    static let wattle = Color(hex: 0xF4BE2C)
    static let gumLeaf = Color(hex: 0x9DBB98)
    static let gumLeafLight = Color(hex: 0xB4CDAC)
}

/// Drawing in shares of the picture, so a place fits any page.
struct Sketch {
    var context: GraphicsContext
    let w: CGFloat
    let h: CGFloat

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
    func r(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect { CGRect(x: x * w, y: y * h, width: width * w, height: height * h) }

    func fill(_ path: Path, _ colour: Color) { context.fill(path, with: .color(colour)) }
    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ colour: Color, corner: CGFloat = 0) {
        fill(Path(roundedRect: r(x, y, width, height), cornerRadius: corner * w), colour)
    }
    func oval(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ colour: Color) {
        fill(Path(ellipseIn: r(x, y, width, height)), colour)
    }
    /// A circle, given its centre and its radius as a share of the width.
    func dot(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ colour: Color) {
        let c = p(x, y), rr = radius * w
        fill(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)), colour)
    }
    func shape(_ colour: Color, _ points: [(CGFloat, CGFloat)]) {
        var path = Path()
        path.addLines(points.map { p($0.0, $0.1) })
        path.closeSubpath()
        fill(path, colour)
    }

    // MARK: Ground and sky

    func sky() { fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), PlaceInk.sky) }

    /// A soft hill whose top is at `rise`, meeting the sides at `left` and `right`.
    func hill(_ rise: CGFloat, _ left: CGFloat, _ right: CGFloat, peak: CGFloat = 0.5, _ colour: Color) {
        fill(Hill(rise: rise, left: left, right: right, peak: peak).path(in: CGRect(x: 0, y: 0, width: w, height: h)), colour)
    }

    func cloud(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
        fill(CloudShape().path(in: CGRect(x: x * w, y: y * h, width: width * w, height: width * w * 0.5)), Color.white.opacity(0.85))
    }

    /// A row of round bushes, their tops at about `y`.
    func bushes(_ y: CGFloat, from: CGFloat = -0.05, to: CGFloat = 1.05, size: CGFloat = 0.16, seed: UInt64 = 3, _ colour: Color = PlaceInk.bush) {
        var random = SeededRandom(seed)
        var x = from
        while x < to {
            let d = size * CGFloat(random.range(0.8, 1.2))
            oval(x, y + CGFloat(random.range(0, 0.03)), d, d * 0.8 * w / h * 0.6, colour)
            x += d * 0.65
        }
    }

    /// Picket fence, the tops of the pickets at `top`, from `from` to `to`.
    func fence(top: CGFloat, height: CGFloat, from: CGFloat = 0, to: CGFloat = 1, _ colour: Color = PlaceInk.picket) {
        let board = 0.034, gap = 0.052
        var x = from
        while x < to - board * 0.5 {
            shape(colour, [(x, top + height), (x, top + 0.02), (x + board / 2, top), (x + board, top + 0.02), (x + board, top + height)])
            x += gap
        }
        rect(from, top + height * 0.3, to - from, 0.014, colour)
        rect(from, top + height * 0.72, to - from, 0.014, colour)
    }

    /// The cream path, winding from (`x0`, `y0`) at the back to the bottom, `wide` across at the front.
    func windingPath(_ x0: CGFloat, _ y0: CGFloat, to x1: CGFloat, wide: CGFloat, bend: CGFloat = 0.25) {
        var path = Path()
        let farHalf = wide * 0.18
        path.move(to: p(x0 - farHalf, y0))
        path.addCurve(to: p(x1 - wide / 2, 1.02), control1: p(x0 - farHalf + bend, y0 + 0.2), control2: p(x1 - wide / 2 - bend, 0.85))
        path.addLine(to: p(x1 + wide / 2, 1.02))
        path.addCurve(to: p(x0 + farHalf, y0), control1: p(x1 + wide / 2 - bend, 0.85), control2: p(x0 + farHalf + bend, y0 + 0.2))
        path.closeSubpath()
        fill(path, PlaceInk.path)
    }

    /// A tuft of long grass, or a clump of lomandra.
    func tuft(_ x: CGFloat, _ y: CGFloat, _ tall: CGFloat, _ colour: Color = PlaceInk.bushDark) {
        for lean in [-0.5, -0.2, 0.1, 0.4] as [CGFloat] {
            var blade = Path()
            blade.move(to: p(x - 0.008, y))
            blade.addQuadCurve(to: p(x + lean * tall * 0.6, y - tall), control: p(x + lean * tall * 0.1, y - tall * 0.6))
            blade.addQuadCurve(to: p(x + 0.008, y), control: p(x + lean * tall * 0.15 + 0.01, y - tall * 0.5))
            fill(blade, colour)
        }
    }

    /// A bottlebrush shrub: a round green bush with red brushes.
    func bottlebrush(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat) {
        oval(x - size / 2, y - size * 0.75 * w / h, size, size * 0.75 * w / h, PlaceInk.bushDark)
        var random = SeededRandom(UInt64(x * 1000) &+ 9)
        for _ in 0..<6 {
            let bx = x + CGFloat(random.range(-0.32, 0.32)) * size
            let by = y - CGFloat(random.range(0.25, 0.65)) * size * 0.75 * w / h
            fill(Path(roundedRect: CGRect(x: bx * w - 3, y: by * h - 7, width: 6, height: 14), cornerRadius: 3), PlaceInk.bottlebrush)
        }
    }

    /// A gum tree: a pale trunk that forks, and round clumps of leaves.
    func gum(_ x: CGFloat, base: CGFloat, top: CGFloat, spread: CGFloat, trunk: Color = PlaceInk.paperbark, spots: Bool = false) {
        let tall = base - top
        var stem = Path()
        stem.move(to: p(x - spread * 0.09, base))
        stem.addQuadCurve(to: p(x - spread * 0.02, top + tall * 0.42), control: p(x - spread * 0.1, base - tall * 0.3))
        stem.addLine(to: p(x - spread * 0.32, top + tall * 0.2))
        stem.addLine(to: p(x - spread * 0.26, top + tall * 0.17))
        stem.addLine(to: p(x + spread * 0.01, top + tall * 0.34))
        stem.addLine(to: p(x + spread * 0.26, top + tall * 0.15))
        stem.addLine(to: p(x + spread * 0.31, top + tall * 0.19))
        stem.addLine(to: p(x + spread * 0.04, top + tall * 0.44))
        stem.addQuadCurve(to: p(x + spread * 0.09, base), control: p(x + spread * 0.05, base - tall * 0.3))
        stem.closeSubpath()
        fill(stem, trunk)
        if spots {
            for (dx, dy) in [(-0.03, 0.62), (0.03, 0.76), (-0.02, 0.88), (0.02, 0.52)] as [(CGFloat, CGFloat)] {
                oval(x + dx * spread * 3 - 0.015, top + tall * dy, 0.03, 0.05, PlaceInk.paperbarkSpot)
            }
        }
        let clumps: [(CGFloat, CGFloat, CGFloat, Bool)] = [(-0.3, 0.12, 0.36, false), (0.3, 0.1, 0.36, false), (0, 0.0, 0.42, true), (-0.12, 0.2, 0.3, false), (0.16, 0.22, 0.28, true)]
        for (dx, dy, d, light) in clumps {
            let cw = d * spread * 1.4
            oval(x + dx * spread - cw / 2, top + dy * tall - cw * 0.3 * w / h, cw, cw * 0.62 * w / h, light ? PlaceInk.gumLeafLight : PlaceInk.gumLeaf)
        }
    }

    /// A house with a pitched roof. `roof` and `wall` colours, a door of `door` colour.
    func house(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, roof: Color, roofTall: CGFloat, overhang: CGFloat = 0.03) {
        rect(x, y, width, height, PlaceInk.wall)
        shape(roof, [(x - overhang, y + 0.01), (x + width * 0.22, y - roofTall), (x + width * 0.78, y - roofTall), (x + width + overhang, y + 0.01)])
    }

    // MARK: The places

    /// Puggle's house: a cream house with a coral roof, a round window with mustard curtains, the round door
    /// with the bench beside it, and the white gate where the path starts.
    mutating func frontStep() {
        sky()
        cloud(0.62, 0.06, 0.24)
        hill(0.32, 0.5, 0.42, peak: 0.75, PlaceInk.farHill)
        bushes(0.44, from: 0.6, to: 1.05, size: 0.18, seed: 11)
        // The house, filling the left.
        let hx: CGFloat = 0.04, hy: CGFloat = 0.36, hw: CGFloat = 0.6, hh: CGFloat = 0.42
        rect(hx, hy, hw, hh, PlaceInk.wall)
        shape(PlaceInk.coral, [(hx - 0.05, hy + 0.02), (hx + hw * 0.5, hy - 0.26), (hx + hw + 0.05, hy + 0.02)])
        // The round window up in the roof.
        dot(hx + hw * 0.5, hy - 0.06, 0.05, PlaceInk.wall)
        dot(hx + hw * 0.5, hy - 0.06, 0.038, PlaceInk.glass)
        // A side window with mustard curtains.
        rect(hx + 0.06, hy + 0.08, 0.13, 0.15, PlaceInk.glass, corner: 0.012)
        rect(hx + 0.06, hy + 0.08, 0.035, 0.15, PlaceInk.mustard, corner: 0.01)
        rect(hx + 0.155, hy + 0.08, 0.035, 0.15, PlaceInk.mustard, corner: 0.01)
        // The round coral door, and its step.
        let dx = hx + hw * 0.6, dw: CGFloat = 0.15
        var door = Path()
        door.addRoundedRect(in: r(dx, hy + 0.1, dw, hh - 0.1), cornerSize: CGSize(width: dw * w / 2, height: dw * w / 2))
        fill(door, PlaceInk.coral)
        dot(dx + dw * 0.78, hy + 0.27, 0.008, PlaceInk.mustard)
        rect(dx - 0.02, hy + hh - 0.005, dw + 0.04, 0.03, PlaceInk.wallShade, corner: 0.006)
        // The bench by the door, for boots.
        rect(hx + 0.24, hy + 0.27, 0.12, 0.018, PlaceInk.wood, corner: 0.005)
        rect(hx + 0.25, hy + 0.288, 0.012, 0.12, PlaceInk.woodDark)
        rect(hx + 0.338, hy + 0.288, 0.012, 0.12, PlaceInk.woodDark)
        // The lawn, the fence and the gate.
        fill(Path(CGRect(x: 0, y: (hy + hh) * h, width: w, height: h)), PlaceInk.grass)
        fence(top: 0.55, height: 0.2, from: 0.66, to: 1.02)
        windingPath(0.82, 0.76, to: 0.62, wide: 0.42, bend: 0.12)
        bottlebrush(0.12, 0.92, 0.2)
        tuft(0.95, 0.98, 0.1)
    }

    /// The back of the garden: the log pile against the fence, the corner of the house, the gum behind.
    mutating func logs() {
        sky()
        cloud(0.08, 0.08, 0.22)
        hill(0.36, 0.5, 0.44, peak: 0.3, PlaceInk.farHill)
        bushes(0.42, size: 0.17, seed: 5)
        fill(Path(CGRect(x: 0, y: 0.56 * h, width: w, height: h)), PlaceInk.grass)
        fence(top: 0.42, height: 0.18, from: 0, to: 0.84)
        // A corner of the house: the wall and the coral roof, on the right.
        rect(0.84, 0.3, 0.2, 0.42, PlaceInk.wall)
        shape(PlaceInk.coral, [(0.8, 0.32), (0.92, 0.2), (1.05, 0.2), (1.05, 0.32)])
        rect(0.9, 0.42, 0.12, 0.14, PlaceInk.glass, corner: 0.01)
        rect(0.9, 0.42, 0.035, 0.14, PlaceInk.mustard, corner: 0.008)
        windingPath(0.06, 0.6, to: 0.14, wide: 0.34, bend: 0.06)
        // Where the logs sit: a little bare earth.
        oval(0.24, 0.66, 0.56, 0.1, PlaceInk.lawn)
        tuft(0.86, 0.96, 0.1)
        bottlebrush(0.78, 0.98, 0.16)
    }

    /// Down the garden: the digging patch beside the path, and a wattle by the fence.
    mutating func hole() {
        sky()
        cloud(0.66, 0.06, 0.2)
        hill(0.3, 0.46, 0.5, peak: 0.6, PlaceInk.farHill)
        bushes(0.4, size: 0.18, seed: 7)
        fill(Path(CGRect(x: 0, y: 0.54 * h, width: w, height: h)), PlaceInk.grass)
        fence(top: 0.4, height: 0.18, from: -0.02, to: 1.02)
        // A wattle, in flower.
        gum(0.84, base: 0.6, top: 0.18, spread: 0.3, trunk: PlaceInk.woodDark)
        var random = SeededRandom(21)
        for _ in 0..<16 { dot(CGFloat(random.range(0.72, 0.97)), CGFloat(random.range(0.12, 0.3)), 0.012, PlaceInk.wattle) }
        windingPath(0.86, 0.6, to: 0.86, wide: 0.3, bend: -0.05)
        // The bare earth round the hole.
        oval(0.1, 0.62, 0.62, 0.3, PlaceInk.lawn)
        tuft(0.08, 0.97, 0.1)
    }

    /// The big gum where the garden ends. Past it, far off, the creek.
    mutating func tree() {
        sky()
        cloud(0.62, 0.08, 0.22)
        hill(0.38, 0.5, 0.46, peak: 0.7, PlaceInk.farHill)
        // The creek, far off, between the hills.
        var creek = Path()
        creek.move(to: p(0.5, 0.56))
        creek.addCurve(to: p(1.02, 0.5), control1: p(0.7, 0.6), control2: p(0.8, 0.48))
        creek.addLine(to: p(1.02, 0.55))
        creek.addCurve(to: p(0.5, 0.6), control1: p(0.8, 0.54), control2: p(0.7, 0.66))
        creek.closeSubpath()
        hill(0.5, 0.58, 0.54, peak: 0.6, PlaceInk.hill)
        fill(creek, PlaceInk.water)
        fill(Path(CGRect(x: 0, y: 0.66 * h, width: w, height: h)), PlaceInk.grass)
        hill(0.6, 0.7, 0.66, peak: 0.4, PlaceInk.grass)
        // The big gum: tall, pale, with long strips of bark.
        gum(0.36, base: 0.92, top: 0.14, spread: 0.7, trunk: PlaceInk.paperbark, spots: true)
        windingPath(0.7, 0.64, to: 0.86, wide: 0.3, bend: 0.06)
        tuft(0.06, 0.98, 0.12)
    }

    /// Nan and Pop's: a cream house with a green roof and a veranda, the washing line out the front.
    mutating func washing() {
        sky()
        cloud(0.7, 0.04, 0.22)
        hill(0.3, 0.42, 0.38, peak: 0.7, PlaceInk.farHill)
        bushes(0.32, from: 0.66, size: 0.16, seed: 13)
        nanAndPops(x: 0.04, y: 0.3, width: 0.62, height: 0.24)
        fill(Path(CGRect(x: 0, y: 0.54 * h, width: w, height: h)), PlaceInk.grass)
        // The washing line: two posts and a line that sags.
        let left = p(0.1, 0.34), right = p(0.94, 0.34), dip = p(0.52, 0.42)
        rect(0.09, 0.34, 0.016, 0.5, PlaceInk.wood, corner: 0.006)
        rect(0.93, 0.34, 0.016, 0.5, PlaceInk.wood, corner: 0.006)
        var line = Path()
        line.move(to: left)
        line.addQuadCurve(to: right, control: dip)
        context.stroke(line, with: .color(PlaceInk.woodDark), lineWidth: 1.4)
        // A pillowcase and a sock already pegged.
        rect(0.16, 0.355, 0.1, 0.12, PlaceInk.wall, corner: 0.01)
        rect(0.78, 0.36, 0.04, 0.09, PlaceInk.glass, corner: 0.01)
        // The vegetable bed.
        rect(0.6, 0.8, 0.36, 0.08, PlaceInk.wood, corner: 0.01)
        for i in 0..<4 { oval(0.61 + CGFloat(i) * 0.085, 0.74, 0.08, 0.08, PlaceInk.bushDark) }
        tuft(0.05, 0.98, 0.1)
    }

    /// The green-roofed house, its veranda, the green door and the mustard curtains.
    func nanAndPops(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        rect(x, y, width, height, PlaceInk.wall)
        // Main roof, then the veranda roof below it.
        shape(PlaceInk.sage, [(x - 0.02, y - 0.02), (x + width * 0.18, y - 0.16), (x + width * 0.82, y - 0.16), (x + width + 0.02, y - 0.02)])
        rect(x - 0.03, y - 0.03, width + 0.06, 0.04, PlaceInk.sageDark, corner: 0.006)
        // The chimney.
        rect(x + width * 0.62, y - 0.22, 0.05, 0.08, PlaceInk.coral)
        // Veranda posts.
        for i in 0..<4 { rect(x + width * CGFloat(i) / 3 - (i == 3 ? 0.014 : 0), y + 0.01, 0.014, height - 0.01, PlaceInk.picket) }
        // Windows with mustard curtains, and the green door.
        for wx in [x + width * 0.1, x + width * 0.7] {
            rect(wx, y + 0.05, width * 0.18, height * 0.42, PlaceInk.glass, corner: 0.008)
            rect(wx, y + 0.05, width * 0.05, height * 0.42, PlaceInk.mustard, corner: 0.006)
            rect(wx + width * 0.13, y + 0.05, width * 0.05, height * 0.42, PlaceInk.mustard, corner: 0.006)
        }
        rect(x + width * 0.43, y + 0.04, width * 0.14, height - 0.04, PlaceInk.greenDoor, corner: 0.01)
        // The veranda floor.
        rect(x - 0.02, y + height - 0.01, width + 0.04, 0.025, PlaceInk.wood, corner: 0.004)
    }

    /// On Nan and Pop's veranda, close: the boards, a post, the rocking chair, the step down.
    mutating func veranda() {
        rect(0, 0, 1, 0.62, PlaceInk.wall)
        // Weatherboards.
        for i in 0..<7 { rect(0, 0.06 + CGFloat(i) * 0.085, 1, 0.006, PlaceInk.wallShade) }
        // The window, with its curtains.
        rect(0.08, 0.1, 0.3, 0.3, PlaceInk.glass, corner: 0.01)
        rect(0.08, 0.1, 0.08, 0.3, PlaceInk.mustard, corner: 0.008)
        rect(0.3, 0.1, 0.08, 0.3, PlaceInk.mustard, corner: 0.008)
        // The green door, half in.
        rect(0.84, 0.08, 0.2, 0.54, PlaceInk.greenDoor, corner: 0.012)
        // The veranda floor and the step.
        rect(0, 0.62, 1, 0.38, PlaceInk.wood)
        for i in 0..<5 { rect(0, 0.66 + CGFloat(i) * 0.07, 1, 0.006, PlaceInk.woodDark.opacity(0.5)) }
        rect(0, 0.92, 1, 0.08, PlaceInk.woodDark)
        // A post, and a pot of waratah.
        rect(0.68, 0, 0.04, 0.62, PlaceInk.picket)
        shape(PlaceInk.coralDark, [(0.74, 0.62), (0.76, 0.52), (0.84, 0.52), (0.86, 0.62)])
        oval(0.75, 0.42, 0.1, 0.1, PlaceInk.bushDark)
        dot(0.8, 0.43, 0.02, PlaceInk.bottlebrush)
        // The rocking chair.
        rect(0.44, 0.3, 0.02, 0.32, PlaceInk.woodDark)
        rect(0.6, 0.3, 0.02, 0.32, PlaceInk.woodDark)
        for i in 0..<3 { rect(0.44, 0.33 + CGFloat(i) * 0.06, 0.18, 0.018, PlaceInk.wood) }
        rect(0.42, 0.52, 0.24, 0.03, PlaceInk.wood, corner: 0.006)
        var rocker = Path()
        rocker.move(to: p(0.4, 0.62))
        rocker.addQuadCurve(to: p(0.68, 0.62), control: p(0.54, 0.69))
        context.stroke(rocker, with: .color(PlaceInk.woodDark), lineWidth: 4)
    }

    /// Nan and Pop's outdoor table, out in the garden.
    mutating func table() {
        sky()
        cloud(0.1, 0.06, 0.2)
        hill(0.34, 0.5, 0.42, peak: 0.6, PlaceInk.farHill)
        bushes(0.38, size: 0.17, seed: 17)
        fill(Path(CGRect(x: 0, y: 0.5 * h, width: w, height: h)), PlaceInk.grass)
        // A corner of the house, with the green roof.
        rect(-0.02, 0.18, 0.24, 0.36, PlaceInk.wall)
        shape(PlaceInk.sage, [(-0.04, 0.2), (0.0, 0.1), (0.26, 0.1), (0.28, 0.2)])
        rect(0.06, 0.26, 0.1, 0.12, PlaceInk.glass, corner: 0.008)
        // The table: a long top, a bench in front, legs splayed.
        rect(0.12, 0.6, 0.8, 0.05, PlaceInk.wood, corner: 0.01)
        shape(PlaceInk.woodDark, [(0.2, 0.65), (0.24, 0.65), (0.2, 0.86), (0.16, 0.86)])
        shape(PlaceInk.woodDark, [(0.8, 0.65), (0.84, 0.65), (0.88, 0.86), (0.84, 0.86)])
        rect(0.06, 0.78, 0.9, 0.035, PlaceInk.wood, corner: 0.008)
        // The cloth, a little check.
        rect(0.3, 0.585, 0.44, 0.03, PlaceInk.coral.opacity(0.75), corner: 0.006)
        tuft(0.04, 0.98, 0.1)
    }

    /// The path down to the creek after the rain, puddles all along it.
    mutating func path() {
        sky()
        cloud(0.18, 0.05, 0.22)
        cloud(0.7, 0.1, 0.16)
        hill(0.3, 0.44, 0.4, peak: 0.3, PlaceInk.farHill)
        // Nan and Pop's, small, behind.
        nanAndPops(x: 0.06, y: 0.34, width: 0.18, height: 0.08)
        fill(Path(CGRect(x: 0, y: 0.44 * h, width: w, height: h)), PlaceInk.grass)
        // The creek ahead, on the right.
        var creek = Path()
        creek.move(to: p(0.66, 0.44))
        creek.addQuadCurve(to: p(1.02, 0.5), control: p(0.86, 0.42))
        creek.addLine(to: p(1.02, 0.58))
        creek.addQuadCurve(to: p(0.66, 0.46), control: p(0.84, 0.5))
        creek.closeSubpath()
        fill(creek, PlaceInk.water)
        // The path, across and down.
        var road = Path()
        road.move(to: p(-0.02, 0.62))
        road.addCurve(to: p(1.02, 0.66), control1: p(0.3, 0.56), control2: p(0.7, 0.72))
        road.addLine(to: p(1.02, 0.94))
        road.addCurve(to: p(-0.02, 0.88), control1: p(0.7, 1.0), control2: p(0.3, 0.82))
        road.closeSubpath()
        fill(road, PlaceInk.path)
        for (x, y, d) in [(0.16, 0.74, 0.16), (0.46, 0.79, 0.2), (0.78, 0.82, 0.16)] as [(CGFloat, CGFloat, CGFloat)] {
            oval(x - d / 2, y, d, d * 0.22, PlaceInk.water)
            oval(x - d / 4, y + d * 0.04, d * 0.3, d * 0.05, PlaceInk.foam)
        }
        gum(0.9, base: 0.46, top: 0.12, spread: 0.24, trunk: PlaceInk.paperbark)
        tuft(0.05, 0.99, 0.1)
        tuft(0.95, 0.99, 0.08)
    }

    /// The creek at the picnic spot: paperbarks, the low bridge, the stepping stones, a rug on the grass.
    mutating func picnic() {
        sky()
        cloud(0.5, 0.04, 0.2)
        hill(0.3, 0.46, 0.42, peak: 0.55, PlaceInk.farHill)
        hill(0.42, 0.52, 0.5, peak: 0.3, PlaceInk.hill)
        // The creek, coming from the back and widening to the right.
        var creek = Path()
        creek.move(to: p(0.5, 0.48))
        creek.addCurve(to: p(1.02, 0.66), control1: p(0.62, 0.56), control2: p(0.8, 0.56))
        creek.addLine(to: p(1.02, 1.02))
        creek.addLine(to: p(0.62, 1.02))
        creek.addCurve(to: p(0.44, 0.48), control1: p(0.6, 0.8), control2: p(0.42, 0.6))
        creek.closeSubpath()
        fill(Path(CGRect(x: 0, y: 0.5 * h, width: w, height: h)), PlaceInk.grass)
        fill(creek, PlaceInk.water)
        // The low bridge, far off.
        var bridge = Path()
        bridge.move(to: p(0.38, 0.53))
        bridge.addQuadCurve(to: p(0.64, 0.53), control: p(0.51, 0.47))
        context.stroke(bridge, with: .color(PlaceInk.wood), lineWidth: 5)
        rect(0.4, 0.47, 0.008, 0.06, PlaceInk.picket)
        rect(0.505, 0.46, 0.008, 0.05, PlaceInk.picket)
        rect(0.61, 0.47, 0.008, 0.06, PlaceInk.picket)
        // Stepping stones.
        for (x, y, d) in [(0.62, 0.66, 0.08), (0.72, 0.74, 0.1), (0.84, 0.83, 0.11), (0.95, 0.93, 0.12)] as [(CGFloat, CGFloat, CGFloat)] {
            oval(x - d / 2, y, d, d * 0.35, PlaceInk.stone)
        }
        // Ripples.
        for (x, y) in [(0.7, 0.62), (0.86, 0.7), (0.78, 0.92)] as [(CGFloat, CGFloat)] { rect(x, y, 0.06, 0.008, PlaceInk.foam, corner: 0.004) }
        // Paperbarks either side.
        gum(0.1, base: 0.82, top: 0.02, spread: 0.36, trunk: PlaceInk.paperbark, spots: true)
        gum(0.94, base: 0.56, top: 0.06, spread: 0.3, trunk: PlaceInk.paperbark, spots: true)
        // The picnic rug, a red check, with the basket on it.
        oval(0.04, 0.8, 0.5, 0.16, PlaceInk.coral)
        for i in 0..<4 { rect(0.1 + CGFloat(i) * 0.1, 0.81, 0.04, 0.14, Color.white.opacity(0.5)) }
        tuft(0.5, 0.98, 0.12)
        tuft(0.04, 0.98, 0.1)
    }

    /// Close in on the rug, by the water.
    mutating func rug() {
        sky()
        hill(0.24, 0.36, 0.3, peak: 0.4, PlaceInk.farHill)
        fill(Path(CGRect(x: 0, y: 0.34 * h, width: w, height: h)), PlaceInk.water)
        for (x, y) in [(0.2, 0.4), (0.6, 0.38), (0.8, 0.44)] as [(CGFloat, CGFloat)] { rect(x, y, 0.08, 0.008, PlaceInk.foam, corner: 0.004) }
        hill(0.5, 0.56, 0.5, peak: 0.6, PlaceInk.grass)
        fill(Path(CGRect(x: 0, y: 0.56 * h, width: w, height: h)), PlaceInk.grass)
        // The rug, from above: a blue check.
        rect(0.06, 0.72, 0.88, 0.24, PlaceInk.glass, corner: 0.02)
        for i in 0..<6 { rect(0.06 + CGFloat(i) * 0.16, 0.72, 0.06, 0.24, Color.white.opacity(0.35)) }
        tuft(0.04, 0.72, 0.1)
        tuft(0.96, 0.72, 0.1)
    }

    /// The edge of the creek at the shallows: still water, a stone, the bank.
    mutating func shallows() {
        sky()
        cloud(0.14, 0.06, 0.24)
        hill(0.3, 0.42, 0.38, peak: 0.6, PlaceInk.farHill)
        fill(Path(CGRect(x: 0, y: 0.42 * h, width: w, height: h)), PlaceInk.water)
        fill(Path(CGRect(x: 0, y: 0.7 * h, width: w, height: h)), PlaceInk.waterDeep.opacity(0.35))
        for (x, y, l) in [(0.12, 0.5, 0.1), (0.66, 0.48, 0.14), (0.34, 0.6, 0.08), (0.8, 0.62, 0.1)] as [(CGFloat, CGFloat, CGFloat)] {
            rect(x, y, l, 0.008, PlaceInk.foam, corner: 0.004)
        }
        // The bank on the left, where the boots are.
        var bank = Path()
        bank.move(to: p(-0.02, 0.62))
        bank.addQuadCurve(to: p(0.3, 1.02), control: p(0.26, 0.66))
        bank.addLine(to: p(-0.02, 1.02))
        bank.closeSubpath()
        fill(bank, PlaceInk.path)
        gum(0.88, base: 0.46, top: 0.04, spread: 0.3, trunk: PlaceInk.paperbark, spots: true)
        oval(0.78, 0.84, 0.14, 0.05, PlaceInk.stone)
        tuft(0.06, 0.66, 0.1)
        // Splash: where Puggle stands, a ring and drops thrown up.
        context.stroke(Path(ellipseIn: r(0.4, 0.86, 0.36, 0.08)), with: .color(PlaceInk.foam), lineWidth: 2.5)
        for (x, y, d) in [(0.4, 0.78, 0.014), (0.46, 0.72, 0.018), (0.74, 0.74, 0.016), (0.79, 0.8, 0.012), (0.36, 0.84, 0.01)] as [(CGFloat, CGFloat, CGFloat)] {
            dot(x, y, d, Color.white)
        }
    }
}

// MARK: The flaps in One Boot

/// What a flap is in the book, as the pack lists them: six raised pieces of card stuck on top of the page,
/// and the dirt, cut into the page, with a notch for a finger.
enum FlapArt {
    case logs, dirt, leaves, towel, hat, lid, blanket

    /// Raised flaps sit on top of the page; the dirt is cut into it.
    var raised: Bool { self != .dirt }

    /// What is printed under it, where that is not the page itself: inside the tin, inside the basket.
    var inside: Color? {
        switch self {
        case .lid: Color(hex: 0x1F4E96)
        case .blanket: Color(hex: 0xC9A06A)
        default: nil
        }
    }

    var shape: FlapShape {
        switch self {
        case .logs: .logs
        case .dirt: .dirt
        case .leaves: .blob
        case .towel: .rounded
        case .hat: .hat
        case .lid: .rounded
        case .blanket: .blanket
        }
    }

    /// The flap's face: the piece of the picture that lifts.
    func front(_ context: inout GraphicsContext, _ size: CGSize) {
        let s = Sketch(context: context, w: size.width, h: size.height)
        switch self {
        case .logs:
            // Six logs, ends out, stacked three, two and one.
            for circle in LogPile.circles(in: CGRect(origin: .zero, size: size)) {
                s.fill(Path(ellipseIn: circle), PlaceInk.log)
                s.fill(Path(ellipseIn: circle.insetBy(dx: circle.width * 0.14, dy: circle.width * 0.14)), PlaceInk.logEnd)
                s.fill(Path(ellipseIn: circle.insetBy(dx: circle.width * 0.36, dy: circle.width * 0.36)), PlaceInk.log.opacity(0.35))
            }
        case .dirt:
            s.oval(0, 0, 1, 1, PlaceInk.earth)
            for (x, y) in [(0.3, 0.3), (0.6, 0.5), (0.4, 0.66), (0.72, 0.28)] as [(CGFloat, CGFloat)] {
                s.oval(x, y, 0.08, 0.06, Color(hex: 0xA77A50))
            }
        case .leaves:
            s.fill(FlapShape.blob.path(in: CGRect(origin: .zero, size: size)), PlaceInk.gumLeaf)
            s.oval(0.36, 0.06, 0.4, 0.4, PlaceInk.gumLeafLight)
        case .towel:
            s.rect(0, 0, 1, 1, PlaceInk.coral)
            for i in 0..<4 { s.rect(0.08 + CGFloat(i) * 0.24, 0, 0.1, 1, Color.white.opacity(0.7)) }
            // The pegs that hold it on the line.
            s.rect(0.12, -0.02, 0.06, 0.16, PlaceInk.wood, corner: 0.02)
            s.rect(0.82, -0.02, 0.06, 0.16, PlaceInk.wood, corner: 0.02)
        case .hat:
            s.fill(FlapShape.hat.path(in: CGRect(origin: .zero, size: size)), Color(hex: 0xD8B77A))
            s.rect(0.24, 0.5, 0.52, 0.1, Color(hex: 0x8C6E50))
        case .lid:
            s.rect(0, 0, 1, 1, Color(hex: 0x2A62B8), corner: 0.12)
            s.rect(0.08, 0.2, 0.84, 0.6, Color(hex: 0x3A74C8), corner: 0.1)
            s.dot(0.5, 0.5, 0.08, PlaceInk.mustard)
        case .blanket:
            s.fill(FlapShape.blanket.path(in: CGRect(origin: .zero, size: size)), Color(hex: 0xC9D7F2))
            for i in 0..<5 { s.rect(0.06 + CGFloat(i) * 0.2, 0.1, 0.07, 0.8, Color.white.opacity(0.45)) }
        }
    }
}

/// Where the logs in a pile go: three along the bottom, two on them, one on top.
enum LogPile {
    static func circles(in rect: CGRect) -> [CGRect] {
        let d = min(rect.width / 3, rect.height / 2.74)
        let left = rect.midX - d * 1.5, bottom = rect.maxY
        var out: [CGRect] = []
        for (row, count) in [(0, 3), (1, 2), (2, 1)] {
            for i in 0..<count {
                let x = left + d * (CGFloat(i) + CGFloat(row) * 0.5)
                let y = bottom - d - CGFloat(row) * d * 0.87
                out.append(CGRect(x: x, y: y, width: d, height: d))
            }
        }
        return out
    }
}

extension FlapShape {
    static func extraPath(_ shape: FlapShape, in rect: CGRect) -> Path? {
        let w = rect.width, h = rect.height
        switch shape {
        case .logs:
            return LogPile.circles(in: rect).reduce(Path()) { $0.union(Path(ellipseIn: $1)) }
        case .dirt:
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + w * 0.04, y: rect.midY))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.12), control2: CGPoint(x: rect.minX + w * 0.24, y: rect.minY))
            path.addCurve(to: CGPoint(x: rect.maxX - w * 0.02, y: rect.midY + h * 0.06), control1: CGPoint(x: rect.maxX - w * 0.2, y: rect.minY), control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.2))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX - w * 0.04, y: rect.maxY - h * 0.08), control2: CGPoint(x: rect.maxX - w * 0.26, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.minX + w * 0.04, y: rect.midY), control1: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY), control2: CGPoint(x: rect.minX, y: rect.maxY - h * 0.12))
            path.closeSubpath()
            return path
        case .hat:
            var path = Path(ellipseIn: CGRect(x: rect.minX, y: rect.minY + h * 0.56, width: w, height: h * 0.44))
            path = path.union(Path(roundedRect: CGRect(x: rect.minX + w * 0.22, y: rect.minY, width: w * 0.56, height: h * 0.8),
                                   cornerSize: CGSize(width: w * 0.24, height: h * 0.5), style: .continuous))
            return path
        case .blanket:
            return Path(roundedRect: rect, cornerSize: CGSize(width: w * 0.3, height: h * 0.45), style: .continuous)
        default:
            return nil
        }
    }
}
