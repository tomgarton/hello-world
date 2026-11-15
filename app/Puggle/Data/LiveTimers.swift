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

    private struct Wanted {
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
            let lastFeed = recent([store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)].compactMap { $0?.startedAt }.max())
            let lastNappy = child.uses(.nappy) ? recent(store.latest(.nappy, for: child)?.startedAt) : nil
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
                result[id] = Wanted(attributes: attributes,
                                    state: .init(mode: "sleep", label: "Asleep", since: start, fedSince: lastFeed, nappySince: lastNappy,
                                                 nextText: next?.line, nextAt: next?.at))
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
                if state.fedSince != nil {
                    result[id] = Wanted(attributes: attributes, state: state)
                }
            }
        }
        return result
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
            _ = try? Activity.request(attributes: want.attributes,
                                      content: ActivityContent(state: want.state, staleDate: want.state.nextAt),
                                      pushType: nil)
        }
    }

    #if DEBUG
    private static func samples(_ mode: String) -> [String: Wanted] {
        let ago = { (minutes: Double) in Date.now.addingTimeInterval(-minutes * 60) }
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
        var all = ["sample-ollie": Wanted(attributes: .init(childID: "sample-ollie", childName: "Ollie", colourIndex: 0), state: state)]
        // "-debugLiveTwo 1" adds a second child, to see two cards and the small round ones.
        if UserDefaults.standard.string(forKey: "debugLiveTwo") == "1" {
            all["sample-bea"] = Wanted(attributes: .init(childID: "sample-bea", childName: "Bea", colourIndex: 2),
                                       state: .init(mode: "sleep", label: "Asleep", since: ago(25)))
        }
        return all
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
            && close(a.nappySince, b.nappySince)
            && a.nextText == b.nextText && close(a.nextAt, b.nextAt)
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
