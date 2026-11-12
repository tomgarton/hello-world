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
        var frames: [(Double, [String: PartState])] = []
        var next = 0.0
        // Step as the screen would, 60 times a second, keeping a frame now and then.
        for tick in 0...Int(seconds * 60) {
            let t = Double(tick) / 60
            let states = runtime.advance(to: start.addingTimeInterval(t))
            if t + 0.0001 >= next {
                frames.append((t, states))
                next += every
            }
        }
        let strip = HStack(spacing: 2) {
            ForEach(Array(frames.enumerated()), id: \.offset) { _, frame in
                RigFrame(rig: rig, states: frame.1)
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
