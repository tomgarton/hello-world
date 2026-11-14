import SwiftUI

/// Mock-ups for the refinements proposed in reports/Cartoon character craft for Puggle.md, drawn with
/// the real rigs so each shows what would actually change. Written by "-debugSheet 1"; nothing here
/// is used by the app itself.
@MainActor
enum RefinementSheets {
    private static let paper = Color(hex: 0xF2ECDD), ink = Color(hex: 0x3A2A20), note = Color(hex: 0x6B5E52)

    private static func state(r: Double = 0, x: Double = 0, y: Double = 0, sx: Double = 1, sy: Double = 1) -> PartState {
        var s = PartState()
        s.r = r; s.x = x; s.y = y; s.sx = sx; s.sy = sy
        return s
    }

    /// One drawing of a character in a pose, with a caption.
    private static func cell(_ rig: Rig, _ states: [String: PartState] = [:], face: [String: String]? = nil,
                             height: CGFloat = 170, caption: String = "", headOnly: Bool = false) -> some View {
        VStack(spacing: 6) {
            Group {
                if headOnly {
                    RigFrame(rig: rig, states: states, face: face)
                        .frame(width: height * 1.5, height: height * 1.5 * rig.size[1] / rig.size[0])
                        .frame(width: height * 1.5, height: height * 1.05, alignment: .top)
                        .clipped()
                } else {
                    RigFrame(rig: rig, states: states, face: face)
                        .frame(width: height * rig.size[0] / rig.size[1], height: height)
                }
            }
            if !caption.isEmpty {
                Text(caption).font(.system(size: 12, weight: .medium)).foregroundStyle(note)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).frame(width: headOnly ? height * 1.4 : 130)
            }
        }
    }

    private static func row(_ title: String, @ViewBuilder _ cells: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(ink)
            HStack(alignment: .bottom, spacing: 14) { cells() }
        }
    }

    private static func save(_ view: some View, as name: String) {
        let renderer = ImageRenderer(content: view.padding(24).background(paper).environment(\.lineStyle, .chosen))
        renderer.scale = 2
        guard let data = renderer.uiImage?.pngData() else { return }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        try? data.write(to: url)
    }

    /// The same character in solid ink: what is left when colour and face are taken away.
    private static func silhouette(_ rig: Rig) -> Rig {
        var copy = rig
        for part in copy.parts.indices {
            for shape in copy.parts[part].shapes.indices {
                if copy.parts[part].shapes[shape].fill != nil { copy.parts[part].shapes[shape].fill = "#3A2A20" }
                if copy.parts[part].shapes[shape].stroke != nil { copy.parts[part].shapes[shape].stroke = "#3A2A20" }
                copy.parts[part].shapes[shape].tint = copy.parts[part].shapes[shape].stroke == nil ? nil : "#3A2A20"
            }
        }
        return copy
    }

    static func writeAll() {
        guard let puggle = Rig.load("puggle") else { return }
        modelSheet(puggle)
        silhouettes(puggle)
        expressions(puggle)
        blink(puggle)
        eyesLead(puggle)
        hop(puggle)
        pair(puggle)
        tuftAndPoses(puggle)
        tuftOptions(puggle)
        heroes(puggle)
    }

    /// Puggle on a clear background, for covers and documents: standing, and waving.
    private static func heroes(_ puggle: Rig) {
        func write(_ name: String, _ states: [String: PartState], _ face: [String: String]?) {
            let renderer = ImageRenderer(content: RigFrame(rig: puggle, states: states, face: face).frame(width: 720, height: 900).environment(\.lineStyle, .chosen))
            renderer.scale = 2
            guard let data = renderer.uiImage?.pngData() else { return }
            try? data.write(to: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name))
        }
        write("hero-standing.png", [:], nil)
        write("hero-waving.png", ["arm-right": state(r: -80), "head": state(r: -5), "blush": state(sx: 1.14, sy: 1.14),
                                  "brow-left": state(r: -6, y: -4), "brow-right": state(r: 6, y: -4)], ["eyes": "happy", "brows": "on"])
    }

    // MARK: 8. A tuft of hair, and arms that bend

    private static let dark = "#3A2A20", fur = "#8A5A3C", furLine = "#5E3A24", sleeve = "#2A62B8", sleeveLine = "#1B4387"

    /// Ways to draw a tuft that is part of her head: the same fur and the same line, joined to it.
    /// Each sits left of centre, clear of her clip. `join` is where the fur covers the seam.
    private static let tufts: [(name: String, locks: [String], join: (CGFloat, CGFloat))] = [
        ("A. As it was: tall", ["M85 62 Q78 44 84 34 Q91 25 98 34 Q104 44 104 60 Z", "M100 58 Q98 36 106 25 Q114 16 120 26 Q125 38 121 56 Z",
                                "M117 58 Q121 42 128 35 Q137 29 140 38 Q141 48 133 60 Z"], (86, 131)),
        ("B. Shorter", ["M89 62 Q84 49 89 43 Q94 38 99 44 Q103 51 104 60 Z", "M101 58 Q100 44 107 37 Q114 32 119 39 Q123 46 121 56 Z",
                        "M118 58 Q121 49 127 45 Q134 42 136 47 Q137 53 132 60 Z"], (90, 130)),
        ("C. Two locks", ["M97 60 Q94 46 100 40 Q106 35 111 42 Q114 50 113 58 Z", "M110 58 Q112 47 119 42 Q126 39 128 45 Q129 52 124 58 Z"], (98, 123)),
        ("D. One lick, leaning", ["M103 58 Q99 44 107 37 Q118 31 124 39 Q117 40 116 47 Q116 53 120 57 Z"], (104, 119)),
        ("E. Low fluff", ["M91 60 Q89 49 97 47 Q106 47 106 58 Z", "M103 58 Q103 44 112 43 Q122 44 121 57 Z", "M118 58 Q119 48 127 48 Q135 50 134 60 Z"], (92, 132)),
    ]

    private static func withTuft(_ rig: Rig, _ style: Int = 0) -> Rig {
        var copy = rig
        guard let head = copy.parts.firstIndex(where: { $0.id == "head" }) else { return rig }
        let tuft = tufts[style]
        var locks = tuft.locks.map { Rig.Shape(kind: "path", d: $0, fill: fur, stroke: dark, tint: furLine, width: 7) }
        // Fur over the join, so the locks and the head read as one shape with one outline.
        let l = tuft.join.0, r = tuft.join.1
        locks.append(Rig.Shape(kind: "path", d: "M\(Int(l)) 58 Q\(Int((l + r) / 2)) 50 \(Int(r)) 57 L\(Int(r) + 2) 74 L\(Int(l) - 2) 74 Z", fill: fur))
        copy.parts[head].shapes.append(contentsOf: locks)
        return copy
    }

    /// Each tuft three ways: close up, as a solid shape, and at the sizes she appears in the app.
    private static func tuftOptions(_ puggle: Rig) {
        func column(_ title: String, _ rig: Rig) -> some View {
            VStack(spacing: 10) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(ink).frame(width: 190)
                RigFrame(rig: rig, states: [:]).frame(width: 260, height: 325)
                    .frame(width: 200, height: 200, alignment: .top).clipped()
                RigFrame(rig: silhouette(rig), states: [:]).frame(width: 260, height: 325)
                    .frame(width: 200, height: 150, alignment: .top).clipped()
                HStack(alignment: .bottom, spacing: 16) {
                    RigFrame(rig: rig, states: [:]).frame(width: 94, height: 118)
                    RigFrame(rig: rig, states: [:]).frame(width: 60, height: 75).frame(width: 44, height: 44, alignment: .top)
                        .background(Color(hex: 0xBFD9F5)).clipShape(Circle())
                }
                .frame(height: 122, alignment: .bottom)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 14) {
            Text("Tuft options. Top: close up. Middle: as a solid shape. Bottom: at the size she is on Today, and as a small round picture")
                .font(.system(size: 14, weight: .bold)).foregroundStyle(ink)
            HStack(alignment: .top, spacing: 12) {
                column("Now: no tuft", puggle)
                ForEach(tufts.indices, id: \.self) { index in column(tufts[index].name, withTuft(puggle, index)) }
            }
        }
        save(sheet, as: "refine-9-tuft-options.png")
    }

    /// An arm as one curve from the shoulder, through an elbow, to wherever the hand needs to be.
    private static func arm(from shoulder: CGPoint, elbow: CGPoint, hand: CGPoint) -> [Rig.Shape] {
        let dx = hand.x - elbow.x, dy = hand.y - elbow.y, length = max(hypot(dx, dy), 1)
        let ux = dx / length, uy = dy / length
        func point(_ p: CGPoint) -> String { "\(Double(p.x).formatted(.number.precision(.fractionLength(1)))) \(Double(p.y).formatted(.number.precision(.fractionLength(1))))" }
        let start = "M\(point(shoulder)) Q\(point(elbow)) "
        let short = CGPoint(x: hand.x - ux * 7, y: hand.y - uy * 7)
        let cuff = CGPoint(x: hand.x - ux * 14, y: hand.y - uy * 14)
        return [
            Rig.Shape(kind: "path", d: start + point(short), stroke: dark, tint: sleeveLine, width: 34, cap: "round"),
            Rig.Shape(kind: "path", d: start + point(hand), stroke: sleeve, width: 22, cap: "round"),
            Rig.Shape(kind: "path", d: "M\(point(CGPoint(x: cuff.x - uy * 11, y: cuff.y + ux * 11))) L\(point(CGPoint(x: cuff.x + uy * 11, y: cuff.y - ux * 11)))",
                      stroke: dark, tint: sleeveLine, width: 4, cap: "round"),
            Rig.Shape(kind: "ellipse", x: hand.x, y: hand.y, rx: 12.5, ry: 12.5, fill: fur, stroke: dark, tint: furLine, width: 5),
        ]
    }

    /// Puggle with her arms bent to these points, something held if given, and her arms in front of her head if they reach it.
    private static func posed(_ rig: Rig, left: (CGPoint, CGPoint)?, right: (CGPoint, CGPoint)?, held: [Rig.Shape] = [], overHead: Bool = false) -> Rig {
        var copy = rig
        for (id, bend, shoulder) in [("arm-left", left, CGPoint(x: 88, y: 178)), ("arm-right", right, CGPoint(x: 152, y: 178))] {
            guard let bend, let index = copy.parts.firstIndex(where: { $0.id == id }) else { continue }
            copy.parts[index].shapes = arm(from: shoulder, elbow: bend.0, hand: bend.1)
            copy.parts[index].spring = 0
        }
        if !held.isEmpty, let index = copy.parts.firstIndex(where: { $0.id == "arm-left" }) {
            copy.parts.insert(Rig.Part(id: "held", parent: "upper", pivot: [120, 220], shapes: held), at: index)
        }
        if overHead {
            for id in ["arm-left", "arm-right"] {
                guard let index = copy.parts.firstIndex(where: { $0.id == id }) else { continue }
                copy.parts.append(copy.parts.remove(at: index))
            }
        }
        return copy
    }

    private static var rabbit: [Rig.Shape] {
        let cloth = "#FBF3E2", line = "#B9AE98"
        return [
            Rig.Shape(kind: "ellipse", x: 112, y: 186, rx: 5, ry: 13, rotate: -8, fill: cloth, stroke: dark, tint: line, width: 4),
            Rig.Shape(kind: "ellipse", x: 128, y: 186, rx: 5, ry: 13, rotate: 10, fill: cloth, stroke: dark, tint: line, width: 4),
            Rig.Shape(kind: "ellipse", x: 120, y: 232, rx: 15, ry: 15, fill: cloth, stroke: dark, tint: line, width: 4),
            Rig.Shape(kind: "ellipse", x: 120, y: 207, rx: 16, ry: 14, fill: cloth, stroke: dark, tint: line, width: 4),
            Rig.Shape(kind: "ellipse", x: 114, y: 205, rx: 1.9, ry: 1.9, fill: dark),
            Rig.Shape(kind: "ellipse", x: 126, y: 205, rx: 1.9, ry: 1.9, fill: dark),
            Rig.Shape(kind: "ellipse", x: 120, y: 210, rx: 2, ry: 1.5, fill: "#F2A48E"),
        ]
    }

    private static var book: [Rig.Shape] {
        [
            Rig.Shape(kind: "path", d: "M78 198 L120 205 L162 198 L162 240 L120 247 L78 240 Z", fill: "#E5553B", stroke: dark, tint: "#B23A26", width: 5),
            Rig.Shape(kind: "path", d: "M120 205 L120 247", stroke: "#B23A26", width: 3, cap: "round"),
            Rig.Shape(kind: "path", d: "M82 196 L120 202 L158 196", stroke: "#FBF6E9", width: 4, cap: "round"),
            Rig.Shape(kind: "ellipse", x: 141, y: 222, rx: 8, ry: 8, fill: "#F4BE2C"),
        ]
    }

    private static func tuftAndPoses(_ puggle: Rig) {
        let tufted = withTuft(puggle, 3)   // the single leaning lick
        func mark(_ text: String) -> some View {
            Text(text).font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0xF4BE2C))
        }
        func figure(_ rig: Rig, _ states: [String: PartState] = [:], face: [String: String]? = nil, _ caption: String, mark text: String? = nil) -> some View {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RigFrame(rig: rig, states: states, face: face).frame(width: 152, height: 190)
                    if let text { mark(text).offset(x: 8, y: -4) }
                }
                Text(caption).font(.system(size: 12, weight: .medium)).foregroundStyle(note).multilineTextAlignment(.center).frame(width: 160)
            }
        }
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        let wide = state(sx: 1.18, sy: 1.18)
        let sheet = VStack(alignment: .leading, spacing: 20) {
            row("A tuft of hair: does it help her stand apart from Mum and Dad?") {
                figure(puggle, [:], "Now")
                figure(tufted, [:], "With one lick")
                figure(silhouette(puggle), [:], "Now, as a shape")
                figure(silhouette(tufted), [:], "With one lick, as a shape")
            }
            row("Arms that bend: what she could do, in her own style. No mouth; hands never over her face or bill") {
                figure(posed(tufted, left: nil, right: (p(204, 214), p(150, 192))),
                       ["head": state(r: 6), "eye-left": state(x: 3, y: -3), "eye-right": state(x: 3, y: -3), "clip": state(r: 5)],
                       "Thinking: a hand under her chin, on her dress", mark: "?")
                figure(posed(tufted, left: (p(52, 228), p(100, 226)), right: (p(188, 228), p(140, 226)), held: rabbit),
                       ["head": state(r: -5), "blush": state(sx: 1.14, sy: 1.14)], face: ["eyes": "happy", "cheeks": "shy"],
                       "Hugging her rabbit")
                figure(posed(tufted, left: (p(56, 206), p(80, 224)), right: (p(184, 206), p(160, 224)), held: book),
                       ["head": state(y: 4), "eye-left": state(y: 3.5), "eye-right": state(y: 3.5)],
                       "Reading: eyes down on the book")
                figure(posed(tufted, left: (p(26, 190), p(52, 140)), right: (p(214, 190), p(188, 140)), overHead: true),
                       ["eye-left": wide, "eye-right": wide, "brow-left": state(y: -4), "brow-right": state(y: -4), "upper": state(sy: 1.03)],
                       face: ["eyes": "open", "brows": "on"], "Oh! Hands to her cheeks, clear of her bill", mark: "!")
            }
        }
        save(sheet, as: "refine-8-tuft-and-arms.png")
    }

    // MARK: 1. The model sheet, as numbers

    private static func modelSheet(_ puggle: Rig) {
        let k: CGFloat = 1.6   // points per unit of the drawing
        func x(_ v: CGFloat) -> CGFloat { v * k }
        func tag(_ text: String, _ at: CGPoint, _ anchor: UnitPoint = .leading) -> some View {
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: 0xB23A26))
                .fixedSize().position(x: at.x * k + (anchor == .leading ? 0 : 0), y: at.y * k)
        }
        func rule(_ from: CGPoint, _ to: CGPoint) -> some View {
            Path { p in p.move(to: CGPoint(x: x(from.x), y: x(from.y))); p.addLine(to: CGPoint(x: x(to.x), y: x(to.y))) }
                .stroke(Color(hex: 0xB23A26), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        let sheet = HStack(alignment: .top, spacing: 28) {
            ZStack(alignment: .topLeading) {
                RigFrame(rig: puggle, states: [:]).frame(width: x(240), height: x(300))
                // Head: 140 wide, 120 high. Eyes on one line, 64 apart. Bill 94 wide.
                rule(CGPoint(x: 50, y: 40), CGPoint(x: 190, y: 40)); tag("head 140 wide", CGPoint(x: 120, y: 32))
                rule(CGPoint(x: 204, y: 48), CGPoint(x: 204, y: 168)); tag("120 high", CGPoint(x: 226, y: 108))
                rule(CGPoint(x: 20, y: 117), CGPoint(x: 220, y: 117)); tag("eye line", CGPoint(x: 22, y: 110))
                rule(CGPoint(x: 88, y: 96), CGPoint(x: 152, y: 96)); tag("64 apart", CGPoint(x: 120, y: 89))
                rule(CGPoint(x: 73, y: 178), CGPoint(x: 167, y: 178)); tag("bill 94", CGPoint(x: 120, y: 186))
                rule(CGPoint(x: 14, y: 166), CGPoint(x: 14, y: 290)); tag("body\n1 head", CGPoint(x: 22, y: 228))
            }
            .frame(width: x(240), height: x(300))
            VStack(alignment: .leading, spacing: 7) {
                Text("Puggle, by numbers").font(.system(size: 17, weight: .bold)).foregroundStyle(ink)
                ForEach(["Head 140 × 120. Never squashes.", "Eyes: dots of radius 6.8, on one line, 64 apart, below the head's middle.",
                         "Bill 94 × 38, never opens, never tilts.", "Cheeks: ovals 24 × 15 at the ends of the bill. No marks at rest.",
                         "Eyebrows: only with a feeling. Rise 4 at most.", "About 2½ heads tall: head 1, body ¾, legs ⅓.",
                         "Outline 7 on the head and dress, 6 on bill and limbs, 5 on small things. The same on screen at any size.",
                         "One accessory: the clip, top right."], id: \.self) { line in
                    Text("•  " + line).font(.system(size: 13)).foregroundStyle(ink).frame(width: 300, alignment: .leading)
                }
                Text("Never").font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: 0xB23A26)).padding(.top, 8)
                ForEach(["A mouth, or an open or bent bill.", "Frowning, sad or worried eyebrows.", "Recolouring her fur, bill or clip.",
                         "A black line.", "Hands hidden in her outline, or over her face or bill.", "Dark patches on her face.",
                         "An outline on the world behind her."], id: \.self) { line in
                    Text("✕  " + line).font(.system(size: 13)).foregroundStyle(ink).frame(width: 300, alignment: .leading)
                }
            }
        }
        save(sheet, as: "refine-1-model.png")
    }

    // MARK: 2. Silhouettes

    private static func silhouettes(_ puggle: Rig) {
        let cast: [(String, Rig, CGFloat)] = [("Puggle", puggle, 118)] + CastMember.allCases.compactMap { member in
            Rig.load(member.rawValue).map { (member.name, $0, member.height - member.headroom) }
        }
        func line(_ solid: Bool) -> some View {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(cast, id: \.0) { name, rig, height in
                    VStack(spacing: 4) {
                        let full = height / ((rig.size[1] - (rig.headroom ?? 0)) / rig.size[1])
                        RigFrame(rig: solid ? silhouette(rig) : rig, states: [:])
                            .frame(width: full * rig.size[0] / rig.size[1], height: full)
                            .frame(height: height, alignment: .bottom).clipped()
                        if solid { Text(name).font(.system(size: 11, weight: .semibold)).foregroundStyle(note) }
                    }
                }
            }
        }
        save(VStack(alignment: .leading, spacing: 14) {
            Text("The silhouette test: can you name each one from the shape alone?").font(.system(size: 14, weight: .bold)).foregroundStyle(ink)
            line(false)
            line(true)
        }, as: "refine-2-silhouettes.png")
    }

    // MARK: 3. A fixed set of expressions

    private static func expressions(_ puggle: Rig) {
        let up = state(y: -4), glow = state(sx: 1.14, sy: 1.14)
        let sheet = row("One small, fixed set of faces. One change at a time.") {
            cell(puggle, caption: "Neutral")
            cell(puggle, ["blush": glow], face: ["eyes": "happy", "cheeks": "shy"], caption: "Pleased: eyes and cheeks")
            cell(puggle, ["brow-left": state(r: -6, y: -4), "brow-right": state(r: 6, y: -4), "blush": glow, "head": state(r: -4)],
                 face: ["eyes": "open", "brows": "on"], caption: "Delighted: eyebrows up")
            cell(puggle, ["head": state(r: 7), "eye-left": state(x: 4.5), "eye-right": state(x: 4.5), "clip": state(r: 5)], caption: "Curious: eyes go first, head follows")
            cell(puggle, ["brow-left": state(r: -14, y: 1), "brow-right": state(r: 14, y: 1), "head": state(r: 5, y: 3)],
                 face: ["eyes": "closed", "brows": "on"], caption: "Sleepy")
            cell(puggle, ["brow-left": up, "brow-right": up, "eye-left": state(sx: 1.18, sy: 1.18), "eye-right": state(sx: 1.18, sy: 1.18), "upper": state(sy: 1.03)],
                 face: ["eyes": "open", "brows": "on"], caption: "Surprised: eyes a little wider")
        }
        save(sheet, as: "refine-3-expressions.png")
    }

    // MARK: 4. Blinks

    private static func blink(_ puggle: Rig) {
        func eyes(_ open: Double, brow: Double = 0) -> [String: PartState] {
            ["eye-left": state(sy: open), "eye-right": state(sy: open), "brow-left": state(y: brow), "brow-right": state(y: brow)]
        }
        func frames(_ list: [(String, Double)]) -> some View {
            ForEach(list, id: \.0) { label, open in
                cell(puggle, eyes(open), height: 86, caption: label, headOnly: true)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 18) {
            row("Now: the eyes shut and open like a switch, on a timer") {
                frames([("0 ms", 1), ("40", 0.12), ("80", 0.12), ("120", 0.12), ("160", 1), ("200", 1), ("240", 1)])
            }
            row("Proposed: shut quickly, open slowly. And she blinks when she looks somewhere new, not only on a timer") {
                frames([("0 ms", 1), ("40", 0.45), ("80 shut", 0.1), ("130 shut", 0.1), ("180", 0.4), ("230", 0.75), ("290", 1)])
            }
        }
        save(sheet, as: "refine-4-blink.png")
    }

    // MARK: 5. Eyes lead the head

    private static func eyesLead(_ puggle: Rig) {
        let look = state(x: 4.5)
        let sheet = VStack(alignment: .leading, spacing: 18) {
            row("Now: head, eyes and clip all tip together") {
                cell(puggle, height: 140, caption: "Rest")
                cell(puggle, ["head": state(r: 3.5), "clip": state(r: 2.5)], height: 140, caption: "Half way")
                cell(puggle, ["head": state(r: 7), "clip": state(r: 5)], height: 140, caption: "Tilted")
            }
            row("Proposed: she looks first, then her head follows, then her clip settles") {
                cell(puggle, height: 140, caption: "Rest")
                cell(puggle, ["eye-left": look, "eye-right": look], height: 140, caption: "Eyes slide: she has noticed")
                cell(puggle, ["eye-left": state(x: 4.5, sy: 0.12), "eye-right": state(x: 4.5, sy: 0.12), "head": state(r: 2)], height: 140, caption: "A blink as the head starts")
                cell(puggle, ["eye-left": look, "eye-right": look, "head": state(r: 8), "clip": state(r: 1)], height: 140, caption: "Head arrives; clip is late")
                cell(puggle, ["eye-left": look, "eye-right": look, "head": state(r: 7), "clip": state(r: 8)], height: 140, caption: "Clip swings past")
                cell(puggle, ["eye-left": look, "eye-right": look, "head": state(r: 7), "clip": state(r: 5)], height: 140, caption: "Settled, and held")
            }
        }
        save(sheet, as: "refine-5-eyes-lead.png")
    }

    // MARK: 6. The hop

    private static func hop(_ puggle: Rig) {
        let armsUp: [String: PartState] = ["arm-left": state(r: 78), "arm-right": state(r: -78)]
        func pose(_ extra: [String: PartState], lift: Double) -> some View {
            // Room above, so the lift shows against a ground line.
            ZStack(alignment: .bottom) {
                Rectangle().fill(note.opacity(0.35)).frame(width: 110, height: 1.5)
                RigFrame(rig: puggle, states: extra.merging(["body": state(y: lift)]) { a, _ in a }, face: lift < -6 ? ["eyes": "squeeze", "brows": "on"] : nil)
                    .frame(width: 112, height: 140)
            }
            .frame(width: 118, height: 170, alignment: .bottom)
        }
        func captioned(_ view: some View, _ text: String) -> some View {
            VStack(spacing: 6) {
                view
                Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(note).multilineTextAlignment(.center).frame(width: 118)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 18) {
            row("Now: straight up and straight down") {
                captioned(pose([:], lift: 0), "Rest")
                captioned(pose(armsUp, lift: -16), "Up")
                captioned(pose(armsUp.merging(["upper": state(sy: 0.93)]) { a, _ in a }, lift: 0), "Down")
            }
            row("Proposed: a dip before, a hard landing, a squash that keeps her size, and a settle") {
                captioned(pose([:], lift: 0), "Rest")
                captioned(pose(["upper": state(sx: 1.04, sy: 0.92), "head": state(y: 5), "arm-left": state(r: -8), "arm-right": state(r: 8)], lift: 3), "Dip: winding up")
                captioned(pose(armsUp.merging(["upper": state(sx: 0.97, sy: 1.06), "tail": state(r: -30), "leg-left": state(r: 10), "leg-right": state(r: -10)]) { a, _ in a }, lift: -20), "Up: stretched, tail trailing")
                captioned(pose(["upper": state(sx: 1.07, sy: 0.9), "head": state(y: 6), "arm-left": state(r: 30), "arm-right": state(r: -30), "tail": state(r: 12)], lift: 0), "Land: wider as she gets shorter")
                captioned(pose(["upper": state(sx: 0.99, sy: 1.02), "arm-left": state(r: 8), "arm-right": state(r: -8), "tail": state(r: -6), "clip": state(r: -8)], lift: 0), "Settle: arms, tail and clip arrive late")
                captioned(pose([:], lift: 0), "Rest, and held")
            }
        }
        save(sheet, as: "refine-6-hop.png")
    }

    // MARK: 7. Two together

    private static func pair(_ puggle: Rig) {
        guard let kip = Rig.load("kip") else { return }
        let kipHeight = CastMember.kip.height
        func beat(_ p: [String: PartState], _ k: [String: PartState], pFace: [String: String]? = nil, _ text: String) -> some View {
            VStack(spacing: 6) {
                HStack(alignment: .bottom, spacing: 2) {
                    RigFrame(rig: puggle, states: p, face: pFace).frame(width: 118 * 0.8, height: 118)
                    RigFrame(rig: kip, states: k).frame(width: kipHeight * kip.size[0] / kip.size[1], height: kipHeight)
                        .frame(height: kipHeight - CastMember.kip.headroom, alignment: .bottom).clipped()
                }
                Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(note).multilineTextAlignment(.center).frame(width: 190)
            }
        }
        // A look is the eyes sliding that way and the head leaning a little after them.
        let toKip = state(x: 6.5), toPuggle = state(x: -6.5)
        let pLooks: [String: PartState] = ["eye-left": toKip, "eye-right": toKip, "head": state(r: 5), "clip": state(r: 4)]
        let kLooks: [String: PartState] = ["eye-left": toPuggle, "eye-right": toPuggle, "head": state(r: -5)]
        func and(_ a: [String: PartState], _ b: [String: PartState]) -> [String: PartState] { a.merging(b) { _, new in new } }
        let sheet = VStack(alignment: .leading, spacing: 18) {
            row("Now: both wave at once, each looking at you") {
                beat(["arm-right": state(r: -80), "head": state(r: -5)], ["arm-right": state(r: -80), "head": state(r: -5)], "Two things to watch, and no sign they know each other is there")
            }
            row("Proposed: one at a time. A look, a pause, an answer") {
                beat(pLooks, [:], "1. Puggle looks at Kip. Kip is still.")
                beat(and(pLooks, ["arm-right": state(r: -80)]), [:], "2. Puggle waves, with the arm nearest Kip")
                beat(pLooks, kLooks, "3. Puggle holds. Kip looks back.")
                beat(pLooks, and(kLooks, ["arm-left": state(r: 80)]), "4. Kip answers, in the gap between them. Puggle is still.")
                beat(and(pLooks, ["blush": state(sx: 1.14, sy: 1.14)]), kLooks, pFace: ["eyes": "happy", "cheeks": "shy"], "5. Puggle is pleased. Hold.")
            }
        }
        save(sheet, as: "refine-7-pair.png")
    }
}
