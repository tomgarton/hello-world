import SwiftUI

/// After a wee, a poo or a try, the phone goes to the child: pick a stamp
/// and press it onto the next space. The fifth one fills the card, and a
/// shiny sticker goes on the end. Only the stamps and the card can be
/// tapped; a grown-up holds the bottom line for two seconds to take it back.
struct StampFlowView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let event: Event

    @State private var chosen: Stamp = .thong
    @State private var before: [Impression] = []
    @State private var theme: CardTheme = .beach
    @State private var cardIndex = 0
    @State private var loaded = false
    @State private var curl: CGFloat = 0
    @State private var corner = CGPoint(x: StampCard.size.width, y: 0)
    @State private var rippleStart: Date?
    @State private var peeled = false
    @State private var laid = false

    @State private var stamped: Impression?
    @State private var pressing = false
    @State private var stamperDown = false
    @State private var dip = false
    @State private var offering = false
    @State private var stuck = false
    @State private var burst = false
    @State private var lifted = false
    @State private var drag: CGSize = .zero
    @State private var tilt: CGSize = .zero
    @State private var held = false
    @State private var stickerFrame: CGRect = .zero
    @State private var targetFrame: CGRect = .zero

    private var child: Child? { event.sortedChildren.first }
    private var name: String { child?.displayName ?? "" }
    private var impressions: [Impression] { before + (stamped.map { [$0] } ?? []) }
    private var space: CGPoint { StampCard.spaces[min(before.count, Stamp.perCard - 1)] }
    private var isFull: Bool { impressions.count == Stamp.perCard }
    private var sticker: StickerStyle { .card(cardIndex) }

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            Text(title)
                .displayFont(30)
                .multilineTextAlignment(.center)
                .frame(minHeight: 76)
            card
                .zIndex(1)
            Group {
                if offering && !stuck {
                    stickerSheet
                } else if stamped == nil {
                    tray
                } else {
                    Color.clear.frame(height: 160)
                }
            }
            .zIndex(2)
            Spacer(minLength: 0)
            Text("Grown-ups: hold here to skip")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 2) { dismiss() }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Hold for two seconds")
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .coordinateSpace(name: "flow")
        .onAppear(perform: load)
    }

    private var title: String {
        if stuck { return "You filled the card!" }
        if offering { return "Stick on the shiny one!" }
        if stamped != nil { return "Stamped!" }
        return name.isEmpty ? "Pick a stamp!" : "Pick a stamp, \(name)!"
    }

    private func load() {
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

    // MARK: The card

    private var card: some View {
        CardCanvas {
            StampCardFace(theme: theme, impressions: impressions, sticker: sticker)
                .modifier(PaperEffects(curl: reduceMotion ? 0 : curl, corner: corner, rippleOrigin: space,
                                       rippleStart: reduceMotion ? nil : rippleStart))
                .gesture(paperGesture)
            if stuck {
                // The sticker folds down onto its space, hinged at its lower edge.
                StickerView(style: sticker, size: 68)
                    .rotationEffect(.degrees(-8))
                    .rotation3DEffect(.degrees(laid ? 0 : -82), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
                    .opacity(laid ? 1 : 0.6)
                    .position(StampCard.last)
                    .allowsHitTesting(false)
            }
            if stamped == nil, !pressing {
                Button(action: press) {
                    Circle()
                        .strokeBorder(Palette.fixedInk.opacity(0.6), style: StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
                        .frame(width: 60, height: 60)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .position(space)
                .accessibilityLabel("Press the \(chosen.name) stamp here")
            }
            if pressing {
                stamper
                    .scaleEffect(stamperDown ? 1 : 1.5)
                    .offset(y: stamperDown ? 0 : -70)
                    .opacity(stamperDown ? 1 : 0)
                    .position(space)
            }
            if burst {
                ForEach(0..<20, id: \.self) { index in
                    Confetto(index: index, go: lifted).position(StampCard.last)
                }
            }
            Color.clear.frame(width: 70, height: 70)
                .background(GeometryReader { geometry in
                    Color.clear.onAppear { targetFrame = geometry.frame(in: .named("flow")) }
                })
                .position(StampCard.last)
                .allowsHitTesting(false)
        }
        // The paper takes the hit: it dips and twists a touch, then settles.
        .scaleEffect(dip ? 0.955 : (lifted ? 1.06 : (held ? 1.03 : 1)))
        .rotationEffect(.degrees(dip ? 0.9 : 0))
        .offset(y: dip ? 4 : (lifted ? -10 : 0))
        .rotation3DEffect(.degrees(Double(-tilt.height)), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(Double(tilt.width)), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        // Matte: the card lifts and casts a deeper shadow, with no highlight.
        .shadow(color: .black.opacity(held || lifted ? 0.3 : 0.2), radius: held || lifted ? 18 : 8, y: held || lifted ? 14 : 5)
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
                withAnimation(.spring(duration: 0.55, bounce: 0.4)) {
                    tilt = .zero
                    curl = 0
                    held = false
                }
            }
    }

    private var stamper: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(hex: 0xC99A6B), Color(hex: 0x8A5A3C), Color(hex: 0x5E3B26)],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 40))
            Circle().fill(RadialGradient(colors: [Color(hex: 0xE2B98C), Color(hex: 0xA8744B)],
                                         center: UnitPoint(x: 0.4, y: 0.35), startRadius: 1, endRadius: 20))
                .padding(16)
        }
        .frame(width: 66, height: 66)
        .shadow(color: .black.opacity(0.35), radius: stamperDown ? 2 : 14, y: stamperDown ? 2 : 20)
        .allowsHitTesting(false)
    }

    // MARK: Stamping

    /// The stamps sit on a sheet of paper, the same in light and dark.
    private var tray: some View {
        VStack(spacing: 6) {
            ForEach([Array(Stamp.offered.prefix(4)), Array(Stamp.offered.dropFirst(4))], id: \.first) { row in
                HStack(spacing: 6) {
                    ForEach(row) { stamp in
                        let isOn = stamp == chosen
                        Button {
                            chosen = stamp
                            Haptics.selection()
                        } label: {
                            StampMark(stamp: stamp, size: 64)
                                .padding(5)
                                .frame(maxWidth: .infinity)
                                .background(isOn ? Color(hex: 0xE3D8BF) : .clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.fixedInk, lineWidth: isOn ? 2 : 0))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(stamp.name) stamp")
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
            }
        }
        .padding(8)
        .background(Palette.stampSpace, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func press() {
        guard !pressing, stamped == nil else { return }
        pressing = true
        Task {
            // Down.
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.18)) { stamperDown = true }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.18))
            // The hit: the thud, the ink, and the paper giving under it.
            Haptics.thud()
            store.setSticker(chosen.rawValue, on: event)
            stamped = Impression(event)
            if !reduceMotion {
                // A real ripple through the paper, from a shader.
                rippleStart = .now
                withAnimation(.spring(duration: 0.08, bounce: 0)) { dip = true }
                try? await Task.sleep(for: .seconds(0.08))
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) { dip = false }
            }
            try? await Task.sleep(for: .seconds(0.15))
            // And away.
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.22)) { stamperDown = false }
            try? await Task.sleep(for: .seconds(0.5))
            pressing = false
            if isFull {
                Haptics.success()
                withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.3)) { offering = true }
            } else {
                try? await Task.sleep(for: .seconds(1.1))
                dismiss()
            }
            rippleStart = nil
        }
    }

    // MARK: The shiny sticker

    /// A backing sheet with the sticker on it. It peels up from one corner as it is lifted.
    private var stickerSheet: some View {
        HStack(spacing: 16) {
            ZStack {
                // Where it was: the outline left on the backing.
                Image(sticker.shape).resizable().scaledToFit()
                    .foregroundStyle(Color(hex: 0xEDE7DA))
                    .frame(width: 80, height: 80)
                StickerView(style: sticker, size: 84)
                    .modifier(PaperEffects(curl: reduceMotion ? 0 : (peeled ? 26 : 0), corner: CGPoint(x: 84, y: 0),
                                           rippleOrigin: .zero, rippleStart: nil,
                                           size: CGSize(width: 84, height: 84), back: .white))
                    .scaleEffect(peeled ? 1.12 : 1)
                    .rotationEffect(.degrees(Double(drag.width) / 12))
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear { stickerFrame = geometry.frame(in: .named("flow")) }
                    })
                    .offset(drag)
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
                                let near = hypot(centre.x - targetFrame.midX, centre.y - targetFrame.midY) < 80
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
                .foregroundStyle(Palette.fixedInk.opacity(0.7))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 120)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        .padding(.vertical, 20)
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
