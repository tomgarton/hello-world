import SwiftUI

/// The Puggle line icons for activities: one ink line and one Wattle accent.
/// Drawn in `design/canvas/gen/iconsys3.py`; each has a dark twin in the asset catalogue.
struct ActivityIcon: View {
    let name: String
    var size: CGFloat = 36

    init(_ kind: EventKind, size: CGFloat = 36) {
        self.name = kind.iconName
        self.size = size
    }

    init(named name: String, size: CGFloat = 36) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

extension EventKind {
    var iconName: String {
        switch self {
        case .bottle: "icon-bottle"
        case .breastfeed: "icon-breastfeed"
        case .solids: "icon-solids"
        case .sleep: "icon-sleep"
        case .nappy: "icon-nappy"
        case .potty: "icon-potty"
        case .note: "icon-note"
        case .weight: "icon-weight"
        case .medicine: "icon-medicine"
        case .temperature: "icon-temperature"
        case .vaccination: "icon-vaccine"
        case .milestone: "icon-milestone"
        }
    }
}

/// Puggle's face on the Wattle tile: the same mark as the app icon.
struct PuggleMark: View {
    var size: CGFloat = 132

    var body: some View {
        Image("PuggleMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Puggle standing, as a still picture. The animated character replaces this
/// where `PuggleView` is used, once the Rive file exists.
struct PuggleStanding: View {
    var height: CGFloat = 160

    var body: some View {
        Image("PuggleStill")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Puggle")
    }
}

/// The logotype: lowercase, in the display face. Only on the splash, the icon and Help.
struct Wordmark: View {
    var size: CGFloat = 44

    var body: some View {
        Text("puggle")
            .font(.display(size))
            .tracking(-size * 0.04)
            .foregroundStyle(Palette.ink)
            .accessibilityLabel("Puggle")
    }
}

/// Shown for a moment each time the app is opened from cold. It matches the
/// launch screen underneath, so the mark does not jump.
struct SplashView: View {
    var body: some View {
        ZStack {
            Palette.sand.ignoresSafeArea()
            PuggleMark()
            Wordmark()
                .offset(y: 66 + 14 + 26)
        }
        .accessibilityElement(children: .combine)
    }
}
