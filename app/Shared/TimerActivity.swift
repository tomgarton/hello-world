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
        /// When the last nappy was changed. Shown beside the feed and the sleep, in every mode.
        var nappySince: Date?
        /// For a child past milk (Tom, 20 November 2026): when they last ate, shown as "Ate" in place of "Fed".
        var ateSince: Date?
        /// While potty training: the last potty, shown as "Potty" in place of "Nappy".
        var pottySince: Date?
        /// Which facts, as on the child's card on Today: false for a child past milk (Ate, Awake, Potty or Nappy),
        /// true for potty training. Nil on a card made before these.
        var milk: Bool?
        var potty: Bool?
        /// What comes next, as a guess from the child's last week: "Next feed around 2:30 pm". Shown only
        /// until `nextAt`, so nothing ever reads as late.
        var nextText: String?
        var nextAt: Date?

        /// The family card (16 November 2026): one card, a row for each child. The fields above are for the
        /// first row, whose child is named here; it is the only row with buttons. Nil on a card made before this,
        /// which is one child's alone and named in the attributes.
        var leadID: String?
        var leadName: String?
        var leadColour: Int?
        /// Everyone else with something to show, one quiet row each, in order. Nil or empty with one child.
        var others: [Other]?
        /// Children left off for want of room, counted.
        var more: Int?

        /// Another child's row: who, and what they are doing, in the same terms as the first row.
        struct Other: Codable, Hashable {
            var id: String
            var name: String
            var colourIndex: Int?
            var state: ContentState
        }

        /// The line to show at this moment, if its time is still ahead.
        func nextLine(now: Date = .now) -> String? {
            guard let nextText, let nextAt, nextAt > now else { return nil }
            return nextText
        }
    }

    var childID: String
    var childName: String
    /// Which of the children's colours is theirs, so the card can be told apart at a glance. Nil on a card made before this.
    var colourIndex: Int?

    /// The family card's id: one card for everyone, so it never has to be swapped for another while the app is
    /// in the background (iOS only lets a card start with the app on screen).
    static let familyID = "family"

    /// Whose the first row is: the lead child on a family card, or the card's own child.
    func lead(_ state: ContentState) -> TimerAttributes {
        guard let id = state.leadID else { return self }
        return TimerAttributes(childID: id, childName: state.leadName ?? childName, colourIndex: state.leadColour)
    }
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
