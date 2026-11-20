import Foundation

/// What comes next for a child: the soonest of their next feed, sleep or nappy, guessed from their own last
/// week (Tom, 15 November 2026). "Next feed around 2:30."
///
/// It is a guess from the usual gap, and it is only ever shown ahead of time. Once the time has passed the
/// line goes, so nothing reads as late.
enum NextUp {
    enum Kind: String { case feed, sleep, nappy }

    struct Guess: Equatable {
        let kind: Kind
        let at: Date

        /// "Next feed around 2:30 pm", in the phone's own way of writing the time.
        var line: String { "Next \(kind == .nappy ? Terms.nappyLower : kind.rawValue) around \(at.formatted(date: .omitted, time: .shortened))" }
    }

    /// How far back it looks, and how many gaps it needs before it will say anything.
    static let days = 7.0
    static let enough = 4
    /// How far ahead a guess may be. Past this it is not "next", it is just the day.
    static let ahead = 6.0 * 3600

    /// The usual gap between one start and the next: the middle one of those from the last week. Gaps under
    /// `least` are one feed entered twice or a top-up; gaps over `most` are the night.
    static func usualGap(_ times: [Date], now: Date, least: TimeInterval, most: TimeInterval) -> TimeInterval? {
        let recent = times.filter { $0 > now.addingTimeInterval(-days * 86400) && $0 <= now }.sorted()
        let gaps = zip(recent, recent.dropFirst()).map { $1.timeIntervalSince($0) }.filter { $0 >= least && $0 <= most }.sorted()
        return gaps.count >= enough ? gaps[gaps.count / 2] : nil
    }

    /// The time a guess is shown as: to the nearest five minutes.
    static func rounded(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 300).rounded() * 300)
    }

    /// - Parameters:
    ///   - feeds: when each feed started.
    ///   - sleeps: each sleep's start and end. A running sleep has no end.
    ///   - nappies: when each nappy was changed.
    static func soonest(feeds: [Date], sleeps: [(start: Date, end: Date?)], nappies: [Date], now: Date) -> Guess? {
        var guesses: [Guess] = []
        func add(_ kind: Kind, after last: Date?, gap: TimeInterval?) {
            guard let last, let gap else { return }
            let at = rounded(last.addingTimeInterval(gap))
            if at > now, at.timeIntervalSince(now) <= ahead { guesses.append(Guess(kind: kind, at: at)) }
        }
        let feedsSoFar = feeds.filter { $0 <= now }
        add(.feed, after: feedsSoFar.max(), gap: usualGap(feeds, now: now, least: 45 * 60, most: 6 * 3600))
        let nappiesSoFar = nappies.filter { $0 <= now }
        add(.nappy, after: nappiesSoFar.max(), gap: usualGap(nappies, now: now, least: 30 * 60, most: 6 * 3600))

        // Sleep: how long they are usually awake before the next one. Not while they are asleep.
        let past = sleeps.filter { $0.start <= now }.sorted { $0.start < $1.start }
        if let last = past.last, let woke = last.end, woke <= now {
            let from = now.addingTimeInterval(-days * 86400)
            let awake = zip(past, past.dropFirst())
                .compactMap { before, after -> TimeInterval? in
                    guard let end = before.end, after.start > from else { return nil }
                    return after.start.timeIntervalSince(end)
                }
                .filter { $0 >= 30 * 60 && $0 <= 8 * 3600 }
                .sorted()
            add(.sleep, after: woke, gap: awake.count >= enough ? awake[awake.count / 2] : nil)
        }
        return guesses.min { $0.at < $1.at }
    }

    static func soonest(for child: Child, now: Date = .now) -> Guess? {
        // Only the last week and a day is looked at, so a long history costs nothing more.
        let from = now.addingTimeInterval(-(days + 1) * 86400)
        let events = (child.events ?? []).filter { ($0.startedAt ?? .distantPast) > from && $0.isLive }
        let feeds = events.filter { $0.kind == .bottle || $0.kind == .breastfeed }.compactMap(\.startedAt)
        let sleeps = events.filter { $0.kind == .sleep }.compactMap { event in event.startedAt.map { (start: $0, end: event.endedAt) } }
        let nappies = child.uses(.nappy) ? events.filter { $0.kind == .nappy }.compactMap(\.startedAt) : []
        return soonest(feeds: feeds, sleeps: sleeps, nappies: nappies, now: now)
    }
}
