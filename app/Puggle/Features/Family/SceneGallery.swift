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
    @MainActor static func writeSheet(pull: CGFloat, name: String) {
        let controller = PuggleController()
        let sheet = VStack(spacing: 4) {
            ForEach(looks, id: \.name) { look in
                HStack(spacing: 4) {
                    ForEach(SceneKind.allCases, id: \.rawValue) { kind in
                        ZStack(alignment: .bottom) {
                            PuggleScene(kind: kind, dark: look.dark, pull: pull, hourOverride: look.hour)
                            PuggleView(controller: controller).frame(height: 118).padding(.bottom, 26)
                        }
                        .frame(width: 402, height: PuggleHeader.sceneHeight + pull)
                        .clipped()
                        .environment(\.colorScheme, look.dark ? .dark : .light)
                    }
                }
            }
        }
        .background(Color.gray)
        let renderer = ImageRenderer(content: sheet)
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
