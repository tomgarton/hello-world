import CoreData
import SwiftUI

/// What the "Last saved" row on Today points at. It stays until the next save.
struct LastSaved: Identifiable {
    enum Undo { case delete, resumeSleep, none }
    let id = UUID()
    let events: [Event]
    let undo: Undo
}

/// All writes go through here, so new objects always land in the same
/// store (private or shared) as the family they belong to.
@MainActor
final class FamilyStore: ObservableObject {
    let persistence: Persistence
    var context: NSManagedObjectContext { persistence.viewContext }

    @Published var lastSaved: LastSaved?
    private var changeObserver: NSObjectProtocol?

    init(persistence: Persistence = .shared) {
        self.persistence = persistence
        // Views that read through the store (status lines, cards) must refresh on any
        // change, including ones Core Data does not report on the child itself, such as
        // a sleep ending, or an edit merged in from another phone.
        changeObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: persistence.viewContext,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.objectWillChange.send() }
        }
    }

    deinit {
        if let changeObserver { NotificationCenter.default.removeObserver(changeObserver) }
    }

    /// The family on screen: a shared family if this person joined one, otherwise their own.
    func currentFamily() -> Family {
        let request = NSFetchRequest<Family>(entityName: "Family")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let families = (try? context.fetch(request)) ?? []
        if let joined = families.first(where: { $0.objectID.persistentStore == persistence.sharedStore }) {
            return joined
        }
        if let own = families.first { return own }

        let family = Family(context: context)
        family.id = UUID()
        family.name = "Our family"
        family.createdAt = .now
        if let store = persistence.privateStore { context.assign(family, to: store) }
        persistence.save()
        return family
    }

    private func place(_ object: NSManagedObject, with family: Family) {
        if let store = family.objectID.persistentStore {
            context.assign(object, to: store)
        }
    }

    @discardableResult
    func addChild(name: String, birthDate: Date, colourIndex: Int,
                  feeding: Feeding? = nil, pottyTraining: Bool = false) -> Child {
        let family = currentFamily()
        let child = Child(context: context)
        place(child, with: family)
        child.id = UUID()
        child.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        child.birthDate = birthDate
        child.colourIndex = Int16(colourIndex)
        child.createdAt = .now
        child.feeding = feeding
        child.pottyTraining = pottyTraining
        child.family = family
        persistence.save()
        return child
    }

    @discardableResult
    func log(_ kind: EventKind,
             for children: [Child],
             at start: Date = .now,
             end: Date? = nil,
             amountML: Double = 0,
             detail: String? = nil,
             note: String? = nil) -> Event {
        let family = currentFamily()
        let event = Event(context: context)
        place(event, with: family)
        event.id = UUID()
        event.kind = kind
        event.startedAt = start
        event.endedAt = end
        event.amountML = amountML
        event.detail = detail
        event.note = note
        event.createdAt = .now
        event.family = family
        event.children = Set(children)
        persistence.save()
        return event
    }

    /// One entry per child, so each can be edited on its own. This is what the log sheet calls.
    @discardableResult
    func logEach(_ kind: EventKind,
                 for children: [Child],
                 at start: Date = .now,
                 end: Date? = nil,
                 amountML: Double = 0,
                 detail: String? = nil,
                 note: String? = nil) -> [Event] {
        let events = children.map {
            log(kind, for: [$0], at: start, end: end, amountML: amountML, detail: detail, note: note)
        }
        lastSaved = LastSaved(events: events, undo: .delete)
        return events
    }

    /// Call after changing an existing entry's fields.
    func saveEdit(_ event: Event) {
        persistence.save()
        lastSaved = LastSaved(events: [event], undo: .none)
    }

    func undoLastSaved() {
        guard let saved = lastSaved else { return }
        lastSaved = nil
        let live = saved.events.filter(\.isLive)
        switch saved.undo {
        case .delete: live.forEach(context.delete)
        case .resumeSleep: live.forEach { $0.endedAt = nil }
        case .none: break
        }
        persistence.save()
    }

    /// Sleep is a timer: start now, finish later. One open sleep per child.
    func startSleep(for child: Child) {
        guard activeSleep(for: child) == nil else { return }
        if lastSaved?.undo == .resumeSleep { lastSaved = nil }
        log(.sleep, for: [child], at: .now)
    }

    func endSleep(for child: Child) {
        guard let sleep = activeSleep(for: child) else { return }
        sleep.endedAt = .now
        persistence.save()
        lastSaved = LastSaved(events: [sleep], undo: .resumeSleep)
    }

    /// A stray tap on "Start sleep" leaves no entry.
    func cancelSleep(for child: Child) {
        guard let sleep = activeSleep(for: child) else { return }
        context.delete(sleep)
        persistence.save()
    }

    /// A timer left running for 14 hours or more.
    func staleSleep(among children: [Child], hours: Double = 14) -> Event? {
        children.compactMap { activeSleep(for: $0) }
            .first { ($0.startedAt ?? .now) < Date.now.addingTimeInterval(-hours * 3600) }
    }

    /// The child most recently logged for this activity.
    func lastChild(for kind: EventKind, among children: [Child]) -> Child? {
        children
            .compactMap { child in latest(kind, for: child)?.startedAt.map { (child, $0) } }
            .max { $0.1 < $1.1 }?.0
    }

    func events(for child: Child, since: Date) -> [Event] {
        (child.events ?? []).filter { ($0.startedAt ?? .distantPast) >= since }
    }

    func activeSleep(for child: Child) -> Event? {
        (child.events ?? []).first { $0.kind == .sleep && $0.endedAt == nil }
    }

    func latest(_ kind: EventKind, for child: Child) -> Event? {
        (child.events ?? [])
            .filter { $0.kind == kind }
            .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    /// The most recent entry of any kind, for the status line when there is no feed yet.
    func latest(for child: Child) -> Event? {
        (child.events ?? [])
            .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    func delete(_ event: Event) {
        if lastSaved?.events.contains(event) == true { lastSaved = nil }
        context.delete(event)
        persistence.save()
    }

    /// Call after changing a child's details.
    func saveChild() {
        persistence.save()
    }

    /// Removes the child and the entries that were only theirs, for everyone.
    func delete(_ child: Child) {
        for event in child.events ?? [] where (event.children ?? []).allSatisfy({ $0 == child }) {
            context.delete(event)
        }
        lastSaved = nil
        context.delete(child)
        persistence.save()
    }

    /// "Delete everything": every entry, child and family this phone can see.
    func deleteEverything() {
        lastSaved = nil
        for name in ["Event", "Child", "Family"] {
            let request = NSFetchRequest<NSManagedObject>(entityName: name)
            ((try? context.fetch(request)) ?? []).forEach(context.delete)
        }
        persistence.save()
    }

    /// Everything, as a plain CSV file the family can open anywhere.
    func exportCSV() -> URL? {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]
        let events = (try? context.fetch(request)) ?? []
        let stamp = ISO8601DateFormatter()
        stamp.timeZone = .current // local time with its offset, not UTC
        func cell(_ text: String?) -> String {
            let value = text ?? ""
            return value.contains(where: { ",\"\n".contains($0) })
                ? "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                : value
        }
        var lines = ["started,ended,child,activity,amount_ml,detail,note"]
        for event in events {
            let names = event.sortedChildren.map(\.displayName).joined(separator: " & ")
            lines.append([
                event.startedAt.map(stamp.string(from:)) ?? "",
                event.endedAt.map(stamp.string(from:)) ?? "",
                cell(names),
                event.kind.rawValue,
                event.amountML > 0 ? String(Int(event.amountML)) : "",
                cell(event.detail),
                cell(event.note),
            ].joined(separator: ","))
        }
        let day = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("puggle-export-\(day).csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
