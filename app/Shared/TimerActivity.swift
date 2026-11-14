import ActivityKit
import AppIntents
import Foundation

/// One Lock Screen card per child. It shows whichever applies: a feed that
/// is running, a sleep that is running, or otherwise how long since the last
/// feed and since they woke. Shared by the app (which starts, updates and
/// ends it) and the widget extension (which draws it).
struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// "feed", "sleep" or "glance".
        var mode: String
        /// "Asleep", "Feeding, left", "Feeding, paused". Empty for a glance.
        var label: String = ""
        /// The clock counts up from here. Nil while a feed is paused.
        var since: Date?
        /// What to show in place of the clock while paused: "12 min".
        var pausedText: String?
        /// The side a feed is running on, "Left" or "Right". Nil when paused.
        var runningSide: String?
        /// Glance: when the last feed started, and when they last woke.
        var fedSince: Date?
        var awakeSince: Date?
    }

    var childID: String
    var childName: String
}

/// The buttons on a Lock Screen card. They run inside the app, which sets `perform` at launch.
enum TimerActions {
    static let wokeUp = "wokeUp"
    static let startSleep = "startSleep"
    static let finishFeed = "finishFeed"
    static let feedLeft = "feedLeft"
    static let feedRight = "feedRight"
    /// From the family widget: a wet nappy, now.
    static let nappyWet = "nappyWet"
    /// From the family widget: take back the nappy just logged.
    static let undoNappy = "undoNappy"

    @MainActor static var perform: ((_ action: String, _ childID: String) -> Void)?
}

struct TimerActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Timer button"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Action") var action: String
    @Parameter(title: "Child") var childID: String

    init() {}

    init(_ action: String, childID: String) {
        self.action = action
        self.childID = childID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TimerActions.perform?(action, childID)
        return .result()
    }
}
