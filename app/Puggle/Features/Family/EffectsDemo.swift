#if DEBUG
import SwiftUI

/// An icon drawing itself over and over, for looking at and recording the drawing by itself.
struct IconDrawPreview: View {
    let name: String
    var size: CGFloat = 44
    var playback = DrawPlayback.byLayer
    /// What it plays, in turn, for ever.
    var loop: [IconDrawView.Phase] = [.on, .off(reversed: true)]
    /// How long it rests after each.
    var rest = 0.8
    @State private var phase = IconDrawView.Phase.on
    @State private var time = 0.0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if let drawing = IconDrawing.named(name) {
            let timeline = drawing.timeline(playback)
            IconDrawView(drawing: drawing, timeline: timeline, phase: phase, time: time, accent: Palette.iconYellow, dark: scheme == .dark)
                .frame(width: size, height: size)
                .task {
                    while !Task.isCancelled {
                        for next in loop {
                            phase = next
                            time = 0
                            try? await Task.sleep(for: .milliseconds(40))
                            withAnimation(.linear(duration: timeline.total)) { time = timeline.total }
                            try? await Task.sleep(for: .seconds(timeline.total + rest))
                        }
                    }
                }
        }
    }
}

/// The drawing effects playing by themselves, for recording: "-debugFx 1" (or "2" for the second page).
/// Page 1: draw on and off, the three ways of playing it, and the two ways an icon can answer a save.
/// Page 2: every icon drawing on.
struct EffectsDemoView: View {
    var page = 1
    @State private var saves = 0

    var body: some View {
        Group {
            if page == 2 { everyIcon } else { main }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                saves += 1
            }
        }
    }

    private var main: some View {
        VStack(spacing: 18) {
            row("Draw on, then draw off") {
                ForEach(["icon-nappy", "icon-bottle", "icon-sleep", "icon-solids"], id: \.self) { name in
                    tile { IconDrawPreview(name: name) }
                }
            }
            row("By layer · Whole symbol · One at a time") {
                tile { IconDrawPreview(name: "icon-nappy", playback: .byLayer, loop: [.on], rest: 1.2) }
                tile { IconDrawPreview(name: "icon-nappy", playback: .wholeSymbol, loop: [.on], rest: 1.2) }
                tile { IconDrawPreview(name: "icon-nappy", playback: .individually, loop: [.on], rest: 1.2) }
            }
            row("Apple's own Draw, on its own symbols") {
                HStack(spacing: 6) {
                    DrawnSymbol(name: saves % 2 == 0 ? "moon" : "sun.max")
                    Text(saves % 2 == 0 ? "Start sleep" : "Woke up")
                }
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 18)
                .frame(minHeight: 52)
                .background(Palette.paper, in: Capsule())
            }
            row("On save: drawn over · From nothing") {
                tile { ActivityIcon(named: "icon-nappy", size: 44, saved: saves) }
                tile { ActivityIcon(named: "icon-potty", size: 44, saved: saves) }
                tile { ActivityIcon(named: "icon-nappy", size: 44, saved: saves).savedEffect(.drawOn) }
                tile { ActivityIcon(named: "icon-potty", size: 44, saved: saves).savedEffect(.drawOn) }
            }
        }
    }

    private var everyIcon: some View {
        let names = IconStrokes.all.keys.sorted()
        return VStack(spacing: 14) {
            Text("Every icon, drawn on by layer").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(names, id: \.self) { name in
                    tile { IconDrawPreview(name: name, loop: [.on], rest: 1.6) }
                }
            }
        }
    }

    private func row(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            HStack(spacing: 10) { content() }
        }
    }

    private func tile(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(width: 78, height: 78)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Every icon as its picture, as the app draws it when whole, part-way on, and with its strokes marked the
/// way Apple marks guide points: an open ring where a stroke starts, a dot where it ends, and a colour for
/// each motion group in the order they start. "-debugDrawSheet 0" (or 1 for the second half).
struct IconDrawSheet: View {
    let page: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let names = IconStrokes.all.keys.sorted()
        let shown = Array(names.dropFirst(page * 10).prefix(10))
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 0) {
                ForEach(["Picture", "Drawn", "25%", "50%", "75%", "Guides"], id: \.self) { title in
                    Text(title).font(.caption2.weight(.semibold)).frame(width: 62)
                }
            }
            ForEach(shown, id: \.self) { name in
                if let drawing = IconDrawing.named(name) {
                    let timeline = drawing.timeline(.byLayer)
                    HStack(spacing: 0) {
                        ActivityIcon(named: name, size: 52).frame(width: 62)
                        ForEach([1.0, 0.25, 0.5, 0.75], id: \.self) { share in
                            IconDrawView(drawing: drawing, timeline: timeline, phase: .on, time: timeline.total * share, accent: Palette.iconYellow, dark: scheme == .dark)
                                .frame(width: 52, height: 52)
                                .frame(width: 62)
                        }
                        IconGuideView(drawing: drawing).frame(width: 60, height: 60).frame(width: 62)
                    }
                }
            }
        }
        .padding(.top, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
    }
}

/// An icon's strokes marked up: a colour for each motion group, a ring at each start and a dot at each end.
struct IconGuideView: View {
    let drawing: IconDrawing
    static let colours: [Color] = [Color(hex: 0x2A62B8), Color(hex: 0xC2412A), Color(hex: 0x3C9A5F), Color(hex: 0x8A5BC4), Color(hex: 0xC98A12), Color(hex: 0x1F8E99)]

    var body: some View {
        Canvas { context, size in
            let unit = size.width / drawing.box
            func place(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x * unit, y: point.y * unit) }
            for line in drawing.lines {
                let colour = Self.colours[line.group % Self.colours.count]
                var path = Path()
                path.addLines(line.points.map(place))
                context.stroke(path, with: .color(colour.opacity(0.75)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                let count = line.points.count
                let starts: [CGPoint], ends: [CGPoint]
                switch line.way {
                case .single:
                    starts = [line.points[0]]
                    ends = line.closed ? [] : [line.points[count - 1]]
                case .midOut:
                    starts = [middle(of: line)]
                    ends = [line.points[0], line.points[count - 1]]
                case .endsIn:
                    starts = [line.points[0], line.points[count - 1]]
                    ends = [middle(of: line)]
                }
                for end in ends {
                    let at = place(end)
                    context.fill(Path(ellipseIn: CGRect(x: at.x - 1.7, y: at.y - 1.7, width: 3.4, height: 3.4)), with: .color(colour))
                }
                for start in starts {
                    let at = place(start)
                    let ring = Path(ellipseIn: CGRect(x: at.x - 2.6, y: at.y - 2.6, width: 5.2, height: 5.2))
                    context.fill(ring, with: .color(Palette.sand))
                    context.stroke(ring, with: .color(colour), lineWidth: 1.3)
                }
                // A small arrowhead a third of the way along, pointing the way the pen goes.
                if line.way == .single, line.length > 4 {
                    let (at, toward) = point(on: line, at: line.length * 0.38)
                    let angle = atan2(toward.y - at.y, toward.x - at.x), tip = place(at)
                    var arrow = Path()
                    arrow.move(to: CGPoint(x: tip.x - 4 * cos(angle - 0.5), y: tip.y - 4 * sin(angle - 0.5)))
                    arrow.addLine(to: tip)
                    arrow.addLine(to: CGPoint(x: tip.x - 4 * cos(angle + 0.5), y: tip.y - 4 * sin(angle + 0.5)))
                    context.stroke(arrow, with: .color(colour), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    private func middle(of line: DrawLine) -> CGPoint { point(on: line, at: line.length / 2).0 }

    /// The point a distance along a stroke, and the next point after it.
    private func point(on line: DrawLine, at distance: CGFloat) -> (CGPoint, CGPoint) {
        var index = 0
        while index < line.points.count - 2, line.along[index + 1] < distance { index += 1 }
        let a = line.points[index], b = line.points[index + 1]
        let span = line.along[index + 1] - line.along[index]
        let share = span > 0 ? (distance - line.along[index]) / span : 0
        return (CGPoint(x: a.x + (b.x - a.x) * share, y: a.y + (b.y - a.y) * share), b)
    }
}
#endif
