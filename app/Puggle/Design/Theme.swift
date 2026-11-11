import SwiftUI

/// Palette from the spec (§10 Palette and type). Each surface and text
/// colour has a dark twin: warm text on near-black, with no white anywhere.
enum Palette {
    static let ink = Color(light: 0x3A2A20, dark: 0xEBDDC4)
    static let paper = Color(light: 0xFBF6E9, dark: 0x2A2420)
    static let sand = Color(light: 0xF2ECDD, dark: 0x14110F)
    static let field = Color(light: 0xEAE2D2, dark: 0x3B332D)
    static let card = Color(light: 0xECE4D4, dark: 0x1F1A17)
    static let muted = Color(light: 0x6B5E52, dark: 0xB3A590)
    /// The sleeping row. A touch lighter in dark so it still reads as blue.
    static let night = Color(light: 0x1B2440, dark: 0x25315A)
    static let moon = Color(hex: 0xF3E0B8)

    /// Ink for UIKit, which draws the navigation titles.
    static let inkUI = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xEB / 255, green: 0xDD / 255, blue: 0xC4 / 255, alpha: 1)
            : UIColor(red: 0x3A / 255, green: 0x2A / 255, blue: 0x20 / 255, alpha: 1)
    }

    /// The same in light and dark, for text on a coloured ground (night, moon, wattle).
    static let fixedInk = Color(hex: 0x3A2A20)
    static let fixedPaper = Color(hex: 0xFBF6E9)

    static let wattle = Color(hex: 0xF4BE2C)
    static let harbour = Color(hex: 0x2A62B8)
    static let waratah = Color(hex: 0xE5553B)
    static let gum = Color(hex: 0x3C9A5F)

    /// Soft fields: one per child.
    static let childColours: [Color] = [
        Color(light: 0xBFD9F5, dark: 0x2C4763), // Sky
        Color(light: 0xF3D9C9, dark: 0x5E4234), // Shell
        Color(light: 0xCFE5D2, dark: 0x33523C), // Mint
        Color(light: 0xF4E7B0, dark: 0x5C5024), // Sun
    ]

    static func childColour(_ index: Int16) -> Color {
        childColours[Int(index) % childColours.count]
    }
}

extension Color {
    /// A colour that follows the phone's light or dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: 1)
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

/// Titles use Bricolage Grotesque once the font file is added (see README);
/// until then the system rounded face stands in.
extension Font {
    static func display(_ size: CGFloat) -> Font {
        if UIFont(name: "BricolageGrotesque-ExtraBold", size: size) != nil {
            return .custom("BricolageGrotesque-ExtraBold", size: size, relativeTo: .largeTitle)
        }
        return .system(size: size, weight: .heavy, design: .rounded)
    }
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

    var body: some View {
        HStack(spacing: 4) {
            if ticked {
                Image(systemName: "checkmark").font(.caption2.weight(.bold))
            }
            Text(child.displayName)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .frame(minHeight: 26)
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
