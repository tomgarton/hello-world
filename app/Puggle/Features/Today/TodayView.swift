import CoreData
import SwiftUI

/// Today: the date with Puggle, every child at once, then the tiles the
/// family chose: up to three large ones and the rest as chips.
struct TodayView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.scenePhase) private var scenePhase
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)],
                  predicate: NSPredicate(format: "archived != YES")) private var allChildren: FetchedResults<Child>
    private var children: [Child] { store.onScreen(allChildren) }

    @State private var logging: EventKind?
    /// Set when logging from a child's panel, so the sheet is for that child only.
    @State private var loggingChild: Child?
    @State private var wantsLog: (kind: EventKind, child: Child)?
    @State private var showingYou = false
    @AppStorage(Setting.yourName) private var yourName = ""
    @AppStorage(Setting.justLog) private var justLog = false
    @State private var pumping = false
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var feedTimer = false
    @State private var pastFeed = false
    @State private var editing: EditTarget?
    /// An entry opened to read, from Today so far.
    @State private var looking: EditTarget?
    /// How far Today has scrolled up, for the soft edge under the clock.
    @State private var scrolledUp: CGFloat = 0
    @State private var dayOf: Child?
    @State private var addingChild = false
    /// True once this phone has ever shown a child, so an empty Today is never the cheerful first-time one again.
    @AppStorage("hadChild") private var hadChild = false
    @AppStorage(Setting.pottyStickers) private var stickersOn = true
    @State private var pendingSticker: Event?
    @State private var stickerFor: EditTarget?
    @State private var showingPlay = false
    @State private var staleSleep: Event?
    @State private var staleFeed: Event?
    @State private var askedAbout: Set<NSManagedObjectID> = []

    @State private var wantsPastSleep: Child?
    @State private var pastSleepFor: Child?
    @State private var choosingTiles = false
    @AppStorage(Setting.tilesCustom) private var tilesCustom = false
    @AppStorage(Setting.tilesMain) private var tilesMain = ""
    @AppStorage(Setting.tilesHidden) private var tilesHidden = ""

    /// Tiles that apply to at least one child, from their setup answers and age.
    private var availableTiles: [Tile] {
        Tile.all.filter { tile in
            if tile == .feeding { return children.contains { $0.uses(.bottle) || $0.uses(.breastfeed) } }
            guard let kind = tile.kind else { return true }
            return children.contains { $0.uses(kind) }
        }
    }

    private var tileLayout: TileLayout {
        tilesCustom
            ? .custom(main: tilesMain, hidden: tilesHidden, available: availableTiles)
            : .suggested(from: availableTiles)
    }

    private func tileButton(_ tile: Tile, large: Bool) -> some View {
        let who = tile == .feeding
            ? (children.filter { $0.uses(.bottle) || $0.uses(.breastfeed) }.nilIfEmpty ?? Array(children))
            : (tile.kind.map(relevant) ?? Array(children))
        return TileButton(tile: tile, children: who, large: large) { kind in
            // Breastfeeds open on the timers; a past feed is one tap from there.
            if kind == .breastfeed { feedTimer = true } else if kind == .pump { pumping = true } else { logging = kind }
        } onEdit: {
            if $0.isRunningFeed { feedTimer = true } else { editing = EditTarget(event: $0) }
        }
    }

    /// Children with a sticker chart: potty training, or with stickers already.
    private var stickerChildren: [Child] {
        children.filter { $0.pottyTraining || !store.stickers(for: $0).isEmpty }
    }

    /// The children an activity applies to; everyone if that would be nobody.
    private func relevant(_ kind: EventKind) -> [Child] {
        let some = children.filter { $0.uses(kind) }
        return some.isEmpty ? Array(children) : some
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                        .background(GeometryReader { geometry in
                            Color.clear.onChange(of: geometry.frame(in: .named("todayScroll")).minY) { _, y in
                                scrolledUp = max(-y, 0)
                            }
                        })
                    SampleBanner()
                    if children.isEmpty {
                        emptyState
                    } else {
                        let _ = markHadChild()
                        ForEach(children) { child in
                            ChildStatusRow(child: child) { dayOf = child }
                        }
                        let layout = tileLayout
                        if !store.canLog {
                            Text("You're a viewer, so you can look but not log. \(store.holderName) can change that.")
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                                .padding(.horizontal, 4)
                        } else {
                        if !layout.main.isEmpty {
                            // One tile per row at the largest text sizes, so the names fit.
                            let tiles = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
                            tiles {
                                ForEach(layout.main) { tileButton($0, large: true) }
                            }
                        }
                        // Everything else is in each child's panel.
                        let hintRow = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                                                                   : AnyLayout(HStackLayout(spacing: 6))
                        hintRow {
                            Text(layout.chips.isEmpty ? "" : "More in each child's panel: tap their name.")
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                            Spacer(minLength: 0)
                            Button("Edit") { choosingTiles = true }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.muted)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 44)
                                .accessibilityLabel("Choose the tiles on Today")
                        }
                        }
                        // One door to everything for the child: drawing, and the stamp book if there is one.
                        Button { showingPlay = true } label: {
                                HStack {
                                    Image(systemName: "scribble.variable")
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Play").fontWeight(.semibold)
                                        Text(stickersOn && !stickerChildren.isEmpty ? "Draw, and the stamp book" : "Draw and colour in")
                                            .font(.footnote)
                                            .foregroundStyle(Palette.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.muted)
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 52)
                                .foregroundStyle(Palette.ink)
                                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .accessibilityHint("Things to hand a child")
                        TodaySoFar { looking = EditTarget(event: $0) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: "todayScroll")
            .background(Palette.sand)
            // The sky runs up under the status bar; content scrolling up fades under it.
            .ignoresSafeArea(edges: .top)
            // Only once the cards reach the clock; over the sky it isn't needed.
            .overlay(alignment: .top) {
                TopScrim(strength: Double(min(max((scrolledUp - PuggleHeader.sceneHeight + 110) / 60, 0), 1)))
            }
            .toolbar(.hidden, for: .navigationBar)
            // Floats above the tab bar, so saving never moves the tile under your thumb.
            .safeAreaInset(edge: .bottom) {
                LastSavedRow { editing = EditTarget(event: $0) }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                    .animation(.spring(duration: 0.4, bounce: 0), value: store.lastSaved?.id)
                    .animation(.spring(duration: 0.4, bounce: 0), value: store.lastSaved?.events.count)
                    .animation(.spring(duration: 0.4, bounce: 0), value: store.justDeleted?.deletedAt)
            }
        }
        .sheet(item: $logging, onDismiss: {
            loggingChild = nil
            offerSticker()
        }) { kind in
            LogSheet(kind: kind, children: loggingChild.map { [$0] } ?? relevant(kind)) { events in
                // After a wee, a poo or a try, the child picks a sticker.
                if kind == .potty, stickersOn, events.count == 1,
                   let event = events.first, event.detail != "Accident" {
                    pendingSticker = event
                }
            }
        }
        .sheet(isPresented: $feedTimer, onDismiss: {
            if pastFeed {
                pastFeed = false
                logging = .breastfeed
            }
        }) {
            FeedTimerView(children: relevant(.breastfeed)) { pastFeed = true }
        }
        // Held against stray swipes home while the child has the phone.
        .protectedCover(item: $stickerFor) { target in
            StampFlowView(event: target.event)
        }
        .sheet(item: $looking) { EntryDetailView(event: $0.event) }
        .sheet(isPresented: $pumping) {
            PumpSheet()
        }
        .sheet(isPresented: $showingPlay) {
            PlayShelfView(stampChildren: stickersOn ? stickerChildren : [])
        }
        .sheet(item: $editing) { target in
            if !store.canChange(target.event) && !(target.endingSleep && store.canLog) {
                // Someone else's entry, for a helper or a viewer: to read, not to change.
                EntryDetailView(event: target.event)
            } else if target.event.kind == .pump {
                PumpSheet(editing: target.event)
            } else {
                LogSheet(kind: target.event.kind, children: Array(children), editing: target.event, endingSleep: target.endingSleep)
            }
        }
        .sheet(item: $dayOf, onDismiss: {
            // Open the next sheet once the panel has gone, so the two never overlap.
            if let child = wantsPastSleep {
                wantsPastSleep = nil
                pastSleepFor = child
            } else if let want = wantsLog {
                wantsLog = nil
                switch want.kind {
                case .pump: pumping = true
                case .breastfeed: feedTimer = true
                default:
                    loggingChild = want.child
                    logging = want.kind
                }
            }
        }) { child in
            DaySoFarView(child: child, onAddSleep: { wantsPastSleep = child }, onLog: { wantsLog = ($0, child) })
        }
        .sheet(isPresented: $showingYou) { YouView() }
        .sheet(item: $pastSleepFor) { child in
            LogSheet(kind: .sleep, children: [child])
        }
        .sheet(isPresented: $choosingTiles) {
            TileChooserView(available: availableTiles)
        }
        .sheet(isPresented: $addingChild) {
            AddChildView()
        }
        .alert("Still asleep?",
               isPresented: Binding(get: { staleSleep != nil }, set: { if !$0 { staleSleep = nil } }),
               presenting: staleSleep) { sleep in
            Button("Set wake time") { editing = EditTarget(event: sleep, endingSleep: true) }
            Button("Still asleep", role: .cancel) {}
        } message: { sleep in
            let name = sleep.sortedChildren.first?.displayName ?? "Their"
            let since = (sleep.startedAt ?? .now).formatted(.dateTime.weekday(.wide).hour().minute())
            Text("\(name)'s sleep timer has been running since \(since).")
        }
        .alert("Still feeding?",
               isPresented: Binding(get: { staleFeed != nil }, set: { if !$0 { staleFeed = nil } }),
               presenting: staleFeed) { feed in
            Button("Finish the feed") {
                if let child = feed.sortedChildren.first { store.finishFeed(for: child) }
            }
            Button("Still feeding", role: .cancel) {}
        } message: { feed in
            let name = feed.sortedChildren.first?.displayName ?? "Their"
            let since = (feed.startedAt ?? .now).formatted(date: .omitted, time: .shortened)
            Text("\(name)'s feed timer has been running since \(since).")
        }
        .onAppear(perform: checkForStaleSleep)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkForStaleSleep() }
        }
    }

    private func markHadChild() {
        guard !hadChild, !store.isSample else { return }
        DispatchQueue.main.async { hadChild = true }
    }

    /// Runs once the log sheet has gone, so the two never overlap.
    private func offerSticker() {
        guard let event = pendingSticker, event.isLive else { return }
        pendingSticker = nil
        stickerFor = EditTarget(event: event)
    }

    /// A timer left running for 14 hours gets one gentle question each time the app opens.
    /// A feed timer left running for 90 minutes gets the same kind of question.
    private func checkForStaleSleep() {
        guard store.canLog, staleSleep == nil, staleFeed == nil, editing == nil, !feedTimer else { return }
        if let sleep = store.staleSleep(among: Array(children)), !askedAbout.contains(sleep.objectID) {
            askedAbout.insert(sleep.objectID)
            staleSleep = sleep
        } else if let feed = store.staleFeed(among: Array(children)), !askedAbout.contains(feed.objectID) {
            askedAbout.insert(feed.objectID)
            staleFeed = feed
        }
    }

    private var header: some View {
        PuggleHeader(quiet: children.contains { store.activeSleep(for: $0) != nil }, line: headerLine) {
            showingYou = true
        }
    }

    /// One plain line about the day: a greeting, then what is happening, or
    /// how the night went in the morning. Nothing to do and nothing to beat.
    private var headerLine: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let greeting = switch hour {
        case 5..<12: "Morning"
        case 12..<17: "Afternoon"
        case 17..<22: "Evening"
        default: "Hello"
        }
        let name = yourName.trimmingCharacters(in: .whitespaces)
        let hello = name.isEmpty ? "\(greeting)." : "\(greeting), \(name)."
        guard !justLog, !children.isEmpty else { return hello }
        let asleep = children.filter { store.activeSleep(for: $0) != nil }.map(\.displayName)
        if !asleep.isEmpty {
            return "\(hello) \(ListFormatter.localizedString(byJoining: asleep)) \(asleep.count == 1 ? "is" : "are") asleep."
        }
        // In the morning: the longest sleep that ended today, for the first child who had one.
        if hour < 12 {
            let today = Calendar.current.startOfDay(for: .now)
            for child in children {
                let night = (child.events ?? [])
                    .filter { $0.kind == .sleep && ($0.endedAt ?? .distantPast) >= today }
                    .max { ($0.endedAt ?? .now).timeIntervalSince($0.startedAt ?? .now) < ($1.endedAt ?? .now).timeIntervalSince($1.startedAt ?? .now) }
                if let night, let start = night.startedAt, let end = night.endedAt, end.timeIntervalSince(start) >= 3 * 3600 {
                    return "\(hello) \(child.displayName) slept \(Elapsed.short(seconds: night.asleepSeconds(from: start, to: end))) last night."
                }
            }
        }
        let count = children.reduce(0) { $0 + store.events(for: $1, since: Calendar.current.startOfDay(for: .now)).count }
        return count == 0 ? hello : "\(hello) \(count) \(count == 1 ? "thing" : "things") logged today."
    }

    @ViewBuilder private var emptyState: some View {
        if hadChild || !store.isParent {
            // A family that has had a child, or someone who was invited: plain, with nothing cheerful to get wrong.
            VStack(alignment: .leading, spacing: 12) {
                Text("No children on Today")
                    .font(.title3.weight(.semibold))
                Text(store.isParent ? "A child hidden from Today is still on the Family tab, with everything logged for them."
                                    : "The family's children show here once they have arrived on this iPhone.")
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if store.isParent {
                    Button("Add a child") { addingChild = true }
                        .buttonStyle(PillButtonStyle(primary: false))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            firstChildPrompt
        }
    }

    private var firstChildPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            PuggleStanding(height: 150)
                .frame(maxWidth: .infinity)
            Text("Add a child")
                .font(.title3.weight(.semibold))
            Text("Twins, siblings, as many as you have. They share one Today.")
                .foregroundStyle(Palette.muted)
            Button("Add a child") { addingChild = true }
                .buttonStyle(PillButtonStyle())
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// One row per child: who is asleep, or what happened last. Tapping the row
/// shows their day so far; the button starts and stops their sleep.
struct ChildStatusRow: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child
    let onOpen: () -> Void
    @AppStorage(Setting.justLog) private var justLog = false
    @State private var backToSleep: Event?
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        // Ticks so the elapsed time and "5 minutes ago" stay current.
        TimelineView(.periodic(from: .now, by: 15)) { context in
            row(now: context.date)
        }
        .confirmationDialog("Back to sleep?",
                            isPresented: Binding(get: { backToSleep != nil }, set: { if !$0 { backToSleep = nil } }),
                            titleVisibility: .visible, presenting: backToSleep) { sleep in
            Button("Carry on the same sleep") { store.resumeSleep(sleep) }
            Button("Start a new sleep") { store.startSleep(for: child) }
            Button("Cancel", role: .cancel) {}
        } message: { sleep in
            let woke = (sleep.endedAt ?? .now).formatted(date: .omitted, time: .shortened)
            Text("\(child.displayName) woke at \(woke). Carry on to keep the night as one sleep.")
        }
    }

    private func row(now: Date) -> some View {
        let sleep = store.activeSleep(for: child)
        let asleep = sleep != nil
        let quiet = asleep ? Palette.moon.opacity(0.85) : Palette.muted
        // At the largest text sizes everything stacks: avatar, details, then the button.
        let big = textSize.isAccessibilitySize
        let outer = big ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 14))
        let inner = big ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 14))
        return outer {
            Button(action: onOpen) {
                inner {
                    ChildAvatar(child: child, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        if big {
                            Text(child.displayName).font(.headline)
                            Text(child.ageText).foregroundStyle(quiet)
                        } else {
                            HStack(spacing: 6) {
                                Text(child.displayName).font(.headline)
                                Text("·").foregroundStyle(quiet)
                                Text(child.ageText).foregroundStyle(quiet)
                            }
                        }
                        // Two fixed lines, what then when, so the row is the same height whatever was logged.
                        let status = statusLines(now: now, sleep: sleep)
                        ForEach(status, id: \.self) { line in
                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(quiet)
                                .monospacedDigit()
                                .lineLimit(big ? 3 : 1)
                                .minimumScaleFactor(big ? 1 : 0.7)
                                .allowsTightening(true)
                                .contentTransition(.numericText())
                        }
                        .animation(.default, value: status)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(justLog ? "Add a past sleep for \(child.displayName)" : "Shows \(child.displayName)'s day so far")
            if store.canLog { sleepButton(now: now, sleep: sleep) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .foregroundStyle(asleep ? Palette.fixedPaper : Palette.ink)
        .background(asleep ? Palette.night : Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.easeInOut(duration: 0.35), value: asleep)
    }

    /// Asleep and for how long, else the last feed, else the last entry of any kind.
    /// An empty day shows nothing: it is just an empty day.
    private func statusLines(now: Date, sleep: Event?) -> [String] {
        // "Just logging": nothing counts up, so only say that they are asleep or feeding.
        if justLog {
            if sleep != nil { return ["Asleep"] }
            return store.activeFeed(for: child) != nil ? ["Feeding"] : []
        }
        if let sleep, let start = sleep.startedAt {
            let woke = sleep.wokeText.map { " · \($0)" } ?? ""
            return ["Asleep · \(Elapsed.short(seconds: sleep.asleepSeconds(from: start, to: now)))",
                    "since \(start.formatted(date: .omitted, time: .shortened))\(woke)"]
        }
        if let feed = store.activeFeed(for: child) {
            let started = "since \((feed.startedAt ?? now).formatted(date: .omitted, time: .shortened))"
            guard let side = feed.runningSide else { return ["Feeding · paused", started] }
            return ["Feeding · \(side.lowercased()) · \(Elapsed.minutes(feed.feedSeconds(side, now: now)))", started]
        }
        // The later of the last bottle and the last breastfeed.
        let feeds = [store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)].compactMap { $0 }
        let last = feeds.max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) } ?? store.latest(for: child)
        // A regular medicine that is due takes the second line, quietly.
        let due = ReminderStore.shared.due(for: child, in: store, now: now).map { "Due · \($0)" }
            ?? store.nextDoseLine(for: child, now: now)
        guard let last, let at = last.startedAt else { return due.map { [$0] } ?? [] }
        return [last.brief, due ?? Elapsed.ago(at, now: now)]
    }

    private func sleepButton(now: Date, sleep: Event?) -> some View {
        let name = child.displayName
        let asleep = sleep != nil
        // For the first minute a stray tap can be taken back without leaving an entry.
        let justStarted = sleep?.startedAt.map { now.timeIntervalSince($0) < 60 } ?? false
        let title = !asleep ? "Start sleep" : (justStarted ? "Cancel" : "Woke up")
        let spoken = !asleep ? "Start \(name)'s sleep" : (justStarted ? "Cancel \(name)'s sleep" : "\(name) woke up")
        return Button {
            if let start = store.activeSleep(for: child)?.startedAt {
                if Date.now.timeIntervalSince(start) < 60 {
                    store.cancelSleep(for: child)
                } else {
                    store.endSleep(for: child)
                }
            } else if let last = store.recentNightSleep(for: child) {
                backToSleep = last
            } else {
                store.startSleep(for: child)
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .foregroundStyle(asleep ? Palette.fixedInk : Palette.ink)
                .glassControl(Capsule(), fallback: Palette.field, tint: asleep ? Palette.moon : nil)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spoken)
        .sensoryFeedback(trigger: asleep) { _, _ in Haptics.isOn ? .success : nil }
    }
}

/// Everything logged today, newest first, so Today shows the day as it goes.
/// Tapping an entry opens it to change.
struct TodaySoFar: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest private var events: FetchedResults<Event>
    let onOpen: (Event) -> Void
    @State private var showingAll = false

    init(onOpen: @escaping (Event) -> Void) {
        self.onOpen = onOpen
        // Begun today, or ended today: last night's sleep belongs to this morning.
        let midnight = Calendar.current.startOfDay(for: .now) as NSDate
        _events = FetchRequest(sortDescriptors: [SortDescriptor(\Event.startedAt, order: .reverse)],
                               predicate: NSPredicate(format: "startedAt >= %@ OR endedAt >= %@", midnight, midnight))
    }

    var body: some View {
        let midnight = Calendar.current.startOfDay(for: .now)
        let today = store.onScreen(events)
            .filter { !($0.kind == .pump && $0.detail == Pump.count) && ($0.listedAt ?? .distantPast) >= midnight }
            .sorted { ($0.listedAt ?? .distantPast) > ($1.listedAt ?? .distantPast) }
        let shown = showingAll ? today : Array(today.prefix(6))
        VStack(alignment: .leading, spacing: 0) {
            // The same room above and below the label (Today's own gap is 14).
            SquiggleLabel("Today so far")
                .padding(.top, 6)
                .padding(.bottom, 20)
            VStack(spacing: 0) {
                if today.isEmpty {
                    // An empty day is just an empty day: say what will appear, nothing more.
                    Text("Entries from everyone show up here.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                } else {
                    ForEach(Array(shown.enumerated()), id: \.element.objectID) { index, event in
                        if index > 0 { Divider().padding(.leading, 16 + EventRow.iconWell + EventRow.gap) }
                        SwipeableEntryRow(event: event) {
                            Button { onOpen(event) } label: { EventRow(event: event) }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .accessibilityHint("Opens this entry")
                        }
                    }
                    if today.count > 6 {
                        Divider()
                        Button(showingAll ? "Show fewer" : "Show all \(today.count)") {
                            withAnimation(.easeInOut(duration: 0.25)) { showingAll.toggle() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

/// Just saved, or just deleted: bars above the tab bar in the reverse of the
/// page's colours, so they are seen. One bar for each entry, each with its own
/// Undo, and each can be swiped away. They stay until the next save.
struct LastSavedRow: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dynamicTypeSize) private var textSize
    /// Only the Deleted bar, for screens other than Today.
    var onlyDeleted = false
    var onChange: (Event) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 8) {
            if let gone = store.justDeleted {
                // Straight after deleting: a way back, until the next save.
                bar(title: "Deleted",
                    text: gone.childNames.isEmpty ? gone.summary : "\(gone.childNames.joined(separator: ", ")): \(gone.summary)",
                    dismiss: { store.justDeleted = nil }) {
                    action("Undo") {
                        Haptics.tap()
                        store.restore(gone)
                    }
                }
                .id(gone.id)
            } else if !onlyDeleted, let saved = store.lastSaved {
                let events = saved.events.filter(\.isLive)
                ForEach(events, id: \.objectID) { event in
                    let names = ListFormatter.localizedString(byJoining: event.sortedChildren.map(\.displayName))
                    bar(title: "Last saved",
                        text: names.isEmpty ? event.summary : "\(names): \(event.summary)",
                        dismiss: { store.forget(event) }) {
                        if saved.undo != .none {
                            action("Undo") {
                                Haptics.tap()
                                store.undo(event)
                            }
                        }
                        // Room for it only when there is one bar.
                        if events.count == 1 {
                            action("Change") { onChange(event) }
                        }
                    }
                }
            }
        }
    }

    private func bar(title: String, text: String, dismiss: @escaping () -> Void,
                     @ViewBuilder buttons: () -> some View) -> some View {
        // At the largest text sizes the buttons go underneath, so the words are never squeezed out.
        let big = textSize.isAccessibilitySize
        let layout = big ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.footnote).foregroundStyle(Palette.paper.opacity(0.75))
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.paper)
                    .lineLimit(big ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            if !big { Spacer(minLength: 0) }
            HStack(spacing: 8) { buttons() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Palette.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 14, y: 5)
        .modifier(SwipeAway(perform: dismiss))
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
        .accessibilityAction(named: "Dismiss") { dismiss() }
    }

    private func action(_ title: String, perform: @escaping () -> Void) -> some View {
        Button(title, action: perform)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.paper)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Palette.paper.opacity(0.18), in: Capsule())
            .buttonStyle(PressStyle())
    }
}

/// Swipe a bar off to either side, or down, to dismiss it. Let go early and it springs back.
private struct SwipeAway: ViewModifier {
    let perform: () -> Void
    @State private var pulled = CGSize.zero
    @State private var gone = false

    func body(content: Content) -> some View {
        content
            .offset(x: pulled.width, y: max(0, pulled.height))
            .opacity(gone ? 0 : 1 - min(0.6, Double(max(abs(pulled.width), pulled.height)) / 300))
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        // Sideways or down, whichever the finger set off in.
                        if abs(value.translation.width) > abs(value.translation.height) {
                            pulled = CGSize(width: value.translation.width, height: 0)
                        } else {
                            pulled = CGSize(width: 0, height: max(0, value.translation.height))
                        }
                    }
                    .onEnded { value in
                        let across = abs(value.predictedEndTranslation.width) > 160 && pulled.width != 0
                        let down = value.predictedEndTranslation.height > 70 && pulled.height > 0
                        if across || down {
                            withAnimation(.easeOut(duration: 0.2)) {
                                gone = true
                                pulled = across ? CGSize(width: value.translation.width > 0 ? 500 : -500, height: 0)
                                                : CGSize(width: 0, height: 200)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(duration: 0.35, bounce: 0)) { perform() }
                            }
                        } else {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) { pulled = .zero }
                        }
                    }
            )
    }
}

/// A child's day so far: plain counts for today and the last 24 hours.
struct DaySoFarView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var child: Child
    /// Called when the parent chooses "Add a past sleep".
    var onAddSleep: () -> Void = {}
    /// Called with what to log for this child; Today opens it once the panel has gone.
    var onLog: (EventKind) -> Void = { _ in }
    @Environment(\.dynamicTypeSize) private var textSize
    /// Half height or full: the log buttons grow when the panel is pulled up.
    @State private var detent: PresentationDetent = .medium
    private var big: Bool { detent == .large }

    /// Everything that can be logged for this child, in the usual order.
    private var kinds: [EventKind] {
        let order: [EventKind] = [.bottle, .breastfeed, .solids, .nappy, .potty, .pump, .weight,
                                  .medicine, .temperature, .vaccination, .milestone, .note]
        return order.filter { child.uses($0) }
    }

    private var logGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: big ? 12 : 8), count: textSize.isAccessibilitySize ? 1 : (big ? 2 : 3)),
                  spacing: big ? 12 : 8) {
            ForEach(kinds) { kind in
                Button {
                    Haptics.tap()
                    onLog(kind)
                    dismiss()
                } label: {
                    VStack(spacing: 4) {
                        ActivityIcon(kind, size: big ? 44 : 28)
                        Text(kind.title).font(big ? .headline : .footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: big ? 104 : 70)
                    .foregroundStyle(Palette.ink)
                    .background(Palette.paper, in: RoundedRectangle(cornerRadius: big ? 22 : 16, style: .continuous))
                }
                .buttonStyle(PressStyle(scale: 0.96))
                .accessibilityLabel("Log \(kind.title.lowercased()) for \(child.displayName)")
            }
            Button {
                onAddSleep()
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    ActivityIcon(.sleep, size: big ? 44 : 28)
                    Text("Past sleep").font(big ? .headline : .footnote.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: big ? 104 : 70)
                .foregroundStyle(Palette.ink)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: big ? 22 : 16, style: .continuous))
            }
            .buttonStyle(PressStyle(scale: 0.96))
            .accessibilityLabel("Add a past sleep for \(child.displayName)")
        }
    }
    @AppStorage(Setting.justLog) private var justLog = false

    private struct Line: Identifiable {
        let id: String
        let today: String
        let day: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if store.canLog {
                        Text("Log for \(child.displayName)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.muted)
                        logGrid
                    }
                    if !justLog {
                        SquiggleLabel("So far")
                            .padding(.vertical, 6)
                    }
                    if justLog {
                        // "Just logging": no counts, only the way to add a sleep after the fact.
                        EmptyView()
                    } else if lines.isEmpty {
                        Text("Entries for \(child.displayName) show up here as they're logged.")
                            .foregroundStyle(Palette.muted)
                    } else {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                            GridRow {
                                Text("")
                                Text("Today").gridColumnAlignment(.trailing)
                                Text("Last 24 hours").gridColumnAlignment(.trailing)
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.muted)
                            ForEach(lines) { line in
                                Divider().gridCellColumns(3)
                                GridRow {
                                    Text(line.id).font(.body.weight(.medium))
                                    Text(line.today).monospacedDigit()
                                    Text(line.day).monospacedDigit()
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
                .padding(16)
                .foregroundStyle(Palette.ink)
            }
            .background(Palette.sand)
            .navigationTitle("\(child.displayName)'s day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: detent)
        .presentationDragIndicator(.visible)
    }

    private var lines: [Line] {
        let today = store.events(for: child, since: Calendar.current.startOfDay(for: .now))
        let day = store.events(for: child, since: Date.now.addingTimeInterval(-24 * 3600))
        var result: [Line] = []

        func add(_ title: String, _ text: ([Event]) -> String?) {
            let a = text(today), b = text(day)
            if a != nil || b != nil {
                result.append(Line(id: title, today: a ?? "–", day: b ?? "–"))
            }
        }
        func count(_ kind: EventKind) -> ([Event]) -> String? {
            { events in
                let n = events.filter { $0.kind == kind }.count
                return n > 0 ? "\(n)" : nil
            }
        }

        add("Bottles") { events in
            let bottles = events.filter { $0.kind == .bottle }
            guard !bottles.isEmpty else { return nil }
            let ml = Int(bottles.reduce(0) { $0 + $1.amountML })
            return ml > 0 ? "\(bottles.count), \(Units.volume(Double(ml)))" : "\(bottles.count)"
        }
        add("Breastfeeds", count(.breastfeed))
        add("Solids", count(.solids))
        // Sleep counts the part of each sleep that falls inside the window, so a
        // night that began yesterday still shows in today's total.
        let sleeps = (child.events ?? []).filter { $0.kind == .sleep }
        func slept(since: Date) -> String? {
            var seconds = 0.0
            for sleep in sleeps {
                guard let start = sleep.startedAt else { continue }
                seconds += sleep.asleepSeconds(from: max(start, since), to: sleep.endedAt ?? .now)
            }
            return seconds >= 60 ? Elapsed.short(from: Date.now.addingTimeInterval(-seconds), to: .now) : nil
        }
        let sleptToday = slept(since: Calendar.current.startOfDay(for: .now))
        let sleptDay = slept(since: Date.now.addingTimeInterval(-24 * 3600))
        if sleptToday != nil || sleptDay != nil {
            result.append(Line(id: "Sleep", today: sleptToday ?? "–", day: sleptDay ?? "–"))
        }
        add(Terms.nappies, count(.nappy))
        add("Potty", count(.potty))
        add("Medicine", count(.medicine))
        return result
    }
}

extension Array {
    var nilIfEmpty: [Element]? { isEmpty ? nil : self }
}
