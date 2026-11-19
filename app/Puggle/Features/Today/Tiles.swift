import CoreData
import SwiftUI

/// One thing that can be logged from Today: an activity, or the Health group.
struct Tile: Identifiable, Hashable {
    let id: String

    static let health = Tile(id: "health")
    /// Bottle and breastfeed together: one tap when a family uses one, a choice when both.
    static let feeding = Tile(id: "feeding")
    /// The order tiles are offered in. Sleep is not here: it starts from each child's row.
    static let all: [Tile] = [feeding] + [EventKind.nappy, .potty, .solids, .weight, .pump].map { Tile(id: $0.rawValue) } + [health]

    var kind: EventKind? { EventKind(rawValue: id) }
    var title: String { self == .feeding ? "Feeding" : (kind?.title ?? "Health") }
    var iconName: String { self == .feeding ? EventKind.bottle.iconName : (kind ?? .medicine).iconName }

    /// The kinds a tile without a single kind offers.
    var choices: [EventKind] {
        switch self {
        case .feeding: [.bottle, .breastfeed]
        case .health: EventKind.health
        default: kind.map { [$0] } ?? []
        }
    }
}

/// Which tiles are large, which are chips and which are hidden. Until the
/// parent changes it, it is suggested from what the children use.
struct TileLayout {
    static let mainLimit = 3

    var main: [Tile]
    var chips: [Tile]
    var hidden: [Tile]

    /// Feeding and nappies (and the potty, while training) are on Today;
    /// everything else is in each child's panel.
    static func suggested(from available: [Tile]) -> TileLayout {
        let main = available.filter { $0 == .feeding || $0.kind == .nappy || $0.kind == .potty }
        return TileLayout(main: Array(main.prefix(mainLimit)), chips: available.filter { !main.contains($0) }, hidden: [])
    }

    /// The parent's own choice, kept to tiles that still apply.
    static func custom(main: String, hidden: String, available: [Tile]) -> TileLayout {
        // Bottle and breastfeed were separate tiles before Feeding.
        var mainIDs: [String] = []
        for id in main.split(separator: ",").map(String.init) {
            let mapped = (id == "bottle" || id == "breastfeed") ? "feeding" : id
            if !mainIDs.contains(mapped) { mainIDs.append(mapped) }
        }
        let hiddenIDs = Set(hidden.split(separator: ",").map(String.init))
        let chosen = Array(mainIDs.compactMap { id in available.first { $0.id == id } }.prefix(mainLimit))
        let hiddenTiles = available.filter { hiddenIDs.contains($0.id) && !chosen.contains($0) }
        return TileLayout(main: chosen,
                          chips: available.filter { !chosen.contains($0) && !hiddenTiles.contains($0) },
                          hidden: hiddenTiles)
    }
}

/// The most recent entry in the last 24 hours, for a tile: "Bea 20:55".
/// Named whenever the tile is for more than one child.
@MainActor
func latestLine(_ entries: [(child: Child, event: Event)], named: Bool) -> String {
    let cutoff = Date.now.addingTimeInterval(-24 * 3600)
    guard let last = entries
        .filter({ ($0.event.startedAt ?? .distantPast) > cutoff })
        .max(by: { ($0.event.startedAt ?? .distantPast) < ($1.event.startedAt ?? .distantPast) }) else { return "" }
    let time = (last.event.startedAt ?? .now).formatted(date: .omitted, time: .shortened)
    return named ? "\(last.child.displayName) \(time)" : time
}

/// A tile on Today, large or as a chip. Tapping logs; touching and holding
/// offers each child's latest entry to change. Health asks which of its three first.
struct TileButton: View {
    @EnvironmentObject private var store: FamilyStore
    let tile: Tile
    let children: [Child]
    var large = true
    let onAdd: (EventKind) -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    let onEdit: (Event) -> Void
    /// Goes up each time something of this tile's kind is saved, so its icon is drawn over once.
    @State private var saves = 0

    /// True while one of this tile's timers is running for one of its children: a breastfeed, for the feeding tile.
    private var running: Bool {
        tile.choices.contains(.breastfeed) && children.contains { store.activeFeed(for: $0) != nil }
    }

    private var entries: [(child: Child, event: Event)] {
        children.compactMap { child in
            let latest: Event?
            let kinds = tile.choices
            latest = (child.events ?? [])
                .filter { kinds.contains($0.kind) }
                .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
            return latest.map { (child, $0) }
        }
    }

    var body: some View {
        let entries = self.entries
        let latest = latestLine(entries, named: children.count > 1)
        Group {
            let choices = tile.choices.filter { kind in children.contains { $0.uses(kind) } }
            if choices.count <= 1, let kind = choices.first ?? tile.choices.first {
                Button {
                    Haptics.tap()
                    onAdd(kind)
                } label: {
                    face(latest)
                }
                .buttonStyle(PressStyle(scale: 0.96))
                .contextMenu { editItems(entries) }
            } else {
                Menu {
                    ForEach(choices) { kind in
                        Button { onAdd(kind) } label: { Label { Text(kind.title) } icon: { Image(kind.iconName + "-plain") } }
                    }
                    if !entries.isEmpty {
                        Divider()
                        editItems(entries)
                    }
                } label: {
                    face(latest)
                }
            }
        }
        // With one child chosen, the icon can take that child's colour.
        .environment(\.iconChildColour, children.count == 1 ? Palette.childColour(children[0].colourIndex) : nil)
        .onChange(of: store.lastSaved?.id) { _, id in
            guard id != nil, let saved = store.lastSaved?.events else { return }
            if saved.contains(where: { $0.isLive && tile.choices.contains($0.kind) }) { saves += 1 }
        }
        .accessibilityLabel("Log \(tile.title.lowercased())")
        .accessibilityValue(latest)
    }

    @ViewBuilder private func editItems(_ entries: [(child: Child, event: Event)]) -> some View {
        ForEach(entries, id: \.event.objectID) { entry in
            Button {
                onEdit(entry.event)
            } label: {
                Label("Change \(entry.child.displayName)'s last: \(entry.event.summary)", systemImage: "pencil")
            }
        }
    }

    @ViewBuilder private func face(_ latest: String) -> some View {
        if large && textSize.isAccessibilitySize {
            // Largest text: icon beside the words, full width, so nothing is cut off.
            HStack(spacing: 14) {
                ActivityIcon(named: tile.iconName, size: 40, saved: saves, breathing: running)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.title).font(.headline)
                    if !latest.isEmpty {
                        Text(latest).font(.subheadline).foregroundStyle(Palette.muted).monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Palette.ink)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else if large {
            VStack(spacing: 4) {
                ActivityIcon(named: tile.iconName, size: 40, saved: saves, breathing: running)
                Text(tile.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                // Always there, so every tile is the same height.
                Text(latest.isEmpty ? " " : latest)
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Palette.ink)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            HStack(spacing: 6) {
                ActivityIcon(named: tile.iconName, size: 24)
                Text(tile.title).font(.subheadline.weight(.semibold))
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .frame(minHeight: 44)
            .foregroundStyle(Palette.ink)
            .background(Palette.field, in: Capsule())
            .contentShape(Capsule())
        }
    }
}

/// Lays chips out in rows, wrapping when a row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews, width: bounds.width)
        for (index, point) in rows.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (points: [CGPoint], width: CGFloat, height: CGFloat) {
        var points: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return (points, widest, y + rowHeight)
    }
}

/// "Tiles on Today": each one is a main tile, a chip, or hidden.
struct TileChooserView: View {
    @Environment(\.dismiss) private var dismiss
    let available: [Tile]
    @AppStorage(Setting.tilesCustom) private var custom = false
    @AppStorage(Setting.tilesMain) private var mainStored = ""
    @AppStorage(Setting.tilesHidden) private var hiddenStored = ""

    private enum Place: String, CaseIterable, Identifiable {
        case main = "On Today", chip = "Child's panel", hidden = "Hidden"
        var id: String { rawValue }
    }

    private var layout: TileLayout {
        custom ? .custom(main: mainStored, hidden: hiddenStored, available: available) : .suggested(from: available)
    }

    private func place(of tile: Tile) -> Place {
        let layout = self.layout
        if layout.main.contains(tile) { return .main }
        return layout.hidden.contains(tile) ? .hidden : .chip
    }

    private func set(_ tile: Tile, to place: Place) {
        let layout = self.layout
        var main = layout.main.filter { $0 != tile }
        var hidden = layout.hidden.filter { $0 != tile }
        switch place {
        case .main:
            // A fourth main tile turns the oldest one into a chip.
            if main.count >= TileLayout.mainLimit { main.removeFirst() }
            main.append(tile)
        case .hidden:
            hidden.append(tile)
        case .chip:
            break
        }
        // Keep main tiles in the usual order, so they do not jump about.
        main = available.filter { main.contains($0) }
        mainStored = main.map(\.id).joined(separator: ",")
        hiddenStored = hidden.map(\.id).joined(separator: ",")
        custom = true
        Haptics.selection()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(available) { tile in
                        HStack(spacing: 12) {
                            ActivityIcon(named: tile.iconName, size: 28)
                            Text(tile.title)
                            Spacer()
                            Picker(tile.title, selection: Binding(get: { place(of: tile) }, set: { set(tile, to: $0) })) {
                                ForEach(Place.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .labelsHidden()
                        }
                        .listRowBackground(Palette.paper)
                    }
                } footer: {
                    Text("Up to three on Today. The rest are in each child's panel: tap their row. Hiding one keeps what's already logged.")
                }
                if custom {
                    Section {
                        Button("Use the suggested tiles") {
                            custom = false
                            Haptics.selection()
                        }
                        .listRowBackground(Palette.paper)
                    } footer: {
                        Text("Suggested from the children's ages and how they feed.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("Tiles on Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .foregroundStyle(Palette.ink)
    }
}

/// The top of Today: Puggle standing on a hill under a sky that follows the
/// time of day, the date, and one plain line about the day. Your photo, top
/// right, opens the "You" sheet.
///
/// Tapping her is just for fun: a small hop. While a child sleeps she sways
/// instead, quietly. She hops once on the first open of each day, and nods
/// each time something is saved.
struct PuggleHeader: View {
    /// True while any child is asleep.
    let quiet: Bool
    /// The greeting: "Afternoon, Tom".
    let title: String
    let line: String
    let onYou: () -> Void

    @StateObject private var controller = PuggleController()
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.puggleNight) private var night
    @State private var nod: CGFloat = 0
    @State private var appeared = false
    @Environment(\.splashing) private var splashing
    @Environment(\.scenePhase) private var scenePhase
    /// How far the sky has been pulled down past the top, and the furthest this pull.
    @State private var pull: CGFloat = 0
    @State private var furthest: CGFloat = 0
    @AppStorage("puggleGreetedOn") private var greetedOn = ""
    /// The weather chosen in the Developer menu (later, the real one). Read here so she changes with it.
    @AppStorage("debugWeather") private var chosenWeather = ""
    @AppStorage(WeatherWatch.liveKey) private var liveWeather = ""
    @AppStorage(WeatherWatch.onKey) private var weatherOn = false
    private var weather: Weather { WeatherWatch.resolve(chosen: chosenWeather, live: liveWeather, on: weatherOn) }
    @State private var lift: CGFloat = 0
    @State private var tilt: Double = 0
    /// Where she has been walked to, in points from the middle. Nil until she is moved: she starts a little to one side.
    @State private var walkedTo: CGFloat?
    /// Where she is while being carried. Read only by her own view, so a drag moves her and nothing else.
    @State private var carry = Carry()
    /// True while a finger is carrying her: the scene leaves out her shadow and she draws her own.
    @State private var holding = false
    /// True for a moment after a walk, so letting go of her is not taken for a tap.
    @State private var justWalked = false
    @State private var lastTap: Date?
    /// How long after Today opens before her first bubbles. "-debugBubbles 1" brings them on at once, for checking.
    private var bubblesFirst: Double { UserDefaults.standard.string(forKey: "debugBubbles") == "1" ? 2.5 : 7 }
    /// Counts her reactions to a tap, so whoever is with her can answer.
    @State private var reactions = 0

    static let sceneHeight: CGFloat = 250

    /// Out in a thunderstorm, awake, and moving: the strikes reach her.
    private var thundery: Bool {
        weather == .storm && appeared && !quiet && !reduceMotion && PuggleScene.room(dark: scheme == .dark || night) == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            scene
            VStack(alignment: .leading, spacing: 2) {
                // The greeting, not the date: the phone already says what day it is (Tom, 15 November 2026).
                Text(title)
                    .displayFont(28)
                    .foregroundStyle(Palette.ink)
                if !line.isEmpty {
                    // One row: several lines take turns, and a long one slides along.
                    GlanceLine(lines: line.split(separator: "\n").map(String.init))
                }
            }
            .accessibilityElement(children: .combine)
        }
        // The entrance plays once the splash has gone, each time Today comes
        // back into view, and when the app is opened again.
        .onAppear {
            controller.asleep = quiet
            if !splashing { playEntrance() }
        }
        .onDisappear { appeared = false }
        .onChange(of: splashing) { _, now in if !now { playEntrance() } }
        .onChange(of: scenePhase) { old, now in
            if now == .background { appeared = false }
            if old == .background, now != .background, !splashing { playEntrance() }
        }
        // Asleep while a child sleeps; a stretch and a yawn when the last one wakes.
        .onChange(of: quiet) { _, now in
            if now { controller.asleep = true } else { controller.wake() }
        }
        // She answers each save: a nod for everyday things, more for the big ones.
        // No sound or tap: the save has its own. Nothing waits for her.
        .onChange(of: store.lastSaved?.id) { _, id in
            guard id != nil, !reduceMotion else { return }
            controller.setEnergy(night ? 0.5 : 1)
            let events = store.lastSaved?.events ?? []
            if events.contains(where: { $0.kind == .milestone }) {
                controller.celebrate()
            } else if events.contains(where: { $0.kind == .potty && $0.detail != "Accident" }) {
                controller.proud()
            } else {
                controller.nod()
            }
            // Without her rig she is one picture, so the whole picture nods.
            guard controller.rig == nil else { return }
            withAnimation(.easeOut(duration: 0.14)) { nod = quiet ? 0.5 : 1 }
            withAnimation(.spring(duration: 0.35, bounce: 0.3).delay(0.14)) { nod = 0 }
        }
        // In a thunderstorm she ducks a little just after each far-off strike, then peeks out again.
        .task(id: thundery) {
            guard thundery else { return }
            while !Task.isCancelled {
                let t = Date.now.timeIntervalSince(SceneClock.start)
                try? await Task.sleep(for: .seconds(Thunder.untilNext(after: t) + 0.2))
                guard !Task.isCancelled else { return }
                controller.rig?.feel(.shy, for: 1.4)
            }
        }
        .task {
            // Once a day, after the splash has gone.
            let today = Date.now.formatted(.iso8601.year().month().day())
            guard greetedOn != today, !quiet else { return }
            try? await Task.sleep(for: .seconds(1.8))
            greetedOn = today
            react()
        }
    }

    /// Full width, running up under the status bar.
    private var scene: some View {
        GeometryReader { geometry in
            let amount = max(0, geometry.frame(in: .named("todayScroll")).minY)
            sceneContent(width: geometry.size.width)
                .frame(width: geometry.size.width, height: Self.sceneHeight + amount)
                .offset(y: -amount)
                .onChange(of: amount) { _, now in pulled(to: now) }
        }
        .frame(height: Self.sceneHeight)
        .padding(.horizontal, -16)
    }

    /// The sky grows upwards as Today is pulled down, so Puggle stays on her hill.
    private func sceneContent(width: CGFloat) -> some View {
        let dim = scheme == .dark || night
        // After tea time she is indoors: lamplight, no coat, and pyjamas at bedtime.
        let room = PuggleScene.room(dark: dim)
        // She sits at the tea table; anywhere else she can be walked along the ground.
        let canWalk = room != .dining
        let reach = max(width / 2 - 58, 0)
        let home = room == nil ? PuggleScene.stand(for: .today) * width : 0
        let x = canWalk ? min(max(walkedTo ?? home, -reach), reach) : 0
        // In the backyard on a fine day she gets her bubble wand out now and then.
        let fine = ["none", "sun"].contains(weather.outfit(night: false))
        // Asked once here: working it out means drawing a frame of the scene.
        let isNight = PuggleScene.isNight(dark: dim)
        let canBubble = room == nil && SceneKind.today == .backyard && !isNight && fine && !quiet && !reduceMotion && appeared && !holding
        return ZStack(alignment: .bottom) {
            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x, puggleShadow: !holding)
            // Whoever is with her today stands behind her, on the same ground.
            if let company = Company.today(kind: .today, room: room,
                                           afterDark: room == nil && (isNight || Room.hourNow >= 18)) {
                // Dressed for the weather when they are out in it, as she is.
                let wearing = room == nil ? weather.outfit(night: isNight) : "none"
                CompanyView(company: company, puggleReacted: reactions, quiet: quiet, appeared: appeared, dark: dim, rain: wearing == "rain",
                            weather: room == nil ? weather : nil, night: isNight)
                    .environment(\.moonlit, room == nil && isNight)
                    .environment(\.outfit, wearing)
                    .environment(\.shades, Shades.forOutfit(wearing))
                    .offset(x: company.x * width)
                    .padding(.bottom, 26)
                    .id("\(company.member.rawValue)-\(wearing)")
            }
            CarriedPuggle(controller: controller, carry: carry, restX: x, reach: reach, canWalk: canWalk, quiet: quiet,
                          holding: $holding, justWalked: $justWalked, shadowNight: room == nil && isNight,
                          outfit: room?.outfit ?? weather.outfit(night: isNight),
                          warmLight: room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: isNight),
                          lift: lift, tilt: tilt, nod: nod, onTap: tapped, onPutDown: { walkedTo = $0; land() })
                // She pops up from behind the hill when Today first opens.
                .offset(y: appeared ? 0 : 60)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 26)
            // Her bubbles, rising from the wand in her right hand. Only while she is making them.
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !controller.makingBubbles)) { timeline in
                Bubbles(t: timeline.date.timeIntervalSince(SceneClock.start), margin: 20)
            }
            .frame(width: 98, height: 104)
            .opacity(controller.makingBubbles ? 1 : 0)
            .animation(.easeInOut(duration: 0.7), value: controller.makingBubbles)
            .offset(x: x + 62)
            .padding(.bottom, 26 + 62)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task(id: canBubble) {
                guard canBubble else { controller.bubbles(false); return }
                try? await Task.sleep(for: .seconds(bubblesFirst))
                while !Task.isCancelled {
                    controller.bubbles(true)
                    try? await Task.sleep(for: .seconds(10))
                    controller.bubbles(false)
                    try? await Task.sleep(for: .seconds(Double.random(in: 35...60)))
                }
            }
            // Out in the rain: the nearest drops in front of her, pops on her hat and shoulders, drips off her brim.
            if room == nil, !holding {
                PuggleRain(weather: weather, night: isNight, puggleX: x)
                    .opacity(appeared ? 1 : 0)
            }
            // The tea table stands in front of her.
            if let room { RoomFront(room: room, dark: dim).opacity(appeared ? 1 : 0) }
        }
        .overlay(alignment: .topTrailing) {
            YouButton(action: onYou)
                .padding(.top, 58 + pull)
                .padding(.trailing, 16)
        }
    }

    private func playEntrance() {
        guard !reduceMotion else { appeared = true; return }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { appeared = false }
        withAnimation(.spring(duration: 0.75, bounce: 0.35).delay(0.12)) { appeared = true }
    }

    /// Pulling the sky down and letting go past the balloon makes Puggle hop.
    private func pulled(to amount: CGFloat) {
        pull = amount
        // While the sky is being pulled down she walks on the spot.
        let walk = amount > 24 && !quiet
        if controller.walking != walk { controller.walking = walk }
        if amount > furthest { furthest = amount }
        if amount < 4 {
            if furthest > 120 { react() }
            furthest = 0
        }
    }

    private func tapped() {
        if justWalked { justWalked = false; return }
        // The first tap in a while takes her by surprise: she is shy for a moment, then herself.
        let first = lastTap.map { Date.now.timeIntervalSince($0) > 600 } ?? true
        lastTap = .now
        if first { controller.rig?.feel(.shy, for: 1.3) } else { react() }
        reactions += 1
    }

    /// Put down: she lands with a little squash and a wag.
    private func land() {
        Haptics.tap()
        guard !reduceMotion else { return }
        controller.rig?.play("wag")
        withAnimation(.easeOut(duration: 0.08)) { nod = quiet ? 0.5 : 1 }
        withAnimation(.spring(duration: 0.35, bounce: 0.35).delay(0.08)) { nod = 0 }
    }

    private func react() {
        // In the rain a tap is a jump in her puddle.
        if weather.outfit == "rain", let rig = controller.rig, !quiet, !reduceMotion {
            rig.play("splash")
            Haptics.tap()
            return
        }
        controller.greet()
        guard !controller.isAnimated, !reduceMotion else {
            if !quiet { Haptics.tap() }
            return
        }
        if quiet {
            // Quiet at night: a slow sway, no hop and no tap to feel.
            withAnimation(.easeInOut(duration: 0.5)) { tilt = 4 }
            withAnimation(.easeInOut(duration: 0.6).delay(0.5)) { tilt = 0 }
        } else {
            Haptics.tap()
            withAnimation(.spring(duration: 0.18, bounce: 0)) { lift = -12 }
            withAnimation(.spring(duration: 0.4, bounce: 0.45).delay(0.18)) { lift = 0 }
        }
    }
}

/// Where Puggle is while a finger carries her, and how far she swings. Watched only by `CarriedPuggle`.
@Observable final class Carry {
    var x: CGFloat?
    var start: CGFloat?
    var sway: Double = 0
    @ObservationIgnored var settle: Task<Void, Never>?
}

/// Puggle on Today. Tap her and she answers; pick her up and carry her sideways and she is lifted off the
/// ground, legs kicking, swinging a little behind the finger, then lands where she is put down. Only this
/// view follows the finger, so a drag never redraws the scene behind her.
private struct CarriedPuggle: View {
    @ObservedObject var controller: PuggleController
    let carry: Carry
    let restX: CGFloat
    let reach: CGFloat
    let canWalk: Bool
    let quiet: Bool
    @Binding var holding: Bool
    @Binding var justWalked: Bool
    let shadowNight: Bool
    let outfit: String
    let warmLight: UnitPoint?
    let lift: CGFloat
    let tilt: Double
    let nod: CGFloat
    let onTap: () -> Void
    let onPutDown: (CGFloat) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let x = carry.x ?? restX
        let up = holding && !reduceMotion
        ZStack(alignment: .bottom) {
            // Her shadow stays on the ground while she is up, smaller and fainter.
            if holding {
                Ellipse().fill(shadowNight ? Color(hex: 0x15163A).opacity(0.2) : Palette.fixedInk.opacity(0.06))
                    .frame(width: 48, height: 7)
                    .offset(y: 3.5)
                    .transition(.opacity)
            }
            Button(action: onTap) {
                PuggleView(controller: controller)
                    .environment(\.moonlit, shadowNight)
                    .environment(\.outfit, outfit)
                    .environment(\.shades, Shades.forOutfit(outfit))
                    .environment(\.warmLight, warmLight)
                    .frame(height: 118)
                    // Held up, she hangs a little longer; put down, she squashes as she lands.
                    .scaleEffect(x: up ? 0.97 : 1, y: (1 - nod * 0.06) * (up ? 1.04 : 1), anchor: .bottom)
                    .offset(y: lift + nod * 3 + (up ? -26 : 0))
                    .rotationEffect(.degrees(tilt), anchor: .bottom)
                    // She hangs from the finger, so she swings from the top.
                    .rotationEffect(.degrees(carry.sway), anchor: .top)
                    .animation(.spring(duration: 0.32, bounce: 0.25), value: up)
                    .animation(.spring(response: 0.5, dampingFraction: 0.42), value: carry.sway)
            }
            // Not dimmed while pressed: she is held for as long as she is carried, and stays herself.
            .buttonStyle(Undimmed())
            .simultaneousGesture(carrying)
        }
        .offset(x: x)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(quiet ? "Puggle, being quiet" : "Puggle")
        .accessibilityHint("Says hello")
        .accessibilityAction(named: "Walk left") { if canWalk { onPutDown(max(x - 60, -reach)) } }
        .accessibilityAction(named: "Walk right") { if canWalk { onPutDown(min(x + 60, reach)) } }
    }

    private var carrying: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { drag in
                guard canWalk, carry.start != nil || abs(drag.translation.width) > abs(drag.translation.height) else { return }
                if carry.start == nil {
                    carry.start = restX
                    justWalked = true
                    withAnimation(.easeOut(duration: 0.2)) { holding = true }
                    controller.held = true
                    Haptics.tap()
                }
                carry.x = min(max((carry.start ?? 0) + drag.translation.width, -reach), reach)
                guard !reduceMotion else { return }
                // She swings behind the finger, more the faster it goes, and back to hanging straight when it stops.
                carry.sway = Double(min(max(drag.velocity.width / 70, -14), 14))
                carry.settle?.cancel()
                carry.settle = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(90))
                    if !Task.isCancelled { carry.sway = 0 }
                }
            }
            .onEnded { _ in
                guard carry.start != nil else { return }
                let at = carry.x ?? restX
                carry.settle?.cancel()
                carry.start = nil
                carry.sway = 0
                controller.held = false
                holding = false
                onPutDown(at)
                carry.x = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { justWalked = false }
            }
    }
}

/// A button that shows no pressed look of its own.
private struct Undimmed: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.contentShape(Rectangle()) }
}

/// Your photo (or initial), top right of Today. Opens the "You" sheet.
struct YouButton: View {
    let action: () -> Void
    @AppStorage(Setting.yourName) private var yourName = ""
    @ObservedObject private var photo = YourPhoto.shared

    var body: some View {
        Button(action: action) {
            YourAvatar(size: 44)
                .overlay(Circle().stroke(Palette.paper, lineWidth: 2))
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(yourName.isEmpty ? "You and settings" : "\(yourName), and settings")
    }
}
