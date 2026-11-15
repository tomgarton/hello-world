import SwiftUI

/// The Puggle icons for activities: an ink line and one fill.
/// Drawn in `docs/tools/make_icons.py`, which writes each as parts: the line, the fill and,
/// for the breast, any colour that never changes. The fill is yellow unless Settings says otherwise.
struct ActivityIcon: View {
    let name: String
    var size: CGFloat = 36
    /// One colour, for lists: the line in ink and the fill a faint tint of it.
    var plain = false
    @AppStorage(Setting.iconColour) private var mode = IconColour.yellow.rawValue
    @AppStorage(Setting.iconColourOwn) private var own = IconColour.ownDefault
    @Environment(\.iconChildColour) private var childColour
    /// Bounces once each time this number changes: something was just saved. From Apple's symbol effects,
    /// where a bounce says an action has happened (Tom, 15 November 2026).
    var bounce = 0
    /// The colour inside breathes while this is true: something is running, such as a feed. Only the colour
    /// moves, so the line stays steady and readable.
    var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false
    @State private var breath = false

    init(_ kind: EventKind, size: CGFloat = 36, plain: Bool = false) {
        self.name = kind.iconName
        self.size = size
        self.plain = plain
    }

    init(named name: String, size: CGFloat = 36, bounce: Int = 0, breathing: Bool = false) {
        self.name = name
        self.size = size
        self.bounce = bounce
        self.breathing = breathing
    }

    /// The drawing with more detail, from 32 points up.
    private var parts: String { size >= 32 && UIImage(named: name + "-reg-line") != nil ? name + "-reg" : name }

    private var fill: Color {
        switch IconColour(rawValue: mode) ?? .yellow {
        case .yellow: Palette.iconYellow
        case .own: Color(hex: UInt32(truncatingIfNeeded: own))
        // Pumping is the parent's, not a child's.
        case .child: name == EventKind.pump.iconName ? Palette.iconYellow : childColour ?? Palette.iconYellow
        }
    }

    var body: some View {
        Group {
            if plain, let trimmed = TrimmedIcon.image(name + "-plain") {
                Image(uiImage: trimmed).resizable().renderingMode(.template).foregroundStyle(Palette.ink)
            } else if plain {
                Image(name + "-plain").resizable().renderingMode(.template).foregroundStyle(Palette.ink)
            } else if UIImage(named: parts + "-line") != nil {
                ZStack {
                    Group {
                        if UIImage(named: parts + "-fill") != nil {
                            Image(parts + "-fill").resizable().renderingMode(.template).foregroundStyle(fill)
                        }
                        if UIImage(named: parts + "-fixed") != nil {
                            Image(parts + "-fixed").resizable()
                        }
                    }
                    .opacity(breath ? 0.45 : 1)
                    Image(parts + "-line").resizable().renderingMode(.template).foregroundStyle(Palette.ink)
                }
            } else {
                Image(name).resizable()
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
        .scaleEffect(lifted ? 1.22 : 1)
        .accessibilityHidden(true)
        .onChange(of: bounce) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(duration: 0.16, bounce: 0)) { lifted = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.55).delay(0.16)) { lifted = false }
        }
        .onChange(of: breathing, initial: true) { _, on in
            guard !reduceMotion else { breath = false; return }
            if on {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breath = true }
            } else {
                withAnimation(.easeOut(duration: 0.3)) { breath = false }
            }
        }
    }
}

/// What colours the fill in an icon. Some colours never change: skin on the breast.
enum IconColour: String, CaseIterable, Identifiable {
    case yellow, own, child
    var id: String { rawValue }
    /// Wattle, until the person picks their own.
    static let ownDefault = 0xF4BE2C

    var title: String {
        switch self {
        case .yellow: "Yellow"
        case .own: "Your own colour"
        case .child: "Each child's colour"
        }
    }
}

private struct IconChildColourKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

extension EnvironmentValues {
    /// The colour of the child an icon belongs to, where it belongs to one.
    var iconChildColour: Color? {
        get { self[IconChildColourKey.self] }
        set { self[IconChildColourKey.self] = newValue }
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
        case .pump: "icon-pump"
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
    @Environment(\.puggleNight) private var night

    var body: some View {
        Image("PuggleStill")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .brightness(night ? -0.18 : 0)
            .saturation(night ? 0.8 : 1)
            .accessibilityLabel("Puggle")
    }
}

/// The wordmark: six drawn letters, lower case (chosen 15 November 2026). It is a picture, not type,
/// so no other word is set in it. Only on the splash, the welcome page and Help.
/// `size` is the size of type it stands in for, so it sits where the typeset name did.
struct Wordmark: View {
    var size: CGFloat = 44

    var body: some View {
        Image("Wordmark")
            .resizable()
            .scaledToFit()
            .frame(height: size * 0.95)
            .foregroundStyle(Palette.ink)
            .accessibilityLabel("Puggle")
    }
}

/// Shown for a moment each time the app is opened from cold. It matches the
/// launch screen underneath, so the mark does not jump.
struct SplashView: View {
    private let look = SplashLook.now

    var body: some View {
        ZStack {
            // The season picks the shape and the time of day the colour.
            look.background.ignoresSafeArea()
            ShapePattern(shape: look.shape)
            PuggleMark()
            Wordmark()
                .offset(y: 66 + 14 + 26)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The icon drawings sit in their boxes with uneven space around them, so a
/// narrow one (the medicine bottle) looks small and off to one side. This
/// trims each to its drawing and centres it in a square, once, then keeps it.
@MainActor
enum TrimmedIcon {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String) -> UIImage? {
        if let made = cache[name] { return made }
        guard let source = UIImage(named: name) else { return nil }
        let side = 120
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let drawn = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            // White on clear, so any byte above zero means part of the drawing, whatever the byte order.
            source.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        guard let cg = drawn.cgImage, let data = cg.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return nil }
        let perRow = cg.bytesPerRow, perPixel = cg.bitsPerPixel / 8
        var minX = side, minY = side, maxX = -1, maxY = -1
        for y in 0..<cg.height {
            for x in 0..<cg.width where (0..<perPixel).contains(where: { bytes[y * perRow + x * perPixel + $0] > 24 }) {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        // A square around the drawing, centred on it, with the same margin all round.
        let width = maxX - minX + 1, height = maxY - minY + 1
        let square = CGFloat(max(width, height)) * 1.08
        let midX = CGFloat(minX + maxX + 1) / 2, midY = CGFloat(minY + maxY + 1) / 2
        let crop = CGRect(x: midX - square / 2, y: midY - square / 2, width: square, height: square)
        let size = CGSize(width: 96, height: 96)
        let result = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let scale = size.width / square
            drawn.draw(in: CGRect(x: -crop.minX * scale, y: -crop.minY * scale,
                                  width: CGFloat(side) * scale, height: CGFloat(side) * scale))
        }.withRenderingMode(.alwaysTemplate)
        cache[name] = result
        return result
    }
}
