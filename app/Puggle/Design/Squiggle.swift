import SwiftUI

/// A gently wavy line, like one drawn by hand.
struct Squiggle: Shape {
    var wavelength: CGFloat = 14
    var amplitude: CGFloat = 1.8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        var x = rect.minX
        var up = true
        // Whole half-waves only, so both ends finish on the middle line.
        let half = wavelength / 2
        while x + half <= rect.maxX + 0.5 {
            path.addQuadCurve(to: CGPoint(x: x + half, y: rect.midY),
                              control: CGPoint(x: x + half / 2, y: rect.midY + (up ? -amplitude : amplitude) * 2))
            x += half
            up.toggle()
        }
        return path
    }
}

/// A wavy line across the page, on its own or with a quiet label in the
/// middle: "~~~~ Today so far ~~~~". For dividing one part of a page from the next.
struct SquiggleLabel: View {
    var text: String?

    init(_ text: String? = nil) { self.text = text }

    private var line: some View {
        Squiggle()
            .stroke(Palette.muted.opacity(0.45), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
            .frame(height: 8)
            .frame(maxWidth: .infinity)
    }

    var body: some View {
        HStack(spacing: 12) {
            line
            if let text {
                Text(text)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
                    .fixedSize()
                line
            }
        }
        .accessibilityElement()
        .accessibilityLabel(text ?? "")
        .accessibilityAddTraits(text == nil ? [] : .isHeader)
        .accessibilityHidden(text == nil)
    }
}
