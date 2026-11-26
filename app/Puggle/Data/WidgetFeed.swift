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

    /// For the Watch's "Sleep today": each stretch asleep that touches today, split around wakings. A sleep
    /// still running ends its last stretch with no end, so the Watch can keep it growing.
    static func sleepsToday(for child: Child, now: Date = .now) -> [WidgetSnapshot.Stretch] {
        let midnight = Calendar.current.startOfDay(for: now)
        let sleeps = (child.events ?? [])
            .filter { $0.kind == .sleep && $0.isLive && ($0.startedAt ?? .distantFuture) <= now && ($0.endedAt ?? now) > midnight }
            .sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
        var result: [WidgetSnapshot.Stretch] = []
        for (index, sleep) in sleeps.enumerated() {
            var pieces = sleep.asleepPieces(to: now, now: now).map { WidgetSnapshot.Stretch(start: $0.start, end: $0.end, sleep: index) }
            if sleep.endedAt == nil, !pieces.isEmpty { pieces[pieces.count - 1].end = nil }
            result += pieces
        }
        return result
    }

    /// For the marks under the Watch's day strip: today's feeds, meals, nappies and potty trips, earliest first.
    static func marksToday(for child: Child, now: Date = .now) -> [WidgetSnapshot.Mark] {
        let midnight = Calendar.current.startOfDay(for: now)
        return (child.events ?? [])
            .filter { $0.isLive }
            .compactMap { event -> WidgetSnapshot.Mark? in
                guard let at = event.startedAt, at >= midnight, at <= now else { return nil }
                switch event.kind {
                case .bottle, .breastfeed: return WidgetSnapshot.Mark(kind: "feed", at: at)
                case .solids: return WidgetSnapshot.Mark(kind: "meal", at: at)
                case .nappy: return WidgetSnapshot.Mark(kind: "nappy", at: at)
                case .potty: return WidgetSnapshot.Mark(kind: "potty", at: at)
                default: return nil
                }
            }
            .sorted { $0.at < $1.at }
    }

    /// For the Watch's "Last 14 days": hours asleep on each of the fourteen whole days before today, oldest
    /// first. A day with no sleep in it is nil, so it is drawn as a gap and left out of the average.
    static func sleepDays(stretches: [DateInterval], now: Date = .now, calendar: Calendar = .current) -> [Double?] {
        let today = calendar.startOfDay(for: now)
        return (1...14).reversed().map { back -> Double? in
            guard let start = calendar.date(byAdding: .day, value: -back, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
            let seconds = stretches.reduce(0.0) { $0 + max(0, min($1.end, end).timeIntervalSince(max($1.start, start))) }
            return seconds >= 60 ? seconds / 3600 : nil
        }
    }

    static func sleepDays(for child: Child, now: Date = .now) -> [Double?] {
        let from = Calendar.current.startOfDay(for: now).addingTimeInterval(-16 * 86400)
        let stretches = (child.events ?? [])
            .filter { $0.kind == .sleep && $0.isLive && ($0.endedAt ?? now) > from }
            .flatMap { $0.asleepPieces(from: from, to: now, now: now) }
        return sleepDays(stretches: stretches, now: now)
    }

    /// Writes the summary for the widgets and sends it to the Watch. Returns it, for the Watch's answer.
    @discardableResult
    static func write(from store: FamilyStore) -> WidgetSnapshot {
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
                pottyTraining: child.pottyTraining && child.uses(.potty),
                feedingSince: store.activeFeed(for: child)?.startedAt,
                feedSide: store.activeFeed(for: child)?.runningSide,
                breastfeeds: child.uses(.breastfeed),
                lastBottleML: store.latest(.bottle, for: child).map { Int($0.amountML) }.flatMap { $0 > 0 ? $0 : nil },
                sleepsToday: sleepsToday(for: child),
                sleepDays: sleepDays(for: child),
                sleepDaysEnd: Calendar.current.startOfDay(for: .now),
                coming: NextUp.all(for: child).sorted { $0.at < $1.at }.map { WidgetSnapshot.Coming(kind: $0.kind.rawValue, at: $0.at) },
                marksToday: marksToday(for: child),
                usesBottle: child.uses(.bottle),
                feedBanked: store.activeFeed(for: child).map { $0.leftSeconds + $0.rightSeconds },
                feedSideSince: store.activeFeed(for: child).flatMap { $0.runningSide == nil ? nil : $0.sideStartedAt })
        }
        let snapshot = WidgetSnapshot(children: rows, updatedAt: .now, ounces: Units.ounces)
        snapshot.save()
        WatchBridge.shared.send(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) { ControlCenter.shared.reloadAllControls() }
        return snapshot
    }
}
