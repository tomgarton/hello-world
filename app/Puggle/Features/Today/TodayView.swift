import CoreData
import SwiftUI

/// Today: every child at once, then a card per activity showing the latest
/// entry for each child. Tapping + opens the log sheet for that activity;
/// tapping an entry opens it to change.
struct TodayView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.scenePhase) private var scenePhase
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)],
                  predicate: NSPredicate(format: "archived != YES")) private var children: FetchedResults<Child>

    @State private var logging: EventKind?
    @State private var feedTimer = false
    @State private var pastFeed = false
    @State private var editing: EditTarget?
    @State private var dayOf: Child?
    @State private var addingChild = false
    @AppStorage("pottyStickers") private var stickersOn = true
    @State private var pendingSticker: Event?
    @State private var stickerFor: EditTarget?
    @State private var showingStickers = false
    @State private var staleSleep: Event?
    @State private var askedAbout: Set<NSManagedObjectID> = []

    private let cardKinds: [EventKind] = [.bottle, .breastfeed, .sleep, .nappy, .potty, .solids, .weight]

    /// Tiles follow each child's setup answers and age.
    private var visibleKinds: [EventKind] {
        cardKinds.filter { kind in children.contains { $0.uses(kind) } }
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
                    if children.isEmpty {
                        emptyState
                    } else {
                        ForEach(children) { child in
                            ChildStatusRow(child: child) { dayOf = child }
                        }
                        LastSavedRow { editing = EditTarget(event: $0) }
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(visibleKinds) { kind in
                                ActivityCard(kind: kind, children: relevant(kind)) {
                                    // Breastfeeds open on the timers; a past feed is one tap from there.
                                    if kind == .breastfeed { feedTimer = true } else { logging = kind }
                                } onEdit: {
                                    if $0.isRunningFeed { feedTimer = true } else { editing = EditTarget(event: $0) }
                                }
                            }
                            HealthCard(children: Array(children)) {
                                logging = $0
                            } onEdit: {
                                editing = EditTarget(event: $0)
                            }
                        }
                        if stickersOn, !stickerChildren.isEmpty {
                            Button { showingStickers = true } label: {
                                HStack {
                                    Image(systemName: "star.circle")
                                    Text("Sticker chart").fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.muted)
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 52)
                                .foregroundStyle(Palette.ink)
                                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Palette.sand)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $logging, onDismiss: offerSticker) { kind in
            LogSheet(kind: kind, children: relevant(kind)) { events in
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
        .fullScreenCover(item: $stickerFor) { target in
            StickerPickerView(event: target.event)
        }
        .sheet(isPresented: $showingStickers) {
            StickerChartView(children: stickerChildren)
        }
        .sheet(item: $editing) { target in
            LogSheet(kind: target.event.kind, children: Array(children), editing: target.event, endingSleep: target.endingSleep)
        }
        .sheet(item: $dayOf) { child in
            DaySoFarView(child: child)
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
        .onAppear(perform: checkForStaleSleep)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkForStaleSleep() }
        }
    }

    /// Runs once the log sheet has gone, so the two never overlap.
    private func offerSticker() {
        guard let event = pendingSticker, event.isLive else { return }
        pendingSticker = nil
        stickerFor = EditTarget(event: event)
    }

    /// A timer left running for 14 hours gets one gentle question each time the app opens.
    private func checkForStaleSleep() {
        guard staleSleep == nil, editing == nil,
              let sleep = store.staleSleep(among: Array(children)),
              !askedAbout.contains(sleep.objectID) else { return }
        askedAbout.insert(sleep.objectID)
        staleSleep = sleep
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
            Text(children.isEmpty ? "Today" : ListFormatter.localizedString(byJoining: children.map(\.displayName)))
                .font(.display(32))
                .foregroundStyle(Palette.ink)
        }
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your little ones")
                .font(.title3.weight(.semibold))
            Text("Twins, siblings, as many as you have. Everyone in the family sees the same day.")
                .foregroundStyle(Palette.muted)
            Button("Add a child") { addingChild = true }
                .buttonStyle(PillButtonStyle())
        }
        .padding(18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// One row per child: who is asleep, or what happened last. Tapping the row
/// shows their day so far; the button starts and stops their sleep.
struct ChildStatusRow: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child
    let onOpen: () -> Void

    var body: some View {
        // Ticks so the elapsed time and "5 minutes ago" stay current.
        TimelineView(.periodic(from: .now, by: 15)) { context in
            row(now: context.date)
        }
    }

    private func row(now: Date) -> some View {
        let sleep = store.activeSleep(for: child)
        let asleep = sleep != nil
        let quiet = asleep ? Palette.moon.opacity(0.85) : Palette.muted
        return HStack(spacing: 14) {
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    ChildAvatar(child: child, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(child.displayName).font(.headline)
                            Text(child.ageText).foregroundStyle(quiet)
                        }
                        if let line = statusLine(now: now, sleep: sleep) {
                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(quiet)
                                .monospacedDigit()
                                .multilineTextAlignment(.leading)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Shows \(child.displayName)'s day so far")
            sleepButton(now: now, sleep: sleep)
        }
        .padding(14)
        .foregroundStyle(asleep ? Palette.fixedPaper : Palette.ink)
        .background(asleep ? Palette.night : Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// Asleep and for how long, else the last feed, else the last entry of any kind.
    /// An empty day shows nothing: it is just an empty day.
    private func statusLine(now: Date, sleep: Event?) -> String? {
        if let start = sleep?.startedAt {
            return "Asleep \(Elapsed.short(from: start, to: now))"
        }
        if let feed = store.activeFeed(for: child) {
            guard let side = feed.runningSide else { return "Feeding, paused" }
            return "Feeding, \(side.lowercased()) \(Elapsed.minutes(feed.feedSeconds(side, now: now)))"
        }
        let last = store.latest(.bottle, for: child) ?? store.latest(.breastfeed, for: child) ?? store.latest(for: child)
        guard let last, let at = last.startedAt else { return nil }
        return "\(last.summary), \(at.formatted(.relative(presentation: .named)))"
    }

    private func sleepButton(now: Date, sleep: Event?) -> some View {
        let name = child.displayName
        let asleep = sleep != nil
        // For the first minute a stray tap can be taken back without leaving an entry.
        let justStarted = sleep?.startedAt.map { now.timeIntervalSince($0) < 60 } ?? false
        let title = !asleep ? "Start sleep" : (justStarted ? "Cancel" : "Woke up")
        let spoken = !asleep ? "Start \(name)'s sleep" : (justStarted ? "Cancel \(name)'s sleep" : "\(name) woke up")
        return Button(title) {
            if let start = store.activeSleep(for: child)?.startedAt {
                if Date.now.timeIntervalSince(start) < 60 {
                    store.cancelSleep(for: child)
                } else {
                    store.endSleep(for: child)
                }
            } else {
                store.startSleep(for: child)
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(asleep ? Palette.moon : Palette.field, in: Capsule())
        .foregroundStyle(asleep ? Palette.fixedInk : Palette.ink)
        .accessibilityLabel(spoken)
        .sensoryFeedback(.success, trigger: asleep)
    }
}

/// "Last saved" stays on Today until the next save, with a way back.
struct LastSavedRow: View {
    @EnvironmentObject private var store: FamilyStore
    let onChange: (Event) -> Void

    var body: some View {
        if let saved = store.lastSaved {
            let events = saved.events.filter(\.isLive)
            if let first = events.first {
                let names = ListFormatter.localizedString(byJoining: events.flatMap(\.sortedChildren).map(\.displayName))
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last saved")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                        Text("\(names): \(first.summary)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.ink)
                    }
                    .accessibilityElement(children: .combine)
                    Spacer(minLength: 0)
                    if saved.undo != .none {
                        action("Undo") { store.undoLastSaved() }
                    }
                    if events.count == 1 {
                        action("Change") { onChange(first) }
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 8)
                .padding(.vertical, 6)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func action(_ title: String, perform: @escaping () -> Void) -> some View {
        Button(title, action: perform)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Palette.field, in: Capsule())
    }
}

/// A card per activity, listing the latest entry for each child.
struct ActivityCard: View {
    @EnvironmentObject private var store: FamilyStore
    let kind: EventKind
    let children: [Child]
    let onAdd: () -> Void
    let onEdit: (Event) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Palette.paper, in: Circle())
                }
                .foregroundStyle(Palette.ink)
                .accessibilityLabel("Log \(kind.title.lowercased())")
            }
            Text(kind.title).font(.title3.weight(.semibold))
            ForEach(children) { child in
                if let event = store.latest(kind, for: child), let at = event.startedAt {
                    Button { onEdit(event) } label: {
                        HStack(spacing: 6) {
                            ChildChip(child: child)
                            Text(at, style: .time).font(.footnote).foregroundStyle(Palette.muted)
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(child.displayName), \(event.summary), \(at.formatted(date: .omitted, time: .shortened))")
                    .accessibilityHint("Opens this entry to change it")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// One tile for medicine, temperature and vaccinations. Logged plainly:
/// no colour, no "high", no alarm.
struct HealthCard: View {
    @EnvironmentObject private var store: FamilyStore
    let children: [Child]
    let onAdd: (EventKind) -> Void
    let onEdit: (Event) -> Void

    private func latest(for child: Child) -> Event? {
        (child.events ?? [])
            .filter { $0.kind.isHealth }
            .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "cross.case")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Menu {
                    ForEach(EventKind.health) { kind in
                        Button { onAdd(kind) } label: { Label(kind.title, systemImage: kind.symbol) }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Palette.paper, in: Circle())
                }
                .foregroundStyle(Palette.ink)
                .accessibilityLabel("Log health")
            }
            Text("Health").font(.title3.weight(.semibold))
            ForEach(children) { child in
                if let event = latest(for: child), let at = event.startedAt {
                    Button { onEdit(event) } label: {
                        HStack(spacing: 6) {
                            ChildChip(child: child)
                            Text(at, style: .time).font(.footnote).foregroundStyle(Palette.muted)
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(child.displayName), \(event.summary), \(at.formatted(date: .omitted, time: .shortened))")
                    .accessibilityHint("Opens this entry to change it")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// A child's day so far: plain counts for today and the last 24 hours.
struct DaySoFarView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var child: Child

    private struct Line: Identifiable {
        let id: String
        let today: String
        let day: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if lines.isEmpty {
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
                .padding(18)
                .foregroundStyle(Palette.ink)
            }
            .background(Palette.sand)
            .navigationTitle("\(child.displayName)'s day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
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
            return ml > 0 ? "\(bottles.count), \(ml) ml" : "\(bottles.count)"
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
                let end = sleep.endedAt ?? .now
                seconds += max(end.timeIntervalSince(max(start, since)), 0)
            }
            return seconds >= 60 ? Elapsed.short(from: Date.now.addingTimeInterval(-seconds), to: .now) : nil
        }
        let sleptToday = slept(since: Calendar.current.startOfDay(for: .now))
        let sleptDay = slept(since: Date.now.addingTimeInterval(-24 * 3600))
        if sleptToday != nil || sleptDay != nil {
            result.append(Line(id: "Sleep", today: sleptToday ?? "–", day: sleptDay ?? "–"))
        }
        add("Nappies", count(.nappy))
        add("Potty", count(.potty))
        add("Medicine", count(.medicine))
        return result
    }
}
