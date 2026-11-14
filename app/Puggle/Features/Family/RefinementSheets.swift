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
        headParts(puggle)
        feelings(puggle)
        parentHair()
        hatsOff()
        nanHair()
        dummy()
        smear(puggle)
        curlOptions()
        tailInMotion(puggle)
        looseEnds(puggle)
        bendingArms(puggle)
        // greyHair() drew the options for Nan's and Pop's grey on the rigs as they were before it was built in.
        goingGrey()
    }

    /// Nan and Pop as built: warmer, lighter fur with a lighter line, and grey dashes scattered through their hair.
    private static func goingGrey() {
        func big(_ name: String) -> some View {
            Group {
                if let rig = Rig.load(name) {
                    RigFrame(rig: rig, states: [:], face: nil)
                        .frame(width: 300 * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: 300 * rig.size[1] / 240)
                        .frame(width: 320, height: 330, alignment: .top).clipped()
                }
            }
        }
        func small(_ name: String, outfit: String = "none") -> some View {
            Group {
                if let rig = Rig.load(name) {
                    RigFrame(rig: rig, states: [:], face: nil)
                        .frame(width: 110 * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: 110 * rig.size[1] / 240)
                        .environment(\.outfit, outfit)
                }
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 16) {
            row("Nan and Pop, going grey") { big("nan"); big("pop") }
            row("With the family, at app size") {
                HStack(alignment: .bottom, spacing: 0) { small("mum"); small("nan"); small("dad"); small("pop"); small("nan-apron"); small("pop-jumper") }
            }
            row("Hats off, in the cold, in the rain") {
                HStack(alignment: .bottom, spacing: 0) { small("pop", outfit: "bare"); small("nan", outfit: "warm"); small("pop", outfit: "warm"); small("nan", outfit: "rain"); small("pop", outfit: "rain") }
            }
        }
        save(sheet, as: "going-grey.png")
    }

    /// Should Nan and Pop be going grey? As now, a few streaks, more streaks, and all grey.
    private static func greyHair() {
        let silver = "#D6CDBE", silverLine = "#8F8778"
        func mirrored(_ d: String) -> String {
            var out = "", number = "", isX = true
            func flush() { if !number.isEmpty { out += isX ? "\(240 - (Double(number) ?? 0))" : number; isX.toggle(); number = "" } }
            for ch in d { if ch.isNumber || ch == "." || ch == "-" { number.append(ch) } else { flush(); out.append(ch) } }
            flush()
            return out
        }
        func streaked(_ rig: Rig, _ streaks: [String: [String]]) -> Rig {
            var copy = rig
            for (id, lines) in streaks {
                guard let index = copy.parts.firstIndex(where: { $0.id == id }) else { continue }
                copy.parts[index].shapes += lines.map { Rig.Shape(kind: "path", d: $0, stroke: silver, width: 4.5, cap: "round") }
            }
            return copy
        }
        func allGrey(_ rig: Rig, _ ids: [String]) -> Rig {
            var copy = rig
            for index in copy.parts.indices where ids.contains(where: { copy.parts[index].id == $0 || copy.parts[index].id == $0 + "-top" }) {
                for shape in copy.parts[index].shapes.indices {
                    copy.parts[index].shapes[shape].fill = silver
                    if copy.parts[index].shapes[shape].tint != nil { copy.parts[index].shapes[shape].tint = silverLine }
                }
            }
            return copy
        }
        guard let nan = Rig.load("nan"), let pop = Rig.load("pop") else { return }
        let nanFew = ["curls-top": ["M86 104 Q95 97 104 101", "M138 100 Q148 96 156 104"], "curl-left-top": ["M45 191 Q46 184 54 183"], "curl-right-top": [mirrored("M45 191 Q46 184 54 183")]]
        let nanMore = ["curls-top": ["M80 112 Q84 102 96 102", "M100 98 Q110 92 120 96", "M124 98 Q134 92 142 98", "M146 104 Q158 102 160 112", "M96 116 Q108 110 120 114", "M124 114 Q136 110 146 116"],
                       "curl-left-top": ["M45 191 Q46 184 54 183", "M46 198 Q49 200 52 199"], "curl-right-top": [mirrored("M45 191 Q46 184 54 183"), mirrored("M46 198 Q49 200 52 199")]]
        let popFew = ["tuft-left-top": ["M47 121 L56 124", "M46 141 L56 138"], "tuft-right-top": [mirrored("M47 121 L56 124"), mirrored("M46 141 L56 138")]]
        let popMore = ["tuft-left-top": ["M46 120 L57 122", "M45 130 L56 130", "M47 141 L57 138"], "tuft-right-top": [mirrored("M46 120 L57 122"), mirrored("M45 130 L56 130"), mirrored("M47 141 L57 138")]]
        func column(_ name: String, _ rig: Rig) -> some View {
            VStack(spacing: 6) {
                RigFrame(rig: rig, states: [:], face: nil)
                    .frame(width: 210 * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: 210 * rig.size[1] / 240)
                    .frame(width: 230, height: 250, alignment: .top).clipped()
                RigFrame(rig: rig, states: [:], face: nil)
                    .frame(width: 60 * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: 60 * rig.size[1] / 240)
                Text(name).font(.system(size: 12, weight: .medium)).foregroundStyle(note)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 16) {
            row("Nan: close up, and at the size she is in the app") {
                column("A. As now", nan)
                column("B. A few streaks", streaked(nan, nanFew))
                column("C. Salt and pepper", streaked(nan, nanMore))
                column("D. All grey", allGrey(nan, ["curls", "curl-left", "curl-right"]))
            }
            row("Pop: his hat is on, so only the cheek tufts show") {
                column("A. As now", pop)
                column("B. A few streaks", streaked(pop, popFew))
                column("C. Salt and pepper", streaked(pop, popMore))
                column("D. All grey", allGrey(pop, ["tuft-left", "tuft-right"]))
            }
        }
        save(sheet, as: "grey-hair.png")

        // Second sheet: salt and pepper, blended in four ways.
        let mid = "#B79F8A", faded = "#A07E65", fadedLine = "#6E4C37"
        /// A lock of hair: a thin leaf from one point to another, bowed to one side.
        func lock(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double, bend: Double = 3, thick: Double = 5) -> String {
            let mx = (ax + bx) / 2, my = (ay + by) / 2, length = max(hypot(bx - ax, by - ay), 1)
            let nx = -(by - ay) / length, ny = (bx - ax) / length
            func point(_ x: Double, _ y: Double) -> String { "\((x * 10).rounded() / 10) \((y * 10).rounded() / 10)" }
            return "M\(point(ax, ay)) Q\(point(mx + nx * (bend + thick), my + ny * (bend + thick))) \(point(bx, by)) Q\(point(mx + nx * (bend - thick), my + ny * (bend - thick))) \(point(ax, ay)) Z"
        }
        func drawn(_ rig: Rig, strokes: [String: [String]] = [:], locks: [String: [(String, String)]] = [:], strokeColour: String = mid, fade: [String] = []) -> Rig {
            var copy = rig
            if !fade.isEmpty {
                for index in copy.parts.indices where fade.contains(where: { copy.parts[index].id == $0 || copy.parts[index].id == $0 + "-top" }) {
                    for shape in copy.parts[index].shapes.indices {
                        copy.parts[index].shapes[shape].fill = faded
                        if copy.parts[index].shapes[shape].tint != nil { copy.parts[index].shapes[shape].tint = fadedLine }
                    }
                }
            }
            for (id, lines) in strokes {
                guard let index = copy.parts.firstIndex(where: { $0.id == id }) else { continue }
                copy.parts[index].shapes += lines.map { Rig.Shape(kind: "path", d: $0, stroke: strokeColour, width: 4.5, cap: "round") }
            }
            for (id, leaves) in locks {
                guard let index = copy.parts.firstIndex(where: { $0.id == id }) else { continue }
                copy.parts[index].shapes += leaves.map { Rig.Shape(kind: "path", d: $0.0, fill: $0.1) }
            }
            return copy
        }
        func both(_ left: [(String, String)]) -> [(String, String)] { left.map { (mirrored($0.0), $0.1) } }
        // Nan. Locks that follow the curls, in two tones.
        let nanLocks: [(String, String)] = [
            (lock(78, 112, 96, 101, bend: -4), mid), (lock(100, 99, 119, 94, bend: -3), silver), (lock(123, 95, 142, 99, bend: -3), mid), (lock(146, 102, 162, 112, bend: -4), silver),
            (lock(94, 117, 116, 111, bend: -3), silver), (lock(124, 111, 146, 117, bend: -3), mid),
        ]
        let nanSideLock = [(lock(44, 193, 55, 183, bend: -3, thick: 4), mid)]
        // Nan. Strands that start at her brow and sweep up into the curls, as hair greys from the root.
        let nanSweep: [(String, String)] = [
            (lock(84, 130, 78, 108, bend: 3), mid), (lock(100, 128, 97, 102, bend: 2), mid), (lock(120, 127, 120, 97, bend: 0, thick: 4), mid),
            (lock(140, 128, 143, 102, bend: -2), mid), (lock(156, 130, 162, 108, bend: -3), mid),
        ]
        // Pop. A leaf along each spike of the tuft; or only the tips.
        let popLocks: [(String, String)] = [(lock(57, 120, 44, 119.5, bend: 0, thick: 3.2), mid), (lock(57, 130, 42, 130, bend: 0, thick: 3.2), silver), (lock(58, 140, 45, 142, bend: 0, thick: 3.2), mid)]
        let popTips: [(String, String)] = [("M42 119 L49 117.6 L50 123.6 Z", mid), ("M40 130 L48 126.8 L48 133.4 Z", mid), ("M43 143 L49 137.6 L51 142.6 Z", mid)]
        let nanSoft = streaked(nan, nanMore), popSoft = streaked(pop, popMore)
        let blended = VStack(alignment: .leading, spacing: 16) {
            row("Nan: salt and pepper, blended in") {
                column("C. As on the first sheet", nanSoft)
                column("1. Softer colour", drawn(nan, strokes: nanMore))
                column("2. Locks, in two tones", drawn(nan, locks: ["curls-top": nanLocks, "curl-left-top": nanSideLock, "curl-right-top": both(nanSideLock)]))
                column("3. Swept up from the brow", drawn(nan, locks: ["curls-top": nanSweep, "curl-left-top": nanSideLock, "curl-right-top": both(nanSideLock)]))
                column("4. Faded hair, lighter locks", drawn(nan, locks: ["curls-top": nanLocks.map { ($0.0, silver) }, "curl-left-top": nanSideLock.map { ($0.0, silver) }, "curl-right-top": both(nanSideLock).map { ($0.0, silver) }], fade: ["curls", "curl-left", "curl-right"]))
            }
            row("Pop") {
                column("C. As on the first sheet", popSoft)
                column("1. Softer colour", drawn(pop, strokes: popMore))
                column("2. Locks, in two tones", drawn(pop, locks: ["tuft-left-top": popLocks, "tuft-right-top": both(popLocks)]))
                column("3. Grey at the tips", drawn(pop, locks: ["tuft-left-top": popTips, "tuft-right-top": both(popTips)]))
                column("4. Faded tufts, lighter locks", drawn(pop, locks: ["tuft-left-top": popLocks.map { ($0.0, silver) }, "tuft-right-top": both(popLocks).map { ($0.0, silver) }], fade: ["tuft-left", "tuft-right"]))
            }
        }
        save(blended, as: "grey-blend.png")

        // Third sheet: short dashes scattered through the hair, all much the same length and leaning the same way,
        // as a speckled coat is drawn. Our own marks: fanned out from the middle of the head, in our own colours.
        func dash(_ x: Double, _ y: Double, long: Double = 6.5, lean: Double? = nil) -> String {
            let angle = (lean ?? (x - 120) / 120 * 32) * .pi / 180
            let dx = sin(angle) * long / 2, dy = cos(angle) * long / 2
            func n(_ v: Double) -> String { "\((v * 10).rounded() / 10)" }
            return "M\(n(x - dx)) \(n(y + dy)) L\(n(x + dx)) \(n(y - dy))"
        }
        func dashed(_ rig: Rig, _ marks: [String: [String]], colour: String, second: String? = nil) -> Rig {
            var copy = rig
            for (id, lines) in marks {
                guard let index = copy.parts.firstIndex(where: { $0.id == id }) else { continue }
                copy.parts[index].shapes += lines.enumerated().map { i, d in
                    Rig.Shape(kind: "path", d: d, stroke: second != nil && i % 3 == 1 ? second! : colour, width: 3, cap: "round")
                }
            }
            return copy
        }
        // Nan: three staggered rows across her curls; then two thinner rows running down onto her head.
        var crown: [String] = []
        for x in stride(from: 90.0, through: 150, by: 15) { crown.append(dash(x, 101)) }
        for x in stride(from: 80.0, through: 160, by: 16) { crown.append(dash(x, 111)) }
        for x in stride(from: 74.0, through: 166, by: 15.4) { crown.append(dash(x, 121)) }
        var thinning = crown
        for x in stride(from: 84.0, through: 156, by: 24) { thinning.append(dash(x, 132, long: 5.5)) }
        for x in [98.0, 142] { thinning.append(dash(x, 142, long: 4.5)) }
        let nanSide = [dash(46, 187, long: 5, lean: -50), dash(50, 197, long: 4.5, lean: -70)]
        func nanMarks(_ top: [String]) -> [String: [String]] { ["curls-top": top, "curl-left-top": nanSide, "curl-right-top": nanSide.map(mirrored)] }
        // Pop: along each spike of the tuft; then a few more on the side of his head, under the brim.
        let popSpikes = [dash(50, 120.5, long: 5.5, lean: -82), dash(47, 130, long: 5.5, lean: -90), dash(51, 140, long: 5.5, lean: -98)]
        let popTemple = popSpikes + [dash(63, 100, long: 5, lean: -30), dash(58, 109, long: 5, lean: -40), dash(66, 112, long: 4.5, lean: -30)]
        func popMarks(_ left: [String]) -> [String: [String]] { ["tuft-left-top": left, "tuft-right-top": left.map(mirrored)] }
        let dashes = VStack(alignment: .leading, spacing: 16) {
            row("Nan: short dashes through the hair") {
                column("2. Locks, from the last sheet", drawn(nan, locks: ["curls-top": nanLocks, "curl-left-top": nanSideLock, "curl-right-top": both(nanSideLock)]))
                column("5. Dashes, grey-brown", dashed(nan, nanMarks(crown), colour: mid))
                column("6. Dashes, silver", dashed(nan, nanMarks(crown), colour: silver))
                column("7. Two tones, thinning down", dashed(nan, nanMarks(thinning), colour: mid, second: silver))
            }
            row("Pop") {
                column("2. Locks, from the last sheet", drawn(pop, locks: ["tuft-left-top": popLocks, "tuft-right-top": both(popLocks)]))
                column("5. Dashes, grey-brown", dashed(pop, popMarks(popSpikes), colour: mid))
                column("6. Dashes, silver", dashed(pop, popMarks(popSpikes), colour: silver))
                column("7. Two tones, onto his temples", dashed(pop, popMarks(popTemple), colour: mid, second: silver))
            }
        }
        save(dashes, as: "grey-dashes.png")

        // Fourth sheet: other ways shows draw a grandparent. Bluey's Nana is her son's colours made paler and greyer
        // all over, with the same marks; an old dog goes pale round the muzzle first.
        let greyer = ["#8A5A3C": "#93745E", "#5E3A24": "#5F4737"]
        func muzzled(_ rig: Rig) -> Rig {
            var copy = rig
            guard let index = copy.parts.firstIndex(where: { $0.id == "face" }),
                  let bill = copy.parts[index].shapes.first(where: { $0.fill == "#6E7F8D" }), let x = bill.x, let y = bill.y else { return rig }
            copy.parts[index].shapes.insert(Rig.Shape(kind: "ellipse", x: x, y: y + 1, rx: 60, ry: 29, fill: "#A5846A"), at: 1)
            return copy
        }
        let nanDashed = dashed(nan, nanMarks(thinning), colour: mid, second: silver)
        let popDashed = dashed(pop, popMarks(popTemple), colour: mid, second: silver)
        let others = VStack(alignment: .leading, spacing: 16) {
            row("Nan: other ways to show her age") {
                column("7. Dashes, from the last sheet", nanDashed)
                column("8. Greyer fur all over", nan.wearing(greyer))
                column("9. Greyer fur, with dashes", nanDashed.wearing(greyer))
                column("10. Pale round the bill", muzzled(nan))
                column("11. Pale round the bill, dashes", muzzled(nanDashed))
            }
            row("Pop") {
                column("7. Dashes, from the last sheet", popDashed)
                column("8. Greyer fur all over", pop.wearing(greyer))
                column("9. Greyer fur, with dashes", popDashed.wearing(greyer))
                column("10. Pale round the bill", muzzled(pop))
                column("11. Pale round the bill, dashes", muzzled(popDashed))
            }
            row("Beside Mum and Dad, at app size: as now, 9, and 11") {
                if let mum = Rig.load("mum"), let dad = Rig.load("dad") {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(Array([mum, [nan, nanDashed.wearing(greyer), muzzled(nanDashed)][i], dad, [pop, popDashed.wearing(greyer), muzzled(popDashed)][i]].enumerated()), id: \.offset) { _, rig in
                                RigFrame(rig: rig, states: [:], face: nil)
                                    .frame(width: 96 * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: 96 * rig.size[1] / 240)
                            }
                        }
                        .padding(.trailing, 30)
                    }
                }
            }
        }
        save(others, as: "grey-others.png")

        // Fifth sheet: the same idea kept warm, so they look older and not unwell, with the line lightened to match.
        // A is a small step from the family's brown; B is a little further. Both keep its warmth.
        let stepA = ["#8A5A3C": "#8F644A", "#5E3A24": "#6B4833"], stepB = ["#8A5A3C": "#946E56", "#5E3A24": "#73523E"]
        let warm = VStack(alignment: .leading, spacing: 16) {
            row("Nan: warmer and less pale, with a lighter line") {
                column("As now", nan)
                column("A. A small step", nan.wearing(stepA))
                column("A, with dashes", nanDashed.wearing(stepA))
                column("B. A little further", nan.wearing(stepB))
                column("B, with dashes", nanDashed.wearing(stepB))
                column("Last sheet's 9, too pale", nanDashed.wearing(greyer))
            }
            row("Pop") {
                column("As now", pop)
                column("A. A small step", pop.wearing(stepA))
                column("A, with dashes", popDashed.wearing(stepA))
                column("B. A little further", pop.wearing(stepB))
                column("B, with dashes", popDashed.wearing(stepB))
                column("Last sheet's 9, too pale", popDashed.wearing(greyer))
            }
            row("Beside Mum and Dad, at app size: as now, A with dashes, B with dashes") {
                if let mum = Rig.load("mum"), let dad = Rig.load("dad") {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(Array([mum, [nan, nanDashed.wearing(stepA), nanDashed.wearing(stepB)][i], dad, [pop, popDashed.wearing(stepA), popDashed.wearing(stepB)][i]].enumerated()), id: \.offset) { _, rig in
                                RigFrame(rig: rig, states: [:], face: nil)
                                    .frame(width: 110 * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: 110 * rig.size[1] / 240)
                            }
                        }
                        .padding(.trailing, 30)
                    }
                }
            }
        }
        save(warm, as: "grey-warm.png")
    }

    /// Arms that bend at the elbow: Puggle's new poses, the same on everyone, and in her other clothes.
    private static func bendingArms(_ puggle: Rig) {
        /// A move played from the start and caught at one moment, with the face it has then.
        func caught(_ rig: Rig, _ move: String?, at moment: Double, width: CGFloat = 104) -> some View {
            let runtime = RigRuntime(rig: rig)
            runtime.blinkAt = .distantPast
            let start = Date.now
            _ = runtime.advance(to: start)
            if let move { runtime.play(move, at: start) }
            var t = 0.0, states: [String: PartState] = [:]
            while t < moment { t += 0.016; states = runtime.advance(to: start.addingTimeInterval(t)) }
            return RigFrame(rig: rig, states: states, face: runtime.face)
                .frame(width: width * (rig.size[0] + 2 * (rig.sideroom ?? 0)) / 240, height: width * rig.size[1] / 240)
        }
        func named(_ text: String, @ViewBuilder _ content: () -> some View) -> some View {
            VStack(spacing: 4) {
                content()
                Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(note)
            }
        }
        func set(_ rig: Rig, _ name: String) -> some View {
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 2) {
                    caught(rig, "greet", at: 0.3, width: 84)
                    caught(rig, "oh", at: 0.7, width: 84)
                    if rig.moves?["read"] != nil { caught(rig, "read", at: 1.0, width: 84) }
                }
                Text(name).font(.system(size: 12, weight: .medium)).foregroundStyle(note)
            }
        }
        let cast: [[String]] = [["pebble", "kip", "quill"], ["digby", "sunny", "mum"], ["dad", "nan", "pop"]]
        let sheet = VStack(alignment: .leading, spacing: 16) {
            row("Puggle: arms that bend at the elbow") {
                named("At rest, as before") { caught(puggle, nil, at: 0.3) }
                named("Wave, from the elbow") { caught(puggle, "greet", at: 0.3) }
                named("Wave, the other way") { caught(puggle, "greet", at: 0.48) }
                named("Oh! Hands to cheeks") { caught(puggle, "oh", at: 0.7) }
                named("Reading") { caught(puggle, "read", at: 1.0) }
                named("Turning a page") { caught(puggle, "read", at: 4.85) }
                named("Hugging her rabbit") { caught(puggle, "hug", at: 0.9) }
            }
            row("In her other clothes: raincoat, pyjamas, scarf and beanie") {
                ForEach(["rain", "night", "warm"], id: \.self) { outfit in
                    HStack(alignment: .bottom, spacing: 2) {
                        caught(puggle, "oh", at: 0.7)
                        caught(puggle, "read", at: 1.0)
                        caught(puggle, "hug", at: 0.9)
                    }
                    .environment(\.outfit, outfit)
                }
            }
            ForEach(cast.indices, id: \.self) { line in
                row(line == 0 ? "Everyone else: wave, oh, reading" : "") {
                    ForEach(cast[line], id: \.self) { who in
                        if let rig = Rig.load(who) { set(rig, who.capitalized) }
                    }
                }
            }
            row("Making bubbles: a wand swept through the air, low then high") {
                named("Puggle, low") { caught(puggle, "bubbles", at: 0.5) }
                named("Puggle, high") { caught(puggle, "bubbles", at: 1.6) }
                ForEach(["kip", "quill", "digby", "sunny"], id: \.self) { who in
                    if let rig = Rig.load(who) { named(who.capitalized) { caught(rig, "bubbles", at: 1.6, width: 84) } }
                }
            }
            row("Mittens stay on the hands; a grown-up in the cold") {
                if let kip = Rig.load("kip"), let nan = Rig.load("nan") {
                    HStack(alignment: .bottom, spacing: 2) {
                        caught(kip, "oh", at: 0.7); caught(kip, "read", at: 1.0); caught(nan, "oh", at: 0.7); caught(nan, "greet", at: 0.3)
                    }
                    .environment(\.outfit, "warm")
                }
            }
        }
        save(sheet, as: "bending-arms.png")
    }

    /// The tail for each feeling, shy on Puggle, and trousers in a walk.
    private static func looseEnds(_ puggle: Rig) {
        func feelingRow(_ rig: Rig) -> some View {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(RigFeeling.all.indices, id: \.self) { i in
                    VStack(spacing: 4) {
                        RigFrame(rig: rig, states: RigFeeling.all[i].held(), face: RigFeeling.all[i].name == "Shy" ? ["eyes": "open", "cheeks": "shy"] : nil)
                            .frame(width: 120 * rig.size[0] / 300, height: 120 * rig.size[1] / 300)
                        Text(RigFeeling.all[i].name).font(.system(size: 12, weight: .medium)).foregroundStyle(note)
                    }
                }
            }
        }
        func walk(_ rig: Rig) -> some View {
            let runtime = RigRuntime(rig: rig)
            runtime.blinkAt = .distantPast
            let start = Date.now
            _ = runtime.advance(to: start)
            runtime.play("walk", at: start)
            var frames: [[String: PartState]] = [], t = 0.0
            for until in [0.15, 0.4, 0.65, 0.9] {
                while t < until { t += 0.016; _ = runtime.advance(to: start.addingTimeInterval(t)) }
                frames.append(runtime.advance(to: start.addingTimeInterval(until)))
            }
            return HStack(alignment: .bottom, spacing: 8) {
                ForEach(frames.indices, id: \.self) { i in
                    RigFrame(rig: rig, states: frames[i], face: nil).frame(width: 120 * rig.size[0] / 300, height: 120 * rig.size[1] / 300)
                }
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 16) {
            row("Puggle's tail, lick and cheeks for each feeling") { feelingRow(puggle) }
            if let dad = Rig.load("dad") { row("Dad's tail and crest for each feeling") { feelingRow(dad) } }
            if let dad = Rig.load("dad-overalls"), let mum = Rig.load("mum-trousers") {
                row("Trousers in a walk: Dad in overalls, Mum in trousers") { walk(dad); walk(mum) }
            }
        }
        save(sheet, as: "loose-ends.png")
    }

    /// The hooray and the wave, frame by frame, to see the new tail move about its new pivot.
    private static func tailInMotion(_ puggle: Rig) {
        func frames(_ rig: Rig, _ move: String, _ times: [Double]) -> [[String: PartState]] {
            let runtime = RigRuntime(rig: rig)
            runtime.blinkAt = .distantPast
            let start = Date.now
            _ = runtime.advance(to: start)
            runtime.play(move, at: start)
            var out: [[String: PartState]] = [], t = 0.0
            for until in times {
                while t < until { t += 0.016; _ = runtime.advance(to: start.addingTimeInterval(t)) }
                out.append(runtime.advance(to: start.addingTimeInterval(until)))
            }
            return out
        }
        let times = [0.1, 0.3, 0.5, 0.7, 0.9, 1.2, 1.6]
        func strip(_ title: String, _ rig: Rig, _ move: String) -> some View {
            let states = frames(rig, move, times)
            return row(title) {
                ForEach(states.indices, id: \.self) { i in
                    RigFrame(rig: rig, states: states[i], face: nil).frame(width: 110 * rig.size[0] / 300, height: 110 * rig.size[1] / 300)
                        .frame(width: 120, height: 190, alignment: .bottom)
                }
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 14) {
            Text("Tails in motion: frames at 0.1 to 1.6 seconds").font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            strip("Puggle: hooray", puggle, "celebrate")
            strip("Puggle: wave", puggle, "greet")
            if let dad = Rig.load("dad") { strip("Dad: hooray", dad, "celebrate") }
        }
        save(sheet, as: "tail-motion.png")
    }

    /// Other ways to draw Pebble's curl.
    private static func curlOptions() {
        guard let pebble = Rig.load("pebble") else { return }
        var bare = pebble
        bare.parts.removeAll { $0.id == "curl" }
        // An open loop is drawn as a line of fur with a dark edge, starting inside the head.
        func looped(_ d: String, _ start: String) -> Rig {
            var copy = bare
            guard let face = copy.parts.firstIndex(where: { $0.id == "face" }) else { return bare }
            copy.parts.insert(Rig.Part(id: "curl", parent: "head", pivot: [120, 54], spring: 110, when: nil, shapes: [
                Rig.Shape(kind: "path", d: d, stroke: dark, tint: furLine, width: 17, cap: "round"),
                Rig.Shape(kind: "path", d: start + d.dropFirst(d.prefix(while: { $0 != "Q" }).count), stroke: fur, width: 9, cap: "round"),
            ]), at: face + 1)
            return copy
        }
        let options: [(String, Rig)] = [
            ("A. Now", pebble),
            ("B. A soft peak", withHair(bare, ["M103 58 Q102 42 113 33 Q122 25 119 11 Q135 22 133 39 Q131 49 137 58 Z"])),
            ("F. A sprout of three", withHair(bare, ["M104 58 Q99 45 105 37 Q112 42 113 56 Z", "M111 56 Q111 38 120 29 Q129 38 129 56 Z", "M127 56 Q128 42 135 37 Q141 45 136 58 Z"])),
            // Three strands swept one way as a wave, each ending in a flick.
            ("G. Three strands, a wave", withHair(bare, [
                "M104 58 Q99 40 112 31 Q125 25 135 30 Q141 23 147 25 Q146 34 137 38 Q127 35 121 41 Q117 48 119 58 Z",
                "M115 58 Q113 47 123 43 Q133 41 140 45 Q146 40 151 42 Q149 50 141 52 Q133 50 129 53 Q127 55 128 58 Z",
                "M99 58 Q94 49 100 43 Q106 40 111 43 Q105 47 107 58 Z"])),
            ("H. One wave, three flicks", withHair(bare, [
                "M99 58 Q94 42 107 35 Q111 27 120 29 Q117 35 122 37 Q128 28 138 31 Q133 37 138 40 Q146 33 153 38 Q147 43 148 49 Q141 55 135 58 Z"])),
            ("I. Three strands, taller", withHair(bare, [
                "M106 58 Q98 36 112 24 Q124 16 134 22 Q140 14 147 16 Q147 27 137 31 Q127 27 121 35 Q117 45 120 58 Z",
                "M116 58 Q113 44 124 39 Q134 36 141 41 Q147 35 153 38 Q151 47 142 49 Q134 46 130 50 Q128 54 129 58 Z",
                "M100 58 Q93 46 100 38 Q107 34 112 39 Q105 43 108 58 Z"])),
        ]
        func column(_ name: String, _ rig: Rig) -> some View {
            VStack(spacing: 6) {
                RigFrame(rig: rig, states: [:], face: nil).frame(width: 200, height: 200 * rig.size[1] / rig.size[0])
                    .frame(width: 200, height: 150, alignment: .top).clipped()
                HStack(spacing: 8) {
                    RigFrame(rig: rig, states: [:], face: nil).frame(width: 70, height: 70 * rig.size[1] / rig.size[0])
                    RigFrame(rig: silhouette(rig), states: [:], face: nil).frame(width: 70, height: 70 * rig.size[1] / rig.size[0])
                }
                Text(name).font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 14) {
            Text("Pebble's curl: the head close up, then small, in colour and as a solid shape").font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            HStack(alignment: .bottom, spacing: 10) { ForEach(options.indices, id: \.self) { i in column(options[i].0, options[i].1) } }
        }
        save(sheet, as: "pebble-curl.png")
    }

    /// Pebble as built: awake with his bottle, asleep with his dummy, in each colour his babygro comes in.
    private static func dummy() {
        guard let pebble = Rig.load("pebble") else { return }
        let looks = pebble.wardrobe?.looks ?? [[:]]
        let names = ["Mint, his own", "Sky", "Shell", "Gum", "Waratah"]
        func column(_ name: String, _ rig: Rig) -> some View {
            VStack(spacing: 6) {
                RigFrame(rig: rig, states: [:], face: nil).frame(width: 150, height: 150 * rig.size[1] / rig.size[0])
                RigFrame(rig: rig, states: [:], face: ["eyes": "closed"]).frame(width: 150, height: 150 * rig.size[1] / rig.size[0])
                RigFrame(rig: rig, states: [:], face: ["eyes": "closed"]).frame(width: 56, height: 56 * rig.size[1] / rig.size[0])
                Text(name).font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 14) {
            Text("Pebble. Top: awake, with his bottle. Middle: asleep, with his dummy. Bottom: asleep at scene size")
                .font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(looks.indices, id: \.self) { i in column(i < names.count ? names[i] : "", pebble.wearing(looks[i])) }
            }
        }
        save(sheet, as: "pebble-dummy.png")
    }

    /// The eye smear, frame by frame: what is drawn in the moments after her eyes jump.
    private static func smear(_ puggle: Rig) {
        func frames(refined: Bool) -> [[String: PartState]] {
            let runtime = RigRuntime(rig: puggle)
            runtime.refined = refined
            runtime.blinkAt = .distantPast       // no blinks or tilts of her own
            let start = Date.now
            var out = [runtime.advance(to: start)]
            runtime.look = CGPoint(x: -1, y: 0)
            _ = runtime.advance(to: start.addingTimeInterval(0.1))
            _ = runtime.advance(to: start.addingTimeInterval(0.2))
            runtime.look = CGPoint(x: 1, y: 0)
            for after in [0.216, 0.25, 0.3] { out.append(runtime.advance(to: start.addingTimeInterval(after))) }
            return out
        }
        let labels = ["Before", "16 ms after", "50 ms after", "100 ms after"]
        func strip(_ title: String, _ states: [[String: PartState]]) -> some View {
            row(title) {
                ForEach(states.indices, id: \.self) { i in cell(puggle, states[i], height: 130, caption: labels[i], headOnly: true) }
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 18) {
            Text("Her eyes jump from one side to the other").font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            strip("Before today: they jump", frames(refined: false))
            strip("Now: one stretched frame on the way", frames(refined: true))
        }
        save(sheet, as: "eye-smear.png")
    }

    /// Other things than a bun for Nan.
    private static func nanHair() {
        guard let nan = Rig.load("nan") else { return }
        var bare = nan
        bare.parts.removeAll { $0.id == "bun" || $0.id == "bun-top" }
        // Her head sits lower in her drawing, to leave room for her umbrella.
        let down = nan.headroom ?? 0
        func placed(_ d: String) -> String {
            var out = "", number = "", isY = false
            func flush() { if !number.isEmpty { out += isY ? "\((Double(number) ?? 0) + down)" : number; isY.toggle(); number = "" } }
            for ch in d { if ch.isNumber || ch == "." || ch == "-" { number.append(ch) } else { flush(); out.append(ch) } }
            flush()
            return out
        }
        let options: [(String, [String])] = [
            ("B. A set of curls", ["M70 70 Q58 52 74 44 Q76 30 94 34 Q102 22 120 28 Q138 22 146 34 Q164 30 166 44 Q182 52 170 70 Z"]),
            ("C. A soft roll", ["M72 70 Q62 40 92 34 Q120 26 148 34 Q178 40 168 70 Q150 52 120 52 Q90 52 72 70 Z"]),
            ("D. A wave to one side", ["M78 68 Q66 44 90 34 Q118 24 144 36 Q160 46 156 60 Q144 48 126 50 Q108 54 104 68 Z"]),
            ("E. A plait round her head", ["M64 78 Q62 50 84 44 Q88 34 104 38 Q112 30 124 36 Q138 30 144 40 Q160 40 162 54 Q176 60 174 78 Q160 62 120 60 Q80 62 64 78 Z"]),
        ]
        func column(_ name: String, _ rig: Rig) -> some View {
            VStack(spacing: 6) {
                RigFrame(rig: rig, states: [:], face: nil).frame(width: 225, height: 225 * rig.size[1] / rig.size[0])
                    .frame(width: 225, height: 215, alignment: .top).clipped()
                HStack(spacing: 8) {
                    RigFrame(rig: rig, states: [:], face: nil).frame(width: 84 * rig.size[0] / rig.size[1], height: 84)
                    RigFrame(rig: silhouette(rig), states: [:], face: nil).frame(width: 84 * rig.size[0] / rig.size[1], height: 84)
                }
                Text(name).font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 14) {
            Text("Hair for Nan").font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            HStack(alignment: .bottom, spacing: 14) {
                column("A. Now: a bun", nan)
                ForEach(options.indices, id: \.self) { i in column(options[i].0, withHair(bare, options[i].1.map(placed))) }
            }
        }
        save(sheet, as: "nan-hair.png")
    }

    /// Digby and Sunny with their hats on, and off: what is under them.
    private static func hatsOff() {
        guard let digby = Rig.load("digby"), let sunny = Rig.load("sunny") else { return }
        func pair(_ name: String, _ rig: Rig) -> some View {
            HStack(alignment: .bottom, spacing: 12) {
                cell(rig, height: 150, caption: "\(name), hat on", headOnly: true)
                cell(rig, height: 150, caption: "Hat off", headOnly: true).environment(\.outfit, "bare")
                RigFrame(rig: rig, states: [:], face: nil).frame(width: 90 * rig.size[0] / rig.size[1], height: 90).environment(\.outfit, "bare")
                RigFrame(rig: silhouette(rig), states: [:], face: nil).frame(width: 90 * rig.size[0] / rig.size[1], height: 90).environment(\.outfit, "bare")
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 18) {
            Text("Under the hats").font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            pair("Digby", digby)
            pair("Sunny", sunny)
            HStack(alignment: .bottom, spacing: 12) {
                if let puggle = Rig.load("puggle"), let mum = Rig.load("mum") {
                    cell(puggle, height: 150, caption: "Puggle's beanie", headOnly: true).environment(\.outfit, "warm")
                    cell(mum, height: 150, caption: "Mum's beanie", headOnly: true).environment(\.outfit, "warm")
                    cell(sunny, height: 150, caption: "Sunny's beanie", headOnly: true).environment(\.outfit, "warm")
                }
            }
        }
        save(sheet, as: "hats-off.png")
    }

    // MARK: Hair for Mum and Dad

    /// Hair drawn the way the ears are: the outlined shape behind the head, its fur over the seam in front.
    private static func withHair(_ rig: Rig, _ locks: [String]) -> Rig {
        var copy = rig
        guard let face = copy.parts.firstIndex(where: { $0.id == "face" }) else { return rig }
        let behind = locks.map { Rig.Shape(kind: "path", d: $0, fill: fur, stroke: dark, tint: furLine, width: 14) }
        let over = locks.map { Rig.Shape(kind: "path", d: $0, fill: fur) }
        copy.parts.insert(Rig.Part(id: "hair-top", parent: "hair", pivot: [120, 60], spring: nil, when: nil, shapes: over), at: face + 1)
        copy.parts.insert(Rig.Part(id: "hair", parent: "head", pivot: [120, 60], spring: 120, when: nil, shapes: behind), at: face)
        return copy
    }

    private static let sweep = "M88 64 Q80 44 96 35 Q114 28 130 38 Q139 45 137 55 Q128 46 117 48 Q107 52 110 64 Z"
    private static let mumHair: [(String, [String])] = [
        ("A. A side sweep", [sweep]),
        ("D. Sweep and flicks", [sweep, "M58 124 Q36 132 30 114 Q42 122 56 108 Z", "M182 124 Q204 132 210 114 Q198 122 184 108 Z"]),
        ("D, smaller flicks", [sweep, "M58 126 Q44 131 40 119 Q48 124 57 114 Z", "M182 126 Q196 131 200 119 Q192 124 183 114 Z"]),
    ]
    private static let dadHair: [(String, [String])] = [
        ("A. A scruffy crest", ["M109 60 Q111 40 120 30 Q129 40 129 60 Z", "M98 62 Q93 46 101 37 Q109 44 112 60 Z", "M126 60 Q130 45 139 39 Q144 48 139 62 Z"]),
        ("D. Crest and cheek tufts", ["M109 60 Q111 40 120 30 Q129 40 129 60 Z", "M98 62 Q93 46 101 37 Q109 44 112 60 Z", "M126 60 Q130 45 139 39 Q144 48 139 62 Z", "M58 116 L34 122 L52 130 L36 142 L60 142 Z", "M182 116 L206 122 L188 130 L204 142 L180 142 Z"]),
        ("D, smaller tufts", ["M109 60 Q111 40 120 30 Q129 40 129 60 Z", "M98 62 Q93 46 101 37 Q109 44 112 60 Z", "M126 60 Q130 45 139 39 Q144 48 139 62 Z", "M58 120 L44 124 L54 130 L45 139 L60 140 Z", "M182 120 L196 124 L186 130 L195 139 L180 140 Z"]),
        ("D, one small tuft each side", ["M109 60 Q111 40 120 30 Q129 40 129 60 Z", "M98 62 Q93 46 101 37 Q109 44 112 60 Z", "M126 60 Q130 45 139 39 Q144 48 139 62 Z", "M57 123 L45 132 L58 139 Z", "M183 123 L195 132 L182 139 Z"]),
    ]

    private static func parentHair() {
        guard let mum = Rig.load("mum"), let dad = Rig.load("dad") else { return }
        func column(_ name: String, _ rig: Rig) -> some View {
            VStack(spacing: 6) {
                cell(rig, height: 150, headOnly: true)
                HStack(spacing: 8) {
                    RigFrame(rig: rig, states: [:], face: nil).frame(width: 70 * rig.size[0] / rig.size[1], height: 70)
                    RigFrame(rig: silhouette(rig), states: [:], face: nil).frame(width: 70 * rig.size[0] / rig.size[1], height: 70)
                }
                Text(name).font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 18) {
            Text("Hair for Mum and Dad: the head close up, then small, in colour and as a solid shape").font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
            row("Mum") {
                column("Now", mum)
                ForEach(mumHair.indices, id: \.self) { i in column(mumHair[i].0, withHair(mum, mumHair[i].1)) }
            }
            row("Dad") {
                column("Now", dad)
                ForEach(dadHair.indices, id: \.self) { i in column(dadHair[i].0, withHair(dad, dadHair[i].1)) }
            }
        }
        save(sheet, as: "parent-hair.png")
    }

    /// What ears, spines and hair do for each feeling: the poses the animation test plays.
    private static func feelings(_ puggle: Rig) {
        let cast = [puggle, Rig.load("pebble"), Rig.load("kip"), Rig.load("quill"), Rig.load("sunny")].compactMap { $0 }
        func line(_ name: String, _ held: [String: PartState]) -> some View {
            HStack(spacing: 6) {
                Text(name).font(.system(size: 15, weight: .bold)).frame(width: 96, alignment: .leading)
                ForEach(cast.indices, id: \.self) { i in
                    var states = held
                    if cast[i].name == "Sunny" { states["head-2"] = state(y: -400) }   // hat off, to see her ears
                    return RigFrame(rig: cast[i], states: states, face: nil).frame(width: 132, height: 132 * cast[i].size[1] / 300)
                        .frame(height: 150, alignment: .bottom)
                }
            }
        }
        let sheet = VStack(alignment: .leading, spacing: 8) {
            Text("Ears, spines and hair for each feeling (proposed)").font(.system(size: 17, weight: .bold))
            line("At rest", [:])
            ForEach(AnimationTestView.feelings.indices, id: \.self) { i in
                line(AnimationTestView.feelings[i].name, AnimationTestView.feelings[i].held())
            }
        }
        .padding(24).background(Color(red: 0.95, green: 0.93, blue: 0.87)).foregroundStyle(Color(red: 0.23, green: 0.16, blue: 0.13))
        .environment(\.lineStyle, .chosen)
        save(sheet, as: "feelings.png")
    }

    /// Ears, spines, bun, curl and lick are parts of their own: at rest, and each one posed by itself.
    private static func headParts(_ puggle: Rig) {
        func cell(_ rig: Rig, _ states: [String: PartState], _ label: String) -> some View {
            VStack(spacing: 6) {
                RigFrame(rig: rig, states: states, face: nil).frame(width: 150, height: 190)
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(red: 0.23, green: 0.16, blue: 0.13))
            }
        }
        let cast: [(String, Rig?, [String: PartState])] = [
            ("Puggle: lick", puggle, ["lick": state(r: 24)]),
            ("Pebble: curl", Rig.load("pebble"), ["curl": state(r: -22)]),
            ("Kip: ears", Rig.load("kip"), ["ear-left": state(r: -24), "ear-right": state(r: 10)]),
            ("Sunny: ears", Rig.load("sunny"), ["ear-left": state(r: -20), "ear-right": state(r: 20), "head-2": state(y: -400)]),
            ("Quill: spines", Rig.load("quill"), ["spine-1": state(r: -16), "spine-3": state(r: -14), "spine-5": state(r: 16), "spine-7": state(r: 14), "spine-8": state(r: 18)]),
            ("Nan: bun", Rig.load("nan"), ["bun": state(r: 0, x: 0, y: 0, sx: 1.25, sy: 1.25)]),
        ]
        let sheet = VStack(alignment: .leading, spacing: 14) {
            Text("Each is its own part. Top: at rest. Bottom: that part alone moved").font(.system(size: 15, weight: .bold))
            HStack(spacing: 10) { ForEach(cast.indices, id: \.self) { i in if let rig = cast[i].1 { cell(rig, [:], cast[i].0) } } }
            HStack(spacing: 10) { ForEach(cast.indices, id: \.self) { i in if let rig = cast[i].1 { cell(rig, cast[i].2, "moved") } } }
        }
        .padding(24).background(Color(red: 0.95, green: 0.93, blue: 0.87)).environment(\.lineStyle, .chosen)
        save(sheet, as: "head-parts.png")
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
