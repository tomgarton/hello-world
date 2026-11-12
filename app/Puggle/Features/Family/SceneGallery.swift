#if DEBUG
import SwiftUI

/// Test builds only: every Today scene at each time of day, for checking the
/// drawings side by side. Developer menu, or launch with "-debugGallery 0".
struct SceneGalleryView: View {
    @State var kind: SceneKind = .hills
    @State private var pull: CGFloat = 0
    @StateObject private var puggle = PuggleController()

    private static let looks: [(name: String, hour: Int, dark: Bool)] = [
        ("Morning", 7, false), ("Day", 13, false), ("Evening", 18, false), ("Late", 22, false), ("Dark mode", 22, true),
    ]

    /// Every scene and look in one picture, saved to Documents: "-debugSheet 1".
    @MainActor static func writeSheet(pull: CGFloat, name: String, style: LineStyle = .chosen) {
        let controller = PuggleController()
        let sheet = VStack(spacing: 4) {
            ForEach(looks, id: \.name) { look in
                HStack(spacing: 4) {
                    ForEach(SceneKind.allCases, id: \.rawValue) { kind in
                        ZStack(alignment: .bottom) {
                            PuggleScene(kind: kind, dark: look.dark, pull: pull, hourOverride: look.hour)
                            PuggleView(controller: controller, frozen: true).frame(height: 118).padding(.bottom, 26)
                                .environment(\.moonlit, PuggleScene.isNight(dark: look.dark, hour: look.hour))
                                .environment(\.warmLight, PuggleScene.lamp(for: kind, night: PuggleScene.isNight(dark: look.dark, hour: look.hour)))
                        }
                        .frame(width: 402, height: PuggleHeader.sceneHeight + pull)
                        .clipped()
                        .environment(\.colorScheme, look.dark ? .dark : .light)
                    }
                }
            }
        }
        .background(Color.gray)
        .environment(\.lineStyle, style)
        save(sheet, as: name)
    }

    /// The two line styles side by side: the characters large, then each scene by day and after dark.
    @MainActor static func writeLineStyles(name: String) {
        let controller = PuggleController()
        func cast(_ style: LineStyle, dark: Bool) -> some View {
            HStack(spacing: 18) {
                PuggleView(controller: controller, frozen: true).frame(width: 150, height: 188).environment(\.moonlit, dark)
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        Bird(dark: dark).frame(width: 46, height: 38).scaleEffect(2).frame(width: 92, height: 76)
                        Crab(dark: dark).frame(width: 60, height: 40).scaleEffect(2).frame(width: 120, height: 80)
                    }
                    HStack(spacing: 14) {
                        Snail(dark: dark).frame(width: 54, height: 38).scaleEffect(2).frame(width: 108, height: 76)
                        Kookaburra(dark: dark).frame(width: 52, height: 54).scaleEffect(1.7).frame(width: 88, height: 92)
                    }
                }
            }
            .frame(width: 402, height: 230)
            .background(dark ? Color(hex: 0x25275C) : Color(hex: 0xF2ECDD))
            .overlay(alignment: .topLeading) {
                Text(style == .ink ? "One dark line" : "Coloured lines").font(.caption.weight(.semibold))
                    .foregroundStyle(dark ? Color.white : Color.black).padding(8)
            }
            .environment(\.lineStyle, style)
        }
        func scene(_ kind: SceneKind, _ style: LineStyle, dark: Bool) -> some View {
            ZStack(alignment: .bottom) {
                PuggleScene(kind: kind, dark: dark, hourOverride: dark ? 22 : 13)
                PuggleView(controller: controller, frozen: true).frame(height: 118).padding(.bottom, 26)
                    .environment(\.moonlit, dark)
            }
            .frame(width: 402, height: PuggleHeader.sceneHeight)
            .clipped()
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.lineStyle, style)
        }
        let sheet = VStack(spacing: 4) {
            ForEach([false, true], id: \.self) { dark in
                HStack(spacing: 4) { cast(.ink, dark: dark); cast(.tinted, dark: dark) }
            }
            ForEach(SceneKind.allCases, id: \.rawValue) { kind in
                ForEach([false, true], id: \.self) { dark in
                    HStack(spacing: 4) { scene(kind, .ink, dark: dark); scene(kind, .tinted, dark: dark) }
                }
            }
        }
        .background(Color.gray)
        save(sheet, as: name)
    }

    /// A move as a strip of frames, one every `every` seconds: "-debugSheet 1".
    @MainActor static func writeStrip(move: String?, seconds: Double, every: Double, name: String) {
        guard let rig = Rig.load("puggle") else { return }
        let runtime = RigRuntime(rig: rig)
        let start = Date.now
        _ = runtime.advance(to: start)
        if let move { runtime.play(move, at: start) }
        if move == "greet" || move == "nod" { runtime.play("wag", at: start) }
        var frames: [(Double, [String: PartState], [String: String])] = []
        var next = 0.0
        // Step as the screen would, 60 times a second, keeping a frame now and then.
        for tick in 0...Int(seconds * 60) {
            let t = Double(tick) / 60
            let states = runtime.advance(to: start.addingTimeInterval(t))
            if t + 0.0001 >= next {
                frames.append((t, states, runtime.face))
                next += every
            }
        }
        let strip = HStack(spacing: 2) {
            ForEach(Array(frames.enumerated()), id: \.offset) { _, frame in
                RigFrame(rig: rig, states: frame.1, face: frame.2)
                    .frame(width: 120, height: 150)
                    .background(Color(hex: 0xF2ECDD))
                    .overlay(alignment: .topLeading) {
                        Text(String(format: "%.2f", frame.0)).font(.system(size: 9)).foregroundStyle(.black).padding(3)
                    }
            }
        }
        .background(Color.gray)
        save(strip, as: name)
    }

    /// Puggle three ways: as she was, with the yellow pocket and clip detail, and drawn by hand.
    @MainActor static func writeDrawingStyles(name: String) {
        guard let rig = Rig.load("puggle") else { return }
        // "Before": the pocket unfilled and the clip plain.
        var before = rig
        for index in before.parts.indices {
            if before.parts[index].id == "dress" { before.parts[index].shapes[1].fill = nil; before.parts[index].shapes[1].tint = "#1B4387" }
            if before.parts[index].id == "clip" { before.parts[index].shapes.removeLast(3) }
        }
        let happy: [String: PartState] = {
            var up = PartState(); up.y = -4
            var glow = PartState(); glow.sx = 1.14; glow.sy = 1.14
            var tilt = PartState(); tilt.r = -5
            return ["brow-left": up, "brow-right": up, "blush": glow, "head": tilt]
        }()
        func cell(_ rig: Rig, _ title: String, hand: Bool, dark: Bool, face: [String: String]? = nil, states: [String: PartState] = [:]) -> some View {
            RigFrame(rig: rig, states: states, face: face)
                .environment(\.handDrawn, hand)
                .environment(\.moonlit, dark)
                .frame(width: 300, height: 375)
                .padding(12)
                .background(dark ? Color(hex: 0x25275C) : Color(hex: 0xF2ECDD))
                .overlay(alignment: .topLeading) {
                    Text(title).font(.caption.weight(.semibold)).foregroundStyle(dark ? Color.white : Color.black).padding(8)
                }
        }
        let sheet = VStack(spacing: 4) {
            HStack(spacing: 4) {
                cell(before, "As she was", hand: false, dark: false)
                cell(rig, "Yellow pocket, clip detail", hand: false, dark: false)
                cell(rig, "Drawn by hand", hand: true, dark: false)
            }
            HStack(spacing: 4) {
                cell(rig, "Happy", hand: false, dark: false, face: ["eyes": "happy", "brows": "on"], states: happy)
                cell(rig, "Happy, by hand", hand: true, dark: false, face: ["eyes": "happy", "brows": "on"], states: happy)
                cell(rig, "By hand, at night", hand: true, dark: true)
            }
        }
        .background(Color.gray)
        .environment(\.lineStyle, .tinted)
        save(sheet, as: name)
    }

    /// Options to choose between: the pocket, several ways.
    @MainActor static func writeOptions(name: String) {
        guard let rig = Rig.load("puggle") else { return }
        func shape(_ json: String) -> Rig.Shape { try! JSONDecoder().decode(Rig.Shape.self, from: Data(json.utf8)) }
        func pocket(fill: String?, line: String, flower: Double) -> Rig {
            var copy = rig
            for index in copy.parts.indices where copy.parts[index].id == "dress" {
                copy.parts[index].shapes[1].fill = fill
                copy.parts[index].shapes[1].tint = line
                guard flower > 0 else { continue }
                // A small white flower, its centre yellow.
                for turn in 0..<5 {
                    let angle = Double(turn) * 2 * .pi / 5 - .pi / 2
                    copy.parts[index].shapes.append(shape("{\"kind\":\"ellipse\",\"x\":\(120 + cos(angle) * 3.4 * flower),\"y\":\(222 + sin(angle) * 3.4 * flower),\"rx\":\(2.7 * flower),\"ry\":\(2.7 * flower),\"fill\":\"#FFFDF6\"}"))
                }
                copy.parts[index].shapes.append(shape("{\"kind\":\"ellipse\",\"x\":120,\"y\":222,\"rx\":\(2.1 * flower),\"ry\":\(2.1 * flower),\"fill\":\"#F4C95D\"}"))
            }
            return copy
        }
        func cell(_ rig: Rig, _ title: String) -> some View {
            RigFrame(rig: rig, states: [:])
                .frame(width: 300, height: 375)
                .padding(12)
                .background(Color(hex: 0xF2ECDD))
                .overlay(alignment: .topLeading) { Text(title).font(.caption.weight(.semibold)).foregroundStyle(.black).padding(8) }
        }
        let sheet = VStack(spacing: 4) {
            HStack(spacing: 4) {
                cell(pocket(fill: "#8FB4E3", line: "#1B4387", flower: 0), "1. Light blue pocket")
                cell(pocket(fill: "#5E90DA", line: "#1B4387", flower: 0), "2. Mid blue pocket")
                cell(pocket(fill: nil, line: "#1B4387", flower: 0), "3. Outline only")
            }
            HStack(spacing: 4) {
                cell(pocket(fill: "#8FB4E3", line: "#1B4387", flower: 1), "4. Light blue, tiny flower")
                cell(pocket(fill: nil, line: "#1B4387", flower: 1), "5. Outline, tiny flower")
                cell(pocket(fill: "#8FB4E3", line: "#5E86C8", flower: 0), "6. Light blue, softer line")
            }
        }
        .background(Color.gray)
        .environment(\.lineStyle, .tinted)
        .environment(\.handDrawn, false)
        save(sheet, as: name)
    }

    @MainActor private static func save(_ view: some View, as name: String) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let data = renderer.uiImage?.pngData() else { return }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        try? data.write(to: url)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Picker("Scene", selection: $kind) {
                    Text("Hills").tag(SceneKind.hills)
                    Text("Beach").tag(SceneKind.beach)
                    Text("Backyard").tag(SceneKind.backyard)
                    Text("Bush").tag(SceneKind.bush)
                }
                .pickerStyle(.segmented)
                Slider(value: $pull, in: 0...460) { Text("Pulled down") }
                    .accessibilityLabel("Pulled down")
                ForEach(Self.looks, id: \.name) { look in
                    ZStack(alignment: .bottom) {
                        PuggleScene(kind: kind, dark: look.dark, pull: pull, hourOverride: look.hour)
                        PuggleView(controller: puggle).frame(height: 118).padding(.bottom, 26)
                            .environment(\.moonlit, PuggleScene.isNight(dark: look.dark, hour: look.hour))
                            .environment(\.warmLight, PuggleScene.lamp(for: kind, night: PuggleScene.isNight(dark: look.dark, hour: look.hour)))
                    }
                    .frame(height: PuggleHeader.sceneHeight + pull)
                    .overlay(alignment: .topLeading) {
                        Text(look.name).font(.caption2.weight(.semibold)).padding(4)
                            .background(.black.opacity(0.35), in: Capsule()).foregroundStyle(.white).padding(6)
                    }
                    .environment(\.colorScheme, look.dark ? .dark : .light)
                }
            }
        }
        .background(Palette.sand)
        .navigationTitle("Scenes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
