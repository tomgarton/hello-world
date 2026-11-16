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
        let asleepSince: Date?
        /// The last feed: when, and a short line ("Bottle · 150 ml").
        let lastFeed: Date?
        let lastFeedText: String?
        let lastNappy: Date?
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
