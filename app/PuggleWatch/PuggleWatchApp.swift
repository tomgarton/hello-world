import SwiftUI

@main
struct PuggleWatchApp: App {
    @StateObject private var model = WatchModel.shared

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
        }
    }
}

/// Puggle's colours on the Watch, as on the Lock Screen card.
enum Tone {
    static let night = Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x40 / 255)
    static let moon = Color(red: 0xF3 / 255, green: 0xE0 / 255, blue: 0xB8 / 255)
    static let cream = Color(red: 0xFB / 255, green: 0xF6 / 255, blue: 0xE9 / 255)
    static let ink = Color(red: 0x3A / 255, green: 0x2A / 255, blue: 0x20 / 255)
    /// A feed running: the warm yellow of the scenes' sun, for words and buttons.
    static let milk = Color(red: 0xF4 / 255, green: 0xC9 / 255, blue: 0x5D / 255)
    /// And the screen behind them: a deep honey, dark enough that the Watch's white clock still reads on it
    /// (the clock is always white; Tom, 20 November 2026).
    static let honey = Color(red: 0x7A / 255, green: 0x4E / 255, blue: 0x10 / 255)

    /// The children's colours, as in the app (Sky, Shell, Mint, Sun, Lilac, Rose, Sea, Stone).
    private static let children: [UInt32] = [0xBFD9F5, 0xF3D9C9, 0xCFE5D2, 0xF4E7B0, 0xE2D4F1, 0xF6CFDC, 0xC4E6E4, 0xDDD8D0]

    static func child(_ index: Int) -> Color {
        let hex = children[((index % children.count) + children.count) % children.count]
        return Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A child's initial on their colour.
struct Badge: View {
    let child: WidgetSnapshot.Child
    var size: CGFloat = 26

    var body: some View {
        Text(String(child.name.prefix(1)).uppercased())
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(Tone.ink)
            .frame(width: size, height: size)
            .background(Tone.child(child.colourIndex), in: Circle())
            .accessibilityHidden(true)
    }
}

struct RootView: View {
    @EnvironmentObject private var model: WatchModel
    /// The child showing. For checking, "-previewChild 1" opens on the second.
    @State private var page: String = {
        let children = WatchModel.shared.snapshot?.children ?? []
        let index = UserDefaults.standard.integer(forKey: "previewChild")
        return children.indices.contains(index) ? children[index].id : (children.first?.id ?? "")
    }()

    var body: some View {
        Group {
            if let children = model.snapshot?.children, !children.isEmpty {
                // One page each, side by side; the title says whose it is.
                // In a navigation stack, so what scrolls up fades under the clock instead of running behind it.
                if Pages.on {
                    // The paged trial: each child has pages of their own, turned with the crown.
                    TabView(selection: $page) {
                        ForEach(children) { child in
                            PagedChild(child: child).tag(child.id)
                        }
                    }
                    .tabViewStyle(.page)
                } else {
                NavigationStack {
                    TabView(selection: $page) {
                        ForEach(children) { child in
                            ChildPage(child: child).tag(child.id)
                        }
                    }
                    .tabViewStyle(.page)
                }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "iphone")
                        .font(.title2)
                        .foregroundStyle(Tone.moon)
                    Text("Open Puggle on your iPhone")
                        .font(.system(.headline, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("Your children appear here once it has run.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .alert(model.trouble ?? "", isPresented: Binding(get: { model.trouble != nil }, set: { if !$0 { model.trouble = nil } })) {
            Button("Close", role: .cancel) {}
        } message: {
            Text("Keep your iPhone nearby, then try again.")
        }
    }
}
