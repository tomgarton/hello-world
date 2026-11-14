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
                         "Eyebrows: only with a feeling. Rise 4 at most.", "Body one head tall; legs a third of a head.",
                         "Outline 7 on the head and dress, 6 on bill and limbs, 5 on small things. The same on screen at any size.",
                         "One accessory: the clip, top right."], id: \.self) { line in
                    Text("•  " + line).font(.system(size: 13)).foregroundStyle(ink).frame(width: 300, alignment: .leading)
                }
                Text("Never").font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: 0xB23A26)).padding(.top, 8)
                ForEach(["A mouth.", "A profile, or a smooth turn of the head.", "Crossed eyes, or eyes at different heights.",
                         "Angry, sad or worried eyebrows.", "A second accessory.", "An outline on the world behind her."], id: \.self) { line in
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
