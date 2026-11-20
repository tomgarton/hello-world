import Foundation

/// What passes between the iPhone and the Watch (Tom, 20 November 2026).
///
/// The Watch keeps no database of its own. The iPhone sends it the same summary the widgets read
/// (`WidgetSnapshot`), whenever something changes, and the Watch sends back what was tapped. The iPhone
/// saves it the usual way, so the rest of the family sees it through iCloud as if it had been logged there.
enum WatchLink {
    /// The key the summary travels under, as JSON.
    static let snapshotKey = "snapshot"

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
