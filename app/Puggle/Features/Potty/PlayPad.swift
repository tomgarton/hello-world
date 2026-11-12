import SwiftUI

/// What the child is holding.
enum PadTool: String, CaseIterable, Identifiable {
    case stamp, crayon, marker
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stamp: "Stamp"
        case .crayon: "Crayon"
        case .marker: "Pen"
        }
    }
}

/// A sheet of paper: blank, or with a picture to colour in.
enum PadPage: Int, CaseIterable, Identifiable {
    case blank, puggle, beach, backyard, night
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .blank: "Plain paper"
        case .puggle: "Puggle"
        case .beach: "At the beach"
        case .backyard: "In the backyard"
        case .night: "Night sky"
        }
    }

    /// The sheet the upright outline is laid out on.
    static let portraitSheet = CGSize(width: 240, height: 360)

    /// The same picture rearranged for an upright sheet, so it fills the paper:
    /// each part is moved and enlarged into its own place.
    var portraitOutline: [Path] {
        let all = outline
        func place(_ indices: [Int], in rect: CGRect) -> [Path] {
            let paths = indices.filter { $0 < all.count }.map { all[$0] }
            guard let first = paths.first else { return [] }
            let box = paths.dropFirst().reduce(first.boundingRect) { $0.union($1.boundingRect) }
            guard box.width > 0, box.height > 0 else { return paths }
            let scale = min(rect.width / box.width, rect.height / box.height)
            let move = CGAffineTransform(translationX: rect.midX - box.midX * scale, y: rect.midY - box.midY * scale)
                .scaledBy(x: scale, y: scale)
            return paths.map { $0.applying(move) }
        }
        switch self {
        case .blank:
            return []
        case .puggle:
            // Puggle large in the middle, the heart and the sun above her.
            return place(Array(0...10), in: CGRect(x: 14, y: 84, width: 212, height: 268))
                + place([11], in: CGRect(x: 18, y: 14, width: 62, height: 62))
                + place([12], in: CGRect(x: 150, y: 6, width: 78, height: 78))
        case .beach:
            return place([3, 4], in: CGRect(x: 138, y: 10, width: 92, height: 92))
                + place([1, 2], in: CGRect(x: 26, y: 96, width: 180, height: 150))
                + place([0], in: CGRect(x: 8, y: 244, width: 224, height: 44))
                + place([5], in: CGRect(x: 76, y: 300, width: 88, height: 46))
        case .backyard:
            return place([0, 1], in: CGRect(x: 14, y: 14, width: 100, height: 100))
                + place([7], in: CGRect(x: 134, y: 30, width: 92, height: 70))
                + place([2, 3, 4, 5, 6], in: CGRect(x: 20, y: 124, width: 200, height: 160))
                + place([8], in: CGRect(x: 14, y: 300, width: 92, height: 46))
                + place([9], in: CGRect(x: 134, y: 300, width: 92, height: 46))
        case .night:
            return place([0], in: CGRect(x: 40, y: 80, width: 160, height: 200))
                + place([1], in: CGRect(x: 160, y: 14, width: 60, height: 60))
                + place([2], in: CGRect(x: 22, y: 24, width: 46, height: 46))
                + place([3], in: CGRect(x: 172, y: 290, width: 44, height: 44))
                + place([4], in: CGRect(x: 26, y: 300, width: 36, height: 36))
        }
    }

    /// The outline to colour in, on the card's 360 by 215 sheet.
    var outline: [Path] {
        switch self {
        case .blank: []
        case .puggle: CardBack(theme: .beach).strokes.map(\.0)
        case .beach: CardTheme.beach.strokes.map(\.0)
        case .backyard: CardTheme.backyard.strokes.map(\.0)
        case .night: CardTheme.night.strokes.map(\.0)
        }
    }
}

/// One thing on the paper. Points are measured from the middle of the paper,
/// so turning the phone keeps the middle of the picture where it was.
struct PadMark: Identifiable {
    enum Kind { case stamp(Stamp, seed: UInt64, tilt: Double), stroke(PadTool) }
    let id = UUID()
    let kind: Kind
    let ink: Ink
    var points: [CGPoint]
}

/// Somewhere to play: stamps, crayons and pens on plain paper or a picture to
/// colour in. Nothing here counts towards a card, and nothing is kept once it
/// is closed. Tap to stamp, or drag and let go. Works either way up.
struct PlayPadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tool: PadTool = .stamp
    @State private var ink: Ink = .red
    @State private var stamp: Stamp = .star
    @State private var page: PadPage = .blank
    @State private var marks: [PadPage: [PadMark]] = [:]
    @State private var drawing: PadMark?
    @State private var hover: CGPoint?
    @State private var confirmingClear = false

    private var pageMarks: [PadMark] { marks[page] ?? [] }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            Group {
                if landscape {
                    HStack(spacing: 12) {
                        VStack(spacing: 8) {
                            topBar
                            paper
                        }
                        ScrollView(showsIndicators: false) { controls(columns: 4) }
                            .frame(width: 216)
                    }
                } else {
                    VStack(spacing: 10) {
                        topBar
                        paper
                        controls(columns: 8)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        // A stray swipe up from the bottom only shows the Home bar; it takes a second to leave.
        .defersSystemGestures(on: .all)
        .persistentSystemOverlays(.hidden)
        .onAppear { Orientation.allowLandscape(true) }
        .onDisappear { Orientation.allowLandscape(false) }
        .confirmationDialog("Start a new sheet?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("New sheet", role: .destructive) {
                withAnimation(.easeOut(duration: 0.25)) { marks[page] = [] }
            }
            Button("Keep it", role: .cancel) {}
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            round("xmark", label: "Close") { dismiss() }
            Spacer(minLength: 0)
            round("chevron.left", label: "Previous page") { turn(-1) }
            Text(page.title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 110)
            round("chevron.right", label: "Next page") { turn(1) }
            Spacer(minLength: 0)
            round("arrow.uturn.backward", label: "Undo") {
                guard !(marks[page] ?? []).isEmpty else { return }
                marks[page]?.removeLast()
            }
            .opacity(pageMarks.isEmpty ? 0.35 : 1)
            round("doc", label: "New sheet") { if !pageMarks.isEmpty { confirmingClear = true } }
                .opacity(pageMarks.isEmpty ? 0.35 : 1)
        }
    }

    private func round(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Palette.field, in: Circle())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(label)
    }

    private func turn(_ by: Int) {
        let all = PadPage.allCases
        let index = (page.rawValue + by + all.count) % all.count
        withAnimation(.easeInOut(duration: 0.2)) { page = all[index] }
    }

    // MARK: Paper

    private var paper: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.scrap)
                Image(uiImage: Grain.image).resizable(resizingMode: .tile)
                    .foregroundStyle(Palette.ink)
                    .opacity(0.06)
                if pageMarks.isEmpty, drawing == nil, page == .blank {
                    Text(tool == .stamp ? "Tap to stamp" : "Draw with your finger")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }
                // Crayon and pen, in the order they were drawn.
                // Finished lines are only redrawn when one is added or taken away.
                StrokeLayer(marks: pageMarks, centre: centre).equatable()
                StrokeLayer(marks: drawing.map { [$0] } ?? [], centre: centre, live: true)
                ForEach(pageMarks) { mark in
                    if case .stamp(let stamp, let seed, let tilt) = mark.kind, let point = mark.points.first {
                        StampMark(stamp: stamp, ink: mark.ink, size: 70, wear: StampWear(seed: seed, gentle: true))
                            .rotationEffect(.degrees(tilt))
                            .position(x: centre.x + point.x, y: centre.y + point.y)
                            .transition(.scale(scale: 1.5).combined(with: .opacity))
                    }
                }
                // The picture to colour in sits on top, so the lines always show.
                outline(in: size)
                // The stamper, under the finger until it is let go.
                if let hover, tool == .stamp {
                    StampMark(stamp: stamp, ink: ink, size: 70)
                        .opacity(0.35)
                        .scaleEffect(1.15)
                        .position(hover)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in touch(value.location, centre: centre) }
                    .onEnded { value in lift(value.location, centre: centre, size: size) }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(page.title), for stamping and drawing")
            .accessibilityAction(named: "Stamp the middle") { place(.zero) }
        }
    }

    private func outline(in size: CGSize) -> some View {
        // Upright paper gets the upright arrangement, so the picture fills it.
        let upright = size.height > size.width
        let sheet = upright ? PadPage.portraitSheet : StampCard.size
        let paths = upright ? page.portraitOutline : page.outline
        let scale = min(size.width / sheet.width, size.height / sheet.height) * 0.94
        return ZStack(alignment: .topLeading) {
            ForEach(Array(paths.enumerated()), id: \.offset) { _, path in
                path.stroke(Palette.ink.opacity(0.85), style: StrokeStyle(lineWidth: 3 / max(scale, 0.1), lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: sheet.width, height: sheet.height, alignment: .topLeading)
        .scaleEffect(scale)
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }

    private static func line(through points: [CGPoint], centre: CGPoint) -> Path {
        var path = Path()
        let moved = points.map { CGPoint(x: centre.x + $0.x, y: centre.y + $0.y) }
        guard let first = moved.first else { return path }
        path.move(to: first)
        if moved.count == 1 {
            path.addLine(to: CGPoint(x: first.x + 0.1, y: first.y + 0.1))
            return path
        }
        // Through the midpoints, so a quick scribble is round and not jagged.
        for index in 1..<moved.count {
            let previous = moved[index - 1], current = moved[index]
            path.addQuadCurve(to: CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2), control: previous)
        }
        if let last = moved.last { path.addLine(to: last) }
        return path
    }

    private func touch(_ location: CGPoint, centre: CGPoint) {
        if tool == .stamp {
            hover = location
            return
        }
        let point = CGPoint(x: location.x - centre.x, y: location.y - centre.y)
        if drawing == nil {
            drawing = PadMark(kind: .stroke(tool), ink: ink, points: [point])
        } else if let last = drawing?.points.last, hypot(last.x - point.x, last.y - point.y) > 1.5 {
            drawing?.points.append(point)
        }
    }

    private func lift(_ location: CGPoint, centre: CGPoint, size: CGSize) {
        if tool == .stamp {
            hover = nil
            // Let go off the paper and nothing is stamped.
            guard CGRect(origin: .zero, size: size).contains(location) else { return }
            place(CGPoint(x: location.x - centre.x, y: location.y - centre.y))
        } else if let finished = drawing {
            drawing = nil
            add(finished)
        }
    }

    private func place(_ point: CGPoint) {
        Haptics.tap()
        let mark = PadMark(kind: .stamp(stamp, seed: UInt64.random(in: 0...UInt64.max), tilt: Double.random(in: -9...9)),
                           ink: ink, points: [point])
        withAnimation(.spring(duration: 0.25, bounce: 0.4)) { add(mark) }
    }

    private func add(_ mark: PadMark) {
        var all = marks[page] ?? []
        all.append(mark)
        // A very busy sheet drops its oldest marks, so it never slows down.
        if all.count > 400 { all.removeFirst(all.count - 400) }
        marks[page] = all
    }

    // MARK: Controls

    private func controls(columns: Int) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(PadTool.allCases) { option in
                    let isOn = tool == option
                    Button {
                        Haptics.selection()
                        tool = option
                    } label: {
                        VStack(spacing: 2) {
                            toolIcon(option).frame(height: 34)
                            Text(option.title).font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 62)
                        .background(isOn ? Palette.field : Palette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            // Ink pads for the stamp; crayons and pens for drawing.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 6) {
                ForEach(Ink.allCases) { option in
                    let isOn = ink == option
                    Button {
                        Haptics.selection()
                        withAnimation(.spring(duration: 0.25, bounce: 0.4)) { ink = option }
                    } label: {
                        colourPiece(option)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58, alignment: .bottom)
                            .offset(y: isOn ? -8 : 0)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(option.rawValue.capitalized) \(tool == .stamp ? "ink pad" : tool.title.lowercased())")
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 6)
            .background(Palette.stampSpace, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            if tool == .stamp {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Stamp.offered) { option in
                            let isOn = stamp == option
                            Button {
                                Haptics.selection()
                                stamp = option
                            } label: {
                                StampPicture(stamp: option)
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(ink.colour)
                                    .frame(width: 48, height: 48)
                                    .background(isOn ? Palette.field : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(option.rawValue.capitalized) stamp")
                            .accessibilityAddTraits(isOn ? .isSelected : [])
                        }
                    }
                    .padding(6)
                }
                .background(Palette.stampSpace, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: tool)
    }

    @ViewBuilder private func toolIcon(_ option: PadTool) -> some View {
        switch option {
        case .stamp:
            StampMark(stamp: stamp, ink: ink, size: 34)
        case .crayon:
            CrayonPiece(colour: ink.colour).frame(width: 13, height: 34).rotationEffect(.degrees(28))
        case .marker:
            MarkerPiece(colour: ink.colour).frame(width: 12, height: 34).rotationEffect(.degrees(28))
        }
    }

    @ViewBuilder private func colourPiece(_ option: Ink) -> some View {
        switch tool {
        case .stamp:
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(option.colour)
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(.black.opacity(0.18), lineWidth: 1))
                .frame(height: 34)
                .padding(.horizontal, 3)
                .padding(.bottom, 8)
        case .crayon:
            CrayonPiece(colour: option.colour).frame(width: 20, height: 54)
        case .marker:
            MarkerPiece(colour: option.colour).frame(width: 17, height: 54)
        }
    }
}

/// A wax crayon, point up, with its paper sleeve.
struct CrayonPiece: View {
    let colour: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: 0))
                    p.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.24), control: CGPoint(x: w * 0.8, y: h * 0.06))
                    p.addLine(to: CGPoint(x: w * 0.12, y: h * 0.24))
                    p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.2, y: h * 0.06))
                }
                .fill(colour)
                RoundedRectangle(cornerRadius: 2).fill(colour).frame(width: w, height: h * 0.78).offset(y: h * 0.22)
                // The sleeve.
                Rectangle().fill(.white.opacity(0.32)).frame(width: w, height: h * 0.44).offset(y: h * 0.38)
                Rectangle().fill(.black.opacity(0.16)).frame(width: w, height: 1.5).offset(y: h * 0.38)
                Rectangle().fill(.black.opacity(0.16)).frame(width: w, height: 1.5).offset(y: h * 0.82)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A felt pen, tip up, with its coloured cap and band.
struct MarkerPiece: View {
    let colour: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                Capsule().fill(colour).frame(width: w * 0.34, height: h * 0.16)
                RoundedRectangle(cornerRadius: 2).fill(colour).frame(width: w * 0.7, height: h * 0.16).offset(y: h * 0.1)
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Palette.paper)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(.black.opacity(0.18), lineWidth: 1))
                    .frame(width: w, height: h * 0.76).offset(y: h * 0.24)
                Rectangle().fill(colour).frame(width: w, height: h * 0.2).offset(y: h * 0.62)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The app is upright everywhere except the play pad, which works either way up.
enum Orientation {
    static var landscapeAllowed = false

    @MainActor static func allowLandscape(_ allowed: Bool) {
        landscapeAllowed = allowed
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                window.rootViewController?.presentedViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
            if !allowed {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }
}

/// Crayon and pen lines on the paper.
///
/// Crayon is wax: the paper's tooth shows through as slanted flecks, the edge
/// is ragged, and going over a patch again fills more of it in. Pen is felt
/// tip: each pass is see-through, so going back over a spot builds it up
/// darker, as a real marker does.
struct StrokeLayer: View, Equatable {
    let marks: [PadMark]
    let centre: CGPoint
    var live = false

    static func == (a: StrokeLayer, b: StrokeLayer) -> Bool {
        !a.live && !b.live && a.centre == b.centre && a.marks.count == b.marks.count && a.marks.last?.id == b.marks.last?.id
    }

    var body: some View {
        Canvas { context, _ in
            let tooth = GraphicsContext.Shading.tiledImage(Image(uiImage: Grain.crayon))
            for mark in marks {
                guard case .stroke(let tool) = mark.kind else { continue }
                if tool == .crayon {
                    let path = Self.line(mark.points, centre: centre)
                    let box = path.boundingRect.insetBy(dx: -12, dy: -12)
                    context.drawLayer { layer in
                        // A soft, broken edge, then the body of the wax.
                        layer.stroke(path, with: .color(mark.ink.colour.opacity(0.45)),
                                     style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round, dash: [1.4, 2.8]))
                        layer.stroke(path, with: .color(mark.ink.colour.opacity(0.9)),
                                     style: StrokeStyle(lineWidth: 12.5, lineCap: .round, lineJoin: .round))
                        // The paper's tooth, knocked out of this pass only. Each
                        // line starts its flecks somewhere else, so a second pass fills gaps.
                        var knock = layer
                        knock.blendMode = .destinationOut
                        let seed = mark.points.first ?? .zero
                        knock.translateBy(x: (seed.x * 7).truncatingRemainder(dividingBy: 120), y: (seed.y * 13).truncatingRemainder(dividingBy: 120))
                        knock.opacity = 0.75
                        knock.fill(Path(box.insetBy(dx: -120, dy: -120)), with: tooth)
                    }
                } else {
                    // Each pass of the pen is its own see-through layer.
                    for pass in Self.passes(mark.points) {
                        var see = context
                        see.opacity = 0.5
                        see.drawLayer { layer in
                            layer.stroke(Self.line(pass, centre: centre), with: .color(mark.ink.colour),
                                         style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Splits a pen line where it doubles back on itself, so scribbling to and
    /// fro over a spot counts as going over it again.
    static func passes(_ points: [CGPoint]) -> [[CGPoint]] {
        guard points.count > 2 else { return [points] }
        var result: [[CGPoint]] = []
        var current = [points[0]]
        // Compare the way the line is heading now with a few points back, to ignore jitter.
        var heading: CGVector?
        var anchor = points[0]
        for point in points.dropFirst() {
            let step = CGVector(dx: point.x - anchor.x, dy: point.y - anchor.y)
            if hypot(step.dx, step.dy) >= 6 {
                if let last = heading, last.dx * step.dx + last.dy * step.dy < 0 {
                    current.append(anchor)
                    result.append(current)
                    current = [anchor]
                }
                heading = step
                anchor = point
            }
            current.append(point)
        }
        result.append(current)
        return result
    }

    static func line(_ points: [CGPoint], centre: CGPoint) -> Path {
        var path = Path()
        let moved = points.map { CGPoint(x: centre.x + $0.x, y: centre.y + $0.y) }
        guard let first = moved.first else { return path }
        path.move(to: first)
        if moved.count == 1 {
            path.addLine(to: CGPoint(x: first.x + 0.1, y: first.y + 0.1))
            return path
        }
        for index in 1..<moved.count {
            let previous = moved[index - 1], current = moved[index]
            path.addQuadCurve(to: CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2), control: previous)
        }
        if let last = moved.last { path.addLine(to: last) }
        return path
    }
}
