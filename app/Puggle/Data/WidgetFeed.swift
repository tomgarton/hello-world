import CoreData
import WidgetKit

/// Keeps the widgets' summary up to date. Written a moment after changes settle,
/// and never for the sample family.
@MainActor
enum WidgetFeed {
    private static var pending: Task<Void, Never>?

    static func update(from store: FamilyStore) {
        guard !store.isSample else { return }
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            write(from: store)
        }
    }

    /// The day so far in a few counts, joined by interpuncts: "4 feeds, 560 ml · 3h 10m asleep · 5 nappies".
    /// A sleep that began yesterday counts for the part that falls today. A sleep still running is left out,
    /// since the widget cannot keep it counting.
    static func today(for child: Child, in store: FamilyStore, now: Date = .now) -> String? {
        let midnight = Calendar.current.startOfDay(for: now)
        // From yesterday, so a night that ran into today is found.
        let events = store.events(for: child, since: midnight.addingTimeInterval(-86400)).filter(\.isLive)
        let todays = events.filter { ($0.startedAt ?? .distantPast) >= midnight }
        func count(_ kinds: EventKind...) -> Int { todays.filter { kinds.contains($0.kind) }.count }
        func some(_ n: Int, _ one: String, _ many: String) -> String { n == 1 ? "1 \(one)" : "\(n) \(many)" }
        var parts: [String] = []
        let feeds = count(.bottle, .breastfeed)
        if feeds > 0 {
            let ml = todays.filter { $0.kind == .bottle }.reduce(0) { $0 + $1.amountML }
            parts.append(some(feeds, "feed", "feeds") + (ml > 0 ? ", \(Units.volume(ml))" : ""))
        }
        let meals = count(.solids)
        if meals > 0 { parts.append(some(meals, "meal", "meals")) }
        let asleep = events.filter { $0.kind == .sleep }.reduce(0.0) { total, sleep in
            guard let start = sleep.startedAt, let end = sleep.endedAt, end > midnight else { return total }
            return total + sleep.asleepSeconds(from: max(start, midnight), to: end)
        }
        if asleep >= 60 { parts.append("\(Elapsed.short(seconds: asleep)) asleep") }
        let nappies = count(.nappy)
        if nappies > 0 { parts.append(some(nappies, Terms.nappyLower, Terms.nappiesLower)) }
        let potty = count(.potty)
        if potty > 0 { parts.append(some(potty, "potty trip", "potty trips")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func write(from store: FamilyStore) {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        request.predicate = store.scoped(request.predicate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let children = (try? store.context.fetch(request)) ?? []
        let rows = children.map { child -> WidgetSnapshot.Child in
            let feeds = [store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)].compactMap { $0 }
            let feed = feeds.max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
            let next = NextUp.soonest(for: child)
            return WidgetSnapshot.Child(
                id: child.id?.uuidString ?? "",
                name: child.displayName,
                colourIndex: Int(child.colourIndex),
                asleepSince: store.activeSleep(for: child)?.startedAt,
                lastFeed: feed?.startedAt,
                lastFeedText: feed?.brief,
                lastNappy: store.latest(.nappy, for: child)?.startedAt,
                usesNappies: child.uses(.nappy),
                lastWoke: store.lastWoke(for: child),
                today: today(for: child, in: store),
                nextText: next?.line,
                nextAt: next?.at,
                lastSolids: store.latest(.solids, for: child)?.startedAt,
                lastPotty: store.latest(.potty, for: child)?.startedAt,
                usesMilk: child.uses(.bottle) || child.uses(.breastfeed),
                usesSolids: child.uses(.solids),
                pottyTraining: child.pottyTraining && child.uses(.potty))
        }
        WidgetSnapshot(children: rows, updatedAt: .now).save()
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) { ControlCenter.shared.reloadAllControls() }
    }
}
