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
             note: String? = nil,
             dose: String? = nil,
             value: Double = 0) -> Event {
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
        event.dose = dose
        event.value = value
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
                 note: String? = nil,
                 dose: String? = nil,
                 value: Double = 0) -> [Event] {
        let events = children.map {
            log(kind, for: [$0], at: start, end: end, amountML: amountML, detail: detail, note: note, dose: dose, value: value)
        }
        lastSaved = LastSaved(events: events, undo: .delete)
        return events
    }

    /// Twins fed together: one bottle each, with their own amounts.
    @discardableResult
    func logBottles(_ amounts: [(child: Child, ml: Double)], at start: Date, detail: String?, note: String?) -> [Event] {
        let events = amounts.map { log(.bottle, for: [$0.child], at: start, amountML: $0.ml, detail: detail, note: note) }
        lastSaved = LastSaved(events: events, undo: .delete)
        return events
    }

    // MARK: Breastfeed timers

    /// A feed whose timer has not been finished. One per child.
    func activeFeed(for child: Child) -> Event? {
        (child.events ?? []).first { $0.isRunningFeed }
    }

    /// Starts a side, or pauses it if it is the one running. Starting one side stops the other.
    func tapFeedSide(_ side: String, for child: Child) {
        let feed = activeFeed(for: child) ?? log(.breastfeed, for: [child], at: .now)
        bank(feed)
        if feed.runningSide == side {
            feed.runningSide = nil
            feed.sideStartedAt = nil
        } else {
            feed.runningSide = side
            feed.sideStartedAt = .now
        }
        persistence.save()
    }

    func finishFeed(for child: Child) {
        guard let feed = activeFeed(for: child) else { return }
        bank(feed)
        feed.runningSide = nil
        feed.sideStartedAt = nil
        feed.endedAt = .now
        let left = feed.leftSeconds > 0, right = feed.rightSeconds > 0
        feed.detail = left && right ? "Both" : (right ? "Right" : "Left")
        persistence.save()
        lastSaved = LastSaved(events: [feed], undo: .none)
    }

    /// A timer started by mistake leaves no entry.
    func discardFeed(for child: Child) {
        guard let feed = activeFeed(for: child) else { return }
        context.delete(feed)
        persistence.save()
    }

    /// Adds the stretch that is running to its side's total.
    private func bank(_ feed: Event) {
        guard let side = feed.runningSide, let since = feed.sideStartedAt else { return }
        let extra = max(Date.now.timeIntervalSince(since), 0)
        if side == "Left" { feed.leftSeconds += extra } else { feed.rightSeconds += extra }
        feed.sideStartedAt = .now
    }

    // MARK: Children

    /// Hides a child from Today and keeps everything logged for them.
    func setArchived(_ archived: Bool, for child: Child) {
        if archived {
            if let sleep = activeSleep(for: child) { sleep.endedAt = .now }
            finishFeed(for: child)
            lastSaved = nil
        }
        child.archived = archived
        persistence.save()
    }

    /// Weights, oldest first, for the growth chart.
    func weights(for child: Child) -> [Event] {
        (child.events ?? [])
            .filter { $0.kind == .weight && $0.value > 0 && $0.startedAt != nil }
            .sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    /// Milestones in order.
    func milestones(for child: Child) -> [Event] {
        (child.events ?? [])
            .filter { $0.kind == .milestone }
            .sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
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

    /// The most recent dose of a medicine by name, for the "too soon?" question.
    func lastDose(of medicine: String, for child: Child) -> Event? {
        let wanted = medicine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (child.events ?? [])
            .filter { $0.kind == .medicine && ($0.detail ?? "").lowercased() == wanted }
            .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    /// The first weight logged for a child, used for "change since".
    func firstWeight(for child: Child) -> Event? {
        (child.events ?? [])
            .filter { $0.kind == .weight && $0.value > 0 }
            .min { ($0.startedAt ?? .distantFuture) < ($1.startedAt ?? .distantFuture) }
    }

    /// The child's potty stickers, oldest first. Accidents never appear here.
    func stickers(for child: Child) -> [Event] {
        (child.events ?? [])
            .filter { $0.kind == .potty && !($0.sticker ?? "").isEmpty }
            .sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    func setSticker(_ sticker: String, on event: Event) {
        guard event.isLive else { return }
        event.sticker = sticker
        persistence.save()
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
            .filter { $0.kind != .milestone }
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
        var lines = ["started,ended,child,activity,amount_ml,detail,note,dose,value,sticker,left_min,right_min"]
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
                cell(event.dose),
                event.value > 0 ? String(event.value) : "",
                cell(event.sticker),
                event.leftSeconds > 0 ? String(Int((event.leftSeconds / 60).rounded())) : "",
                event.rightSeconds > 0 ? String(Int((event.rightSeconds / 60).rounded())) : "",
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
