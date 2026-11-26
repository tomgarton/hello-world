import Foundation

/// The arithmetic behind Insights (16 November 2026): a child's days set against that child's own recent
/// past. After Gentler Streak's Activity Path, which draws a band of what is usual for you and puts each day
/// on it as a dot, with no target. Nothing here knows what is usual for children in general, and nothing is
/// compared with anyone else's child.
enum InsightStats {
    /// What one day held.
    struct Day: Identifiable, Equatable {
        let id: Date
        /// Seconds asleep that fell in this day.
        var sleep = 0.0
        /// Of that, the seconds between 7 in the evening and 7 in the morning.
        var nightSleep = 0.0
        var sleeps = 0
        var bottleML = 0.0
        var bottles = 0
        var breastfeeds = 0
        var solids = 0
        var nappies = 0
        var wet = 0
        var dirty = 0
        var potty = 0
        var other = 0
        /// The longest unbroken stretch asleep in the night that ended this morning (6 pm the day before to noon).
        var longestNight = 0.0

        var feeds: Int { bottles + breastfeeds }
        var daySleep: Double { max(sleep - nightSleep, 0) }
        var any: Bool { sleep > 0 || feeds > 0 || solids > 0 || nappies > 0 || potty > 0 || other > 0 }
        /// Any of the everyday things: sleep, a feed, food, a nappy or the potty.
        var everyday: Bool { sleep > 0 || feeds > 0 || solids > 0 || nappies > 0 || potty > 0 }
    }

    /// One entry, reduced to what the sums need, so they can be tested without a store.
    struct Entry {
        enum Kind { case sleep, bottle, breastfeed, solids, nappy, potty, other }
        let kind: Kind
        let start: Date
        /// A sleep's pieces asleep, wakings left out. Empty for anything else.
        var asleep: [DateInterval] = []
        var ml = 0.0
        var detail = ""
    }

    /// Every day from `from` up to and including the day `to` falls on, in order, in one pass over the entries.
    static func days(_ entries: [Entry], from: Date, to: Date, calendar: Calendar = .current) -> [Day] {
        let first = calendar.startOfDay(for: from), last = calendar.startOfDay(for: to)
        var days: [Date: Day] = [:]
        var order: [Date] = []
        var cursor = first
        while cursor <= last {
            days[cursor] = Day(id: cursor)
            order.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        /// The seconds of a stretch that fall at night: 19:00 to 07:00.
        func night(_ piece: DateInterval, in day: Date) -> Double {
            guard let seven = calendar.date(byAdding: .hour, value: 7, to: day),
                  let evening = calendar.date(byAdding: .hour, value: 19, to: day),
                  let end = calendar.date(byAdding: .day, value: 1, to: day) else { return 0 }
            func overlap(_ a: Date, _ b: Date) -> Double { max(0, min(piece.end, b).timeIntervalSince(max(piece.start, a))) }
            return overlap(day, seven) + overlap(evening, end)
        }
        for entry in entries {
            if entry.kind == .sleep {
                let started = calendar.startOfDay(for: entry.start)
                if days[started] != nil { days[started]?.sleeps += 1 }
                for piece in entry.asleep {
                    // A stretch is shared out over the days it crosses.
                    var day = calendar.startOfDay(for: piece.start)
                    while day < piece.end {
                        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                        let from = max(piece.start, day), until = min(piece.end, next)
                        guard until > from else { day = next; continue }
                        let part = DateInterval(start: from, end: until)
                        if days[day] != nil {
                            days[day]?.sleep += part.duration
                            days[day]?.nightSleep += night(part, in: day)
                        }
                        day = next
                    }
                    // The night it belongs to: the morning after 6 pm, up to noon.
                    let morning = calendar.startOfDay(for: piece.start.addingTimeInterval(6 * 3600))
                    if let noon = calendar.date(byAdding: .hour, value: 12, to: morning), piece.start < noon, days[morning] != nil {
                        let within = min(piece.end, noon).timeIntervalSince(piece.start)
                        let held = days[morning]?.longestNight ?? 0
                        days[morning]?.longestNight = max(held, within)
                    }
                }
                continue
            }
            let day = calendar.startOfDay(for: entry.start)
            guard days[day] != nil else { continue }
            switch entry.kind {
            case .bottle: days[day]?.bottles += 1; days[day]?.bottleML += entry.ml
            case .breastfeed: days[day]?.breastfeeds += 1
            case .solids: days[day]?.solids += 1
            case .nappy:
                days[day]?.nappies += 1
                let what = entry.detail.lowercased()
                if what.contains("wet") || what.contains("both") { days[day]?.wet += 1 }
                if what.contains("dirty") || what.contains("both") { days[day]?.dirty += 1 }
            case .potty: days[day]?.potty += 1
            case .other: days[day]?.other += 1
            case .sleep: break
            }
        }
        return order.compactMap { days[$0] }
    }

    // MARK: Usual

    /// How many earlier days there must be before anything is called usual.
    static let enough = 7

    /// The middle half of some earlier days' values: from a quarter of the way up to three quarters. Days with
    /// nothing are left out, never counted as nought. Nil until there are enough days to say.
    static func usual(_ values: [Double]) -> ClosedRange<Double>? {
        let sorted = values.filter { $0 > 0 }.sorted()
        guard sorted.count >= enough else { return nil }
        func at(_ share: Double) -> Double {
            let place = share * Double(sorted.count - 1)
            let low = Int(place.rounded(.down)), high = min(low + 1, sorted.count - 1)
            return sorted[low] + (sorted[high] - sorted[low]) * (place - Double(low))
        }
        return at(0.25)...at(0.75)
    }

    enum Standing: Equatable { case within, more, less }

    /// Where a value stands against the usual range. A hair outside still counts as within.
    static func standing(_ value: Double, in usual: ClosedRange<Double>) -> Standing {
        let slack = (usual.upperBound - usual.lowerBound) * 0.1
        if value > usual.upperBound + slack { return .more }
        if value < usual.lowerBound - slack { return .less }
        return .within
    }

    /// The average of the days that had any, leaving out today, which is not over yet.
    static func average(_ values: [Double], leavingOutLast: Bool) -> Double? {
        let some = (leavingOutLast ? Array(values.dropLast()) : values).filter { $0 > 0 }
        return some.isEmpty ? nil : some.reduce(0, +) / Double(some.count)
    }

    enum Compared: Equatable { case same, more(Double), less(Double) }

    /// This stretch against the one before. Within a twentieth either way is "about the same".
    static func compare(_ now: Double, with before: Double?) -> Compared? {
        guard let before, before > 0, now > 0 else { return nil }
        let change = now - before
        if abs(change) < before * 0.05 { return .same }
        return change > 0 ? .more(change) : .less(-change)
    }

    // MARK: A usual day

    /// The day in half hours. For each, the share of days the child was asleep in it, and the share with a feed.
    struct UsualDay: Equatable {
        static let slots = 48
        var asleep = [Double](repeating: 0, count: slots)
        var fed = [Double](repeating: 0, count: slots)
        var days = 0

        /// Runs of half hours asleep on at least half of the days: where they start and end, in hours, and
        /// how sure (the average share).
        var sleepRuns: [(from: Double, to: Double, share: Double)] {
            var runs: [(Double, Double, Double)] = []
            var start: Int?
            var total = 0.0
            // Twice round, so a night that crosses midnight is one run.
            for step in 0..<(Self.slots * 2) {
                let slot = step % Self.slots
                if asleep[slot] >= 0.5 {
                    if start == nil { start = step; total = 0 }
                    total += asleep[slot]
                } else if let began = start {
                    // A run found at the very start that carries on from the evening before is the tail of that
                    // night, and is met again, whole, the second time round.
                    let tail = began == 0 && asleep[Self.slots - 1] >= 0.5
                    if began < Self.slots, !tail { runs.append((Double(began) / 2, Double(step) / 2, total / Double(step - began))) }
                    start = nil
                }
                // A child asleep all round the clock is not a finding.
                if let began = start, step - began >= Self.slots { return [] }
            }
            return runs.map { (from: $0.0, to: $0.1, share: $0.2) }
        }

        /// The hours feeds usually fall at: the middle of each run of half hours with a feed on at least a
        /// third of days.
        var feedTimes: [Double] {
            var times: [Double] = []
            var run: [Int] = []
            for slot in 0..<Self.slots {
                if fed[slot] >= 1.0 / 3 { run.append(slot) } else if !run.isEmpty {
                    times.append((Double(run.first!) + Double(run.last! + 1)) / 4)
                    run = []
                }
            }
            if !run.isEmpty { times.append((Double(run.first!) + Double(run.last! + 1)) / 4) }
            return times
        }

        func asleep(atHour hour: Double) -> Bool { asleep[Int(hour * 2) % Self.slots] >= 0.5 }
    }

    /// The child's usual day, from the days in `from..<to` that have anything logged.
    static func usualDay(_ entries: [Entry], from: Date, to: Date, calendar: Calendar = .current) -> UsualDay {
        let first = calendar.startOfDay(for: from)
        var sleepDays = [Set<Int>](repeating: [], count: UsualDay.slots)
        var feedDays = [Set<Int>](repeating: [], count: UsualDay.slots)
        var seen = Set<Int>()
        func dayNumber(_ date: Date) -> Int { calendar.dateComponents([.day], from: first, to: calendar.startOfDay(for: date)).day ?? 0 }
        func slot(_ date: Date) -> Int {
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            return ((parts.hour ?? 0) * 60 + (parts.minute ?? 0)) / 30 % UsualDay.slots
        }
        for entry in entries {
            if entry.kind == .sleep {
                for piece in entry.asleep where piece.end > from && piece.start < to {
                    // Step through the stretch a half hour at a time.
                    var moment = max(piece.start, from)
                    let end = min(piece.end, to)
                    while moment < end {
                        sleepDays[slot(moment)].insert(dayNumber(moment))
                        seen.insert(dayNumber(moment))
                        moment = moment.addingTimeInterval(1800)
                    }
                }
            } else if entry.start >= from, entry.start < to {
                seen.insert(dayNumber(entry.start))
                if entry.kind == .bottle || entry.kind == .breastfeed { feedDays[slot(entry.start)].insert(dayNumber(entry.start)) }
            }
        }
        var result = UsualDay()
        result.days = seen.count
        guard !seen.isEmpty else { return result }
        for index in 0..<UsualDay.slots {
            result.asleep[index] = Double(sleepDays[index].count) / Double(seen.count)
            result.fed[index] = Double(feedDays[index].count) / Double(seen.count)
        }
        return result
    }
}

extension InsightStats.Entry {
    /// An entry from the store, with a sleep's wakings already taken out.
    init?(_ event: Event, now: Date = .now) {
        guard let start = event.startedAt else { return nil }
        let kind: Kind = switch event.kind {
        case .sleep: .sleep
        case .bottle: .bottle
        case .breastfeed: .breastfeed
        case .solids: .solids
        case .nappy: .nappy
        case .potty: .potty
        default: .other
        }
        self.init(kind: kind, start: start, asleep: kind == .sleep ? event.asleepPieces(now: now) : [],
                  ml: event.amountML, detail: event.detail ?? "")
    }
}
