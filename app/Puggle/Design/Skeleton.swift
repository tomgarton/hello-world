import SwiftUI

/// A soft block standing in for something that is still loading, with a slow
/// sheen passing over it. Still with Reduce Motion.
struct SkeletonBlock: View {
    var corner: CGFloat = 12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Palette.field)
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(colors: [.clear, Palette.paper.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: phase * geometry.size.width)
                }
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1.4 }
            }
            .accessibilityHidden(true)
    }
}

/// The shape of Today while a family is loading: the scene, the date, two
/// children, two tiles and the day's entries.
struct TodaySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SkeletonBlock(corner: 0).frame(height: PuggleHeader.sceneHeight).padding(.horizontal, -16)
            SkeletonBlock().frame(width: 250, height: 30)
            SkeletonBlock().frame(width: 190, height: 18)
            SkeletonBlock(corner: 22).frame(height: 84)
            SkeletonBlock(corner: 22).frame(height: 84)
            HStack(spacing: 10) {
                SkeletonBlock(corner: 22).frame(height: 108)
                SkeletonBlock(corner: 22).frame(height: 108)
            }
            SkeletonBlock(corner: 18).frame(height: 220)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.sand)
        .ignoresSafeArea(edges: .top)
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

/// The app's shapes as a quiet repeating pattern that drifts slowly down and
/// across. Used behind the splash. Still with Reduce Motion.
struct ShapePattern: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let names = ["shape-blossom", "shape-pebble", "shape-quatrefoil", "shape-scallop",
                                "shape-soft-square", "shape-pill", "shape-soft-hexagon"]
    private static let cell: CGFloat = 76

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let cell = Self.cell
                // One full repeat of the pattern is seven cells; drift a little each second.
                let period = cell * CGFloat(Self.names.count)
                let drift = reduceMotion ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 600)) * 14
                let shift = drift.truncatingRemainder(dividingBy: period)
                let columns = Int(size.width / cell) + 3, rows = Int(size.height / cell) + 3
                let extra = Int(period / cell)
                for row in -extra..<rows {
                    for column in -extra..<columns {
                        let index = ((column + row * 3) % Self.names.count + Self.names.count) % Self.names.count
                        guard let image = context.resolveSymbol(id: index) else { continue }
                        let stagger = row.isMultiple(of: 2) ? 0 : cell / 2
                        let side = cell * (index.isMultiple(of: 3) ? 0.5 : 0.42)
                        let x = CGFloat(column) * cell + stagger + shift
                        let y = CGFloat(row) * cell + shift
                        context.draw(image, in: CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side))
                    }
                }
            } symbols: {
                // Tinted here, so the shapes follow day, dark and night.
                ForEach(Array(Self.names.enumerated()), id: \.offset) { index, name in
                    Image(name).resizable().scaledToFit()
                        .foregroundStyle(Palette.ink.opacity(index.isMultiple(of: 2) ? 0.09 : 0.06))
                        .frame(width: 40, height: 40)
                        .tag(index)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
