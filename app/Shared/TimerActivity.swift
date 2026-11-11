import ActivityKit
import AppIntents
import Foundation

/// What a Lock Screen timer shows: one running sleep or feed for one child.
/// Shared by the app (which starts and ends it) and the widget extension (which draws it).
struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// "Asleep", "Feeding, left", "Feeding, paused".
        var label: String
        /// The clock counts up from here. Nil while a feed is paused.
        var since: Date?
        /// What to show in place of the clock while paused: "12 min".
        var pausedText: String?
    }

    /// "sleep" or "feed".
    var kind: String
    var childID: String
    var childName: String
}

/// The button on a Lock Screen timer. It runs inside the app, which sets `perform` at launch.
enum TimerActions {
    @MainActor static var perform: ((_ kind: String, _ childID: String) -> Void)?
}

struct TimerActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop timer"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Kind") var kind: String
    @Parameter(title: "Child") var childID: String

    init() {}

    init(kind: String, childID: String) {
        self.kind = kind
        self.childID = childID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TimerActions.perform?(kind, childID)
        return .result()
    }
}
