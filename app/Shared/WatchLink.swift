import Foundation

/// What passes between the iPhone and the Watch (Tom, 20 November 2026).
///
/// The Watch keeps no database of its own. The iPhone sends it the same summary the widgets read
/// (`WidgetSnapshot`), whenever something changes, and the Watch sends back what was tapped. The iPhone
/// saves it the usual way, so the rest of the family sees it through iCloud as if it had been logged there.
enum WatchLink {
    /// The key the summary travels under, as JSON.
    static let snapshotKey = "snapshot"

    /// The key the Watch asks for a fresh summary under, when it wakes.
    static let refreshKey = "refresh"

    /// Something tapped on the Watch, for one child.
    struct Request: Codable {
        enum Action: String, Codable {
            // The same as the Lock Screen buttons (`TimerActions`), so the iPhone handles them the same way.
            case startSleep, wokeUp, feedLeft, feedRight, finishFeed
            // Logged at the moment they were tapped, even if the iPhone hears of them later.
            case nappy, bottle
        }

        var action: Action
        var childID: String
        /// When it was tapped.
        var at: Date = .now
        /// A nappy's kind: "Wet", "Dirty" or "Both".
        var detail: String?
        /// A bottle's amount, in millilitres.
        var ml: Int?

        /// Timers only make sense at the moment they are tapped, so they need the iPhone there and then.
        /// A nappy or a bottle can wait to be delivered.
        var needsReply: Bool { action != .nappy && action != .bottle }

        /// Tells one tap from another, so one delivered twice is saved once.
        var key: String { "\(action.rawValue)-\(childID)-\(at.timeIntervalSinceReferenceDate)" }

        var message: [String: Any] {
            (try? JSONEncoder().encode(self)).map { ["request": $0] } ?? [:]
        }

        init(action: Action, childID: String, detail: String? = nil, ml: Int? = nil) {
            self.action = action
            self.childID = childID
            self.detail = detail
            self.ml = ml
        }

        init?(message: [String: Any]) {
            guard let data = message["request"] as? Data,
                  let request = try? JSONDecoder().decode(Request.self, from: data) else { return nil }
            self = request
        }
    }
}

extension WidgetSnapshot.Child {
    /// A tap's effect on the summary, shown on the Watch before the iPhone answers: the facts on Now, and
    /// the day strip, the marks and the guesses on the other pages.
    mutating func apply(_ request: WatchLink.Request, ounces: Bool = false) {
        let now = request.at
        func mark(_ kind: String, _ at: Date) {
            guard marksToday != nil else { return }
            marksToday?.append(WidgetSnapshot.Mark(kind: kind, at: at))
            marksToday?.sort { $0.at < $1.at }
        }
        switch request.action {
        case .startSleep:
            guard asleepSince == nil else { return }
            asleepSince = now
            if sleepsToday != nil {
                let next = ((sleepsToday ?? []).map(\.sleep).max() ?? -1) + 1
                sleepsToday?.append(WidgetSnapshot.Stretch(start: now, end: nil, sleep: next))
            }
            // The guess was for a sleep that has now started. The iPhone sends the next one.
            coming?.removeAll { $0.kind == "sleep" }
        case .wokeUp:
            asleepSince = nil
            lastWoke = now
            if let open = sleepsToday?.lastIndex(where: { $0.end == nil }) { sleepsToday?[open].end = now }
        case .feedLeft, .feedRight:
            let side = request.action == .feedLeft ? "Left" : "Right"
            // A summary from an older Puggle has no fed time: leave it so, and the counter runs from the start.
            let counted = feedingSince == nil || feedBanked != nil
            if feedingSince == nil {
                feedingSince = now
                mark("feed", now)
                coming?.removeAll { $0.kind == "feed" }
            }
            if counted {
                feedBanked = (feedBanked ?? 0) + (feedSideSince.map { max(now.timeIntervalSince($0), 0) } ?? 0)
                feedSideSince = feedSide == side ? nil : now
            }
            feedSide = feedSide == side ? nil : side
        case .finishFeed:
            if let start = feedingSince { lastFeed = start; lastFeedText = "Breastfeed" }
            feedingSince = nil; feedSide = nil; feedBanked = nil; feedSideSince = nil
        case .nappy:
            lastNappy = max(lastNappy ?? now, now)
            mark("nappy", now)
            coming?.removeAll { $0.kind == "nappy" }
        case .bottle:
            if now >= lastFeed ?? now {
                lastFeed = now
                lastFeedText = request.ml.map { "Bottle · \(WidgetSnapshot.volume($0, ounces: ounces))" } ?? "Bottle"
                lastBottleML = request.ml
            }
            mark("feed", now)
            coming?.removeAll { $0.kind == "feed" }
        }
    }

    /// Whether a summary from the iPhone already has this nappy or bottle in it.
    func has(_ request: WatchLink.Request) -> Bool {
        switch request.action {
        case .nappy: (marksToday ?? []).contains { $0.kind == "nappy" && abs($0.at.timeIntervalSince(request.at)) < 1 }
            || (lastNappy.map { abs($0.timeIntervalSince(request.at)) < 1 } ?? false)
        case .bottle: (marksToday ?? []).contains { $0.kind == "feed" && abs($0.at.timeIntervalSince(request.at)) < 1 }
            || (lastFeed.map { abs($0.timeIntervalSince(request.at)) < 1 } ?? false)
        default: true
        }
    }
}
