import SwiftUI

/// A sticker a child has earned. Stickers are for things that happened:
/// finished cards, firsts, new foods tried, milestones and dry days in total.
/// There are no streaks, nothing expires, and nothing is earned for logging.
struct EarnedSticker: Identifiable {
    let id: String
    let title: String
    var style = StickerStyle()
    /// What it was for, on the back.
    var detail = ""
}

extension FamilyStore {
    func earnedStickers(for child: Child) -> [EarnedSticker] {
        let events = Array(child.events ?? [])
        var earned: [EarnedSticker] = []

        // Finished stamp cards.
        let cards = stickers(for: child).count / Stamp.perCard
        if cards >= 1 { earned.append(EarnedSticker(id: "card-1", title: "First card", style: .card(0), detail: "Five stamps on a card, and the shiny one on the end.")) }
        for count in [5, 10, 25, 50] where cards >= count {
            earned.append(EarnedSticker(id: "card-\(count)", title: "\(count) cards", style: .card(count), detail: "\(count) stamp cards filled."))
        }

        // Firsts on the potty.
        let potty = events.filter { $0.kind == .potty }
        if potty.contains(where: { $0.detail == "Wee" }) {
            earned.append(EarnedSticker(id: "wee", title: "First wee on the potty", style: StickerStyle(shape: "shape-pebble", foil: nil, colour: Color(hex: 0xCFE5D2), emblem: "icon-potty"), detail: "The first wee on the potty."))
        }
        if potty.contains(where: { $0.detail == "Poo" }) {
            earned.append(EarnedSticker(id: "poo", title: "First poo on the potty", style: StickerStyle(shape: "shape-pebble", foil: nil, colour: Color(hex: 0xF3D9C9), emblem: "icon-potty"), detail: "The first poo on the potty."))
        }

        // Days with a wee or a poo on the potty and no accident, in total (never in a row).
        var days: [Date: (success: Bool, accident: Bool)] = [:]
        for event in potty {
            guard let at = event.startedAt else { continue }
            let day = Calendar.current.startOfDay(for: at)
            var entry = days[day] ?? (false, false)
            if event.detail == "Accident" { entry.accident = true }
            if event.detail == "Wee" || event.detail == "Poo" { entry.success = true }
            days[day] = entry
        }
        let dry = days.values.filter { $0.success && !$0.accident }.count
        if dry >= 1 { earned.append(EarnedSticker(id: "dry-1", title: "First dry day", style: StickerStyle(shape: "shape-soft-square", foil: .sea), detail: "A day on the potty with no accidents.")) }
        for count in [3, 7, 14, 30] where dry >= count {
            earned.append(EarnedSticker(id: "dry-\(count)", title: "\(count) dry days", style: StickerStyle(shape: "shape-soft-square", foil: .sea), detail: "\(count) days with no accidents, in total."))
        }

        // New foods tried.
        let foods = Set(events.filter { $0.kind == .solids }
            .compactMap { $0.detail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }).count
        if foods >= 1 { earned.append(EarnedSticker(id: "food-1", title: "First food", style: StickerStyle(shape: "shape-scallop", foil: .gold, emblem: "icon-solids"), detail: "A first taste of something new.")) }
        for count in [5, 10, 20, 50] where foods >= count {
            earned.append(EarnedSticker(id: "food-\(count)", title: "\(count) new foods", style: StickerStyle(shape: "shape-scallop", foil: .gold, emblem: "icon-solids"), detail: "\(count) different foods tried."))
        }

        // Milestones.
        for event in milestones(for: child) {
            earned.append(EarnedSticker(id: event.objectID.uriRepresentation().absoluteString,
                                        title: event.detail ?? "Milestone",
                                        style: StickerStyle(shape: "shape-blossom", foil: .sunset, emblem: "icon-milestone"),
                                        detail: event.startedAt?.formatted(date: .long, time: .omitted) ?? ""))
        }
        return earned
    }
}

/// The stickers a child has earned. Only earned ones are shown, so nothing looks missing.
struct EarnedStickersGrid: View {
    let stickers: [EarnedSticker]
    @State private var looking: EarnedSticker?

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 4), spacing: 14) {
            ForEach(stickers) { sticker in
                Button { looking = sticker } label: {
                    VStack(spacing: 4) {
                        StickerView(style: sticker.style, size: 58)
                        Text(sticker.title)
                            .font(.caption2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                    .foregroundStyle(Palette.ink)
                }
                .buttonStyle(PressStyle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(sticker.title) sticker")
                .accessibilityHint("Opens it large")
            }
        }
        .sheet(item: $looking) { StickerDetailView(sticker: $0) }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// A child's stickers, on their page.
struct EarnedStickersView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child

    var body: some View {
        let stickers = store.earnedStickers(for: child)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if stickers.isEmpty {
                    Text("Stickers appear here as \(child.displayName) earns them: a first food, a milestone, a finished stamp card.")
                        .foregroundStyle(Palette.muted)
                } else {
                    EarnedStickersGrid(stickers: stickers)
                }
                Text("Stickers are for things that happened. There are no streaks, and nothing is ever taken away.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .navigationTitle("\(child.displayName)'s stickers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The stamp book: the card being filled, the finished cards, and the
/// stickers earned. It only ever adds up.
struct StampBookView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    let children: [Child]
    @State private var playing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // Back to the stamps, crayons and pens, just to play.
                    Button { playing = true } label: {
                        HStack(spacing: 12) {
                            StampMark(stamp: .star, ink: .red, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stamps, crayons and pens").font(.headline)
                                Text("Play and colour in. Nothing here counts.")
                                    .font(.footnote)
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.muted)
                        }
                        .padding(14)
                        .foregroundStyle(Palette.ink)
                        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(PressStyle(scale: 0.98))
                    ForEach(children) { child in
                        book(for: child)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.sand)
            .fullScreenCover(isPresented: $playing) { PlayPadView() }
            .navigationTitle("Stamp book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .foregroundStyle(Palette.ink)
    }

    @ViewBuilder private func book(for child: Child) -> some View {
        let cards = store.stampCards(for: child)
        let current = cards.last.flatMap { $0.count < Stamp.perCard ? $0 : nil }
        let finished = Array(cards.enumerated()).filter { $0.element.count == Stamp.perCard }
        let stickers = store.earnedStickers(for: child)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ChildAvatar(child: child, size: 36)
                Text(child.displayName).font(.title3.weight(.semibold))
            }
            // The card being filled, or a fresh one ready to start.
            PlayfulCard(theme: .forCard(current == nil ? cards.count : cards.count - 1), impressions: current ?? [],
                        sticker: .card(current == nil ? cards.count : cards.count - 1))
            Text(current.map { "\(Stamp.perCard - $0.count) to go before the shiny one." } ?? "A new card, ready for its first stamp.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)

            if !finished.isEmpty {
                SquiggleLabel("Finished cards").padding(.top, 6)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(finished.reversed(), id: \.offset) { index, card in
                        CardCanvas {
                            StampCardFace(theme: .forCard(index), impressions: card, sticker: .card(index), hasSticker: true)
                        }
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
                    }
                }
            }
            if !stickers.isEmpty {
                SquiggleLabel("Stickers earned").padding(.top, 6)
                EarnedStickersGrid(stickers: stickers)
            }
        }
    }
}

/// A card that can be played with: drag a corner to fold it over. Fold every
/// corner, or the same corner three times, and it turns over to show Puggle
/// drawn in crayon on the back. Tap to turn it back.
struct PlayfulCard: View {
    let theme: CardTheme
    let impressions: [Impression]
    var sticker = StickerStyle()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var curl: CGFloat = 0
    @State private var corner = CGPoint(x: StampCard.size.width, y: 0)
    @State private var held = false
    @State private var pulls: [String: Int] = [:]
    @State private var flipped = false

    var body: some View {
        CardCanvas {
            ZStack(alignment: .topLeading) {
                StampCardFace(theme: theme, impressions: impressions, sticker: sticker)
                    .modifier(PaperEffects(curl: reduceMotion ? 0 : curl, corner: corner, rippleOrigin: .zero, rippleStart: nil))
                    .opacity(flipped ? 0 : 1)
                    .animation(.linear(duration: 0.01).delay(0.25), value: flipped)
                CardBack(theme: theme)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(flipped ? 1 : 0)
                    .animation(.linear(duration: 0.01).delay(0.25), value: flipped)
            }
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .contentShape(Rectangle())
            .gesture(fold, including: flipped || reduceMotion ? .none : .all)
            .onTapGesture {
                if flipped { withAnimation(.easeInOut(duration: 0.5)) { flipped = false } }
            }
        }
        .scaleEffect(held ? 1.02 : 1)
        .shadow(color: .black.opacity(held ? 0.28 : 0.2), radius: held ? 14 : 8, y: held ? 10 : 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(flipped ? "The back of the card: a crayon drawing of Puggle"
                                    : "\(theme.name) card, \(impressions.count) of \(Stamp.perCard) stamps")
    }

    private var fold: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if !held {
                    held = true
                    let size = StampCard.size
                    corner = CGPoint(x: value.startLocation.x < size.width / 2 ? 0 : size.width,
                                     y: value.startLocation.y < size.height / 2 ? 0 : size.height)
                }
                let centre = CGPoint(x: StampCard.size.width / 2, y: StampCard.size.height / 2)
                let length = hypot(centre.x - corner.x, centre.y - corner.y)
                let inward = (value.translation.width * (centre.x - corner.x) + value.translation.height * (centre.y - corner.y)) / length
                curl = max(0, min(90, inward))
            }
            .onEnded { _ in
                let folded = curl > 30
                withAnimation(.spring(duration: 0.55, bounce: 0.4)) {
                    curl = 0
                    held = false
                }
                guard folded else { return }
                let key = "\(Int(corner.x))-\(Int(corner.y))"
                pulls[key, default: 0] += 1
                if pulls.count == 4 || pulls[key, default: 0] >= 3 {
                    pulls = [:]
                    Haptics.success()
                    withAnimation(.easeInOut(duration: 0.5)) { flipped = true }
                }
            }
    }
}
