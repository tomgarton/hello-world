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
                        Button { onAdd(kind) } label: { Label(kind.title, systemImage: kind.symbol) }
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
                ActivityIcon(named: tile.iconName, size: 40)
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
                ActivityIcon(named: tile.iconName, size: 40)
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
    @State private var walkStart: CGFloat?
    /// True for a moment after a walk, so letting go of her is not taken for a tap.
    @State private var justWalked = false
    @State private var lastTap: Date?
    /// Counts her reactions to a tap, so whoever is with her can answer.
    @State private var reactions = 0

    static let sceneHeight: CGFloat = 250

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            scene
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .displayFont(28)
                    .foregroundStyle(Palette.ink)
                if !line.isEmpty {
                    Text(line)
                        .font(.body)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
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
        return ZStack(alignment: .bottom) {
            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x)
            // Whoever is with her today stands behind her, on the same ground.
            if let company = Company.today(kind: .today, room: room,
                                           afterDark: room == nil && (PuggleScene.isNight(dark: dim) || Room.hourNow >= 18)) {
                // Dressed for the weather when they are out in it, as she is.
                let wearing = room == nil ? weather.outfit(night: PuggleScene.isNight(dark: dim)) : "none"
                CompanyView(company: company, puggleReacted: reactions, quiet: quiet, appeared: appeared, dark: dim, rain: wearing == "rain")
                    .environment(\.moonlit, room == nil && PuggleScene.isNight(dark: dim))
                    .environment(\.outfit, wearing)
                    .offset(x: company.x * width)
                    .padding(.bottom, 26)
                    .id("\(company.member.rawValue)-\(wearing)")
            }
            Button {
                if justWalked { justWalked = false } else {
                    // The first tap in a while takes her by surprise: she is shy for a moment, then herself.
                    let first = lastTap.map { Date.now.timeIntervalSince($0) > 600 } ?? true
                    lastTap = .now
                    if first { controller.rig?.feel(.shy, for: 1.3) } else { react() }
                    reactions += 1
                }
            } label: {
                PuggleView(controller: controller)
                    .environment(\.moonlit, room == nil && PuggleScene.isNight(dark: dim))
                    .environment(\.outfit, room?.outfit ?? weather.outfit(night: PuggleScene.isNight(dark: dim)))
                    .environment(\.warmLight, room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: PuggleScene.isNight(dark: dim)))
                    .frame(height: 118)
                    .scaleEffect(x: 1, y: 1 - nod * 0.06, anchor: .bottom)
                    .offset(y: lift + nod * 3)
                    .rotationEffect(.degrees(tilt), anchor: .bottom)
            }
            .buttonStyle(.plain)
            // Drag her sideways and she walks there, and stays.
            .simultaneousGesture(DragGesture(minimumDistance: 12)
                .onChanged { drag in
                    guard canWalk, walkStart != nil || abs(drag.translation.width) > abs(drag.translation.height) else { return }
                    if walkStart == nil { walkStart = x }
                    justWalked = true
                    walkedTo = min(max((walkStart ?? 0) + drag.translation.width, -reach), reach)
                    if !quiet && !reduceMotion { controller.walking = true }
                }
                .onEnded { _ in
                    guard walkStart != nil else { return }
                    walkStart = nil
                    controller.walking = false
                    Haptics.tap()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { justWalked = false }
                })
            .offset(x: x)
            // She pops up from behind the hill when Today first opens.
            .offset(y: appeared ? 0 : 60)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 26)
            .accessibilityLabel(quiet ? "Puggle, being quiet" : "Puggle")
            .accessibilityHint("Says hello")
            .accessibilityAction(named: "Walk left") { if canWalk { walkedTo = max(x - 60, -reach) } }
            .accessibilityAction(named: "Walk right") { if canWalk { walkedTo = min(x + 60, reach) } }
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
        controller.walking = amount > 24 && !quiet
        if amount > furthest { furthest = amount }
        if amount < 4 {
            if furthest > 120 { react() }
            furthest = 0
        }
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
