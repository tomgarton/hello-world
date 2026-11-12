import SwiftUI

/// After a wee, a poo or a try, the phone goes to the child. Two pages:
///
/// 1. Get your stamp ready: pick a picture, press the wooden stamper on an ink
///    pad, and try it on scrap paper as often as they like. Those marks fade as
///    the ink dries. The ink runs out after eight presses.
/// 2. Stamp your card: the whole card, then it moves in on the glowing space.
///    One press lands where it was pressed, a little off centre if so, and the
///    card moves back out to show it in place. The fifth fills the card, and a
///    shiny sticker goes on the end.
///
/// Everything works by tapping as well as dragging. A grown-up holds Skip for
/// two seconds to take the phone back.
struct StampFlowView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let event: Event

    private enum Page { case ready, card }

    // Choosing and inking
    @State private var page: Page = .ready
    @State private var chosen: Stamp = .star
    @State private var ink: Ink?
    @State private var load = 0
    @State private var squished: Ink?
    @State private var loose: [LooseStamp] = []
    @State private var readyHint = "Pick a picture, then press the stamper on an ink pad."

    // The stamper
    @State private var stamperAt: CGPoint = .zero
    @State private var grab: CGSize?
    @State private var stamperUp = false
    @State private var stamperThud = false
    @State private var stamperGone = false
    @State private var shakes = 0
    @State private var nudges = 0
    @State private var nudgeTask: Task<Void, Never>?

    // Where things are
    @State private var pageSize: CGSize = .zero
    @State private var scrapFrame: CGRect = .zero
    @State private var padFrames: [Ink: CGRect] = [:]
    @State private var cardFrame: CGRect = .zero
    @State private var stickerFrame: CGRect = .zero

    // Hold to skip
    @State private var skipProgress: CGFloat = 0
    @State private var skipTask: Task<Void, Never>?

    // The card
    @State private var before: [Impression] = []
    @State private var theme: CardTheme = .beach
    @State private var cardIndex = 0
    @State private var loaded = false
    @State private var zoomed = false
    @State private var cardHint = ""
    @State private var curl: CGFloat = 0
    @State private var corner = CGPoint(x: StampCard.size.width, y: 0)
    @State private var rippleStart: Date?
    @State private var stamped: Impression?
    @State private var pressing = false
    @State private var dip = false
    @State private var tilt: CGSize = .zero
    @State private var held = false
    /// The Easter egg: corners folded over so far, and whether the card is turned over.
    @State private var cornerPulls: [String: Int] = [:]
    @State private var flipped = false

    // The shiny sticker
    @State private var offering = false
    @State private var stuck = false
    @State private var peeled = false
    @State private var laid = false
    @State private var burst = false
    @State private var lifted = false
    @State private var drag: CGSize = .zero

    private static let zoomScale: CGFloat = 1.75
    /// How strong a press is with this much ink left: full for the first five, then fading.
    private static let strengths: [Double] = [0, 0.3, 0.5, 0.72, 0.9, 1, 1, 1, 1]

    private var child: Child? { event.sortedChildren.first }
    private var name: String { child?.displayName ?? "" }
    private var impressions: [Impression] { before + (stamped.map { [$0] } ?? []) }
    private var space: CGPoint { StampCard.spaces[min(before.count, Stamp.perCard - 1)] }
    private var isFull: Bool { impressions.count == Stamp.perCard }
    private var sticker: StickerStyle { .card(cardIndex) }
    private var inkColour: Color { ink?.colour ?? Palette.ink }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                readyPage
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: page == .ready ? 0 : -geometry.size.width)
                cardPage
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: page == .card ? 0 : geometry.size.width)
                stamper
            }
            .coordinateSpace(name: "flow")
            .onAppear { pageSize = geometry.size }
            .onChange(of: geometry.size) { _, size in pageSize = size }
        }
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        // A stray swipe up from the bottom only shows the Home bar; it takes a second to leave.
        .defersSystemGestures(on: .bottom)
        .onAppear(perform: setUpCard)
        .onDisappear {
            nudgeTask?.cancel()
            skipTask?.cancel()
        }
    }

    private func setUpCard() {
        guard !loaded else { return }
        loaded = true
        guard let child else { return }
        let cards = store.stampCards(for: child)
        // A full last card means this stamp starts a new one.
        if let last = cards.last, last.count < Stamp.perCard {
            before = last
            cardIndex = cards.count - 1
        } else {
            before = []
            cardIndex = cards.count
        }
        theme = .forCard(cardIndex)
    }

    // MARK: - Page one: get your stamp ready

    private var readyPage: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get your stamp ready").displayFont(26)
                    Text(readyHint)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                skipButton
            }
            scrapPaper
            pictures
            pads
            Button("Stamp my card") { goToCard() }
                .buttonStyle(PillButtonStyle())
                .disabled(ink == nil)
                .opacity(ink == nil ? 0.4 : 1)
                .modifier(Shake(amount: 4, animatableData: CGFloat(nudges)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .coordinateSpace(name: "readyPage")
    }

    /// Somewhere to try the stamp. Nothing here counts; it fades as it dries.
    private var scrapPaper: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.scrap)
            Image(uiImage: Grain.image).resizable(resizingMode: .tile)
                .foregroundStyle(Palette.ink)
                .opacity(0.06)
            if loose.isEmpty {
                Text("Try your stamp here")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }
            ForEach(loose) { mark in
                LooseStampView(mark: mark) { loose.removeAll { $0.id == mark.id } }
                    .position(mark.point)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 150)
        .contentShape(Rectangle())
        .onTapGesture { location in tapPaper(location) }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("readyPage")) } action: { frame in
            scrapFrame = frame
            if stamperAt == .zero, page == .ready { stamperAt = readyHome }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Scrap paper")
        .accessibilityAction(named: "Try the stamp") { playPress(at: CGPoint(x: scrapFrame.width / 2, y: scrapFrame.height / 2)) }
    }

    private var pictures: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
            ForEach(Stamp.offered) { stamp in
                let isOn = stamp == chosen
                Button {
                    chosen = stamp
                    Haptics.selection()
                } label: {
                    StampPicture(stamp: stamp)
                        .foregroundStyle(inkColour)
                        .frame(width: 38, height: 38)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(isOn ? Palette.field : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(stamp.name) stamp")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(6)
        .background(Palette.stampSpace, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var pads: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(Ink.allCases) { pad in
                let isOn = ink == pad
                Button { inkUp(pad) } label: {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(pad.colour)
                        .overlay(alignment: .bottom) {
                            // The pad's lower edge, so it reads as a block of ink.
                            Rectangle().fill(.black.opacity(0.2)).frame(height: 6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay {
                            if isOn { Image(systemName: "checkmark").font(.subheadline.weight(.bold)).foregroundStyle(.white) }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                        .frame(height: 46)
                        .scaleEffect(x: squished == pad ? 0.9 : 1, y: squished == pad ? 0.82 : 1, anchor: .bottom)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                }
                .buttonStyle(.plain)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("readyPage")) } action: { padFrames[pad] = $0 }
                .accessibilityLabel("\(pad.rawValue.capitalized) ink pad")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }

    /// For grown-ups: the ring fills while held, and drains if let go early.
    private var skipButton: some View {
        ZStack {
            Circle().fill(Palette.field)
            Circle()
                .trim(from: 0, to: skipProgress)
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(2)
            Text("Skip").font(.caption.weight(.semibold))
        }
        .frame(width: 56, height: 56)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startSkip() }
                .onEnded { _ in stopSkip() }
        )
        .accessibilityElement()
        .accessibilityLabel("Skip")
        .accessibilityHint("For grown-ups. Hold for two seconds.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { dismiss() }
    }

    private func startSkip() {
        guard skipTask == nil else { return }
        Haptics.tap()
        let remaining = 2 * Double(1 - skipProgress)
        withAnimation(.linear(duration: remaining)) { skipProgress = 1 }
        skipTask = Task {
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            Haptics.success()
            dismiss()
        }
    }

    private func stopSkip() {
        skipTask?.cancel()
        skipTask = nil
        withAnimation(.easeOut(duration: 0.35)) { skipProgress = 0 }
    }

    private func inkUp(_ pad: Ink) {
        ink = pad
        load = 8
        Haptics.tap()
        withAnimation(.easeOut(duration: 0.08)) { squished = pad }
        Task {
            try? await Task.sleep(for: .seconds(0.16))
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) { squished = nil }
        }
        readyHint = "Try it on the paper, then stamp your card."
        scheduleNudge()
    }

    /// After a while of play, the "Stamp my card" button gives a small wiggle.
    private func scheduleNudge() {
        nudgeTask?.cancel()
        nudgeTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled, page == .ready else { return }
                withAnimation(.linear(duration: 0.6)) { nudges += 1 }
            }
        }
    }

    private func tapPaper(_ location: CGPoint) {
        let target = CGPoint(x: scrapFrame.minX + location.x, y: scrapFrame.minY + location.y)
        withAnimation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0)) { stamperAt = target }
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.2))
            playPress(at: location)
        }
    }

    /// A press on the scrap paper, at a point in the paper's own space.
    private func playPress(at location: CGPoint) {
        guard let ink else { return dry("It needs ink first. Press an ink pad.") }
        guard load > 0 else { return dry("The ink has run out. Press an ink pad again.") }
        let strength = Self.strengths[load]
        load -= 1
        thud()
        loose.append(LooseStamp(point: location, stamp: chosen, ink: ink, strength: strength,
                                tilt: Double.random(in: -20...20), seed: UInt64.random(in: 1...UInt64(UInt32.max))))
        if loose.count > 20 { loose.removeFirst() }
    }

    private func dry(_ message: String) {
        Haptics.warning()
        withAnimation(.linear(duration: 0.35)) { shakes += 1 }
        if page == .ready { readyHint = message } else { cardHint = message }
    }

    private func thud() {
        Haptics.thud()
        withAnimation(.easeOut(duration: 0.07)) { stamperThud = true }
        Task {
            try? await Task.sleep(for: .seconds(0.09))
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) { stamperThud = false }
        }
    }

    // MARK: - The stamper

    private var readyHome: CGPoint {
        guard scrapFrame != .zero else { return CGPoint(x: pageSize.width - 70, y: 260) }
        return CGPoint(x: scrapFrame.maxX - 58, y: scrapFrame.maxY - 58)
    }

    private var cardHome: CGPoint { CGPoint(x: pageSize.width / 2, y: pageSize.height - 95) }

    private var stamper: some View {
        let loaded = ink != nil
        return ZStack {
            // A ring of ink round the base: how loaded it is.
            Circle()
                .strokeBorder(inkColour, lineWidth: 6)
                .padding(-7)
                .opacity(loaded ? max(Double(load), 1) / 8 : 0)
            Circle().fill(RadialGradient(colors: [Color(hex: 0xC99A6B), Color(hex: 0x8A5A3C), Color(hex: 0x5E3B26)],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 56))
            Circle().fill(RadialGradient(colors: [Color(hex: 0xE2B98C), Color(hex: 0xA8744B)],
                                         center: UnitPoint(x: 0.4, y: 0.35), startRadius: 1, endRadius: 28))
                .padding(22)
            StampPicture(stamp: chosen)
                .foregroundStyle(loaded ? inkColour : Color(hex: 0x5E3B26))
                .frame(width: 28, height: 28)
        }
        .frame(width: 96, height: 96)
        .scaleEffect(stamperThud ? 0.9 : (stamperUp ? 1.16 : 1))
        .shadow(color: .black.opacity(0.32), radius: stamperUp ? 14 : 5, y: stamperUp ? 18 : 5)
        .modifier(Shake(amount: 7, animatableData: CGFloat(shakes)))
        .contentShape(Circle())
        .position(stamperAt)
        .opacity(stamperGone || offering || stuck ? 0 : 1)
        .allowsHitTesting(!(stamperGone || offering || stuck || pressing))
        .gesture(stamperDrag)
        .accessibilityLabel("Stamper")
        .accessibilityHint(page == .ready ? "Drag it onto an ink pad, then onto the paper" : "Drag it onto the glowing space")
    }

    /// Picked up where it is held: the stamper's centre stays under the same spot of the finger.
    private var stamperDrag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("flow"))
            .onChanged { value in
                if grab == nil {
                    grab = CGSize(width: value.startLocation.x - stamperAt.x, height: value.startLocation.y - stamperAt.y)
                    withAnimation(.easeOut(duration: 0.15)) { stamperUp = true }
                }
                let offset = grab ?? .zero
                stamperAt = CGPoint(x: min(max(value.location.x - offset.width, 40), pageSize.width - 40),
                                    y: min(max(value.location.y - offset.height, 40), pageSize.height - 40))
            }
            .onEnded { value in
                grab = nil
                withAnimation(.easeOut(duration: 0.15)) { stamperUp = false }
                guard hypot(value.translation.width, value.translation.height) > 6 else { return }
                drop(at: stamperAt)
            }
    }

    private func drop(at point: CGPoint) {
        switch page {
        case .ready:
            if let pad = padFrames.first(where: { $0.value.insetBy(dx: -8, dy: -16).contains(point) })?.key {
                inkUp(pad)
                // Back to its spot on the paper, so it does not sit on the pads.
                withAnimation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.2).delay(0.15)) { stamperAt = readyHome }
            } else if scrapFrame.contains(point) {
                playPress(at: CGPoint(x: point.x - scrapFrame.minX, y: point.y - scrapFrame.minY))
            }
        case .card:
            cardPress(at: point)
        }
    }

    // MARK: - Page two: stamp your card

    private var cardTitle: String {
        if stuck { return "You filled the card!" }
        if offering { return "Stick on the shiny one!" }
        if stamped != nil { return "Stamped!" }
        return name.isEmpty ? "Stamp your card!" : "Stamp your card, \(name)!"
    }

    private var cardPage: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                if stamped == nil {
                    Button { backToReady() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .frame(width: 46, height: 46)
                            .background(Palette.field, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back to the stamps")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(cardTitle).displayFont(26)
                    if !cardHint.isEmpty {
                        Text(cardHint).font(.subheadline).foregroundStyle(Palette.muted)
                    }
                }
                Spacer(minLength: 0)
            }
            .zIndex(2)
            Spacer(minLength: 0)
            cardView
            Spacer(minLength: 0)
            ZStack {
                if offering && !stuck { stickerSheet }
            }
            .frame(height: 170)
            .zIndex(3)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .coordinateSpace(name: "cardPage")
    }

    private var base: CGFloat { cardFrame.width / StampCard.size.width }

    /// How far the card slides so the space to stamp sits in the middle.
    private var zoomShift: CGFloat { pageSize.width / 2 - (cardFrame.minX + space.x * base) }

    /// Where the glowing space is on screen, once zoomed in.
    private var targetCentre: CGPoint {
        CGPoint(x: cardFrame.minX + space.x * base + (zoomed ? zoomShift : 0), y: cardFrame.minY + space.y * base)
    }

    private var cardView: some View {
        CardCanvas {
            ZStack(alignment: .topLeading) {
                StampCardFace(theme: theme, impressions: impressions, sticker: sticker)
                    .modifier(PaperEffects(curl: reduceMotion ? 0 : curl, corner: corner, rippleOrigin: space,
                                           rippleStart: reduceMotion ? nil : rippleStart))
                    .gesture(paperGesture, including: zoomed || flipped ? .none : .all)
                    .opacity(flipped ? 0 : 1)
                    .animation(.linear(duration: 0.01).delay(0.25), value: flipped)
                // The back: only seen when the card is turned over.
                CardBack(theme: theme)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(flipped ? 1 : 0)
                    .animation(.linear(duration: 0.01).delay(0.25), value: flipped)
                    .allowsHitTesting(false)
            }
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            if stuck {
                // The sticker folds down onto its space, hinged at its lower edge.
                StickerView(style: sticker, size: 68)
                    .rotationEffect(.degrees(-8))
                    .rotation3DEffect(.degrees(laid ? 0 : -82), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
                    .opacity(laid ? 1 : 0.6)
                    .position(StampCard.last)
                    .allowsHitTesting(false)
            }
            if stamped == nil, page == .card {
                StampTarget().position(space)
            }
            if burst {
                ForEach(0..<20, id: \.self) { index in
                    Confetto(index: index, go: lifted).position(StampCard.last)
                }
            }
        }
        // Moves in on the space to stamp, then back out to show it in place.
        .scaleEffect(zoomed ? Self.zoomScale : 1,
                     anchor: UnitPoint(x: space.x / StampCard.size.width, y: space.y / StampCard.size.height))
        .offset(x: zoomed ? zoomShift : 0)
        // The paper takes the hit: it dips and twists a touch, then settles.
        .scaleEffect(dip ? 0.955 : (lifted ? 1.06 : (held ? 1.03 : 1)))
        .rotationEffect(.degrees(dip ? 0.9 : 0))
        .offset(y: dip ? 4 : (lifted ? -10 : 0))
        .rotation3DEffect(.degrees(Double(-tilt.height)), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(Double(tilt.width)), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        // Matte: the card lifts and casts a deeper shadow, with no highlight.
        .shadow(color: .black.opacity(held || lifted ? 0.3 : 0.2), radius: held || lifted ? 18 : 8, y: held || lifted ? 14 : 5)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("cardPage")) } action: { cardFrame = $0 }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .named("flow")) { location in tapCard(location) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(theme.name) card, \(impressions.count) of \(Stamp.perCard) stamps")
        .accessibilityAction(named: "Stamp the card") { cardPress(at: targetCentre) }
    }

    /// Dragging tilts the card and folds over the nearest corner, as far as it is pulled in.
    /// Both spring back when let go.
    private var paperGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !reduceMotion else { return }
                if !held {
                    held = true
                    let size = StampCard.size
                    corner = CGPoint(x: value.startLocation.x < size.width / 2 ? 0 : size.width,
                                     y: value.startLocation.y < size.height / 2 ? 0 : size.height)
                }
                tilt = CGSize(width: max(-7, min(7, value.translation.width / 14)),
                              height: max(-7, min(7, value.translation.height / 14)))
                let centre = CGPoint(x: StampCard.size.width / 2, y: StampCard.size.height / 2)
                let length = hypot(centre.x - corner.x, centre.y - corner.y)
                let inward = (value.translation.width * (centre.x - corner.x) + value.translation.height * (centre.y - corner.y)) / length
                curl = max(0, min(90, inward))
            }
            .onEnded { _ in
                let folded = curl > 30
                withAnimation(.spring(duration: 0.55, bounce: 0.4)) {
                    tilt = .zero
                    curl = 0
                    held = false
                }
                // Fold every corner, or one corner three times, and the card turns over.
                guard folded else { return }
                let key = "\(Int(corner.x))-\(Int(corner.y))"
                cornerPulls[key, default: 0] += 1
                if cornerPulls.count == 4 || cornerPulls[key, default: 0] >= 3 {
                    cornerPulls = [:]
                    turnOver()
                }
            }
    }

    private func goToCard() {
        guard ink != nil else { return dry("It needs ink first. Press an ink pad.") }
        nudgeTask?.cancel()
        stopSkip()
        Haptics.tap()
        // A fresh dab, so the stamp that counts is never faint.
        load = 8
        zoomed = false
        cardHint = "Here is your card."
        withAnimation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0)) {
            page = .card
            stamperAt = cardHome
        }
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            guard page == .card, stamped == nil else { return }
            withAnimation(reduceMotion ? nil : .spring(duration: 0.75, bounce: 0)) { zoomed = true }
            cardHint = "Press the stamper on the glowing space."
        }
    }

    private func backToReady() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0)) {
            zoomed = false
            page = .ready
            stamperAt = readyHome
        }
        scheduleNudge()
    }

    /// Turns the card over to show Puggle on the back, then back again.
    private func turnOver() {
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.5)) { flipped = true }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeInOut(duration: 0.5)) { flipped = false }
        }
    }

    private func tapCard(_ location: CGPoint) {
        if flipped {
            withAnimation(.easeInOut(duration: 0.5)) { flipped = false }
            return
        }
        guard page == .card, zoomed, stamped == nil, !pressing else { return }
        withAnimation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0)) { stamperAt = location }
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.2))
            cardPress(at: location)
        }
    }

    /// The press that counts. It lands where in the circle it was pressed, up to a little off centre.
    private func cardPress(at point: CGPoint) {
        guard page == .card, zoomed, stamped == nil, !pressing, base > 0 else { return }
        let centre = targetCentre
        let diameter = 54 * base * Self.zoomScale
        var dx = point.x - centre.x, dy = point.y - centre.y
        let far = hypot(dx, dy)
        guard far <= diameter * 0.8 else {
            cardHint = "Nearly. Press it on the glowing space."
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) { stamperAt = cardHome }
            return
        }
        let most = diameter * 0.17
        if far > most {
            dx *= most / far
            dy *= most / far
        }
        let unit = base * Self.zoomScale
        let offset = CGSize(width: dx / unit, height: dy / unit)
        pressing = true
        Task {
            thud()
            let seed = UInt64.random(in: 1...UInt64(UInt32.max))
            let saved = "\(chosen.rawValue):\((ink ?? chosen.ink).rawValue):\(seed):"
                + "\(String(format: "%.1f", offset.width)):\(String(format: "%.1f", offset.height))"
            store.setSticker(saved, on: event)
            stamped = Impression(event)
            cardHint = ""
            if !reduceMotion {
                // A real ripple through the paper, from a shader.
                rippleStart = .now
                withAnimation(.spring(duration: 0.08, bounce: 0)) { dip = true }
                try? await Task.sleep(for: .seconds(0.08))
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) { dip = false }
            }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeIn(duration: 0.25)) { stamperGone = true }
            try? await Task.sleep(for: .seconds(0.45))
            // Back out, to see it in place on the whole card.
            withAnimation(reduceMotion ? nil : .spring(duration: 0.75, bounce: 0)) { zoomed = false }
            pressing = false
            if isFull {
                try? await Task.sleep(for: .seconds(0.8))
                Haptics.success()
                withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.3)) { offering = true }
            } else {
                try? await Task.sleep(for: .seconds(2.4))
                dismiss()
            }
            rippleStart = nil
        }
    }

    // MARK: - The shiny sticker

    /// Where the sticker's space is on screen.
    private var lastCentre: CGPoint {
        CGPoint(x: cardFrame.minX + StampCard.last.x * base, y: cardFrame.minY + StampCard.last.y * base)
    }

    /// A backing sheet with the sticker on it. It peels up from one corner as it is lifted.
    private var stickerSheet: some View {
        HStack(spacing: 16) {
            ZStack {
                // Where it was: the outline left on the backing.
                Image(sticker.shape).resizable().scaledToFit()
                    .foregroundStyle(Palette.field)
                    .frame(width: 80, height: 80)
                StickerView(style: sticker, size: 84)
                    .modifier(PaperEffects(curl: reduceMotion ? 0 : (peeled ? 26 : 0), corner: CGPoint(x: 84, y: 0),
                                           rippleOrigin: .zero, rippleStart: nil,
                                           size: CGSize(width: 84, height: 84), back: Palette.paper))
                    .scaleEffect(peeled ? 1.12 : 1)
                    .rotationEffect(.degrees(Double(drag.width) / 12))
                    .offset(drag)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("flow")) } action: { stickerFrame = $0 }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !peeled {
                                    Haptics.tap()
                                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) { peeled = true }
                                }
                                drag = value.translation
                            }
                            .onEnded { value in
                                let centre = CGPoint(x: stickerFrame.midX + value.translation.width,
                                                     y: stickerFrame.midY + value.translation.height)
                                let near = hypot(centre.x - lastCentre.x, centre.y - lastCentre.y) < 80
                                let tapped = hypot(value.translation.width, value.translation.height) < 8
                                if near || tapped {
                                    stick()
                                } else {
                                    withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                                        drag = .zero
                                        peeled = false
                                    }
                                }
                            }
                    )
                    .accessibilityElement()
                    .accessibilityLabel("Shiny sticker")
                    .accessibilityHint("Sticks it onto the card")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { stick() }
            }
            Text("Peel it off and stick it on the card.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 120)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// The big moment: the card lifts, quatrefoils scatter, and it is done.
    private func stick() {
        guard !stuck else { return }
        drag = .zero
        stuck = true
        Task {
            if reduceMotion {
                laid = true
                Haptics.thud()
                burst = true
                lifted = true
            } else {
                // It folds down onto the space, then the card takes the press.
                withAnimation(.spring(duration: 0.32, bounce: 0.25)) { laid = true }
                try? await Task.sleep(for: .seconds(0.26))
                Haptics.thud()
                burst = true
                withAnimation(.spring(duration: 0.12, bounce: 0)) { dip = true }
                try? await Task.sleep(for: .seconds(0.12))
                Haptics.success()
                withAnimation(.spring(duration: 0.6, bounce: 0.5)) {
                    dip = false
                    lifted = true
                }
            }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2)) { lifted = false }
            try? await Task.sleep(for: .seconds(1.6))
            dismiss()
        }
    }
}

/// A play stamp on the scrap paper.
private struct LooseStamp: Identifiable {
    let id = UUID()
    let point: CGPoint
    let stamp: Stamp
    let ink: Ink
    let strength: Double
    let tilt: Double
    let seed: UInt64
}

/// Fades as the ink dries, then goes.
private struct LooseStampView: View {
    let mark: LooseStamp
    let onGone: () -> Void
    @State private var dried = false

    var body: some View {
        let wear = StampWear(seed: mark.seed, gentle: false)
        let size: CGFloat = 84
        ZStack {
            if let ghost = wear.ghost {
                StampMark(stamp: mark.stamp, ink: mark.ink, size: size, wear: wear)
                    .offset(x: ghost.width * size / 54, y: ghost.height * size / 54)
                    .opacity(0.2)
            }
            StampMark(stamp: mark.stamp, ink: mark.ink, size: size, wear: wear)
        }
        .rotationEffect(.degrees(mark.tilt))
        .opacity(dried ? 0 : mark.strength)
        .allowsHitTesting(false)
        .task {
            try? await Task.sleep(for: .seconds(6))
            withAnimation(.linear(duration: 5)) { dried = true }
            try? await Task.sleep(for: .seconds(5))
            onGone()
        }
    }
}

/// "Stamp here", without words: a soft glow that breathes, and a band of light running round the rim.
private struct StampTarget: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.wattle.opacity(breathe ? 0.5 : 0.18), lineWidth: breathe ? 7 : 3)
            Circle()
                .trim(from: 0, to: 0.32)
                .stroke(AngularGradient(colors: [.white.opacity(0), .white, Palette.wattle, .white.opacity(0)], center: .center),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(spin ? 360 : 0))
        }
        .frame(width: 60, height: 60)
        .shadow(color: .white.opacity(breathe ? 0.9 : 0.4), radius: breathe ? 9 : 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else {
                breathe = true
                return
            }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) { breathe = true }
        }
    }
}

/// A quick side-to-side shake: the stamper with no ink, or a gentle nudge on a button.
private struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}

/// One quatrefoil flying out from the sticker.
private struct Confetto: View {
    let index: Int
    let go: Bool

    private static let colours: [Color] = [Palette.wattle, Palette.waratah, Palette.harbour, Palette.gum,
                                           Color(hex: 0xF9C6D8), Color(hex: 0xB5D8FA)]

    var body: some View {
        let angle = Double(index) / 20 * 2 * .pi + Double(index % 3) * 0.4
        let distance = 70.0 + Double((index * 37) % 120)
        Quatrefoil()
            .fill(Self.colours[index % Self.colours.count])
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(go ? Double(index * 50) : 0))
            .offset(x: go ? cos(angle) * distance : 0, y: go ? sin(angle) * distance - 20 : 0)
            .opacity(go ? 0 : 1)
            .animation(.easeOut(duration: 1.1 + Double(index % 5) * 0.1), value: go)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
