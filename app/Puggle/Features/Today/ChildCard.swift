import CoreData
import SwiftUI

/// How Today is laid out. "Children first" is the default (Tom, 15 November 2026): each child's card carries
/// their three facts and their other actions. "Shared tiles" is the earlier Today, kept as a choice.
enum TodayLayout: String, CaseIterable, Identifiable {
    case children, tiles
    var id: String { rawValue }
    var title: String { self == .children ? "Children first" : "Shared tiles" }
}

/// One of the three things asked most about a child: when they last fed, how long they have been awake or
/// asleep, and their last nappy or potty. Each is a button that logs the next one for that child.
struct ChildFact: Identifiable, Equatable {
    enum Kind: String { case fed, ate, awake, asleep, nappy, potty }
    let kind: Kind
    /// "1h 29m", or nil when there is nothing to count from.
    let value: String?

    var id: String { kind.rawValue }

    var label: String {
        switch kind {
        case .fed: "Fed"
        case .ate: "Ate"
        case .awake: "Awake"
        case .asleep: "Asleep"
        case .nappy: Terms.nappy
        case .potty: "Potty"
        }
    }

    /// The icon beside the label, from the app's own set.
    var icon: String {
        switch kind {
        case .fed: EventKind.bottle.iconName
        case .ate: EventKind.solids.iconName
        case .awake, .asleep: EventKind.sleep.iconName
        case .nappy: EventKind.nappy.iconName
        case .potty: EventKind.potty.iconName
        }
    }

    /// Which three facts a child has. A baby: fed, awake, nappy. An older child: awake, ate, and the potty or
    /// the nappy, whichever they use. Whether a child is "a baby" here follows milk: one who has had a bottle
    /// or a breastfeed in the last two days, or is under a year old and takes either.
    static func kinds(milk: Bool, potty: Bool, asleep: Bool) -> [Kind] {
        let sleep: Kind = asleep ? .asleep : .awake
        let last: Kind = potty ? .potty : .nappy
        return milk ? [.fed, sleep, last] : [sleep, .ate, last]
    }

    /// Whether the sleep button belongs on a child's card: while they are asleep, in the evening and at night,
    /// for a child who naps (a daytime sleep in the last two weeks), and for the very young, who nap whether
    /// or not anyone has logged it yet.
    static func offersSleep(asleep: Bool, hour: Int, napped: Bool, months: Int) -> Bool {
        asleep || hour >= 17 || hour < 7 || napped || months < 18
    }
}

extension FamilyStore {
    /// The three facts for a child's card.
    func facts(for child: Child, now: Date = .now, counting: Bool = true) -> [ChildFact] {
        let sleep = activeSleep(for: child)
        let feeds = [latest(.bottle, for: child), latest(.breastfeed, for: child)].compactMap { $0?.startedAt }
        let lastFeed = feeds.max()
        let takesMilk = child.uses(.bottle) || child.uses(.breastfeed)
        let milk = takesMilk && (child.ageMonths < 12 || (lastFeed.map { now.timeIntervalSince($0) < 2 * 86400 } ?? false))
        // The potty for a child who is training; the nappy for everyone else.
        let potty = child.pottyTraining && child.uses(.potty)
        func since(_ date: Date?) -> String? {
            guard counting, let date else { return nil }
            return Elapsed.short(seconds: max(now.timeIntervalSince(date), 0))
        }
        return ChildFact.kinds(milk: milk, potty: potty, asleep: sleep != nil).map { kind in
            switch kind {
            case .fed: ChildFact(kind: kind, value: since(lastFeed))
            case .ate: ChildFact(kind: kind, value: since(latest(.solids, for: child)?.startedAt))
            case .awake: ChildFact(kind: kind, value: since(lastWoke(for: child)))
            case .asleep:
                ChildFact(kind: kind, value: counting ? sleep.flatMap { event in
                    event.startedAt.map { Elapsed.short(seconds: event.asleepSeconds(from: $0, to: now)) }
                } : nil)
            case .nappy: ChildFact(kind: kind, value: since(latest(.nappy, for: child)?.startedAt))
            case .potty: ChildFact(kind: kind, value: since(latest(.potty, for: child)?.startedAt))
            }
        }
    }
}

/// A child's card on Today, children first: who they are, the sleep button if they nap, their three facts as
/// buttons, one line for what comes next, and a plus that opens the rest of their actions in place.
struct ChildCard: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child
    /// Whether this child's other actions are showing inside the card.
    let open: Bool
    /// With one child there is no plus: their actions sit open under the card.
    let hasPlus: Bool
    let onOpenDay: () -> Void
    let onToggle: () -> Void
    /// Log this for this child.
    let onLog: (EventKind) -> Void
    let onPastSleep: () -> Void
    /// Open a running timer or the last entry to change it.
    let onEdit: (EditTarget) -> Void
    @AppStorage(Setting.justLog) private var justLog = false
    @State private var backToSleep: Event?
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        // Ticks so the facts stay current.
        TimelineView(.periodic(from: .now, by: 15)) { context in
            card(now: context.date)
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

    private func card(now: Date) -> some View {
        let sleep = store.activeSleep(for: child)
        let asleep = sleep != nil
        let quiet = asleep ? Palette.moon.opacity(0.85) : Palette.muted
        let big = textSize.isAccessibilitySize
        let facts = store.facts(for: child, now: now, counting: !justLog)
        let showsSleep = store.canLog && ChildFact.offersSleep(asleep: asleep, hour: Room.hourNow, napped: store.lastNap(for: child, now: now) != nil, months: child.ageMonths)
        return VStack(alignment: .leading, spacing: 10) {
            let top = big ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 8))
            top {
                Button(action: onOpenDay) {
                    HStack(spacing: 10) {
                        ChildAvatar(child: child, size: 40)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 6) {
                                Text(child.displayName).font(.headline)
                                Text("·").foregroundStyle(quiet)
                                Text(child.ageText).foregroundStyle(quiet)
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text(child.displayName).font(.headline)
                                Text(child.ageText).font(.subheadline).foregroundStyle(quiet)
                            }
                        }
                        .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Shows \(child.displayName)'s day so far")
                if showsSleep { sleepButton(now: now, sleep: sleep) }
                if hasPlus && store.canLog { plus(asleep: asleep) }
            }
            let row = big ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
            row {
                ForEach(facts) { fact in factButton(fact, sleep: sleep, asleep: asleep, quiet: quiet) }
            }
            if let line = underLine(now: now, asleep: asleep) {
                Text(line)
                    .font(.footnote)
                    .foregroundStyle(quiet)
                    .monospacedDigit()
                    .padding(.horizontal, 2)
            }
            // Milk from bottles today, beside what the tin suggests. Only once there has been a bottle.
            if !justLog, let milk = MilkDay(child: child, store: store, now: now)?.line {
                Text(milk)
                    .font(.footnote)
                    .foregroundStyle(quiet)
                    .monospacedDigit()
                    .padding(.horizontal, 2)
            }
            if open && store.canLog {
                ChildActions(child: child, facts: facts.map(\.kind), inside: true, asleep: asleep, onLog: onLog, onPastSleep: onPastSleep)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .foregroundStyle(asleep ? Palette.fixedPaper : Palette.ink)
        .background(asleep ? Palette.night : Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.easeInOut(duration: 0.35), value: asleep)
    }

    /// A medicine that is due comes first; then what comes next, until its time has passed.
    private func underLine(now: Date, asleep: Bool) -> String? {
        if let due = ReminderStore.shared.due(for: child, in: store, now: now).map({ "Due · \($0)" }) ?? store.nextDoseLine(for: child, now: now) {
            return due
        }
        if let feed = store.activeFeed(for: child) {
            guard !justLog else { return "Feeding" }
            guard let side = feed.runningSide else { return "Feeding · Paused" }
            return "Feeding · \(side) · \(Elapsed.minutes(feed.feedSeconds(side, now: now)))"
        }
        guard !justLog, !asleep, let next = NextUp.soonest(for: child, now: now), next.at > now else { return nil }
        return next.line
    }

    private func factButton(_ fact: ChildFact, sleep: Event?, asleep: Bool, quiet: Color) -> some View {
        let box = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let face = VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(fact.icon + "-plain")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .accessibilityHidden(true)
                Text(fact.label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(quiet)
            // "Just logging" counts nothing, so the box is only the way in.
            if !justLog {
                Text(fact.value ?? "–")
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(asleep ? Color.white.opacity(0.12) : Palette.field, in: box)
        .contentShape(box)
        // Both kinds of milk: the fact asks which.
        let feeds = [EventKind.bottle, .breastfeed].filter { child.uses($0) }
        return Group {
            if !store.canLog {
                face
            } else if fact.kind == .fed, feeds.count > 1, store.activeFeed(for: child) == nil {
                Menu {
                    ForEach(feeds) { kind in
                        Button { onLog(kind) } label: { Label { Text(kind.title) } icon: { Image(kind.iconName + "-plain") } }
                    }
                } label: { face }
            } else {
                Button {
                    Haptics.tap()
                    tapped(fact, sleep: sleep, feeds: feeds)
                } label: { face }
                .buttonStyle(PressStyle(scale: 0.96))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(fact))
        .accessibilityHint(store.canLog ? hint(fact) : "")
    }

    private func tapped(_ fact: ChildFact, sleep: Event?, feeds: [EventKind]) {
        switch fact.kind {
        case .fed: onLog(store.activeFeed(for: child) != nil ? .breastfeed : (feeds.first ?? .bottle))
        case .ate: onLog(.solids)
        case .nappy: onLog(.nappy)
        case .potty: onLog(.potty)
        case .awake: onPastSleep()
        case .asleep: if let sleep { onEdit(EditTarget(event: sleep, endingSleep: true)) }
        }
    }

    private func spoken(_ fact: ChildFact) -> String {
        let name = child.displayName
        guard let value = fact.value else { return "\(name), \(fact.label.lowercased())" }
        return switch fact.kind {
        case .fed: "\(name) fed \(value) ago"
        case .ate: "\(name) ate \(value) ago"
        case .awake: "\(name) has been awake \(value)"
        case .asleep: "\(name) has been asleep \(value)"
        case .nappy: "\(name)'s last \(Terms.nappyLower) was \(value) ago"
        case .potty: "\(name)'s last potty was \(value) ago"
        }
    }

    private func hint(_ fact: ChildFact) -> String {
        switch fact.kind {
        case .fed: "Logs a feed"
        case .ate: "Logs a meal"
        case .awake: "Adds a sleep"
        case .asleep: "Sets when they woke"
        case .nappy: "Logs a \(Terms.nappyLower)"
        case .potty: "Logs the potty"
        }
    }

    private func plus(asleep: Bool) -> some View {
        Button {
            Haptics.tap()
            onToggle()
        } label: {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
                .rotationEffect(.degrees(open ? 45 : 0))
                .frame(width: 44, height: 44)
                .foregroundStyle(asleep ? Palette.fixedPaper : Palette.ink)
                .background(asleep ? Color.white.opacity(0.12) : Palette.field, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(open ? "Close \(child.displayName)'s other actions" : "More to log for \(child.displayName)")
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
            HStack(spacing: 6) {
                DrawnSymbol(name: !asleep ? "moon" : (justStarted ? "arrow.uturn.backward" : "sun.max"))
                    .accessibilityHidden(true)
                Text(title)
            }
            .animation(.default, value: title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .foregroundStyle(asleep ? Palette.fixedInk : Palette.ink)
            .glassControl(Capsule(), fallback: Palette.field, tint: asleep ? Palette.moon : nil)
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(spoken)
        .sensoryFeedback(trigger: asleep) { _, _ in Haptics.isOn ? .success : nil }
    }
}

/// Everything else that can be logged for one child: inside their card when the plus is open, or under the
/// card as larger tiles when they are the only child.
struct ChildActions: View {
    @ObservedObject var child: Child
    /// The facts on the card, which already log their own kind.
    let facts: [ChildFact.Kind]
    /// Inside a card: four across and small. Under a lone child's card: three across, as tiles.
    let inside: Bool
    var asleep = false
    let onLog: (EventKind) -> Void
    let onPastSleep: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    /// What the card's facts leave out, in the usual order.
    static func kinds(for child: Child, facts: [ChildFact.Kind]) -> [EventKind] {
        let order: [EventKind] = [.bottle, .breastfeed, .solids, .nappy, .potty, .pump, .weight,
                                  .medicine, .temperature, .vaccination, .milestone, .care, .note]
        var covered: Set<EventKind> = []
        if facts.contains(.fed) { covered.formUnion([.bottle, .breastfeed]) }
        if facts.contains(.ate) { covered.insert(.solids) }
        if facts.contains(.nappy) { covered.insert(.nappy) }
        if facts.contains(.potty) { covered.insert(.potty) }
        return order.filter { child.uses($0) && !covered.contains($0) }
    }

    var body: some View {
        let columns = textSize.isAccessibilitySize ? 1 : (inside ? 4 : 3)
        let shape = RoundedRectangle(cornerRadius: inside ? 14 : 22, style: .continuous)
        let ground = inside ? (asleep ? Color.white.opacity(0.12) : Palette.field) : Palette.card
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(Self.kinds(for: child, facts: facts)) { kind in
                Button {
                    Haptics.tap()
                    onLog(kind)
                } label: {
                    face(kind.title, shape: shape, ground: ground) { icon(kind) }
                }
                .buttonStyle(PressStyle(scale: 0.96))
                .accessibilityLabel("Log \(kind.title.lowercased()) for \(child.displayName)")
            }
            Button {
                Haptics.tap()
                onPastSleep()
            } label: {
                face("Past sleep", shape: shape, ground: ground) { icon(.sleep) }
            }
            .buttonStyle(PressStyle(scale: 0.96))
            .accessibilityLabel("Add a past sleep for \(child.displayName)")
        }
        .environment(\.iconChildColour, Palette.childColour(child.colourIndex))
    }

    /// A sleeping child's card is in night colours whatever the phone's appearance, so the icons on it take
    /// their dark drawing: a pale line. In light they were drawn in dark ink on the dark card (Tom, 16 November 2026).
    @Environment(\.colorScheme) private var scheme

    private func icon(_ kind: EventKind) -> some View {
        ActivityIcon(kind, size: inside ? 24 : 40)
            .environment(\.colorScheme, asleep && inside ? .dark : scheme)
    }

    private func face(_ title: String, shape: RoundedRectangle, ground: Color, @ViewBuilder icon: () -> some View) -> some View {
        VStack(spacing: 4) {
            icon()
            Text(title)
                .font(inside ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, minHeight: inside ? 64 : 92)
        .foregroundStyle(asleep && inside ? Palette.fixedPaper : Palette.ink)
        .background(ground, in: shape)
        .contentShape(shape)
    }
}
