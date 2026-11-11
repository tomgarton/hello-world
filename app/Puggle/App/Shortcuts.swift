import AppIntents
import CoreData
import Foundation

// Actions for Siri, the Action button, Shortcuts, and anything Shortcuts can
// trigger (an NFC tag on the change table, a Focus, a time of day).
// They run in the app without opening it and write through the same store.

/// A child, as Siri and Shortcuts see them.
struct ChildEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Child"
    static var defaultQuery = ChildQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct ChildQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [ChildEntity] {
        FamilyStore.live.shortcutChildren().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ChildEntity] {
        FamilyStore.live.shortcutChildren()
    }

    /// With one child there is nothing to ask.
    @MainActor
    func defaultResult() async -> ChildEntity? {
        let children = FamilyStore.live.shortcutChildren()
        return children.count == 1 ? children.first : nil
    }
}

extension FamilyStore {
    func shortcutChildren() -> [ChildEntity] {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return ((try? context.fetch(request)) ?? []).compactMap { child in
            child.id.map { ChildEntity(id: $0.uuidString, name: child.displayName) }
        }
    }

    func child(for entity: ChildEntity) throws -> Child {
        let request = NSFetchRequest<Child>(entityName: "Child")
        let children = (try? context.fetch(request)) ?? []
        guard let child = children.first(where: { $0.id?.uuidString == entity.id }) else {
            throw ShortcutError.childNotFound
        }
        return child
    }
}

enum ShortcutError: Error, CustomLocalizedStringResourceConvertible {
    case childNotFound

    var localizedStringResource: LocalizedStringResource {
        "That child isn't in the app any more."
    }
}

enum NappyKind: String, AppEnum {
    case wet, dirty, both, dry

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Nappy"
    static var caseDisplayRepresentations: [NappyKind: DisplayRepresentation] = [
        .wet: "Wet", .dirty: "Dirty", .both: "Both", .dry: "Dry",
    ]

    var detail: String { rawValue.capitalized }
}

struct StartSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Start sleep"
    static var description = IntentDescription("Starts a child's sleep timer.")

    @Parameter(title: "Child") var child: ChildEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FamilyStore.live
        let who = try store.child(for: child)
        guard store.activeSleep(for: who) == nil else {
            return .result(dialog: "\(child.name)'s sleep timer is already running.")
        }
        store.startSleep(for: who)
        return .result(dialog: "Started \(child.name)'s sleep.")
    }
}

struct WokeUpIntent: AppIntent {
    static var title: LocalizedStringResource = "Woke up"
    static var description = IntentDescription("Ends a child's sleep timer.")

    @Parameter(title: "Child") var child: ChildEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FamilyStore.live
        let who = try store.child(for: child)
        guard let sleep = store.activeSleep(for: who), let start = sleep.startedAt else {
            return .result(dialog: "\(child.name) has no sleep timer running.")
        }
        store.endSleep(for: who)
        return .result(dialog: "\(child.name) slept \(Elapsed.short(from: start, to: .now)).")
    }
}

struct LogNappyIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a nappy"
    static var description = IntentDescription("Saves a nappy change.")

    @Parameter(title: "Child") var child: ChildEntity
    @Parameter(title: "Nappy", default: .wet) var nappy: NappyKind

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FamilyStore.live
        let who = try store.child(for: child)
        store.logEach(.nappy, for: [who], detail: nappy.detail)
        return .result(dialog: "Saved a \(nappy.rawValue) nappy for \(child.name).")
    }
}

struct LogBottleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a bottle"
    static var description = IntentDescription("Saves a bottle. Without an amount it uses the child's last one.")

    @Parameter(title: "Child") var child: ChildEntity
    @Parameter(title: "Millilitres", inclusiveRange: (1, 1000)) var amount: Int?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FamilyStore.live
        let who = try store.child(for: child)
        let last = store.latest(.bottle, for: who)
        let ml: Int
        if let amount {
            ml = amount
        } else if let last, last.amountML > 0 {
            ml = Int(last.amountML)
        } else {
            ml = try await $amount.requestValue("How many millilitres?")
        }
        store.logEach(.bottle, for: [who], amountML: Double(ml), detail: last?.detail ?? "Formula")
        return .result(dialog: "Saved a \(ml) millilitre bottle for \(child.name).")
    }
}

/// A question, not a log. It reports what was recorded and nothing more.
struct LastFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Last feed"
    static var description = IntentDescription("Says when a child was last fed.")

    @Parameter(title: "Child") var child: ChildEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FamilyStore.live
        let who = try store.child(for: child)
        let feeds = [store.latest(.bottle, for: who), store.latest(.breastfeed, for: who)].compactMap { $0 }
        guard let last = feeds.max(by: { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }),
              let at = last.startedAt else {
            return .result(dialog: "No feeds are logged for \(child.name) yet.")
        }
        let time = at.formatted(date: .omitted, time: .shortened)
        return .result(dialog: "\(child.name): \(last.summary) at \(time), \(Elapsed.short(from: at, to: .now)) ago.")
    }
}

/// The phrases Siri knows without any setup. Each must name the app.
struct PuggleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartSleepIntent(),
                    phrases: ["Start a sleep in \(.applicationName)",
                              "Start sleep for \(\.$child) in \(.applicationName)"],
                    shortTitle: "Start sleep", systemImageName: "moon")
        AppShortcut(intent: WokeUpIntent(),
                    phrases: ["Woke up in \(.applicationName)",
                              "\(\.$child) woke up in \(.applicationName)"],
                    shortTitle: "Woke up", systemImageName: "sun.max")
        AppShortcut(intent: LogNappyIntent(),
                    phrases: ["Log a nappy in \(.applicationName)",
                              "Log a nappy for \(\.$child) in \(.applicationName)"],
                    shortTitle: "Log a nappy", systemImageName: "drop")
        AppShortcut(intent: LogBottleIntent(),
                    phrases: ["Log a bottle in \(.applicationName)",
                              "Log a bottle for \(\.$child) in \(.applicationName)"],
                    shortTitle: "Log a bottle", systemImageName: "waterbottle")
        AppShortcut(intent: LastFeedIntent(),
                    phrases: ["Last feed in \(.applicationName)",
                              "When was \(\.$child) last fed in \(.applicationName)"],
                    shortTitle: "Last feed", systemImageName: "clock")
    }
}

/// Appears under a Focus in the Settings app. Switch it on for Sleep and the
/// app takes its dark look while that Focus is on, whatever the phone is set to.
struct NightLookFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Night look"
    static var description: IntentDescription? = IntentDescription("Use the dark look while this Focus is on.")

    /// Off by default: iOS runs this with the defaults when the Focus ends.
    @Parameter(title: "Dark while this Focus is on", default: false) var night: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Night look", subtitle: night ? "Dark" : "Unchanged")
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(night, forKey: Setting.focusNight)
        return .result()
    }
}
