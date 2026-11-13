import Foundation

/// How a child's days have changed with age, worked out from what was logged.
///
/// Plain arithmetic: the same entries always give the same answer. Days run from
/// 05:00 to 05:00, so a night belongs to the evening it started. Days with nothing
/// logged are left out, never counted as zero. Nothing here says what is usual for
/// a child, sets a target, or compares a child with anyone else's.
struct ChildPatterns {
    struct Month: Identifiable, Equatable {
        /// Completed months of age.
        let id: Int
        var days = 0
        /// Minutes after noon, so a bedtime after midnight still sorts after 23:00.
        var bedtime: Int?
        var bedtimeEarly: Int?
        var bedtimeLate: Int?
        /// The middle of each night's longest stretch asleep, in seconds.
        var longestNight: Double?
        var napsPerDay: Double?
        /// The number of naps most days had.
        var usualNaps: Int?
        /// Minutes after midnight that the day's first nap usually started.
        var firstNap: Int?
        var bottlesPerDay: Double?
        var mlPerBottle: Double?
        var nightBottlesPerDay: Double?

        var bedtimeSpread: Int? { bedtimeEarly.flatMap { early in bedtimeLate.map { $0 - early } } }
    }

    /// A finding as a sentence, and a line under it.
    struct Change: Equatable {
        var text: String
        var detail: String?
    }

    var months: [Month] = []
    var changes: [Change] = []
    /// A fact about the last two weeks worth pointing to reading for.
    var prompt: String?
    var ageMonths = 0
    var ageDays = 0
}

enum Patterns {
    /// A month needs this many days with entries before anything is said about it.
    static let enough = 5

    static func make(child: Child, now: Date = .now) -> ChildPatterns {
        guard let birth = child.birthDate else { return ChildPatterns() }
        return make(events: Array(child.events ?? []).filter(\.isLive), birth: birth, now: now)
    }

    static func make(events: [Event], birth: Date, now: Date = .now) -> ChildPatterns {
        let calendar = Calendar.current
        var result = ChildPatterns()
        result.ageMonths = months(from: birth, to: now)
        result.ageDays = max(calendar.dateComponents([.day], from: birth, to: now).day ?? 0, 0)

        /// The day an event belongs to: the date of (time - 5 hours).
        func day(_ date: Date) -> Date { calendar.startOfDay(for: date.addingTimeInterval(-5 * 3600)) }
        func hour(_ date: Date) -> Int { calendar.component(.hour, from: date) }
        func minuteOfDay(_ date: Date) -> Int { hour(date) * 60 + calendar.component(.minute, from: date) }

        struct DayFacts {
            var any = false
            var bedtime: Int?
            var longest: Double = 0
            var sleptAtAll = false
            var naps = 0
            var firstNap: Int?
            var bottles = 0
            var ml = 0.0
            var nightBottles = 0
        }
        var facts: [Date: DayFacts] = [:]
        for event in events {
            guard let start = event.startedAt, start <= now else { continue }
            let key = day(start)
            var f = facts[key] ?? DayFacts()
            f.any = true
            switch event.kind {
            case .sleep:
                guard let end = event.endedAt else { break }
                f.sleptAtAll = true
                let h = hour(start)
                let night = h >= 17 || h < 5
                if night {
                    let longest = event.asleepPieces(now: now).map(\.duration).max() ?? end.timeIntervalSince(start)
                    f.longest = max(f.longest, longest)
                    // Bedtime: the evening's first sleep of two hours or more.
                    if h >= 17, end.timeIntervalSince(start) >= 2 * 3600 {
                        let afterNoon = minuteOfDay(start) - 12 * 60
                        f.bedtime = min(f.bedtime ?? .max, afterNoon)
                    }
                } else {
                    f.naps += 1
                    f.firstNap = min(f.firstNap ?? .max, minuteOfDay(start))
                }
            case .bottle:
                f.bottles += 1
                f.ml += event.amountML
                let h = hour(start)
                if h >= 22 || h < 5 { f.nightBottles += 1 }
            default:
                break
            }
            facts[key] = f
        }

        var byMonth: [Int: [DayFacts]] = [:]
        for (key, f) in facts { byMonth[months(from: birth, to: key), default: []].append(f) }
        for (m, list) in byMonth.sorted(by: { $0.key < $1.key }) where m >= 0 && list.count >= enough {
            var month = ChildPatterns.Month(id: m, days: list.count)
            let beds = list.compactMap(\.bedtime).sorted()
            if beds.count >= enough {
                month.bedtime = median(beds)
                month.bedtimeEarly = quartile(beds, 0.25)
                month.bedtimeLate = quartile(beds, 0.75)
            }
            let nights = list.map(\.longest).filter { $0 > 0 }.sorted()
            if nights.count >= enough { month.longestNight = nights[nights.count / 2] }
            let sleepDays = list.filter(\.sleptAtAll)
            if sleepDays.count >= enough {
                month.napsPerDay = Double(sleepDays.map(\.naps).reduce(0, +)) / Double(sleepDays.count)
                let counts = Dictionary(grouping: sleepDays.map(\.naps), by: { $0 }).mapValues(\.count)
                month.usualNaps = counts.max { $0.value == $1.value ? $0.key > $1.key : $0.value < $1.value }?.key
                let first = sleepDays.compactMap(\.firstNap).sorted()
                if first.count >= enough { month.firstNap = median(first) }
            }
            let bottleDays = list.filter { $0.bottles > 0 }
            if bottleDays.count >= enough {
                let count = bottleDays.map(\.bottles).reduce(0, +)
                month.bottlesPerDay = Double(count) / Double(bottleDays.count)
                let ml = bottleDays.map(\.ml).reduce(0, +)
                if ml > 0 { month.mlPerBottle = ml / Double(count) }
                month.nightBottlesPerDay = Double(bottleDays.map(\.nightBottles).reduce(0, +)) / Double(bottleDays.count)
            }
            result.months.append(month)
        }

        result.changes = changes(result.months, events: events, birth: birth, now: now, day: day, hour: hour)
        // Bedtime in the last two weeks against the two weeks before: said only when it moved 45 minutes or more later.
        let today = day(now)
        func bedtimes(_ from: Int, _ to: Int) -> [Int] {
            facts.compactMap { key, f -> Int? in
                let back = calendar.dateComponents([.day], from: key, to: today).day ?? 0
                return back >= from && back < to ? f.bedtime : nil
            }.sorted()
        }
        let recent = bedtimes(1, 15), before = bedtimes(15, 29)
        if recent.count >= 7, before.count >= 7 {
            let moved = median(recent) - median(before)
            if moved >= 45 {
                result.prompt = "Bedtimes in the last two weeks were about \(Elapsed.short(seconds: Double(round5(moved)) * 60)) later than in the two weeks before."
            }
        }
        return result
    }

    // MARK: Sentences

    private static func changes(_ months: [ChildPatterns.Month], events: [Event], birth: Date, now: Date,
                                day: (Date) -> Date, hour: (Date) -> Int) -> [ChildPatterns.Change] {
        var out: [ChildPatterns.Change] = []

        // Bedtime that has become steady: the last run of months where most bedtimes fell within 40 minutes
        // of each other, and the usual time stayed within 20 minutes of where it is now.
        let withBed = months.filter { $0.bedtimeSpread != nil && $0.bedtime != nil }
        if let last = withBed.last, let now = last.bedtime, (last.bedtimeSpread ?? .max) <= 40 {
            var run: [ChildPatterns.Month] = []
            for m in withBed.reversed() {
                guard (m.bedtimeSpread ?? .max) <= 40, abs((m.bedtime ?? .max) - now) <= 20 else { break }
                run.insert(m, at: 0)
            }
            if run.count >= 2 {
                let usual = run.compactMap(\.bedtime).sorted()[run.count / 2]
                var change = ChildPatterns.Change(text: "Since \(ageWords(run[0].id)), bedtime has usually been around \(clock(afterNoon: round5(usual))).")
                if let before = withBed.last(where: { $0.id < run[0].id }), let wide = before.bedtimeSpread, wide >= 90 {
                    change.detail = "At \(ageWords(before.id)), bedtimes varied by about \(Elapsed.short(seconds: Double(round5(wide)) * 60))."
                }
                out.append(change)
            }
        }

        // The end of night bottles.
        let bottles = events.filter { $0.kind == .bottle }.compactMap(\.startedAt).filter { $0 <= now }.sorted()
        let night = bottles.filter { let h = hour($0); return h >= 22 || h < 5 }
        if night.count >= 10, let lastNight = night.last, now.timeIntervalSince(lastNight) >= 28 * 86_400 {
            let daysSince = Set(bottles.filter { $0 > lastNight }.map(day)).count
            if daysSince >= 14 {
                out.append(.init(text: "The last bottle logged between 22:00 and 05:00 was at \(ageWords(Patterns.months(from: birth, to: lastNight))).",
                                 detail: "Bottles were logged on \(daysSince) days after that, none of them at night."))
            }
        }

        // Naps: the most recent change in how many most days had, if it has held since.
        let naps = months.compactMap { m in m.usualNaps.map { (m.id, $0, m.firstNap) } }
        if naps.count >= 2, let current = naps.last {
            var i = naps.count - 1
            while i > 0, naps[i - 1].1 == current.1 { i -= 1 }
            if i > 0, current.1 > 0 {
                let from = naps[i - 1], to = naps[i]
                func count(_ n: Int) -> String { n == 1 ? "1 nap" : "\(n) naps" }
                var change = ChildPatterns.Change(text: "From \(ageWords(to.0)), most days had \(count(current.1)). Before that, most had \(from.1).")
                if let first = current.2 { change.detail = "\(current.1 == 1 ? "It" : "The first") usually starts around \(clock(minute: round5(first)))." }
                out.append(change)
            }
        }

        // Bottles: the busiest month against the latest.
        let bottleMonths = months.filter { $0.bottlesPerDay != nil && $0.mlPerBottle != nil }
        if let latest = bottleMonths.last, let busiest = bottleMonths.dropLast().max(by: { ($0.bottlesPerDay ?? 0) < ($1.bottlesPerDay ?? 0) }),
           let a = busiest.bottlesPerDay, let b = latest.bottlesPerDay, a - b >= 1 {
            out.append(.init(text: "Bottles went from about \(Int(a.rounded())) a day of \(Units.volume(round10(busiest.mlPerBottle ?? 0))) at \(ageWords(busiest.id)) to about \(Int(b.rounded())) a day of \(Units.volume(round10(latest.mlPerBottle ?? 0))) at \(ageWords(latest.id))."))
        }
        return out
    }

    // MARK: Helpers

    static func months(from birth: Date, to date: Date) -> Int {
        max(Calendar.current.dateComponents([.month], from: birth, to: date).month ?? 0, 0)
    }

    static func ageWords(_ months: Int) -> String {
        if months == 0 { return "under a month" }
        if months < 24 { return months == 1 ? "1 month" : "\(months) months" }
        let years = months / 12, rest = months % 12
        return rest >= 6 ? "\(years)½ years" : "\(years) years"
    }

    static func clock(afterNoon minutes: Int) -> String { clock(minute: (minutes + 12 * 60) % (24 * 60)) }

    static func clock(minute: Int) -> String {
        let start = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 0))
        return start.addingTimeInterval(Double(minute) * 60).formatted(date: .omitted, time: .shortened)
    }

    static func round5(_ minutes: Int) -> Int { Int((Double(minutes) / 5).rounded()) * 5 }
    static func round10(_ ml: Double) -> Double { (ml / 10).rounded() * 10 }

    private static func median(_ sorted: [Int]) -> Int { sorted[sorted.count / 2] }
    private static func quartile(_ sorted: [Int], _ q: Double) -> Int { sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * q))] }
}
