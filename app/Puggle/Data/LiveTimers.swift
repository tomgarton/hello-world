import ActivityKit
import CoreData
import Foundation

/// Keeps the Lock Screen and Dynamic Island timers in step with the data:
/// one Live Activity for each running sleep and each running feed.
/// It compares what should be showing with what is, so it is safe to call often.
@MainActor
final class LiveTimers {
    static let shared = LiveTimers()

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

    private func key(_ attributes: TimerAttributes) -> String {
        "\(attributes.kind)-\(attributes.childID)"
    }

    private func wanted(from store: FamilyStore) -> [String: Wanted] {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        let children = (try? store.context.fetch(request)) ?? []
        var result: [String: Wanted] = [:]
        for child in children {
            guard let id = child.id?.uuidString else { continue }
            if let sleep = store.activeSleep(for: child), let start = sleep.startedAt {
                let attributes = TimerAttributes(kind: "sleep", childID: id, childName: child.displayName)
                result[key(attributes)] = Wanted(attributes: attributes,
                                                 state: .init(label: "Asleep", since: start, pausedText: nil))
            }
            if let feed = store.activeFeed(for: child) {
                let attributes = TimerAttributes(kind: "feed", childID: id, childName: child.displayName)
                let state: TimerAttributes.ContentState
                if let side = feed.runningSide {
                    // Count from where this side's total would have started.
                    let since = Date.now.addingTimeInterval(-feed.feedSeconds(side))
                    state = .init(label: "Feeding, \(side.lowercased())", since: since, pausedText: nil)
                } else {
                    let total = feed.feedSeconds("Left") + feed.feedSeconds("Right")
                    state = .init(label: "Feeding, paused", since: nil, pausedText: Elapsed.minutes(total))
                }
                result[key(attributes)] = Wanted(attributes: attributes, state: state)
            }
        }
        return result
    }

    private func apply(_ wanted: [String: Wanted]) async {
        var showing = Set<String>()
        for activity in Activity<TimerAttributes>.activities {
            let name = key(activity.attributes)
            guard let want = wanted[name], !showing.contains(name) else {
                await activity.end(nil, dismissalPolicy: .immediate)
                continue
            }
            showing.insert(name)
            if !same(activity.content.state, want.state) {
                await activity.update(ActivityContent(state: want.state, staleDate: nil))
            }
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        for (name, want) in wanted where !showing.contains(name) {
            // Starting needs the app on screen; if it is not, the next sync tries again.
            _ = try? Activity.request(attributes: want.attributes,
                                      content: ActivityContent(state: want.state, staleDate: nil),
                                      pushType: nil)
        }
    }

    /// The running side's start is recomputed each time, so allow a second of drift.
    private func same(_ a: TimerAttributes.ContentState, _ b: TimerAttributes.ContentState) -> Bool {
        guard a.label == b.label, a.pausedText == b.pausedText else { return false }
        switch (a.since, b.since) {
        case (nil, nil): return true
        case let (x?, y?): return abs(x.timeIntervalSince(y)) < 2
        default: return false
        }
    }
}

extension FamilyStore {
    /// The real family's store, shared with the Lock Screen buttons.
    static let live = FamilyStore()

    /// What the Lock Screen buttons do: "Woke up" and "Finish".
    func handleTimerAction(kind: String, childID: String) {
        let request = NSFetchRequest<Child>(entityName: "Child")
        let children = (try? context.fetch(request)) ?? []
        guard let child = children.first(where: { $0.id?.uuidString == childID }) else {
            LiveTimers.shared.sync(with: self)
            return
        }
        if kind == "sleep" { endSleep(for: child) } else { finishFeed(for: child) }
        LiveTimers.shared.sync(with: self)
    }
}
