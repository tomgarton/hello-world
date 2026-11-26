import AppIntents
import Foundation

/// What the Home Screen widgets and the Control Centre control show: a small
/// summary the app writes to the shared App Group each time something changes.
/// The widgets never open the database themselves.
struct WidgetSnapshot: Codable {
    struct Child: Codable, Identifiable, Hashable {
        let id: String
        let name: String
        let colourIndex: Int
        /// When the running sleep started, if they are asleep.
        var asleepSince: Date?
        /// The last feed: when, and a short line ("Bottle · 150 ml").
        var lastFeed: Date?
        var lastFeedText: String?
        var lastNappy: Date?
        let usesNappies: Bool
        /// When their last sleep ended. Nil in a summary written before this was added.
        var lastWoke: Date?
        /// The day so far, for the large widget: "4 feeds, 560 ml · 3h 10m asleep · 5 nappies". Nil when nothing yet.
        var today: String?
        /// What comes next, as on the Lock Screen card: "Next feed around 2:30 pm", shown until `nextAt`.
        var nextText: String?
        var nextAt: Date?
        /// For the tiles widget (16 November 2026). Nil in a summary written before this.
        var lastSolids: Date?
        var lastPotty: Date?
        var usesMilk: Bool?
        var usesSolids: Bool?
        /// Training, so the potty takes the nappy's place.
        var pottyTraining: Bool?
        /// For the Watch (20 November 2026): a breastfeed whose timer is running, the side it is on (nil while
        /// paused), whether they are breastfed at all, and their last bottle's amount to start from.
        var feedingSince: Date?
        var feedSide: String?
        var breastfeeds: Bool?
        var lastBottleML: Int?
        /// For the Watch's pages (26 November 2026). Nil in a summary written before this.
        /// Each stretch asleep that touches today, split around wakings, the earliest first.
        var sleepsToday: [Stretch]?
        /// Hours asleep on each of the fourteen whole days before today, oldest first. Nil for a day with no sleep logged.
        var sleepDays: [Double?]?
        /// The midnight `sleepDays` runs up to: the start of the day the summary was written (27 November
        /// 2026). Nil in a summary written before this, when the days are taken as they are.
        var sleepDaysEnd: Date?
        /// What is guessed to come next, soonest first.
        var coming: [Coming]?
        /// Today's feeds, meals, nappies and potty trips, for the marks under the day strip, earliest first.
        var marksToday: [Mark]?
    }

    /// Something logged at a moment today: "feed", "meal", "nappy" or "potty".
    struct Mark: Codable, Hashable {
        var kind: String
        var at: Date
    }

    /// One stretch asleep. `sleep` numbers the sleep it belongs to, so a night broken by a waking is still
    /// one night. `end` is nil while the sleep is running.
    struct Stretch: Codable, Hashable {
        var start: Date
        var end: Date?
        var sleep: Int
    }

    /// A guess at what comes next: "feed", "sleep" or "nappy", and about when.
    struct Coming: Codable, Hashable {
        var kind: String
        var at: Date
    }

    var children: [Child]
    var updatedAt: Date

    static let groupID = "group.com.tomgarton.puggle"
    private static let fileName = "widgets.json"

    private static var url: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?.appendingPathComponent(fileName)
    }

    /// Nil when there is no App Group (the free-account test build) or nothing written yet.
    static func load() -> WidgetSnapshot? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let url = Self.url, let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// A made-up family for the widget gallery and previews.
    static let preview = WidgetSnapshot(children: [
        Child(id: "preview-ollie", name: "Ollie", colourIndex: 0, asleepSince: nil,
              lastFeed: Date.now.addingTimeInterval(-95 * 60), lastFeedText: "Bottle · 150 ml",
              lastNappy: Date.now.addingTimeInterval(-40 * 60), usesNappies: true, lastWoke: Date.now.addingTimeInterval(-71 * 60),
              today: "4 feeds, 560 ml · 3h 10m asleep · 5 nappies",
              lastSolids: Date.now.addingTimeInterval(-200 * 60), usesMilk: true, usesSolids: true),
        Child(id: "preview-bea", name: "Bea", colourIndex: 1, asleepSince: Date.now.addingTimeInterval(-50 * 60),
              lastFeed: Date.now.addingTimeInterval(-150 * 60), lastFeedText: "Solids", lastNappy: nil, usesNappies: false),
    ], updatedAt: .now)
}

extension WidgetSnapshot.Child {
    /// The fourteen whole days before today, as of `now`. The iPhone writes them only when something changes,
    /// so after midnight they are a day or more out of date. Moved on here: the oldest drop off, and each day
    /// since the summary was written is added from the sleeps it sent for its own day (`sleepsToday`), which
    /// also carry a sleep still running through the nights after. A day nothing covers is a gap, as on the iPhone.
    func sleepDays(now: Date, calendar: Calendar = .current) -> [Double?]? {
        guard let sent = sleepDays else { return nil }
        guard let end = sleepDaysEnd else { return sent }
        let written = calendar.startOfDay(for: end)
        let today = calendar.startOfDay(for: now)
        let behind = calendar.dateComponents([.day], from: written, to: today).day ?? 0
        guard behind > 0 else { return sent }
        // A sleep running when the summary was written ran on until now, or until they woke if the Watch saw it.
        let until = asleepSince != nil ? now : min(lastWoke ?? now, now)
        let stretches = (sleepsToday ?? []).map { DateInterval(start: $0.start, end: max($0.start, $0.end ?? until)) }
        let added = (max(0, behind - 14)..<behind).map { offset -> Double? in
            guard let start = calendar.date(byAdding: .day, value: offset, to: written),
                  let next = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
            let seconds = stretches.reduce(0.0) { $0 + max(0, min($1.end, next).timeIntervalSince(max($1.start, start))) }
            return seconds >= 60 ? seconds / 3600 : nil
        }
        return Array((sent + added).suffix(14))
    }
}

/// A child to choose when setting up a widget or control.
struct WidgetChild: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Child"
    static var defaultQuery = WidgetChildQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct WidgetChildQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WidgetChild] {
        (WidgetSnapshot.load()?.children ?? []).filter { identifiers.contains($0.id) }.map { WidgetChild(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [WidgetChild] {
        (WidgetSnapshot.load()?.children ?? []).map { WidgetChild(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> WidgetChild? {
        try? await suggestedEntities().first
    }
}
