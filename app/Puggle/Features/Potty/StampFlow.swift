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

    @State private var chosen: Stamp = .clip
    @State private var before: [Impression] = []
    @State private var theme: CardTheme = .beach
    @State private var loaded = false

    @State private var stamped: Impression?
    @State private var pressing = false
    @State private var stamperDown = false
    @State private var dip = false
    @State private var ring = false
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
                    Color.clear.frame(height: 76)
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
            theme = .forCard(cards.count - 1)
        } else {
            before = []
            theme = .forCard(cards.count)
        }
    }

    // MARK: The card

    private var card: some View {
        CardCanvas {
            StampCardFace(theme: theme, impressions: impressions, hasSticker: stuck)
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
                // A ring runs out through the paper from where the stamp landed.
                Circle().stroke(Palette.fixedInk.opacity(0.35), lineWidth: 3)
                    .frame(width: 20, height: 20)
                    .scaleEffect(ring ? 9 : 1)
                    .opacity(ring ? 0 : 0.6)
                    .position(space)
                    .allowsHitTesting(false)
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
        .gesture(tiltGesture)
    }

    /// Dragging tilts the card under the finger; it springs back when let go.
    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !reduceMotion else { return }
                held = true
                tilt = CGSize(width: max(-11, min(11, value.translation.width / 9)),
                              height: max(-11, min(11, value.translation.height / 9)))
            }
            .onEnded { _ in
                withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
                    tilt = .zero
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

    private var tray: some View {
        HStack(spacing: 6) {
            ForEach(Stamp.offered) { stamp in
                let isOn = stamp == chosen
                Button {
                    chosen = stamp
                    Haptics.selection()
                } label: {
                    StampMark(stamp: stamp, size: 44)
                        .padding(4)
                        .background(isOn ? Palette.field : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(stamp.name) stamp")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(8)
        .frame(height: 76)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                withAnimation(.easeOut(duration: 0.5)) { ring = true }
                withAnimation(.spring(duration: 0.08, bounce: 0)) { dip = true }
                try? await Task.sleep(for: .seconds(0.08))
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) { dip = false }
            }
            try? await Task.sleep(for: .seconds(0.15))
            // And away.
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.22)) { stamperDown = false }
            try? await Task.sleep(for: .seconds(0.5))
            pressing = false
            ring = false
            if isFull {
                Haptics.success()
                withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.3)) { offering = true }
            } else {
                try? await Task.sleep(for: .seconds(1.1))
                dismiss()
            }
        }
    }

    // MARK: The shiny sticker

    private var stickerSheet: some View {
        HStack(spacing: 14) {
            StickerView(size: 68)
                .scaleEffect(drag == .zero ? 1 : 1.1)
                .rotationEffect(.degrees(Double(drag.width) / 12))
                .background(GeometryReader { geometry in
                    Color.clear.onAppear { stickerFrame = geometry.frame(in: .named("flow")) }
                })
                .offset(drag)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag = $0.translation }
                        .onEnded { value in
                            let centre = CGPoint(x: stickerFrame.midX + value.translation.width,
                                                 y: stickerFrame.midY + value.translation.height)
                            let near = hypot(centre.x - targetFrame.midX, centre.y - targetFrame.midY) < 70
                            let tapped = hypot(value.translation.width, value.translation.height) < 8
                            if near || tapped {
                                stick()
                            } else {
                                withAnimation(.spring(duration: 0.4, bounce: 0.4)) { drag = .zero }
                            }
                        }
                )
                .accessibilityElement()
                .accessibilityLabel("Shiny sticker")
                .accessibilityHint("Sticks it onto the card")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { stick() }
            Text("Peel it off and stick it on the card.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 76)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// The big moment: the card lifts, quatrefoils scatter, and it is done.
    private func stick() {
        guard !stuck else { return }
        drag = .zero
        stuck = true
        Haptics.thud()
        Task {
            burst = true
            if reduceMotion {
                lifted = true
            } else {
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
