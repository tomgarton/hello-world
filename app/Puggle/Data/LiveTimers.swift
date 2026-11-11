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
        let children = (try? store.context.fetch(request)) ?? []
        let defaults = UserDefaults.standard
        // The glance is on unless switched off, and never in "Just logging".
        let glanceOn = (defaults.object(forKey: Setting.lockScreenGlance) as? Bool ?? true)
            && !defaults.bool(forKey: Setting.justLog)
        var result: [String: Wanted] = [:]
        for child in children {
            guard let id = child.id?.uuidString else { continue }
            let attributes = TimerAttributes(childID: id, childName: child.displayName)
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
                                    state: .init(mode: "sleep", label: "Asleep", since: start))
            } else if glanceOn, child.uses(.bottle) || child.uses(.breastfeed) {
                let cutoff = Date.now.addingTimeInterval(-glanceHours * 3600)
                var state = TimerAttributes.ContentState(mode: "glance")
                let feeds = [store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)]
                if let fed = feeds.compactMap({ $0?.startedAt }).max(), fed > cutoff, fed <= .now {
                    state.fedSince = fed
                }
                let woke = (child.events ?? [])
                    .filter { $0.kind == .sleep }
                    .compactMap(\.endedAt)
                    .max()
                if let woke, woke > cutoff, woke <= .now {
                    state.awakeSince = woke
                }
                if state.fedSince != nil || state.awakeSince != nil {
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
                  want.attributes.childName == activity.attributes.childName else {
                await activity.end(nil, dismissalPolicy: .immediate)
                continue
            }
            showing.insert(id)
            if !same(activity.content.state, want.state) {
                // Updating works with the app in the background, so "Woke up" on the
                // Lock Screen can turn the card into "Awake" without opening the app.
                await activity.update(ActivityContent(state: want.state, staleDate: nil))
            }
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        for (id, want) in wanted where !showing.contains(id) {
            // Starting needs the app on screen; if it is not, the next sync tries again.
            _ = try? Activity.request(attributes: want.attributes,
                                      content: ActivityContent(state: want.state, staleDate: nil),
                                      pushType: nil)
        }
    }

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
    }
}

extension FamilyStore {
    /// The real family's store, shared with the Lock Screen buttons.
    static let live = FamilyStore()

    /// What the Lock Screen buttons do.
    func handleTimerAction(_ action: String, childID: String) {
        let request = NSFetchRequest<Child>(entityName: "Child")
        let children = (try? context.fetch(request)) ?? []
        if let child = children.first(where: { $0.id?.uuidString == childID }) {
            switch action {
            case TimerActions.wokeUp: endSleep(for: child)
            case TimerActions.finishFeed: finishFeed(for: child)
            case TimerActions.feedLeft: tapFeedSide("Left", for: child)
            case TimerActions.feedRight: tapFeedSide("Right", for: child)
            default: break
            }
        }
        LiveTimers.shared.sync(with: self)
    }
}
