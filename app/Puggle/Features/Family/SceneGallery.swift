#if DEBUG
import SwiftUI

/// Test builds only: every Today scene at each time of day, for checking the
/// drawings side by side. Developer menu, or launch with "-debugGallery 0".
struct SceneGalleryView: View {
    @State var kind: SceneKind = .hills
    @State private var pull: CGFloat = 0
    @State private var weather = Weather.current
    @StateObject private var puggle = PuggleController()

    private static let looks: [(name: String, hour: Int, dark: Bool)] = [
        ("Morning", 7, false), ("Day", 13, false), ("Evening", 18, false), ("Late", 22, false), ("Dark mode", 22, true),
    ]

    /// Every scene and look in one picture, saved to Documents: "-debugSheet 1".
    /// `empty` leaves Puggle out, so a scene can sit behind something else.
    @MainActor static func writeSheet(pull: CGFloat, name: String, style: LineStyle = .chosen, empty: Bool = false) {
        let controller = PuggleController()
        let sheet = VStack(spacing: 4) {
            ForEach(looks, id: \.name) { look in
                HStack(spacing: 4) {
                    ForEach(SceneKind.allCases, id: \.rawValue) { kind in
                        ZStack(alignment: .bottom) {
                            PuggleScene(kind: kind, dark: look.dark, pull: pull, hourOverride: look.hour, puggleX: PuggleScene.stand(for: kind) * 402)
                            if !empty {
                                PuggleView(controller: controller, frozen: true).frame(height: 118).padding(.bottom, 26)
                                    .offset(x: PuggleScene.stand(for: kind) * 402)
                                    .environment(\.moonlit, PuggleScene.isNight(dark: look.dark, hour: look.hour))
                                    .environment(\.warmLight, PuggleScene.lamp(for: kind, night: PuggleScene.isNight(dark: look.dark, hour: look.hour)))
                            }
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

    /// The whole cast beside Puggle, to scale, by day and in the coloured line at night.
    @MainActor static func writeCast(name: String) {
        let puggle = PuggleController()
        func row(dark: Bool) -> some View {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach([CastMember.nan, .mum, .dad, .pop], id: \.self) { member in
                    CastView(controller: CastController(member), frozen: true).frame(height: member.height)
                }
                PuggleView(controller: puggle, frozen: true).frame(height: 118)
                ForEach([CastMember.pebble, .quill, .kip, .digby, .sunny], id: \.self) { member in
                    CastView(controller: CastController(member), frozen: true).frame(height: member.height)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(dark ? Color(hex: 0x25275C) : Color(hex: 0xF2ECDD))
            .environment(\.moonlit, dark)
        }
        let sheet = VStack(spacing: 4) { row(dark: false); row(dark: true) }
            .frame(width: 1100)
            .background(Color.gray)
            .environment(\.lineStyle, .chosen)
        save(sheet, as: name)
    }

    /// The firework of Puggle's face, from the rocket going up to the sparks fading.
    @MainActor static func writeFirework(name: String) {
        let strip = HStack(spacing: 4) {
            ForEach([0.4, 0.8, 1.1, 1.6, 2.6, 3.6, 4.4], id: \.self) { moment in
                PuggleFirework(t: moment).frame(width: 150, height: 130).padding(10).background(Color(hex: 0x1C1F52))
            }
        }
        .background(Color.gray)
        save(strip, as: name)
    }

    /// The four rooms, in the evening light and in the dark look, pulled down to show what hangs higher up.
    @MainActor static func writeRooms(pull: CGFloat, name: String) {
        let controller = PuggleController()
        let sheet = VStack(spacing: 4) {
            ForEach([false, true], id: \.self) { dark in
                HStack(spacing: 4) {
                    ForEach(Room.allCases, id: \.rawValue) { room in
                        ZStack(alignment: .bottom) {
                            RoomFrame(room: room, dark: dark, pull: pull, t: 3.2, hour: dark ? 22 : 19)
                            PuggleView(controller: controller, frozen: true).frame(height: 118).padding(.bottom, 26)
                                .environment(\.outfit, room.outfit)
                                .environment(\.warmLight, dark ? room.lamp : nil)
                            RoomFront(room: room, dark: dark)
                        }
                        .frame(width: 402, height: PuggleHeader.sceneHeight + pull)
                        .clipped()
                        .environment(\.colorScheme, dark ? .dark : .light)
                    }
                }
            }
        }
        .background(Color.gray)
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
                        Crab(dark: dark).frame(width: 76, height: 44).scaleEffect(2).frame(width: 152, height: 88)
                    }
                    HStack(spacing: 14) {
                        Snail(dark: dark).frame(width: 54, height: 38).scaleEffect(2).frame(width: 108, height: 76)
                        Kookaburra(dark: dark).frame(width: 66, height: 54).scaleEffect(1.7).frame(width: 112, height: 92)
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
    /// `clear` leaves out the background, the gaps and the times, for use as a see-through film strip.
    /// `rig` names another character's file; `frame` is the size each pose is drawn at, and `ground` what is behind it.
    @MainActor static func writeStrip(move: String?, seconds: Double, every: Double, name: String, clear: Bool = false,
                                      rig rigName: String = "puggle", frame: CGSize = CGSize(width: 120, height: 150), ground: Color = Color(hex: 0xF2ECDD)) {
        guard let rig = Rig.load(rigName) else { return }
        let runtime = RigRuntime(rig: rig)
        let start = Date.now
        _ = runtime.advance(to: start)
        if move == "asleep" { runtime.asleep = true }
        if move == "walk" { runtime.walking = true }
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
        if clear {
            let film = HStack(spacing: 0) {
                ForEach(Array(frames.enumerated()), id: \.offset) { _, frame in
                    RigFrame(rig: rig, states: frame.1, face: frame.2).frame(width: 160, height: 200)
                }
            }
            save(film, as: name)
            return
        }
        let size = frame
        let strip = HStack(spacing: 2) {
            ForEach(Array(frames.enumerated()), id: \.offset) { _, frame in
                RigFrame(rig: rig, states: frame.1, face: frame.2)
                    .frame(width: size.width, height: size.height)
                    .background(ground)
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

    /// Options to choose between: her cheeks, several ways, seen close.
    @MainActor static func writeOptions(name: String) {
        guard let rig = Rig.load("puggle") else { return }
        func shape(_ json: String) -> Rig.Shape { try! JSONDecoder().decode(Rig.Shape.self, from: Data(json.utf8)) }
        /// Both cheeks from one description of the left; `x` is mirrored for the right.
        func cheeks(_ make: (_ x: Double, _ side: Double) -> [String]) -> Rig {
            var copy = rig
            for index in copy.parts.indices where copy.parts[index].id == "blush" {
                copy.parts[index].shapes = (make(70, -1) + make(170, 1)).map(shape)
            }
            return copy
        }
        func oval(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ fill: String) -> String {
            "{\"kind\":\"ellipse\",\"x\":\(x),\"y\":\(y),\"rx\":\(rx),\"ry\":\(ry),\"fill\":\"\(fill)\"}"
        }
        func dash(_ x: Double, _ y: Double, _ colour: String, _ width: Double) -> String {
            "{\"kind\":\"path\",\"d\":\"M\(x - 2) \(y + 4) L\(x + 2) \(y - 4)\",\"stroke\":\"\(colour)\",\"width\":\(width),\"cap\":\"round\"}"
        }
        let options: [(String, Rig)] = [
            ("1. As now", rig),
            ("2. Plain round, no marks", cheeks { x, _ in [oval(x, 131, 9.5, 9.5, "#EE9C88")] }),
            ("3. Soft oval, quieter pink", cheeks { x, _ in [oval(x, 132, 12, 7.5, "#C27C66")] }),
            ("4. Three small marks only", cheeks { x, _ in [dash(x - 6, 131, "#E58A76", 3), dash(x, 131, "#E58A76", 3), dash(x + 6, 131, "#E58A76", 3)] }),
            ("5. Oval with two soft marks", cheeks { x, _ in [oval(x, 132, 11.5, 7.5, "#E8917C"), dash(x - 3, 132, "#F7B9A8", 2.6), dash(x + 3, 132, "#F7B9A8", 2.6)] }),
            ("6. Small and round, with a glint", cheeks { x, side in [oval(x, 132, 8, 8, "#EE9C88"), oval(x - 2.5, 129, 2.2, 2.2, "#F9C4B6")] }),
        ]
        func cell(_ rig: Rig, _ title: String) -> some View {
            ZStack(alignment: .top) {
                Color(hex: 0xF2ECDD)
                RigFrame(rig: rig, states: [:])
                    .frame(width: 560, height: 700)
                    .offset(y: -70)
            }
            .frame(width: 420, height: 380)
            .clipped()
            .overlay(alignment: .topLeading) { Text(title).font(.caption.weight(.semibold)).foregroundStyle(.black).padding(8) }
        }
        let sheet = VStack(spacing: 4) {
            HStack(spacing: 4) { ForEach(0..<3, id: \.self) { cell(options[$0].1, options[$0].0) } }
            HStack(spacing: 4) { ForEach(3..<6, id: \.self) { cell(options[$0].1, options[$0].0) } }
        }
        .background(Color.gray)
        .environment(\.lineStyle, .tinted)
        .environment(\.handDrawn, false)
        save(sheet, as: name)
    }

    /// Every kind of weather in every scene, by day, with what she wears for it.
    @MainActor static func writeWeather(name: String, dark: Bool) {
        let controller = PuggleController()
        let sheet = VStack(spacing: 4) {
            ForEach(Weather.allCases) { weather in
                HStack(spacing: 4) {
                    ForEach(SceneKind.allCases, id: \.rawValue) { kind in
                        ZStack(alignment: .bottom) {
                            PuggleScene(kind: kind, dark: dark, hourOverride: dark ? 22 : 13, still: true, weather: weather)
                            PuggleView(controller: controller, frozen: true).frame(height: 118).padding(.bottom, 26)
                                .environment(\.moonlit, dark)
                                .environment(\.outfit, weather.outfit(night: dark))
                        }
                        .frame(width: 402, height: PuggleHeader.sceneHeight)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            Text(weather.name).font(.caption2.weight(.semibold)).padding(4)
                                .background(.black.opacity(0.35), in: Capsule()).foregroundStyle(.white).padding(6)
                        }
                        .environment(\.colorScheme, dark ? .dark : .light)
                    }
                }
            }
        }
        .background(Color.gray)
        .environment(\.lineStyle, .tinted)
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
                Picker("Weather", selection: $weather) {
                    ForEach(Weather.allCases) { Text($0.name).tag($0) }
                }
                .pickerStyle(.menu)
                Slider(value: $pull, in: 0...460) { Text("Pulled down") }
                    .accessibilityLabel("Pulled down")
                ForEach(Self.looks, id: \.name) { look in
                    ZStack(alignment: .bottom) {
                        PuggleScene(kind: kind, dark: look.dark, pull: pull, hourOverride: look.hour, weather: weather)
                        PuggleView(controller: puggle).frame(height: 118).padding(.bottom, 26)
                            .environment(\.outfit, weather.outfit(night: PuggleScene.isNight(dark: look.dark, hour: look.hour)))
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
