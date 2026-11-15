import SwiftUI

/// The line under Today's greeting, kept to one row. With more than one thing to say (a line for each child's
/// day), it shows them one after another. A line too long for the row slides along, as a long song title
/// does in Music, then rests at its end before the next. With Reduce Motion on, or at the largest text
/// sizes, nothing moves: every line is shown in full, wrapped (Tom, 15 November 2026).
struct GlanceLine: View {
    let lines: [String]
    /// Goes up each time a line has had its turn. The line shown is this, counted round.
    @State private var turn = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        Group {
            if reduceMotion || textSize.isAccessibilitySize {
                Text(lines.joined(separator: "\n"))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                SlidingText(text: lines[turn % lines.count], alone: lines.count == 1) {
                    withAnimation(.easeInOut(duration: 0.35)) { turn += 1 }
                }
                // A new line, or the same one starting again, is a new view: it fades in at its start.
                .id("\(turn)|\(lines.count)")
                .transition(.opacity)
            }
        }
        .font(.body)
        .foregroundStyle(Palette.muted)
        .monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.joined(separator: ". "))
        .onChange(of: lines.count) { _, _ in turn = 0 }
    }
}

/// One line of text in one row. If it is wider than the row it waits, slides to its end at reading pace,
/// waits again, and says it is done. A line that fits says so after a few seconds, unless it is the only one.
private struct SlidingText: View {
    let text: String
    /// The only line: if it fits it stays put, and nothing is ever "done".
    let alone: Bool
    let onDone: () -> Void
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var rowWidth: CGFloat = 0

    /// Points a second. Slow enough to read as it goes.
    private static let pace = 32.0

    private var over: CGFloat { max(textWidth - rowWidth, 0) }

    var body: some View {
        // The row is as tall as one line of the text and as wide as there is room for.
        Text(" ")
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                Text(text)
                    .lineLimit(1)
                    .fixedSize()
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear { textWidth = geometry.size.width }
                            .onChange(of: geometry.size.width) { _, width in textWidth = width }
                    })
                    .offset(x: offset)
            }
            .background(GeometryReader { geometry in
                Color.clear.onAppear { rowWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, width in rowWidth = width }
            })
            .clipped()
            // Soft at the edge it runs off, so a cut-off word does not look like the end.
            .mask {
                LinearGradient(stops: [.init(color: .black.opacity(offset < 0 ? 0 : 1), location: 0),
                                       .init(color: .black, location: 0.04),
                                       .init(color: .black, location: 0.94),
                                       .init(color: .black.opacity(over > 0 && offset > -over ? 0 : 1), location: 1)],
                               startPoint: .leading, endPoint: .trailing)
            }
            .task(id: "\(text)|\(Int(textWidth))|\(Int(rowWidth))") {
                offset = 0
                guard textWidth > 0, rowWidth > 0 else { return }
                let far = over
                if far > 1 {
                    try? await Task.sleep(for: .seconds(1.6))
                    guard !Task.isCancelled else { return }
                    let time = Double(far) / Self.pace
                    withAnimation(.linear(duration: time)) { offset = -far }
                    try? await Task.sleep(for: .seconds(time + 1.8))
                } else {
                    guard !alone else { return }
                    try? await Task.sleep(for: .seconds(4.5))
                }
                guard !Task.isCancelled else { return }
                onDone()
            }
    }
}
