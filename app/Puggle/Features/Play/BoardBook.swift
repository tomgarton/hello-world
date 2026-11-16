import SwiftUI

// A board book on the screen: thick card pages that turn stiffly on a spine, and flaps cut into the page
// that lift on a hinge and leave a recess. A first try (16 November 2026), to find out how convincing card
// can be made with nothing but SwiftUI. See docs/stories/board-book-build.md for what was weighed up.
// Open it from Settings, Test builds only, "Board book", or with "-debugBook 1".

/// The card every page and flap is cut from.
enum Board {
    static let corner: CGFloat = 26
    /// How thick the card is, in points. It shows at the page's edge as it turns and in a flap's recess.
    static let thick: CGFloat = 5
    static let face = Color(hex: 0xFBF6E9)
    /// The cut edge of grey board.
    static let edge = Color(hex: 0xCDBFA6)
    static let edgeDark = Color(hex: 0xA99A80)
    /// How far a page swings before it has left the screen, in degrees.
    static let swing = 104.0
}

// MARK: The book

/// A book shown one page to a screen, as a phone held upright shows it. The spine is the left edge.
struct BoardBookView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    /// The page that is turning, if one is, and how far: 0 is lying flat, 1 is gone to the left.
    @State private var mover: Int?
    @State private var turned = 0.0
    /// Which pages have their flap open.
    @State private var open: Set<Int> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { box in
            let width = min(box.size.width - 28, (box.size.height - 40) * 0.7)
            let size = CGSize(width: width, height: width / 0.7)
            ZStack {
                // The table it lies on.
                LinearGradient(colors: [Color(hex: 0x4A3B30), Color(hex: 0x2E241D)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                pages(size)
                    .frame(width: size.width, height: size.height)
                    .gesture(turning(width: size.width))
            }
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Board.face)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }
                .padding(.leading, 14)
                .accessibilityLabel("Close the book")
            }
        }
        .statusBarHidden(true)
    }

    /// The page lying flat, the page under it while one turns, and the stack of card behind.
    @ViewBuilder private func pages(_ size: CGSize) -> some View {
        let last = book.pages.count - 1
        // What lies flat underneath, and what is on top of it turning.
        let under: Int? = mover == nil ? nil : (mover == index ? (index < last ? index + 1 : nil) : index)
        let top = mover ?? index
        let angle = mover == nil ? 0 : turned * Board.swing
        ZStack {
            stack(left: index - (mover == index - 1 ? 1 : 0), right: last - index)
            if let under {
                page(under, size)
                    .overlay(castShadow(angle))
                    .clipShape(RoundedRectangle(cornerRadius: Board.corner, style: .continuous))
            } else if mover != nil {
                // Past the last page there is only the back board.
                RoundedRectangle(cornerRadius: Board.corner, style: .continuous).fill(Board.edge)
            }
            page(top, size)
                .overlay(lighting(angle).clipShape(RoundedRectangle(cornerRadius: Board.corner, style: .continuous)))
                // The cut edge of the card, which comes into view as the page stands up.
                .overlay(alignment: .trailing) {
                    let wide = min(Board.thick * tan(angle * .pi / 180), 60)
                    LinearGradient(colors: [Board.edge, Board.edgeDark], startPoint: .leading, endPoint: .trailing)
                        .frame(width: max(wide, 0))
                        .padding(.vertical, Board.corner * 0.6)
                        .offset(x: max(wide, 0))
                }
                .rotation3DEffect(.degrees(-angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.42)
                .shadow(color: .black.opacity(mover == nil ? 0.35 : 0.2), radius: 10, x: 4, y: 8)
            edges(size)
        }
    }

    /// The other pages, seen as their edges: those still to come on the right and below, those read on the left.
    private func stack(left: Int, right: Int) -> some View {
        ZStack {
            ForEach(Array((0..<min(right, 7)).reversed()), id: \.self) { step in
                RoundedRectangle(cornerRadius: Board.corner, style: .continuous)
                    .fill(step.isMultiple(of: 2) ? Board.edge : Board.edgeDark)
                    .offset(x: CGFloat(step + 1) * 1.6, y: CGFloat(step + 1) * 1.6)
            }
            ForEach(Array((0..<min(max(left, 0), 7)).reversed()), id: \.self) { step in
                RoundedRectangle(cornerRadius: Board.corner, style: .continuous)
                    .fill(step.isMultiple(of: 2) ? Board.edge : Board.edgeDark)
                    .offset(x: -CGFloat(step + 1) * 1.6, y: CGFloat(step + 1) * 0.8)
            }
        }
    }

    private func page(_ number: Int, _ size: CGSize) -> some View {
        BookPageView(page: book.pages[number], number: number, of: book.pages.count,
                     open: Binding(get: { open.contains(number) },
                                   set: { if $0 { open.insert(number) } else { open.remove(number) } }))
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: Board.corner, style: .continuous))
    }

    /// The shadow a standing page throws on the one beneath: under the page, and a little past its edge.
    private func castShadow(_ angle: Double) -> some View {
        let reach = max(cos(angle * .pi / 180), 0)
        let dark = 0.38 * sin(min(angle, 90) * .pi / 180) + 0.06
        return LinearGradient(stops: [.init(color: .black.opacity(dark), location: 0),
                                      .init(color: .black.opacity(dark * 0.85), location: reach),
                                      .init(color: .clear, location: min(reach + 0.22, 1))],
                              startPoint: .leading, endPoint: .trailing)
            .allowsHitTesting(false)
    }

    /// A page darkens as it turns from the light, and a soft band of shine crosses it.
    private func lighting(_ angle: Double) -> some View {
        let lean = sin(min(angle, 90) * .pi / 180)
        return ZStack {
            Color.black.opacity(0.3 * lean)
            LinearGradient(stops: [.init(color: .clear, location: max(lean - 0.25, 0)),
                                   .init(color: .white.opacity(0.22 * lean), location: lean),
                                   .init(color: .clear, location: min(lean + 0.2, 1))],
                           startPoint: .trailing, endPoint: .leading)
        }
        .allowsHitTesting(false)
    }

    /// A strip down each side to tap, for a child who does not swipe. Flaps sit clear of them.
    private func edges(_ size: CGSize) -> some View {
        HStack {
            Color.clear.frame(width: 40).contentShape(Rectangle()).onTapGesture { turn(to: index - 1) }
                .accessibilityLabel("Page before")
            Spacer()
            Color.clear.frame(width: 40).contentShape(Rectangle()).onTapGesture { turn(to: index + 1) }
                .accessibilityLabel("Next page")
        }
        .opacity(mover == nil ? 1 : 0)
    }

    private func turn(to target: Int) {
        guard mover == nil, book.pages.indices.contains(target) else { return }
        // With Reduce Motion the page does not swing: the next one fades in.
        if reduceMotion {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.25)) { index = target }
            return
        }
        let forward = target > index
        mover = forward ? index : index - 1
        turned = forward ? 0 : 1
        settle(forward: forward)
    }

    /// Lets the turning page fall the rest of the way, forward or back, then makes it the page that lies flat.
    private func settle(forward: Bool) {
        guard let moving = mover else { return }
        Haptics.tap()
        // Card is stiff: it falls quickly and lands without a bounce.
        withAnimation(.easeIn(duration: 0.32 * (forward ? 1 - turned : turned) + 0.08)) {
            turned = forward ? 1 : 0
        } completion: {
            index = forward ? min(moving + 1, book.pages.count - 1) : moving
            mover = nil
            turned = 0
        }
    }

    /// A drag across the page turns it with the finger: leftwards to go on, rightwards to go back.
    private func turning(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { drag in
                guard !reduceMotion else { return }
                let across = drag.translation.width
                if mover == nil {
                    guard abs(across) > abs(drag.translation.height) else { return }
                    if across < 0, index < book.pages.count - 1 { mover = index; turned = 0 }
                    else if across > 0, index > 0 { mover = index - 1; turned = 1 }
                    else { return }
                }
                let forward = mover == index
                let share = Double(abs(across) / (width * 0.85))
                turned = forward ? min(max(share * (across < 0 ? 1 : 0), 0), 1) : min(max(1 - share * (across > 0 ? 1 : 0), 0), 1)
            }
            .onEnded { drag in
                if reduceMotion {
                    if abs(drag.translation.width) > 40 { turn(to: index + (drag.translation.width < 0 ? 1 : -1)) }
                    return
                }
                guard mover != nil else { return }
                let forward = mover == index
                // Past a third of the way, or flicked, it goes over. Otherwise it falls back.
                let flicked = abs(drag.predictedEndTranslation.width) > width * 0.6
                let over = forward ? (turned > 0.33 || flicked) : (turned < 0.67 || flicked)
                if forward { settle(forward: over) } else { settle(forward: !over) }
            }
    }
}

// MARK: A flap

/// A piece cut from the page and hinged along one edge. Shut, it sits in the page with a fine cut line and a
/// thumb notch. Lifted, it swings over on its hinge, shows its plain back, and leaves a recess as deep as the
/// card, with what was hidden at the bottom of it.
struct Flap<Front: View, Under: View>: View {
    let shape: FlapShape
    let hinge: Edge
    @Binding var open: Bool
    @ViewBuilder var front: Front
    @ViewBuilder var under: Under
    /// 0 shut, 1 lying open.
    @State private var lift = 0.0

    var body: some View {
        let angle = lift * 172
        // How far it stands from the page: nothing lying shut or lying open, most when upright.
        let lean = sin(angle * .pi / 180)
        ZStack {
            // The recess. Always there, so it shows through the thumb notch even when the flap is shut.
            under
                .clipShape(shape)
                .overlay(Color.black.opacity(0.10).clipShape(shape))
                // The wall of the recess, lit from the top left: dark along the top and left, a thin light lip opposite.
                .overlay(shape.stroke(Color.black.opacity(0.55), lineWidth: Board.thick * 1.6).blur(radius: 3)
                    .offset(x: Board.thick * 0.5, y: Board.thick * 0.7).clipShape(shape))
                .overlay(shape.stroke(Color.white.opacity(0.5), lineWidth: 1).offset(x: -0.5, y: -0.5).clipShape(shape))
                .overlay(shape.stroke(Board.edgeDark, lineWidth: 1))
            // The flap.
            Group {
                if angle < 90 {
                    front
                        .overlay(Color.black.opacity(0.28 * lean))
                } else {
                    // Its back: bare card, a little in shade.
                    Board.face.overlay(Color.black.opacity(0.06 + 0.2 * lean))
                }
            }
            .clipShape(NotchedFlap(shape: shape, hinge: hinge))
            // The cut: a hairline all round, light on the side the light comes from.
            .overlay(NotchedFlap(shape: shape, hinge: hinge).stroke(Color.black.opacity(0.32), lineWidth: 0.9))
            .overlay(NotchedFlap(shape: shape, hinge: hinge).stroke(Color.white.opacity(0.55), lineWidth: 0.8).offset(x: -0.7, y: -0.7)
                .clipShape(NotchedFlap(shape: shape, hinge: hinge)))
            .rotation3DEffect(.degrees(sign * angle), axis: axis, anchor: anchor, perspective: 0.55)
            // Shut, it is level with the page. Lifted, it throws a soft shadow that grows.
            .shadow(color: .black.opacity(0.12 + 0.25 * lean), radius: 1 + 9 * lean, x: 2 * lean, y: 1 + 5 * lean)
        }
        .contentShape(Rectangle())
        // Lifted by the finger: it follows a drag away from its hinge, and on letting go it falls open or shut,
        // whichever it is nearer, or the way it was flicked. A tap still opens and shuts it.
        .highPriorityGesture(lifting)
        .onTapGesture {
            Haptics.tap()
            open.toggle()
        }
        .background(GeometryReader { box in Color.clear.onAppear { size = box.size } })
        .onAppear { lift = open ? 1 : 0 }
        .onChange(of: open) { _, now in
            // Card springs a little as it lands, and falls shut faster than it lifts.
            withAnimation(now ? .spring(response: 0.55, dampingFraction: 0.62) : .spring(response: 0.38, dampingFraction: 0.8)) {
                lift = now ? 1 : 0
            }
        }
        .accessibilityElement()
        .accessibilityLabel(open ? "Flap, open" : "Flap")
        .accessibilityAddTraits(.isButton)
    }

    /// Where the drag began, as how far open the flap was then.
    @State private var startLift: Double?
    @State private var size: CGSize = .zero

    /// How far a drag of this much would open the flap: pulling it away from its hinge by its own depth lifts it
    /// upright, and on over.
    private func reach(_ drag: CGSize) -> Double {
        let depth = Double(max(hinge == .top || hinge == .bottom ? size.height : size.width, 40))
        let along: Double = switch hinge {
        case .top: drag.height
        case .bottom: -drag.height
        case .leading: drag.width
        case .trailing: -drag.width
        }
        return along / (depth * 1.6)
    }

    private var lifting: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { drag in
                if startLift == nil {
                    startLift = lift
                    Haptics.tap()
                }
                lift = min(max((startLift ?? 0) + reach(drag.translation), 0), 1)
            }
            .onEnded { drag in
                let flick = reach(drag.predictedEndTranslation) - reach(drag.translation)
                let opening = flick > 0.25 ? true : (flick < -0.25 ? false : lift > 0.5)
                startLift = nil
                if opening != open {
                    open = opening
                } else {
                    // Back where it was: the same spring as a tap.
                    withAnimation(opening ? .spring(response: 0.55, dampingFraction: 0.62) : .spring(response: 0.38, dampingFraction: 0.8)) {
                        lift = opening ? 1 : 0
                    }
                }
            }
    }

    private var axis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        hinge == .top || hinge == .bottom ? (1, 0, 0) : (0, 1, 0)
    }

    private var sign: Double { hinge == .top || hinge == .trailing ? 1 : -1 }

    private var anchor: UnitPoint {
        switch hinge {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }
}

/// The outline a flap is cut to.
enum FlapShape: Shape {
    case rounded, capsule, dome, blob

    func path(in rect: CGRect) -> Path {
        switch self {
        case .rounded: return Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.18, style: .continuous)
        case .capsule: return Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2, style: .continuous)
        case .dome:
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                          control1: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY - rect.height * 0.3),
                          control2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY - rect.height * 0.3))
            path.closeSubpath()
            return path
        case .blob:
            var path = Path()
            let w = rect.width, h = rect.height
            path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY + h * 0.2, width: w * 0.6, height: h * 0.8))
            path.addEllipse(in: CGRect(x: rect.minX + w * 0.3, y: rect.minY, width: w * 0.55, height: h * 0.75))
            path.addEllipse(in: CGRect(x: rect.minX + w * 0.45, y: rect.minY + h * 0.25, width: w * 0.55, height: h * 0.75))
            return path
        }
    }
}

/// A flap's outline with a thumb notch bitten out of the edge opposite its hinge.
struct NotchedFlap: Shape {
    let shape: FlapShape
    let hinge: Edge

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 9
        let centre: CGPoint = switch hinge {
        case .top: CGPoint(x: rect.midX, y: rect.maxY)
        case .bottom: CGPoint(x: rect.midX, y: rect.minY)
        case .leading: CGPoint(x: rect.maxX, y: rect.midY)
        case .trailing: CGPoint(x: rect.minX, y: rect.midY)
        }
        let notch = Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2))
        return shape.path(in: rect).subtracting(notch)
    }
}

// MARK: A page

/// What is on one page: a picture, the question above the flap if there is one, and the words.
struct BookPage {
    var sky = Color(hex: 0xBFD9F5)
    var ground = Color(hex: 0xCFE5D2)
    /// Where the ground meets the sky, from the top, as a share of the picture.
    var horizon = 0.62
    /// Flat shapes in the scene, back to front.
    var props: [Prop] = []
    /// Who is in the picture: the rig's name, where their feet are, and how tall, as shares of the picture.
    var cast: [Figure] = []
    var flap: FlapSpot?
    /// Where the little paper boat is hidden.
    var boat = CGPoint(x: 0.9, y: 0.9)
    /// The question the flap answers. Shown with the page.
    var ask: String?
    /// The words. With a flap, they come once it has been lifted.
    var words: [String] = []
    /// The line that comes back.
    var refrain: String?

    struct Figure {
        let who: String
        let x: Double
        let y: Double
        let tall: Double
        /// Something yellow on their head, by the end.
        var hat: Thing?
    }

    struct Prop {
        let thing: Thing
        let x: Double
        let y: Double
        let wide: Double
        var colour: Color?
    }

    struct FlapSpot {
        let shape: FlapShape
        let hinge: Edge
        /// Its place in the picture, as shares of it.
        let rect: CGRect
        let colour: Color
        /// Who is under it, and the yellow thing with them.
        let who: String?
        let found: Thing
    }
}

/// The few things the storyboard needs, drawn as flat shapes with no outline, as the world is.
enum Thing {
    case log, mound, trunk, leaves, towel, stone, hat, tin, basket, door, puddle, water, house
    case cone, flower, leaf, bucket, duck, biscuit, boot

    @ViewBuilder func view(colour: Color? = nil) -> some View {
        switch self {
        case .log: Capsule().fill(colour ?? Color(hex: 0x9A6B45)).aspectRatio(3.4, contentMode: .fit)
        case .mound: FlapShape.dome.fill(colour ?? Color(hex: 0xB98A5E)).aspectRatio(2.2, contentMode: .fit)
        case .trunk: RoundedRectangle(cornerRadius: 8).fill(colour ?? Color(hex: 0xB7A58C)).aspectRatio(0.22, contentMode: .fit)
        case .leaves: FlapShape.blob.fill(colour ?? Color(hex: 0x3C9A5F)).aspectRatio(1.6, contentMode: .fit)
        case .towel:
            RoundedRectangle(cornerRadius: 8).fill(colour ?? Color(hex: 0xE5553B)).aspectRatio(2.2, contentMode: .fit)
                .overlay(HStack(spacing: 0) { ForEach(0..<7, id: \.self) { i in (i.isMultiple(of: 2) ? Color.clear : Color.white.opacity(0.75)) } }
                    .clipShape(RoundedRectangle(cornerRadius: 8)))
        case .stone: Ellipse().fill(colour ?? Color(hex: 0xA9AEB4)).aspectRatio(2.4, contentMode: .fit)
        case .hat:
            ZStack(alignment: .bottom) {
                Ellipse().fill(colour ?? Color(hex: 0xD8B77A)).aspectRatio(3.2, contentMode: .fit)
                FlapShape.dome.fill(colour ?? Color(hex: 0xD8B77A)).aspectRatio(1.5, contentMode: .fit).scaleEffect(0.55, anchor: .bottom).offset(y: -4)
            }
        case .tin: RoundedRectangle(cornerRadius: 10).fill(colour ?? Color(hex: 0x2A62B8)).aspectRatio(1.3, contentMode: .fit)
        case .basket: FlapShape.dome.fill(colour ?? Color(hex: 0xC9A06A)).aspectRatio(1.7, contentMode: .fit).rotationEffect(.degrees(180))
        case .door:
            Circle().fill(Color(hex: 0x6B4A33)).overlay(Circle().fill(colour ?? Color(hex: 0x8A5A3C)).padding(8))
        case .puddle: Ellipse().fill(colour ?? Color(hex: 0x8DB8E8)).aspectRatio(3, contentMode: .fit)
        case .water: Rectangle().fill(colour ?? Color(hex: 0x8DB8E8))
        case .house:
            VStack(spacing: 0) {
                FlapShape.dome.fill(Color(hex: 0xE5553B)).aspectRatio(2.4, contentMode: .fit)
                Rectangle().fill(colour ?? Color(hex: 0xF3D9C9)).aspectRatio(1.6, contentMode: .fit)
            }
        case .cone: Ellipse().fill(Color(hex: 0xF4BE2C)).aspectRatio(0.6, contentMode: .fit)
        case .flower:
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(Color(hex: 0xF4BE2C)).scaleEffect(0.45).offset(y: -9).rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color(hex: 0xE5553B)).scaleEffect(0.28)
            }
            .aspectRatio(1, contentMode: .fit)
        case .leaf: Ellipse().fill(Color(hex: 0xF4BE2C)).aspectRatio(2.2, contentMode: .fit).rotationEffect(.degrees(-25))
        case .bucket:
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: 30, y: 0))
                path.addLine(to: CGPoint(x: 25, y: 26)); path.addLine(to: CGPoint(x: 5, y: 26)); path.closeSubpath()
            }
            .fill(Color(hex: 0xF4BE2C)).frame(width: 30, height: 26)
        case .duck:
            ZStack(alignment: .topTrailing) {
                Ellipse().fill(Color(hex: 0xF4BE2C)).aspectRatio(1.4, contentMode: .fit).padding(.top, 10)
                Circle().fill(Color(hex: 0xF4BE2C)).frame(width: 18, height: 18)
                Capsule().fill(Color(hex: 0xE5553B)).frame(width: 9, height: 5).offset(x: 6, y: 7)
            }
        case .biscuit: Circle().fill(Color(hex: 0xD8B77A)).overlay(Circle().fill(Color(hex: 0x8A5A3C)).scaleEffect(0.18))
        case .boot:
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xF4BE2C)).frame(width: 15, height: 28)
                Capsule().fill(Color(hex: 0xF4BE2C)).frame(width: 28, height: 13)
            }
            .frame(width: 28, height: 28, alignment: .bottomLeading)
        }
    }
}

/// One page of card: the picture above, the words below, the gutter's shadow down the spine.
struct BookPageView: View {
    let page: BookPage
    let number: Int
    let of: Int
    @Binding var open: Bool
    @State private var boatWobble = 0.0

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { box in picture(box.size) }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding([.top, .horizontal], 14)
            words
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(height: 178, alignment: .top)
        }
        .background(Board.face)
        // The page dips toward the spine.
        .overlay(alignment: .leading) {
            LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 16)
                .allowsHitTesting(false)
        }
        // A faint sheen, as coated card has.
        .overlay(LinearGradient(colors: [.white.opacity(0.10), .clear, .black.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .allowsHitTesting(false))
    }

    private func picture(_ size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            page.sky
            page.ground
                .frame(height: size.height * (1 - page.horizon) + 40)
                .clipShape(FlapShape.dome.scale(x: 1.4, y: 1, anchor: .bottom))
                .frame(maxHeight: .infinity, alignment: .bottom)
            page.ground.frame(height: size.height * (1 - page.horizon) - 10).frame(maxHeight: .infinity, alignment: .bottom)
            ForEach(Array(page.props.enumerated()), id: \.offset) { _, prop in
                prop.thing.view(colour: prop.colour)
                    .frame(width: size.width * prop.wide)
                    .position(x: size.width * prop.x, y: size.height * prop.y)
            }
            ForEach(Array(page.cast.enumerated()), id: \.offset) { _, figure in
                BookFigure(who: figure.who, tall: size.height * figure.tall, hat: figure.hat)
                    .position(x: size.width * figure.x, y: size.height * figure.y - size.height * figure.tall / 2)
            }
            // The little paper boat, to find. It wobbles when it is found.
            PaperBoat()
                .frame(width: 20, height: 15)
                .rotationEffect(.degrees(boatWobble))
                .position(x: size.width * page.boat.x, y: size.height * page.boat.y)
                .onTapGesture {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) { boatWobble = boatWobble == 0 ? 14 : 0 }
                }
                .accessibilityLabel("The paper boat")
            if let spot = page.flap {
                let rect = CGRect(x: spot.rect.minX * size.width, y: spot.rect.minY * size.height,
                                  width: spot.rect.width * size.width, height: spot.rect.height * size.height)
                Flap(shape: spot.shape, hinge: spot.hinge, open: $open) {
                    spot.colour
                } under: {
                    ZStack {
                        Color(hex: 0x5B4636)
                        HStack(spacing: 4) {
                            if let who = spot.who {
                                BookFigure(who: who, tall: rect.height * 1.5, hat: nil).offset(y: rect.height * 0.3)
                            }
                            spot.found.view().frame(width: min(rect.width * 0.3, 44))
                        }
                    }
                }
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            }
        }
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ask = page.ask {
                Text(ask).displayFont(24).foregroundStyle(Palette.fixedInk)
            }
            // With a flap, the answer comes when it is lifted.
            if page.flap == nil || open {
                ForEach(page.words, id: \.self) { line in
                    Text(line).font(.system(size: 19, weight: .medium, design: .rounded)).foregroundStyle(Palette.fixedInk)
                }
                if let refrain = page.refrain {
                    Text(refrain).font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundStyle(Palette.fixedInk)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeOut(duration: 0.3), value: open)
        .overlay(alignment: .bottomTrailing) {
            Text("\(number + 1)").font(.caption2).foregroundStyle(Palette.fixedInk.opacity(0.4)).offset(y: 150)
        }
    }
}

/// One of the cast standing still, with something on their head if the story has put it there.
struct BookFigure: View {
    let who: String
    let tall: CGFloat
    var hat: Thing?
    private static var rigs: [String: Rig] = [:]

    private var rig: Rig? {
        if let held = Self.rigs[who] { return held }
        let loaded = Rig.load(who)
        Self.rigs[who] = loaded
        return loaded
    }

    var body: some View {
        if let rig {
            RigFrame(rig: rig, states: [:])
                .frame(width: tall * rig.size[0] / rig.size[1], height: tall)
                .environment(\.lineStyle, .chosen)
                .overlay(alignment: .top) {
                    if let hat {
                        hat.view().frame(width: tall * 0.3).offset(y: tall * (rig.headroom ?? 0) / rig.size[1] - tall * 0.08)
                    }
                }
                .accessibilityLabel(who.capitalized)
        }
    }
}

struct PaperBoat: View {
    var body: some View {
        Canvas { context, size in
            var hull = Path()
            hull.move(to: CGPoint(x: 0, y: size.height * 0.55))
            hull.addLine(to: CGPoint(x: size.width, y: size.height * 0.55))
            hull.addLine(to: CGPoint(x: size.width * 0.78, y: size.height))
            hull.addLine(to: CGPoint(x: size.width * 0.22, y: size.height))
            hull.closeSubpath()
            var sail = Path()
            sail.move(to: CGPoint(x: size.width * 0.5, y: 0))
            sail.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.5))
            sail.addLine(to: CGPoint(x: size.width * 0.22, y: size.height * 0.5))
            sail.closeSubpath()
            context.fill(hull, with: .color(.white))
            context.fill(sail, with: .color(Color(white: 0.93)))
        }
    }
}

struct Book {
    let title: String
    let pages: [BookPage]
}
