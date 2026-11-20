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
    /// The children's evening, for her bedtime. See `Evening`.
    var evening = Evening()
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
    /// Her eyes following the tea lamp while it swings.
    @State private var watchingLamp: Task<Void, Never>?
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
    /// Her bed as last settled, so a change of minute that changes it is noticed.
    @State private var bedNow: BedPose?
    /// Counts each entrance, and whether it is the full one or she was here a moment ago.
    @State private var entrance = 0
    @State private var fullEntrance = true
    /// Today is out of sight; everyone is hidden until they arrive again.
    @State private var away = true
    /// Today went inactive without going to the background: Control Centre, a notification, an alert.
    @State private var glancing = false
    /// When Today was last left, for how big a hello to give on coming back.
    nonisolated(unsafe) private static var leftAt: Date?

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
            bedNow = bedPose(PuggleScene.room(dark: scheme == .dark || night))
            settle(in: bedNow)
            if !splashing { playEntrance() }
        }
        // Story time, while a grown-up reads to her in bed.
        .task(id: storyTonight && appeared && !reduceMotion) {
            guard storyTonight, appeared, !reduceMotion else { StoryTime.hugging = false; return }
            await listen()
        }
        // Bedtime comes while Today is open: look again each half minute.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                let now = bedPose(PuggleScene.room(dark: scheme == .dark || night))
                if now != bedNow { bedNow = now; settle(in: now) }
            }
        }
        .onDisappear { appeared = false; away = true; Self.leftAt = .now }
        .onChange(of: splashing) { _, now in if !now { playEntrance() } }
        .onChange(of: scenePhase) { old, now in
            // Hidden as soon as Today starts to go, while it can still draw: by the time it is in the background
            // it may not draw again, and the scene as left would flash up on the way back.
            if now == .inactive, old == .active { away = true; glancing = true }
            if now == .background { appeared = false; away = true; glancing = false; Self.leftAt = .now }
            if old == .background, now != .background, !splashing { playEntrance() }
            // Only a glance at Control Centre or a notification: everyone is still there.
            if old == .inactive, now == .active, glancing { glancing = false; away = false }
        }
        // Asleep while a child sleeps; a stretch and a yawn when the last one wakes. In her bedroom, her bed decides.
        .onChange(of: quiet) { _, now in
            guard bedPose(PuggleScene.room(dark: scheme == .dark || night)) == nil else { return }
            if now { controller.asleep = true } else { controller.wake() }
        }
        .onChange(of: evening) { _, _ in
            bedNow = bedPose(PuggleScene.room(dark: scheme == .dark || night))
            settle(in: bedNow)
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
        // In bed, or at her place at the tea table, she stays put; anywhere else she can be walked along the ground.
        let bed = bedPose(room)
        let inBed = bed != nil && bed != .up
        let canWalk = room != .dining && !inBed
        let reach = max(width / 2 - 58, 0)
        let home = room == nil ? PuggleScene.stand(for: .today) * width : 0
        let x: CGFloat = switch (room, bed) {
        // Sitting up against her pillow, or tucked in with her head on it. See `RoomPainter.bedFront`.
        case (.bedroom, .reading?), (.bedroom, .stirring?): 70 - width / 2
        case (.bedroom, .asleep?): 61 - width / 2
        case (.dining, _): Company.tea().puggle * width
        default: canWalk ? min(max(walkedTo ?? home, -reach), reach) : 0
        }
        // How far down from standing: sat behind the table, sitting up in bed, or tucked in.
        let drop: CGFloat = switch (room, bed) {
        case (.bedroom, .reading?), (.bedroom, .stirring?): -51
        case (.bedroom, .asleep?): -25
        case (.dining, _): 26
        default: 0
        }
        // In the backyard on a fine day she gets her bubble wand out now and then.
        let fine = ["none", "sun"].contains(weather.outfit(night: false))
        // Asked once here: working it out means drawing a frame of the scene.
        let isNight = PuggleScene.isNight(dark: dim)
        let canBubble = room == nil && SceneKind.today == .backyard && !isNight && fine && !quiet && !reduceMotion && appeared && !holding
        return ZStack(alignment: .bottom) {
            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x, puggleShadow: !holding && !inBed)
            // Whoever is with her: today's companion behind her on the same ground, her family at the tea table,
            // or at bedtime whoever is reading to her or sleeping over.
            let gathering = Company.gathering(kind: .today, room: room, afterDark: room == nil && (isNight || Room.hourNow >= 18),
                                              bed: bed, minute: Evening.minuteNow)
            let arrive = arrival(room: room, settled: inBed || room == .dining)
            ForEach(Array(gathering.enumerated()), id: \.element.member) { order, company in
                // Dressed for the weather when they are out in it, as she is; in pyjamas on a sleepover.
                let wearing = room == nil ? weather.outfit(night: isNight) : "none"
                CompanyView(company: company, puggleReacted: reactions, quiet: quiet, appeared: appeared, dark: dim, rain: wearing == "rain",
                            weather: room == nil ? weather : nil, night: isNight,
                            entrance: entrance, arrive: arrive, edge: Self.edge(from: company.x * width, width: width, mine: company.x),
                            delay: Self.beat + Double(order) * 0.15, away: away)
                    .environment(\.moonlit, room == nil && isNight)
                    .environment(\.outfit, wearing)
                    .environment(\.shades, Shades.forOutfit(wearing))
                    // In the armchair with their legs in front of the seat, or at the tea table: sitting, so their lap shows.
                    .environment(\.seat, (company.pose == .armchair && BedroomLayout.current.legsInFront) || (company.pose == .atTable && TeaTable.current == .bare) ? "sitting" : "standing")
                    // In the armchair: as far back as the chair stands, so smaller and higher up.
                    .scaleEffect(company.pose == .armchair ? BedroomLayout.current.chairScale : 1, anchor: .bottom)
                    .offset(x: company.x * width, y: company.pose == .armchair ? BedroomLayout.current.sitterLift : 0)
                    .padding(.bottom, 26)
                    .id("\(company.member.rawValue)-\(wearing)-\(company.pose)")
            }
            CarriedPuggle(controller: controller, carry: carry, restX: x, reach: reach, canWalk: canWalk, quiet: quiet,
                          holding: $holding, justWalked: $justWalked, shadowNight: room == nil && isNight,
                          outfit: room?.outfit ?? weather.outfit(night: isNight),
                          warmLight: room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: isNight),
                          lift: lift, tilt: tilt, nod: nod, drop: drop, lying: room == .bedroom && bed == .asleep ? Self.lying : 0,
                          onTap: tapped, onPutDown: { walkedTo = $0; land() })
                // At a bare tea table she sits on her chair, her knees and feet showing under it.
                .environment(\.seat, room == .dining && TeaTable.current == .bare && !holding ? "sitting" : "standing")
                // She arrives a moment after whoever is with her, so they seem to have been waiting.
                .arrival(entrance, arrive, edge: Self.edge(from: x, width: width, awayFrom: gathering.first.map { $0.x },
                                                  mine: width > 0 ? x / width : PuggleScene.stand(for: .today)), delay: Self.beat + (gathering.isEmpty ? 0 : 0.2), away: away) { [controller] in
                    controller.walking = $0
                }
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
                    // She hums as she starts.
                    controller.rig?.air("notes", for: 3)
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
            // The tea table in front of everyone at it; at bedtime her quilt, the armchair's arms, a sleeping bag.
            if let room { RoomFront(room: room, dark: dim).opacity(appeared ? 1 : 0) }
        }
        // At tea, the lamp over the table swings when it is tapped or dragged. Not with Reduce Motion, where the
        // scene is not redrawn as time passes: there a drag on it pulls Today down like anywhere else.
        .overlay(alignment: .top) {
            if room == .dining, !reduceMotion { LampHandle(pull: pull, width: width) { watchLamp(width: width) } }
        }
        .overlay(alignment: .topTrailing) {
            YouButton(action: onYou)
                // Stays put under the clock while Today is pulled down; only the sky stretches (Tom, 20 November 2026).
                .padding(.top, 58)
                .padding(.trailing, 16)
        }
    }

    /// While the tea lamp swings, her eyes follow it from her place at the table; once it hangs still, she looks
    /// back down.
    private func watchLamp(width: CGFloat) {
        watchingLamp?.cancel()
        let mine = Double(Company.tea().puggle * width)
        watchingLamp = Task { @MainActor in
            var still = 0
            while !Task.isCancelled, still < 6 {
                let reach = Double(pull + 75)
                let across = sin(LampSwing.shared.angle) * reach - mine
                controller.look(x: min(max(across / 110, -1), 1), y: -0.8)
                still = LampSwing.shared.settled ? still + 1 : 0
                try? await Task.sleep(for: .milliseconds(100))
            }
            if !Task.isCancelled { controller.look(x: 0, y: 0) }
        }
    }

    /// Whether a grown-up is in the armchair to read her a story tonight.
    private var storyTonight: Bool {
        guard bedNow == .reading else { return false }
        return Company.gathering(kind: .today, room: .bedroom, afterDark: true, bed: .reading, minute: Evening.minuteNow)
            .contains { $0.pose == .armchair && $0.activity == .with }
    }

    /// Story time: she looks over at the grown-up reading and nods along now and then; when the book closes she
    /// hugs her rabbit and looks back. Kept to `StoryTime`'s clock, as the reader is.
    private func listen() async {
        var was: StoryTime.Part?
        var beat = 0
        controller.rig?.calmLook = true
        defer { controller.rig?.calmLook = false }
        while !Task.isCancelled {
            let part = StoryTime.part()
            if part != was {
                switch part {
                case .reading:
                    controller.look(x: 0.85, y: 0.15)
                case .hugging:
                    StoryTime.hugging = true
                    controller.rig?.play("hug")
                    controller.rig?.air("heart", for: 2.4)
                case .quiet:
                    StoryTime.hugging = false
                    controller.look(x: 0, y: 0)
                }
                was = part
            }
            if part == .reading {
                beat += 1
                // A small nod every so often, as if following along.
                if beat % 24 == 0 { controller.rig?.play("nod") }
            }
            try? await Task.sleep(for: .milliseconds(500))
        }
        StoryTime.hugging = false
    }

    /// What she is doing in her bedroom, from the children's evening. Nil anywhere else.
    private func bedPose(_ room: Room?) -> BedPose? {
        room == .bedroom ? Evening.now.pose(minute: Evening.minuteNow) : nil
    }

    /// Puts her into the pose for her bed: reading with her book, asleep, or
    /// sitting up with a stretch and a yawn when a child is seen to in the night.
    private func settle(in bed: BedPose?) {
        guard let rig = controller.rig else { return }
        rig.stop("read")
        switch bed {
        case .reading?:
            controller.asleep = false
            // With a grown-up in the armchair she is read to (see `listen()`); on her own she reads her book.
            if !storyTonight { rig.play("read") }
        case .asleep?:
            controller.asleep = true
        case .stirring?:
            controller.asleep = false
            rig.play("wake")
        default:
            controller.asleep = quiet
        }
    }

    /// How everyone arrives just now. Back within twenty minutes, she is already there. Sat at the table or in
    /// bed, they fade in where they are. Indoors they walk in; outdoors they mostly come up from behind the hill,
    /// and walk in along the ground one day in four.
    private func arrival(room: Room?, settled: Bool) -> ArrivalStyle {
        guard fullEntrance else { return .none }
        if reduceMotion || settled { return .fade }
        if room != nil { return .walk }
        #if DEBUG
        // For checking: "-debugArrive walk" or "rise".
        if let forced = UserDefaults.standard.string(forKey: "debugArrive") { return forced == "walk" ? .walk : .rise }
        #endif
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return day % 4 == 3 ? .walk : .rise
    }

    /// A moment of the empty scene before anyone arrives, while Today finishes opening.
    private static let beat = 0.2
    /// How far a sleeping head lies over on its pillow, in degrees: enough to read as lying down, little enough
    /// that a face drawn from the front still reads as a face. Puggle in bed and a friend in a sleeping bag alike.
    static let lying = -22.0

    /// From where someone stands to just past the nearer edge of the scene.
    /// With someone already there, she comes from the other side, so the two walk towards each other
    /// rather than her walking through them.
    /// Which side is decided from places on the stage (fractions of its width), so it holds while the scene is
    /// still being laid out.
    private static func edge(from x: CGFloat, width: CGFloat, awayFrom other: CGFloat? = nil, mine: CGFloat? = nil) -> CGFloat {
        let here = mine ?? (width > 0 ? x / width : 0)
        let side: CGFloat = other.map { $0 > here ? -1 : 1 } ?? (here < 0 ? -1 : 1)
        return side * (width / 2 + 70) - x
    }

    private func playEntrance() {
        let gone = Self.leftAt.map { Date.now.timeIntervalSince($0) } ?? .infinity
        fullEntrance = gone > 20 * 60
        #if DEBUG
        // Checking an entrance: play it in full every time.
        if UserDefaults.standard.string(forKey: "debugArrive") != nil { fullEntrance = true }
        #endif
        if fullEntrance, !reduceMotion {
            // Coming back to Today can keep the phone busy for a moment. The entrance starts from a task, which runs
            // only once that is over, so the walk or the rise is seen rather than played behind a frozen screen.
            Task {
                try? await Task.sleep(for: .seconds(0.2))
                entrance += 1
                // Nobody shows until their entrance has begun. See `ArrivalPose.live`.
                try? await Task.sleep(for: .seconds(Arrival.unhideAfter))
                self.away = false
            }
        } else {
            entrance += 1
            self.away = false
        }
        guard fullEntrance, !reduceMotion else {
            appeared = true
            // Back after a moment: she was here all along. A blink, and she looks up at you.
            guard !reduceMotion, controller.rig?.asleep == false else { return }
            controller.rig?.blinkAt = .now.addingTimeInterval(0.15)
            controller.look(x: 0, y: -0.6)
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                controller.look(x: 0, y: 0)
            }
            return
        }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { appeared = false }
        withAnimation(.spring(duration: 0.75, bounce: 0.35).delay(0.12)) { appeared = true }
        glanceAtCompany()
    }

    /// Once she has arrived she looks over at whoever is with her, and they answer with their hello.
    private func glanceAtCompany() {
        let room = PuggleScene.room(dark: scheme == .dark || night)
        let bed = bedPose(room)
        let first = Company.gathering(kind: .today, room: room, afterDark: room == nil && Room.hourNow >= 18,
                                      bed: bed, minute: Evening.minuteNow).first
        guard let first, room != .bedroom || bed == .reading else { return }
        let mine = room == nil ? PuggleScene.stand(for: .today) : (room == .dining ? Company.tea().puggle : 0)
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            controller.look(x: first.x < mine ? -0.8 : 0.8, y: 0)
            try? await Task.sleep(for: .seconds(1.1))
            controller.look(x: 0, y: 0)
        }
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
    /// How far down from standing: behind the tea table, or in bed.
    var drop: CGFloat = 0
    /// Asleep in bed, her head laid over on the pillow by this many degrees and her body under the quilt.
    var lying: Double = 0
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
                    // Lying down: her head goes over onto the pillow, turning at her neck, and nothing below
                    // the quilt shows, so her feet never poke out under it (Tom, 20 November 2026).
                    .rotationEffect(.degrees(lying), anchor: UnitPoint(x: 0.5, y: 0.553))
                    .mask(alignment: .top) { Rectangle().frame(width: 400, height: lying == 0 ? 1000 : 110) }
                    .offset(y: drop)
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
