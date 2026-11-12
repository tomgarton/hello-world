import CoreText
import SwiftUI

/// Palette from the spec (§10 Palette and type). Each surface and text
/// colour has a dark twin: warm text on near-black, with no white anywhere.
enum Palette {
    /// True while the night look is on. Set by `NightMode`, on the main thread only.
    /// Colours read the `NightTrait` in preference; this is for code with no traits to hand.
    static var isNight = false
    /// When the night look last switched while the app was running.
    static var nightChangedAt: Date?
    /// True for a moment after a switch, so the rebuilt root does not replay the splash.
    static var nightJustChanged: Bool {
        guard let nightChangedAt else { return false }
        return Date.now.timeIntervalSince(nightChangedAt) < 2
    }

    static let ink = Color(light: 0x3A2A20, dark: 0xEBDDC4, night: 0xC2A988)
    static let paper = Color(light: 0xFBF6E9, dark: 0x2A2420, night: 0x15110E)
    static let sand = Color(light: 0xF2ECDD, dark: 0x14110F, night: 0x0A0807)
    static let field = Color(light: 0xEAE2D2, dark: 0x3B332D, night: 0x221C18)
    static let card = Color(light: 0xECE4D4, dark: 0x1F1A17, night: 0x100D0B)
    static let muted = Color(light: 0x6B5E52, dark: 0xB3A590, night: 0x9C8A72)
    /// The sleeping row. A touch lighter in dark so it still reads as blue.
    static let night = Color(light: 0x1B2440, dark: 0x25315A, night: 0x161C33)
    static let moon = Color(light: 0xF3E0B8, dark: 0xF3E0B8, night: 0xC4B08C)

    /// Ink for UIKit, which draws the navigation titles.
    static let inkUI = UIColor { traits in
        if traits[NightTrait.self] { return UIColor(hex: 0xC2A988) }
        return UIColor(hex: traits.userInterfaceStyle == .dark ? 0xEBDDC4 : 0x3A2A20)
    }

    /// Muted ink for UIKit: the tab bar's unselected items.
    static let mutedUI = UIColor { traits in
        if traits[NightTrait.self] { return UIColor(hex: 0x9C8A72) }
        return UIColor(hex: traits.userInterfaceStyle == .dark ? 0xB3A590 : 0x6B5E52)
    }

    /// The same in light and dark, for text on a coloured ground (night, moon, wattle).
    static let fixedInk = Color(hex: 0x3A2A20)
    /// Dimmed at night only, so nothing near white is left on screen.
    static let fixedPaper = Color(light: 0xFBF6E9, dark: 0xFBF6E9, night: 0xC9BEA8)

    static let wattle = Color(hex: 0xF4BE2C)
    static let harbour = Color(hex: 0x2A62B8)
    static let waratah = Color(hex: 0xE5553B)
    static let gum = Color(hex: 0x3C9A5F)

    /// Soft fields: one per child.
    static let childColours: [Color] = [
        Color(light: 0xBFD9F5, dark: 0x2C4763, night: 0x1F3246), // Sky
        Color(light: 0xF3D9C9, dark: 0x5E4234, night: 0x422E25), // Shell
        Color(light: 0xCFE5D2, dark: 0x33523C, night: 0x243A2B), // Mint
        Color(light: 0xF4E7B0, dark: 0x5C5024, night: 0x40381A), // Sun
    ]

    static func childColour(_ index: Int16) -> Color {
        childColours[Int(index) % childColours.count]
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    /// A colour that follows the phone's light or dark appearance, with an
    /// optional dimmer value for the night look (see `Palette.isNight`).
    init(light: UInt32, dark: UInt32, night: UInt32? = nil) {
        self.init(uiColor: UIColor { traits in
            if let night, traits[NightTrait.self] { return UIColor(hex: night) }
            return UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Display type: the logotype, big numbers and screen titles.
///
/// Bricolage Grotesque once its font file is added (see README); until then
/// the system rounded face stands in. Either way the size is the optical size:
/// - The system face picks its own optical size and tracking for each point size.
/// - Bricolage is a variable font with an optical-size axis. It is set to the
///   point size being drawn, so 64 pt numerals get the display cut and 26 pt
///   titles get the sturdier text cut, instead of one cut stretched to every size.
/// Sizes also follow Dynamic Type, up to a limit so the big numbers still fit.
enum DisplayType {
    private static let opticalSize = 0x6F70_737A // 'opsz'
    private static let weight = 0x7767_6874      // 'wght'
    private static let width = 0x7764_7468       // 'wdth'

    private static let family = "Bricolage Grotesque"
    /// The face to start from, by its exact name, or nil if the font file is not in the app.
    /// Looked up by name: asking for the family alone falls back to the system font.
    private static let faceName: String? = {
        let names = UIFont.fontNames(forFamilyName: family)
        return names.first { !$0.contains("_") } ?? names.first
    }()

    static func font(_ size: CGFloat) -> Font {
        guard let faceName, let base = UIFont(name: faceName, size: size) else {
            return .system(size: size, weight: .heavy, design: .rounded)
        }
        // Which axes this file has; a static cut has none and is used as it is.
        let axes = (CTFontCopyVariationAxes(base) as? [[String: Any]] ?? [])
            .compactMap { $0[kCTFontVariationAxisIdentifierKey as String] as? Int }
        guard !axes.isEmpty else { return Font(base) }
        var variation: [Int: CGFloat] = [:]
        if axes.contains(opticalSize) { variation[opticalSize] = min(max(size, 12), 96) }
        if axes.contains(weight) { variation[weight] = 800 }
        if axes.contains(width) { variation[width] = 100 }
        let key = UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
        return Font(UIFont(descriptor: base.fontDescriptor.addingAttributes([key: variation]), size: size))
    }
}

private struct DisplayFont: ViewModifier {
    @ScaledMetric private var scaled: CGFloat
    private let base: CGFloat

    init(size: CGFloat) {
        base = size
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    func body(content: Content) -> some View {
        // Grows with the reader's text size, but not past half as big again.
        content.font(DisplayType.font(min(scaled, base * 1.5)))
    }
}

extension View {
    /// Display type at a design size in points. See `DisplayType`.
    func displayFont(_ size: CGFloat) -> some View { modifier(DisplayFont(size: size)) }
}

/// Filled pill, no outline or hard shadow (Refined Puggle).
struct PillButtonStyle: ButtonStyle {
    var primary = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(primary ? Palette.paper : Palette.ink)
            .background(primary ? Palette.ink : Palette.field, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.2, bounce: 0), value: configuration.isPressed)
    }
}

/// Child chip: soft colour, used to label entries and pick children.
struct ChildChip: View {
    let child: Child
    var selected = true
    /// For pickers: selection shows as a tick and a border as well as the colour.
    var ticked = false
    /// Picker size: tall enough to tap, and the same as the buttons beside it.
    var large = false

    var body: some View {
        HStack(spacing: 4) {
            if ticked {
                Image(systemName: "checkmark").font(.caption2.weight(.bold))
            }
            Text(child.displayName)
        }
        .font((large ? Font.subheadline : .footnote).weight(.semibold))
        .padding(.horizontal, large ? 14 : 10)
        .frame(minHeight: large ? 40 : 26)
        .background(selected ? Palette.childColour(child.colourIndex) : Palette.field, in: Capsule())
        .overlay(Capsule().stroke(Palette.ink, lineWidth: ticked ? 1.5 : 0))
        .foregroundStyle(Palette.ink)
    }
}

/// Placeholder avatar until photos and characters are added.
struct ChildAvatar: View {
    let child: Child
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(Palette.childColour(child.colourIndex))
            .frame(width: size, height: size)
            .overlay(Text(child.initial).font(.system(size: size * 0.42, weight: .bold, design: .rounded)))
            .foregroundStyle(Palette.ink)
            .accessibilityLabel(child.displayName)
    }
}

/// The night look, as a trait iOS knows about. Changing it re-resolves every
/// colour in place, so nothing is rebuilt and open sheets stay open.
struct NightTrait: UITraitDefinition {
    static let defaultValue = false
    static let affectsColorAppearance = true
    static let name = "PuggleNight"
}

private struct NightKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Set once at the root from `NightMode`; flows down to UIKit as `NightTrait`.
    var puggleNight: Bool {
        get { self[NightKey.self] }
        set { self[NightKey.self] = newValue }
    }
}

extension NightKey: UITraitBridgedEnvironmentKey {
    static func read(from traitCollection: UITraitCollection) -> Bool { traitCollection[NightTrait.self] }
    static func write(to mutableTraits: inout UIMutableTraits, value: Bool) { mutableTraits[NightTrait.self] = value }
}
