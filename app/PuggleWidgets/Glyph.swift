import SwiftUI

/// One of Puggle's own icons in one colour, from the widget target's `Glyphs` catalogue
/// (written by `docs/tools/make_icons.py --install`). It takes the colour of the text around it.
struct Glyph: View {
    let name: String
    var size: CGFloat = 18

    init(_ name: String, size: CGFloat = 18) {
        self.name = "glyph-" + name
        self.size = size
    }

    var body: some View {
        Image(name)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
