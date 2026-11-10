import SwiftUI

/// Palette from the spec (§10 Palette and type).
enum Palette {
    static let ink = Color(hex: 0x3A2A20)
    static let paper = Color(hex: 0xFBF6E9)
    static let sand = Color(hex: 0xF2ECDD)
    static let field = Color(hex: 0xEAE2D2)
    static let card = Color(hex: 0xECE4D4)
    static let muted = Color(hex: 0x6B5E52)
    static let night = Color(hex: 0x1B2440)
    static let moon = Color(hex: 0xF3E0B8)

    static let wattle = Color(hex: 0xF4BE2C)
    static let harbour = Color(hex: 0x2A62B8)
    static let waratah = Color(hex: 0xE5553B)
    static let gum = Color(hex: 0x3C9A5F)

    /// Soft fields: one per child.
    static let childColours: [Color] = [
        Color(hex: 0xBFD9F5), // Sky
        Color(hex: 0xF3D9C9), // Shell
        Color(hex: 0xCFE5D2), // Mint
        Color(hex: 0xF4E7B0), // Sun
    ]

    static func childColour(_ index: Int16) -> Color {
        childColours[Int(index) % childColours.count]
    }
}

extension Color {
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
    }
}

/// Child chip: soft colour, used to label entries and pick children.
struct ChildChip: View {
    let child: Child
    var selected = true

    var body: some View {
        Text(child.displayName)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .frame(minHeight: 26)
            .background(selected ? Palette.childColour(child.colourIndex) : Palette.field, in: Capsule())
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
