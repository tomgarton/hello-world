import Photos
import SwiftUI
import UIKit

/// What the child is holding.
enum PadTool: String, CaseIterable, Identifiable, Codable {
    case stamp, crayon, marker, fill, eraser
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stamp: "Stamp"
        case .crayon: "Crayon"
        case .marker: "Pen"
        case .fill: "Fill"
        case .eraser: "Rubber"
        }
    }
    /// How wide a line is at the middle size, in points.
    var width: CGFloat {
        switch self {
        case .crayon: 12.5
        case .marker: 7
        case .eraser: 26
        default: 0
        }
    }
    var draws: Bool { self == .crayon || self == .marker || self == .eraser }
}

/// Thin, middle or chunky.
enum PadSize: Double, CaseIterable, Identifiable {
    case thin = 0.6, middle = 1, chunky = 1.9
    var id: Double { rawValue }
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
struct PadMark: Identifiable, Codable {
    enum Kind: Codable {
        case stamp(stamp: String, seed: UInt64, tilt: Double, strength: Double)
        case stroke(tool: PadTool, width: Double)
        /// A tap of the paint pot: the shape around this point is filled.
        case fill
    }
    var id = UUID()
    let kind: Kind
    let ink: Ink
    var points: [CGPoint]
}

extension Ink: Codable {}

/// The sheets, kept on this phone so a drawing is still there next time.
@MainActor
enum PadStore {
    private static var url: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("play-pad.json")
    }

    static func load() -> [PadPage: [PadMark]] {
        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([Int: [PadMark]].self, from: data) else { return [:] }
        var marks: [PadPage: [PadMark]] = [:]
        for (key, value) in saved { if let page = PadPage(rawValue: key) { marks[page] = value } }
        return marks
    }

    static func save(_ marks: [PadPage: [PadMark]]) {
        let plain = Dictionary(uniqueKeysWithValues: marks.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(plain) else { return }
        let target = url
        DispatchQueue.global(qos: .utility).async { try? data.write(to: target, options: .atomic) }
    }
}

/// Where a picture's outline sits on paper of a given size, shared by the
/// drawing and by the paint pot so a fill meets the lines exactly.
struct OutlineLayout {
    let paths: [Path]
    let transform: CGAffineTransform
    /// Three points on screen, in the outline's own units.
    let lineWidth: CGFloat

    init(page: PadPage, size: CGSize) {
        let upright = size.height > size.width
        let sheet = upright ? PadPage.portraitSheet : StampCard.size
        paths = upright ? page.portraitOutline : page.outline
        let scale = min(size.width / sheet.width, size.height / sheet.height) * 0.94
        transform = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -sheet.width / 2, y: -sheet.height / 2)
        lineWidth = 3 / max(scale, 0.1)
    }
}

/// The paint pot: finds the shape around a point, inside the picture's lines
/// and the edge of the paper, and returns it as a mask (white where it fills).
enum PaintPot {
    static let scale: CGFloat = 1.5

    nonisolated static func mask(page: PadPage, size: CGSize, at point: CGPoint) -> CGImage? {
        // A pixel and a half a point is plenty for a fill, and quick.
        let scale = PaintPot.scale
        let width = Int(size.width * scale), height = Int(size.height * scale)
        guard width > 0, height > 0,
              let walls = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let data = walls.data else { return nil }
        walls.setFillColor(gray: 1, alpha: 1)
        walls.fill(CGRect(x: 0, y: 0, width: width, height: height))
        // Core Graphics counts up from the bottom; flip so it matches the screen.
        walls.translateBy(x: 0, y: CGFloat(height))
        walls.scaleBy(x: scale, y: -scale)
        let layout = OutlineLayout(page: page, size: size)
        walls.concatenate(layout.transform)
        walls.setStrokeColor(gray: 0, alpha: 1)
        walls.setLineWidth(layout.lineWidth * 1.4)
        walls.setLineCap(.round)
        walls.setLineJoin(.round)
        for path in layout.paths {
            walls.addPath(path.cgPath)
            walls.strokePath()
        }
        let walls8 = data.bindMemory(to: UInt8.self, capacity: width * height)
        var start = (x: Int(point.x * scale), y: Int(point.y * scale))
        guard start.x >= 0, start.y >= 0, start.x < width, start.y < height else { return nil }
        // A tap right on a line looks a little way round for somewhere to fill.
        if walls8[start.y * width + start.x] < 128 {
            var found: (Int, Int)?
            search: for radius in stride(from: 2, through: 14, by: 2) {
                for (dx, dy) in [(radius, 0), (-radius, 0), (0, radius), (0, -radius)] {
                    let x = start.x + dx, y = start.y + dy
                    if x >= 0, y >= 0, x < width, y < height, walls8[y * width + x] >= 128 { found = (x, y); break search }
                }
            }
            guard let found else { return nil }
            start = found
        }
        // Scanline flood fill over the open (white) pixels, on raw memory so it is quick.
        let count = width * height
        let filled = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        filled.initialize(repeating: 0, count: count)
        defer { filled.deallocate() }
        @inline(__always) func open(_ i: Int) -> Bool { walls8[i] >= 128 && filled[i] == 0 }
        var stack: [Int] = [start.y * width + start.x]
        stack.reserveCapacity(4096)
        while let seed = stack.popLast() {
            let y = seed / width
            var x = seed % width
            let row = y * width
            while x > 0, open(row + x - 1) { x -= 1 }
            var spanAbove = false, spanBelow = false
            while x < width, open(row + x) {
                filled[row + x] = 255
                if y > 0 {
                    let above = open(row - width + x)
                    if above, !spanAbove { stack.append(row - width + x) }
                    spanAbove = above
                }
                if y < height - 1 {
                    let below = open(row + width + x)
                    if below, !spanBelow { stack.append(row + width + x) }
                    spanBelow = below
                }
                x += 1
            }
        }
        // Grow it a little, so the colour tucks under the lines with no white gap.
        let grown = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        grown.update(from: filled, count: count)
        defer { grown.deallocate() }
        for y in 1..<(height - 1) {
            let row = y * width
            for x in 1..<(width - 1) where filled[row + x] == 0 {
                if filled[row + x - 1] | filled[row + x + 1] | filled[row - width + x] | filled[row + width + x] != 0 {
                    grown[row + x] = 255
                }
            }
        }
        return CGContext(data: grown, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                         space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)?.makeImage()
    }
}

/// Everything finished on a sheet, drawn in order: stamps, crayon, pen, fills,
/// and the rubber taking things away. Redrawn only when something changes.
struct PaperArt: View, Equatable {
    let marks: [PadMark]
    let fills: [UUID: CGImage]
    let centre: CGPoint
    let version: Int

    static func == (a: PaperArt, b: PaperArt) -> Bool {
        a.version == b.version && a.centre == b.centre && a.fills.count == b.fills.count
    }

    var body: some View {
        Canvas { context, size in
            let tooth = GraphicsContext.Shading.tiledImage(Image(uiImage: Grain.crayon))
            for mark in marks {
                switch mark.kind {
                case .stamp(_, _, let tilt, _):
                    guard let point = mark.points.first, let symbol = context.resolveSymbol(id: mark.id) else { continue }
                    var turned = context
                    turned.translateBy(x: centre.x + point.x, y: centre.y + point.y)
                    turned.rotate(by: .degrees(tilt))
                    turned.draw(symbol, at: .zero)
                case .fill:
                    guard let mask = fills[mark.id] else { continue }
                    let all = Path(CGRect(origin: .zero, size: size))
                    context.drawLayer { layer in
                        layer.fill(all, with: .color(mark.ink.colour.opacity(0.88)))
                        // The same waxy tooth as crayon, so a fill looks coloured in by hand.
                        var knock = layer
                        knock.blendMode = .destinationOut
                        knock.opacity = 0.3
                        knock.fill(all, with: tooth)
                        // Then keep only the shape that was tapped (the mask is white there).
                        var keep = layer
                        keep.blendMode = .destinationIn
                        keep.addFilter(.luminanceToAlpha)
                        keep.draw(Image(decorative: mask, scale: PaintPot.scale), in: CGRect(origin: .zero, size: size))
                    }
                case .stroke(let tool, let width):
                    StrokeLayer.draw(tool: tool, width: width, mark: mark, centre: centre, tooth: tooth, in: &context)
                }
            }
        } symbols: {
            ForEach(marks) { mark in
                if case .stamp(let name, let seed, _, let strength) = mark.kind {
                    StampMark(stamp: Stamp(rawValue: name) ?? .star, ink: mark.ink, size: 70, wear: StampWear(seed: seed, gentle: true))
                        .opacity(strength)
                        .tag(mark.id)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Holding the close button for a moment closes the pad, so a stray tap does not.
struct HoldToClose: View {
    let action: () -> Void
    @State private var progress: CGFloat = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        ZStack {
            Circle().fill(Palette.field)
            Circle().trim(from: 0, to: progress)
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(2)
            Image(systemName: "xmark").font(.subheadline.weight(.bold))
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard task == nil else { return }
                    Haptics.tap()
                    withAnimation(.linear(duration: 1.2 * Double(1 - progress))) { progress = 1 }
                    task = Task {
                        try? await Task.sleep(for: .seconds(1.2))
                        guard !Task.isCancelled else { return }
                        Haptics.success()
                        action()
                    }
                }
                .onEnded { _ in
                    task?.cancel()
                    task = nil
                    withAnimation(.easeOut(duration: 0.3)) { progress = 0 }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Close")
        .accessibilityHint("For grown-ups. Hold to close.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}

/// Somewhere to play: stamps, crayons, pens, a paint pot and a rubber, on plain
/// paper or pictures to colour in. Nothing here counts towards a card. Each
/// sheet is kept on this phone until it is cleared. Works either way up.
struct PlayPadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tool: PadTool = .stamp
    @State private var ink: Ink = .red
    @State private var stamp: Stamp = .star
    @State private var brush: PadSize = .middle
    @State private var page: PadPage = .blank
    @State private var marks: [PadPage: [PadMark]] = [:]
    @State private var fills: [UUID: CGImage] = [:]
    @State private var fillSize: CGSize = .zero
    @State private var version = 0
    @State private var drawing: PadMark?
    @State private var hover: CGPoint?
    @State private var confirmingClear = false
    @State private var loaded = false
    @State private var paperSize: CGSize = .zero
    // A stamp's ink runs out, as on the stamper, until an ink pad is pressed again.
    @State private var inkLeft = 8
    @State private var squished: Ink?
    @State private var dryNudge = 0
    // Puggle comes to look every so often.
    @State private var peeking = false
    @State private var untilPeek = 9
    @State private var toast: String?
    /// True while a finger is on the paper. If a touch is cut short (a system
    /// gesture, a call), whatever was being drawn is still kept.
    @GestureState private var touching = false

    private static let strengths: [Double] = [0, 0.3, 0.5, 0.72, 0.9, 1, 1, 1, 1]
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
                            .frame(width: 236)
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
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 40)
                    .background(Palette.paper, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // A stray swipe up from the bottom only shows the Home bar; it takes a second to leave.
        .defersSystemGestures(on: .all)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            Orientation.allowLandscape(true)
            guard !loaded else { return }
            loaded = true
            marks = PadStore.load()
            version += 1
        }
        .onDisappear {
            Orientation.allowLandscape(false)
            PadStore.save(marks)
        }
        .onChange(of: paperSize) { _, _ in refreshFills() }
        .onChange(of: page) { _, _ in refreshFills() }
        .confirmationDialog("Start a new sheet?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("New sheet", role: .destructive) {
                withAnimation(.easeOut(duration: 0.25)) { marks[page] = [] }
                changed()
            }
            Button("Keep it", role: .cancel) {}
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            HoldToClose { dismiss() }
            Spacer(minLength: 0)
            round("chevron.left", label: "Previous page") { turn(-1) }
            Text(page.title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(minWidth: 96)
            round("chevron.right", label: "Next page") { turn(1) }
            Spacer(minLength: 0)
            round("arrow.uturn.backward", label: "Undo") {
                guard !(marks[page] ?? []).isEmpty else { return }
                marks[page]?.removeLast()
                changed()
            }
            .opacity(pageMarks.isEmpty ? 0.35 : 1)
            // Grown-up things, out of the way.
            Menu {
                Button { saveToPhotos() } label: { Label("Save to Photos", systemImage: "square.and.arrow.down") }
                Button(role: .destructive) { confirmingClear = true } label: { Label("New sheet", systemImage: "doc") }
                    .disabled(pageMarks.isEmpty)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(Palette.field, in: Circle())
            }
            .accessibilityLabel("More")
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
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }
                PaperArt(marks: pageMarks, fills: fills, centre: centre, version: version).equatable()
                // The line being drawn now. The rubber shows as paper until it is let go.
                if let drawing {
                    Canvas { context, _ in
                        if case .stroke(let tool, let width) = drawing.kind {
                            if tool == .eraser {
                                context.stroke(StrokeLayer.line(drawing.points, centre: centre), with: .color(Palette.scrap),
                                               style: StrokeStyle(lineWidth: tool.width * width, lineCap: .round, lineJoin: .round))
                            } else {
                                let tooth = GraphicsContext.Shading.tiledImage(Image(uiImage: Grain.crayon))
                                StrokeLayer.draw(tool: tool, width: width, mark: drawing, centre: centre, tooth: tooth, in: &context)
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
                // The picture to colour in sits on top, so the lines always show.
                outline(in: size)
                if let hover, tool == .stamp {
                    StampMark(stamp: stamp, ink: ink, size: 70)
                        .opacity(0.35)
                        .scaleEffect(1.15)
                        .position(hover)
                        .allowsHitTesting(false)
                }
                peekingPuggle(in: size)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($touching) { _, state, _ in state = true }
                    .onChanged { value in touch(value.location, centre: centre) }
                    .onEnded { value in lift(value.location, centre: centre, size: size) }
            )
            .onChange(of: touching) { _, now in
                guard !now else { return }
                hover = nil
                if let unfinished = drawing {
                    drawing = nil
                    add(unfinished)
                }
            }
            .onAppear { paperSize = size }
            .onChange(of: size) { _, now in paperSize = now }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(page.title), for stamping and drawing")
            .accessibilityAction(named: "Stamp the middle") { place(.zero) }
        }
    }

    private var hint: String {
        switch tool {
        case .stamp: "Tap to stamp"
        case .fill: "Tap to fill with colour"
        case .eraser: "Rub out with your finger"
        default: "Draw with your finger"
        }
    }

    private func outline(in size: CGSize) -> some View {
        let layout = OutlineLayout(page: page, size: size)
        return Canvas { context, _ in
            context.concatenate(layout.transform)
            for path in layout.paths {
                context.stroke(path, with: .color(Palette.ink.opacity(0.85)),
                               style: StrokeStyle(lineWidth: layout.lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
    }

    /// Puggle pops up at the bottom of the paper to see, gives a little hop, and goes.
    private func peekingPuggle(in size: CGSize) -> some View {
        PuggleStanding(height: 104)
            .rotationEffect(.degrees(peeking ? -6 : 0))
            .offset(x: size.width / 2 - 64, y: size.height / 2 + (peeking ? -34 : 70))
            .opacity(reduceMotion ? (peeking ? 1 : 0) : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func maybePeek() {
        untilPeek -= 1
        guard untilPeek <= 0, !peeking else { return }
        untilPeek = Int.random(in: 12...20)
        withAnimation(.spring(duration: 0.55, bounce: 0.45)) { peeking = true }
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.easeIn(duration: 0.4)) { peeking = false }
        }
    }

    private func touch(_ location: CGPoint, centre: CGPoint) {
        switch tool {
        case .stamp:
            hover = location
        case .fill:
            break
        default:
            let point = CGPoint(x: location.x - centre.x, y: location.y - centre.y)
            if drawing == nil {
                drawing = PadMark(kind: .stroke(tool: tool, width: brush.rawValue), ink: ink, points: [point])
            } else if let last = drawing?.points.last, hypot(last.x - point.x, last.y - point.y) > 1.5 {
                drawing?.points.append(point)
            }
        }
    }

    private func lift(_ location: CGPoint, centre: CGPoint, size: CGSize) {
        switch tool {
        case .stamp:
            hover = nil
            // Let go off the paper and nothing is stamped.
            guard CGRect(origin: .zero, size: size).contains(location) else { return }
            place(CGPoint(x: location.x - centre.x, y: location.y - centre.y))
        case .fill:
            // Worked out away from the screen, so nothing pauses.
            let sheet = page, colour = ink
            let point = CGPoint(x: location.x - centre.x, y: location.y - centre.y)
            Task {
                let mask = await Task.detached(priority: .userInitiated) {
                    PaintPot.mask(page: sheet, size: size, at: location)
                }.value
                guard let mask, page == sheet else { return }
                Haptics.tap()
                let mark = PadMark(kind: .fill, ink: colour, points: [point])
                fills[mark.id] = mask
                fillSize = size
                add(mark)
            }
        default:
            if let finished = drawing {
                drawing = nil
                add(finished)
            }
        }
    }

    private func place(_ point: CGPoint) {
        guard inkLeft > 0 else {
            // Out of ink: the pads give a little wiggle to say where to go.
            Haptics.warning()
            withAnimation(.default) { dryNudge += 1 }
            return
        }
        Haptics.tap()
        let mark = PadMark(kind: .stamp(stamp: stamp.rawValue, seed: UInt64.random(in: 0...UInt64.max),
                                        tilt: Double.random(in: -9...9), strength: Self.strengths[inkLeft]),
                           ink: ink, points: [point])
        inkLeft -= 1
        withAnimation(.spring(duration: 0.25, bounce: 0.4)) { add(mark) }
    }

    private func add(_ mark: PadMark) {
        var all = marks[page] ?? []
        all.append(mark)
        // A very busy sheet drops its oldest marks, so it never slows down.
        if all.count > 400 { all.removeFirst(all.count - 400) }
        marks[page] = all
        changed()
        maybePeek()
    }

    private func changed() {
        version += 1
        PadStore.save(marks)
    }

    /// Fills are worked out for the paper's size, so they are redone when it turns.
    private func refreshFills() {
        guard paperSize != .zero else { return }
        if fillSize != paperSize { fills = [:] }
        fillSize = paperSize
        let size = paperSize, sheet = page
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let wanted = pageMarks.compactMap { mark -> (UUID, CGPoint)? in
            guard case .fill = mark.kind, fills[mark.id] == nil, let point = mark.points.first else { return nil }
            return (mark.id, CGPoint(x: centre.x + point.x, y: centre.y + point.y))
        }
        guard !wanted.isEmpty else { version += 1; return }
        Task {
            let made = await Task.detached(priority: .userInitiated) {
                wanted.compactMap { id, point in PaintPot.mask(page: sheet, size: size, at: point).map { (id, $0) } }
            }.value
            guard paperSize == size else { return }
            for (id, mask) in made { fills[id] = mask }
            version += 1
        }
    }

    private func saveToPhotos() {
        let size = paperSize
        guard size != .zero else { return }
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let picture = ZStack {
            Palette.scrap
            PaperArt(marks: pageMarks, fills: fills, centre: centre, version: version)
            outline(in: size)
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: picture)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in show("Photos is switched off for this app in Settings") }
                return
            }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            Task { @MainActor in show("Saved to Photos") }
        }
    }

    private func show(_ message: String) {
        withAnimation(.spring(duration: 0.35)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) { toast = nil }
        }
    }

    // MARK: Controls

    private func controls(columns: Int) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(PadTool.allCases) { option in
                    let isOn = tool == option
                    Button {
                        Haptics.selection()
                        tool = option
                    } label: {
                        VStack(spacing: 2) {
                            toolIcon(option).frame(height: 32)
                            Text(option.title).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(isOn ? Palette.field : Palette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            if tool != .eraser {
                colours(columns: columns)
                    .modifier(Shake(amount: 5, animatableData: CGFloat(dryNudge)))
            }
            if tool.draws { sizes }
            if tool == .stamp { stampPictures.transition(.opacity) }
        }
        .animation(.easeInOut(duration: 0.2), value: tool)
    }

    /// Ink pads for the stamp; crayons, pens or paint for the rest.
    private func colours(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 6) {
            ForEach(Ink.allCases) { option in
                let isOn = ink == option
                Button {
                    Haptics.selection()
                    withAnimation(.spring(duration: 0.25, bounce: 0.4)) { ink = option }
                    if tool == .stamp {
                        // Pressing a pad inks the stamp afresh.
                        inkLeft = 8
                        withAnimation(.spring(duration: 0.15)) { squished = option }
                        Task {
                            try? await Task.sleep(for: .seconds(0.15))
                            withAnimation(.spring(duration: 0.3, bounce: 0.5)) { squished = nil }
                        }
                    }
                } label: {
                    colourPiece(option)
                        .scaleEffect(x: squished == option ? 0.9 : 1, y: squished == option ? 0.8 : 1, anchor: .bottom)
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
    }

    private var sizes: some View {
        HStack(spacing: 10) {
            ForEach(PadSize.allCases) { option in
                let isOn = brush == option
                Button {
                    Haptics.selection()
                    brush = option
                } label: {
                    Circle()
                        .fill(tool == .eraser ? Palette.muted : ink.colour)
                        .frame(width: 8 + 12 * option.rawValue, height: 8 + 12 * option.rawValue)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(isOn ? Palette.field : Palette.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel(option == .thin ? "Thin" : option == .middle ? "Middle" : "Chunky")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }

    private var stampPictures: some View {
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
    }

    @ViewBuilder private func toolIcon(_ option: PadTool) -> some View {
        switch option {
        case .stamp:
            StampMark(stamp: stamp, ink: ink, size: 32)
                .opacity(max(Self.strengths[inkLeft], 0.25))
        case .crayon:
            CrayonPiece(colour: ink.colour).frame(width: 12, height: 32).rotationEffect(.degrees(28))
        case .marker:
            MarkerPiece(colour: ink.colour).frame(width: 11, height: 32).rotationEffect(.degrees(28))
        case .fill:
            PaintPotPiece(colour: ink.colour).frame(width: 30, height: 28)
        case .eraser:
            RubberPiece().frame(width: 30, height: 18).rotationEffect(.degrees(-20))
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
        case .fill, .eraser:
            PaintPotPiece(colour: option.colour).frame(width: 34, height: 32).padding(.bottom, 8)
        }
    }
}

/// A little pot of paint, for the paint pot tool.
struct PaintPotPiece: View {
    let colour: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(Palette.paper)
                    .overlay(RoundedRectangle(cornerRadius: w * 0.16, style: .continuous).stroke(.black.opacity(0.18), lineWidth: 1))
                    .frame(width: w * 0.8, height: h * 0.72)
                Ellipse().fill(colour).frame(width: w * 0.8, height: h * 0.3).offset(y: -h * 0.56)
                // A drip down the side.
                Capsule().fill(colour).frame(width: w * 0.14, height: h * 0.32).offset(x: w * 0.22, y: -h * 0.36)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// A pink rubber with a paper band.
struct RubberPiece: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color(hex: 0xF2A7B5))
            Rectangle().fill(Color(hex: 0x6C93C4)).frame(width: 12)
        }
        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(.black.opacity(0.2), lineWidth: 1))
        .accessibilityHidden(true)
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


/// Crayon and pen lines.
///
/// Crayon is wax: the paper's tooth shows through as slanted flecks, the edge
/// is ragged, and going over a patch again fills more of it in. Pen is felt
/// tip: each pass is see-through, so going back over a spot builds it up
/// darker, as a real marker does. The rubber takes everything under it away.
enum StrokeLayer {
    static func draw(tool: PadTool, width: Double, mark: PadMark, centre: CGPoint,
                     tooth: GraphicsContext.Shading, in context: inout GraphicsContext) {
        let scale = CGFloat(width)
        switch tool {
        case .crayon:
            let path = line(mark.points, centre: centre)
            let box = path.boundingRect.insetBy(dx: -30, dy: -30)
            context.drawLayer { layer in
                layer.stroke(path, with: .color(mark.ink.colour.opacity(0.45)),
                             style: StrokeStyle(lineWidth: 16 * scale, lineCap: .round, lineJoin: .round, dash: [1.4, 2.8]))
                layer.stroke(path, with: .color(mark.ink.colour.opacity(0.9)),
                             style: StrokeStyle(lineWidth: tool.width * scale, lineCap: .round, lineJoin: .round))
                // The paper's tooth, knocked out of this pass only. Each line
                // starts its flecks somewhere else, so a second pass fills gaps.
                var knock = layer
                knock.blendMode = .destinationOut
                let seed = mark.points.first ?? .zero
                knock.translateBy(x: (seed.x * 7).truncatingRemainder(dividingBy: 120), y: (seed.y * 13).truncatingRemainder(dividingBy: 120))
                knock.opacity = 0.75
                knock.fill(Path(box.insetBy(dx: -120, dy: -120)), with: tooth)
            }
        case .marker:
            // Each pass of the pen is its own see-through layer.
            for pass in passes(mark.points) {
                var see = context
                see.opacity = 0.5
                see.drawLayer { layer in
                    layer.stroke(line(pass, centre: centre), with: .color(mark.ink.colour),
                                 style: StrokeStyle(lineWidth: tool.width * scale, lineCap: .round, lineJoin: .round))
                }
            }
        case .eraser:
            var rub = context
            rub.blendMode = .destinationOut
            rub.stroke(line(mark.points, centre: centre), with: .color(.black),
                       style: StrokeStyle(lineWidth: tool.width * scale, lineCap: .round, lineJoin: .round))
        default:
            break
        }
    }

    /// Splits a pen line where it doubles back on itself, so scribbling to and
    /// fro over a spot counts as going over it again.
    static func passes(_ points: [CGPoint]) -> [[CGPoint]] {
        guard points.count > 2 else { return [points] }
        var result: [[CGPoint]] = []
        var current = [points[0]]
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
