import ActivityKit
import CoreData
import Foundation

/// Keeps the Lock Screen and Dynamic Island in step with the data: one Live
/// Activity per child, showing a running feed, a running sleep, or otherwise
/// how long since the last feed and since they woke.
/// It compares what should be showing with what is, so it is safe to call often.
@MainActor
final class LiveTimers {
    static let shared = LiveTimers()

    /// How long the "since" card stays after the last feed or wake.
    private let glanceHours = 8.0

    private var syncing = false
    private var again = false

    struct Wanted {
        let attributes: TimerAttributes
        let state: TimerAttributes.ContentState
    }

    func sync(with store: FamilyStore) {
        #if DEBUG
        // For checking the cards with the sample family: "-debugLive glance", "sleep", "feed" or "paused".
        if let mode = UserDefaults.standard.string(forKey: "debugLive") {
            guard !syncing else { return }
            syncing = true
            Task { await apply(Self.samples(mode)) }
            return
        }
        #endif
        guard !store.isSample else { return }
        if syncing {
            again = true
            return
        }
        syncing = true
        let wanted = self.wanted(from: store)
        Task {
            await apply(wanted)
            syncing = false
            if again {
                again = false
                sync(with: store)
            }
        }
    }

    private func wanted(from store: FamilyStore) -> [String: Wanted] {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        request.predicate = store.scoped(request.predicate)
        // In Today's order, which the family card keeps.
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let children = (try? store.context.fetch(request)) ?? []
        let defaults = UserDefaults.standard
        // The glance is on unless switched off, and never in "Just logging".
        let glanceOn = (defaults.object(forKey: Setting.lockScreenGlance) as? Bool ?? true)
            && !defaults.bool(forKey: Setting.justLog)
        var result: [String: Wanted] = [:]
        for child in children {
            guard let id = child.id?.uuidString else { continue }
            let attributes = TimerAttributes(childID: id, childName: child.displayName, colourIndex: Int(child.colourIndex))
            // The snapshot beside whatever is running: the last feed and the last nappy, if they are recent.
            let cutoff = Date.now.addingTimeInterval(-glanceHours * 3600)
            let recent = { (date: Date?) -> Date? in date.flatMap { $0 > cutoff && $0 <= .now ? $0 : nil } }
            let anyFeed = [store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)].compactMap { $0?.startedAt }.max()
            let lastFeed = recent(anyFeed)
            // The same facts as the child's card on Today: Fed for a child on milk, Ate for one past it; Potty while
            // potty training, Nappy otherwise (Tom, 20 November 2026).
            let milk = (child.uses(.bottle) || child.uses(.breastfeed))
                && (child.ageMonths < 12 || (anyFeed.map { Date.now.timeIntervalSince($0) < 2 * 86400 } ?? false))
            let potty = child.pottyTraining && child.uses(.potty)
            let lastAte = recent(store.latest(.solids, for: child)?.startedAt)
            let lastPotty = potty ? recent(store.latest(.potty, for: child)?.startedAt) : nil
            let lastNappy = child.uses(.nappy) && !potty ? recent(store.latest(.nappy, for: child)?.startedAt) : nil
            let next = NextUp.soonest(for: child)
            if let feed = store.activeFeed(for: child) {
                var state = TimerAttributes.ContentState(mode: "feed")
                if let side = feed.runningSide {
                    // Count from where this side's total would have started.
                    state.since = Date.now.addingTimeInterval(-feed.feedSeconds(side))
                    state.label = "Feeding, \(side.lowercased())"
                    state.runningSide = side
                } else {
                    let total = feed.feedSeconds("Left") + feed.feedSeconds("Right")
                    state.label = "Feeding, paused"
                    state.pausedText = Elapsed.minutes(total)
                }
                result[id] = Wanted(attributes: attributes, state: state)
            } else if let sleep = store.activeSleep(for: child), let start = sleep.startedAt {
                var state = TimerAttributes.ContentState(mode: "sleep", label: "Asleep", since: start, fedSince: lastFeed, nappySince: lastNappy,
                                                         nextText: next?.line, nextAt: next?.at)
                state.ateSince = lastAte
                state.pottySince = lastPotty
                state.milk = milk
                state.potty = potty
                result[id] = Wanted(attributes: attributes, state: state)
            } else if glanceOn, child.ageMonths < 24, child.uses(.bottle) || child.uses(.breastfeed) {
                var state = TimerAttributes.ContentState(mode: "glance")
                state.fedSince = lastFeed
                state.nappySince = lastNappy
                let woke = store.lastWoke(for: child)
                // "Awake" is for young babies, and only beside a feed: on its own it is just a clock.
                if let woke, woke > cutoff, woke <= .now, child.ageMonths < 18, state.fedSince != nil {
                    state.awakeSince = woke
                }
                state.nextText = next?.line
                state.nextAt = next?.at
                state.potty = potty
                state.pottySince = lastPotty
                state.milk = true
                if state.fedSince != nil {
                    result[id] = Wanted(attributes: attributes, state: state)
                }
            } else if glanceOn, !milk, child.ageMonths < 48 {
                // A toddler: Awake, Ate, and Potty or Nappy, as on their card on Today.
                var state = TimerAttributes.ContentState(mode: "glance")
                state.milk = false
                state.potty = potty
                state.ateSince = lastAte
                state.pottySince = lastPotty
                state.nappySince = lastNappy
                if let woke = store.lastWoke(for: child), woke > cutoff, woke <= .now { state.awakeSince = woke }
                state.nextText = next?.line
                state.nextAt = next?.at
                if state.ateSince != nil || state.awakeSince != nil {
                    result[id] = Wanted(attributes: attributes, state: state)
                }
            }
        }
        return Self.family(children.compactMap { $0.id?.uuidString }.compactMap { result[$0] })
    }

    /// Every child's card made into one, with a row each (decided 15 November 2026, drawn in
    /// `docs/previews/live-activity/family.png`). First a running feed, then a running sleep, then whoever was
    /// fed longest ago. Only the first row has buttons. The Lock Screen has height for three rows, or two
    /// under a feed with its buttons; the rest are counted.
    static func family(_ cards: [Wanted]) -> [String: Wanted] {
        func rank(_ state: TimerAttributes.ContentState) -> Int { state.mode == "feed" ? 0 : state.mode == "sleep" ? 1 : 2 }
        let ordered = cards.sorted { a, b in
            let (x, y) = (rank(a.state), rank(b.state))
            if x != y { return x < y }
            let (p, q) = (a.state.since ?? a.state.fedSince ?? a.state.ateSince ?? .distantFuture, b.state.since ?? b.state.fedSince ?? b.state.ateSince ?? .distantFuture)
            if p != q { return p < q }
            return a.attributes.childName < b.attributes.childName
        }
        guard let lead = ordered.first else { return [:] }
        var state = lead.state
        state.leadID = lead.attributes.childID
        state.leadName = lead.attributes.childName
        state.leadColour = lead.attributes.colourIndex
        let room = lead.state.mode == "feed" ? 1 : 2
        let rest = ordered.dropFirst()
        // Who is shown is decided by what is going on; the rows then run in Today's order (the order `cards`
        // came in), so each child keeps their place as on Today.
        let place = { (wanted: Wanted) in cards.firstIndex { $0.attributes.childID == wanted.attributes.childID } ?? 0 }
        let shown = rest.prefix(room).sorted { place($0) < place($1) }
        state.others = shown.map {
            .init(id: $0.attributes.childID, name: $0.attributes.childName, colourIndex: $0.attributes.colourIndex, state: $0.state)
        }
        state.leadPlace = shown.filter { place($0) < place(lead) }.count
        state.more = rest.count > room ? rest.count - room : nil
        let attributes = TimerAttributes(childID: TimerAttributes.familyID, childName: "Family", colourIndex: nil)
        return [TimerAttributes.familyID: Wanted(attributes: attributes, state: state)]
    }

    /// When each card was started, by its id, as iOS does not say.
    private static let startsKey = "liveActivityStarts"

    private static func started(_ activity: Activity<TimerAttributes>) {
        var starts = UserDefaults.standard.dictionary(forKey: startsKey) as? [String: Double] ?? [:]
        let live = Set(Activity<TimerAttributes>.activities.map(\.id))
        starts = starts.filter { live.contains($0.key) }
        starts[activity.id] = Date.now.timeIntervalSince1970
        UserDefaults.standard.set(starts, forKey: startsKey)
    }

    /// How long a card has been up. One from before this was kept counts as new, and is timed from now.
    private static func age(of activity: Activity<TimerAttributes>) -> TimeInterval {
        let starts = UserDefaults.standard.dictionary(forKey: startsKey) as? [String: Double] ?? [:]
        guard let start = starts[activity.id] else {
            started(activity)
            return 0
        }
        return Date.now.timeIntervalSince1970 - start
    }

    private func apply(_ wanted: [String: Wanted]) async {
        var showing = Set<String>()
        for activity in Activity<TimerAttributes>.activities {
            let id = activity.attributes.childID
            guard let want = wanted[id], !showing.contains(id),
                  want.attributes.childName == activity.attributes.childName,
                  want.attributes.colourIndex == activity.attributes.colourIndex else {
                await activity.end(nil, dismissalPolicy: .immediate)
                continue
            }
            showing.insert(id)
            // iOS keeps a card for eight hours. Past seven, a fresh one takes over whenever one can be started (the
            // app on screen, or a button on the card pressed); the old one ends only once the new one is up, so the
            // card never goes missing (Tom, 20 November 2026). Started in the background, the request just fails
            // and the old card carries on until the next chance.
            if Self.age(of: activity) > 7 * 3600,
               let fresh = try? Activity.request(attributes: want.attributes,
                                                 content: ActivityContent(state: want.state, staleDate: want.state.nextAt),
                                                 pushType: nil) {
                Self.started(fresh)
                await activity.end(nil, dismissalPolicy: .immediate)
                continue
            }
            if !same(activity.content.state, want.state) {
                // The stale date is when the "next" line's time passes: iOS then draws the card again, without it.
                // Updating works with the app in the background, so "Woke up" on the
                // Lock Screen can turn the card into "Awake" without opening the app.
                await activity.update(ActivityContent(state: want.state, staleDate: want.state.nextAt))
            }
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        for (id, want) in wanted where !showing.contains(id) {
            // Starting needs the app on screen; if it is not, the next sync tries again.
            if let fresh = try? Activity.request(attributes: want.attributes,
                                                 content: ActivityContent(state: want.state, staleDate: want.state.nextAt),
                                                 pushType: nil) {
                Self.started(fresh)
            }
        }
    }

    #if DEBUG
    private static func samples(_ mode: String) -> [String: Wanted] {
        let ago = { (minutes: Double) in Date.now.addingTimeInterval(-minutes * 60) }
        // "-debugLive toddler": Bea alone, potty training: Awake, Ate, Potty.
        if mode == "toddler" {
            var bea = TimerAttributes.ContentState(mode: "glance", awakeSince: ago(264))
            bea.milk = false
            bea.potty = true
            bea.ateSince = ago(66)
            bea.pottySince = ago(50)
            return family([Wanted(attributes: .init(childID: "sample-bea", childName: "Bea", colourIndex: 2), state: bea)])
        }
        var state: TimerAttributes.ContentState
        switch mode {
        case "sleep": state = .init(mode: "sleep", label: "Asleep", since: ago(72), fedSince: ago(125), nappySince: ago(90))
        case "feed": state = .init(mode: "feed", label: "Feeding, left", since: ago(12), runningSide: "Left")
        case "paused": state = .init(mode: "feed", label: "Feeding, paused", pausedText: "12 min")
        default: state = .init(mode: "glance", fedSince: ago(89), awakeSince: ago(71), nappySince: ago(45))
        }
        if mode != "feed", mode != "paused" {
            let guess = NextUp.Guess(kind: mode == "sleep" ? .feed : .sleep, at: NextUp.rounded(ago(-35)))
            state.nextText = guess.line
            state.nextAt = guess.at
        }
        var all = [Wanted(attributes: .init(childID: "sample-ollie", childName: "Ollie", colourIndex: 0), state: state)]
        // "-debugLiveTwo 1" adds a second child, to see the family card; "2" adds a third, and "3" a fourth.
        let others = Int(UserDefaults.standard.string(forKey: "debugLiveTwo") ?? "") ?? 0
        if others >= 1 {
            // Bea is two and a half and potty training: Asleep, Ate, Potty.
            var bea = TimerAttributes.ContentState(mode: "sleep", label: "Asleep", since: ago(72))
            bea.milk = false
            bea.potty = true
            bea.ateSince = ago(150)
            bea.pottySince = ago(95)
            all.append(Wanted(attributes: .init(childID: "sample-bea", childName: "Bea", colourIndex: 2), state: bea))
        }
        if others >= 2 {
            all.append(Wanted(attributes: .init(childID: "sample-kit", childName: "Kit", colourIndex: 1),
                              state: .init(mode: "glance", fedSince: ago(125), awakeSince: ago(40), nappySince: ago(70))))
        }
        if others >= 3 {
            all.append(Wanted(attributes: .init(childID: "sample-robin", childName: "Robin", colourIndex: 4),
                              state: .init(mode: "glance", fedSince: ago(30))))
        }
        return family(all)
    }
    #endif

    /// A running side's start is recomputed each time, so allow a little drift.
    private func same(_ a: TimerAttributes.ContentState, _ b: TimerAttributes.ContentState) -> Bool {
        func close(_ x: Date?, _ y: Date?) -> Bool {
            switch (x, y) {
            case (nil, nil): return true
            case let (x?, y?): return abs(x.timeIntervalSince(y)) < 2
            default: return false
            }
        }
        return a.mode == b.mode && a.label == b.label && a.pausedText == b.pausedText
            && a.runningSide == b.runningSide
            && close(a.since, b.since) && close(a.fedSince, b.fedSince) && close(a.awakeSince, b.awakeSince)
            && close(a.nappySince, b.nappySince) && close(a.ateSince, b.ateSince) && close(a.pottySince, b.pottySince)
            && a.milk == b.milk && a.potty == b.potty
            && a.nextText == b.nextText && close(a.nextAt, b.nextAt)
            && a.leadID == b.leadID && a.leadName == b.leadName && a.leadColour == b.leadColour && a.more == b.more
            && (a.others ?? []).count == (b.others ?? []).count
            && zip(a.others ?? [], b.others ?? []).allSatisfy { x, y in
                x.id == y.id && x.name == y.name && x.colourIndex == y.colourIndex && same(x.state, y.state)
            }
    }
}

extension FamilyStore {
    /// The real family's store, shared with the Lock Screen buttons.
    static let live = FamilyStore()

    /// What the Lock Screen buttons do.
    func handleTimerAction(_ action: String, childID: String) {
        let request = NSFetchRequest<Child>(entityName: "Child")
        let children = (try? context.fetch(request)) ?? []
        refreshRole()
        if canLog, let child = children.first(where: { $0.id?.uuidString == childID }) {
            switch action {
            case TimerActions.wokeUp:
                // A sleep under a minute old was a stray tap: take it back and leave no entry.
                if let sleep = activeSleep(for: child), let began = sleep.startedAt, Date.now.timeIntervalSince(began) < 60 {
                    cancelSleep(for: child)
                } else {
                    endSleep(for: child)
                }
            case TimerActions.startSleep: startSleep(for: child)
            case TimerActions.finishFeed: finishFeed(for: child)
            case TimerActions.feedLeft: tapFeedSide("Left", for: child)
            case TimerActions.feedRight: tapFeedSide("Right", for: child)
            case TimerActions.nappyWet:
                logEach(.nappy, for: [child], detail: "Wet")
                Haptics.success()
            case TimerActions.undoNappy:
                // Only a nappy from the last two minutes, so an old one is never lost.
                if let nappy = latest(.nappy, for: child), let at = nappy.startedAt, Date.now.timeIntervalSince(at) < 120 {
                    delete(nappy)
                }
            default: break
            }
        }
        LiveTimers.shared.sync(with: self)
    }
}
