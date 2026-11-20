import CoreData
import SwiftUI

// Looking after (Tom, 17 November 2026): baths, brushing teeth, nails, haircuts, the dentist, the doctor, and
// anything a family adds of its own. Each is logged as a `care` entry whose `detail` is the item's key, for
// one child or several at once. The dentist and the doctor can be booked ahead: a booked visit is a care entry
// with its date and `dose` set to "booked", until it is marked done. How often each happens is learned from
// what is logged, unless a parent sets it; nothing is ever "overdue". Brushing teeth earns a stamp.

/// One thing a family looks after.
struct CareItem: Identifiable, Hashable {
    let key: String
    var name: String
    /// An activity icon in the asset catalogue ("icon-bath"), or an SF Symbol.
    var icon: String
    var iconIsAsset: Bool
    /// Booked ahead, then marked done.
    var appointment = false
    /// Earns a stamp, as a potty try does.
    var stamps = false
    /// One the family added.
    var own = false

    var id: String { key }

    @ViewBuilder func image(plain: Bool = true) -> some View {
        if iconIsAsset { Image(icon + (plain ? "-plain" : "")).resizable().scaledToFit() }
        else { Image(systemName: icon).resizable().scaledToFit() }
    }

    static let bath = CareItem(key: "bath", name: "Bath", icon: "icon-bath", iconIsAsset: true)
    static let brushing = CareItem(key: "brushing", name: "Brushing teeth", icon: "icon-toothbrush", iconIsAsset: true, stamps: true)
    static let nails = CareItem(key: "nails", name: "Nails", icon: "icon-scissors", iconIsAsset: true)
    static let haircut = CareItem(key: "haircut", name: "Haircut", icon: "comb", iconIsAsset: false)
    static let dentist = CareItem(key: "dentist", name: "Dentist", icon: "icon-teeth", iconIsAsset: true, appointment: true)
    static let doctor = CareItem(key: "doctor", name: "Doctor", icon: "stethoscope", iconIsAsset: false, appointment: true)

    static let builtIn: [CareItem] = [.bath, .brushing, .nails, .haircut, .dentist, .doctor]

    /// The name to show for an entry, from its key alone: a built-in one's name, or the family's own as typed
    /// (kept in lower case in the key, so given a capital again).
    static func name(forKey key: String?) -> String {
        guard let key else { return "Looking after" }
        if let item = builtIn.first(where: { $0.key == key }) { return item.name }
        let own = key.hasPrefix("own.") ? String(key.dropFirst(4)) : key
        return own.prefix(1).uppercased() + own.dropFirst()
    }

    /// Icons to choose from for one of the family's own.
    static let ownIcons = ["star", "drop", "sun.max", "figure.pool.swim", "ear", "eye", "music.note", "book", "leaf", "heart"]

    /// A starting gap in days, before anything is learned: about right for most children, never a rule.
    func startingGap(ageMonths: Int) -> Double? {
        switch key {
        case "bath": ageMonths < 12 ? 2 : 1
        case "brushing": 0.5
        case "nails": ageMonths < 12 ? 7 : 10
        case "haircut": 42
        case "dentist": 182
        default: nil
        }
    }
}

extension Event {
    static let booked = "booked"
    /// A visit booked ahead and not yet marked done.
    var isBooked: Bool { kind == .care && dose == Self.booked }
    /// Which care item, for a care entry.
    var careKey: String? { kind == .care ? detail : nil }
}

/// How often something happens, and where the number came from.
struct CareGap: Equatable {
    enum Source: Equatable { case set, learned, starting }
    let days: Double
    let source: Source

    /// "Every 9 days", "Twice a day", "Every 6 weeks", "Every 6 months".
    var text: String {
        if days <= 0.6 { return "Twice a day" }
        if days < 1.5 { return "Every day" }
        if days < 14 { return "Every \(Int(days.rounded())) days" }
        if days < 70 { return "Every \(Int((days / 7).rounded())) weeks" }
        return "Every \(Int((days / 30.4).rounded())) months"
    }
}

extension FamilyStore {
    /// Everything the family looks after: the six built in, then their own.
    func careItems() -> [CareItem] {
        let own = guides(.care).filter { guide in !CareItem.builtIn.contains { $0.key == guide.key } }
            .sorted { ($0.readAt ?? .distantPast) < ($1.readAt ?? .distantPast) }
            .compactMap { guide -> CareItem? in
                guard let key = guide.key, let name = guide.name else { return nil }
                return CareItem(key: key, name: name, icon: guide.strength ?? "star", iconIsAsset: false, own: true)
            }
        return CareItem.builtIn + own
    }

    func careItem(_ key: String?) -> CareItem? {
        guard let key else { return nil }
        return careItems().first { $0.key == key }
    }

    /// Done entries for one item, oldest first.
    func careDone(_ key: String, for child: Child) -> [Event] {
        (child.events ?? [])
            .filter { $0.kind == .care && $0.detail == key && !$0.isBooked && $0.isLive }
            .sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    func lastCare(_ key: String, for child: Child) -> Event? { careDone(key, for: child).last }

    /// The next visit booked, if there is one.
    func booked(_ key: String, for child: Child) -> Event? {
        (child.events ?? [])
            .filter { $0.isBooked && $0.detail == key && $0.isLive }
            .min { ($0.startedAt ?? .distantFuture) < ($1.startedAt ?? .distantFuture) }
    }

    /// Every care entry for a child in one pass, by item: done ones oldest first, and the next booked.
    /// For Today, which would otherwise go through all the child's entries once per item, per line.
    func careIndex(for child: Child) -> [String: (done: [Event], booked: Event?)] {
        var index: [String: (done: [Event], booked: Event?)] = [:]
        for event in child.events ?? [] where event.kind == .care && event.isLive {
            guard let key = event.detail else { continue }
            if event.isBooked {
                let kept = index[key]?.booked
                if kept == nil || (event.startedAt ?? .distantFuture) < (kept?.startedAt ?? .distantFuture) { index[key, default: ([], nil)].booked = event }
            } else {
                index[key, default: ([], nil)].done.append(event)
            }
        }
        for key in index.keys { index[key]?.done.sort { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) } }
        return index
    }

    /// How often it happens for this child: as a parent set it, else as learned, else a starting guess.
    /// `done` is the child's done entries for the item, if already to hand.
    func careGap(_ item: CareItem, for child: Child, done: [Event]? = nil) -> CareGap? {
        if let set = guides(.care).first(where: { $0.key == item.key }), set.gapHours > 0 {
            return CareGap(days: set.gapHours / 24, source: .set)
        }
        if let learned = Self.learnedGap((done ?? careDone(item.key, for: child)).compactMap(\.startedAt)) {
            return CareGap(days: learned, source: .learned)
        }
        return item.startingGap(ageMonths: child.ageMonths).map { CareGap(days: $0, source: .starting) }
    }

    /// The middle of the last few gaps, in days, once there are three or more entries. Times on the same day
    /// count as one, except for something done twice a day.
    static func learnedGap(_ dates: [Date]) -> Double? {
        let sorted = dates.sorted()
        guard sorted.count >= 3 else { return nil }
        let gaps = zip(sorted.dropFirst(), sorted).map { $0.timeIntervalSince($1) / 86_400 }.suffix(6).sorted()
        let middle = gaps.count.isMultiple(of: 2) ? (gaps[gaps.count / 2 - 1] + gaps[gaps.count / 2]) / 2 : gaps[gaps.count / 2]
        return max(middle, 0.25)
    }

    /// Sets how often something happens, for the whole family, or clears it to be learned again. Parents only.
    func setCareGap(_ item: CareItem, days: Double?) {
        guard isParent else { return }
        let guide = careGuide(item)
        guide.gapHours = (days ?? 0) * 24
        guide.updatedAt = .now
        persistence.save()
    }

    /// Adds one of the family's own. Parents only.
    @discardableResult
    func addCareItem(name: String, icon: String) -> CareItem? {
        let name = name.trimmingCharacters(in: .whitespaces)
        let key = "own." + MedicineRules.key(name)
        guard isParent, !name.isEmpty, careItem(key) == nil else { return nil }
        let item = CareItem(key: key, name: name, icon: icon, iconIsAsset: false, own: true)
        let guide = careGuide(item)
        guide.name = name
        guide.strength = icon
        persistence.save()
        return item
    }

    func removeCareItem(_ item: CareItem) {
        guard isParent, item.own, let guide = guides(.care).first(where: { $0.key == item.key }) else { return }
        deleteGuide(guide)
    }

    private func careGuide(_ item: CareItem) -> Guide {
        if let found = guides(.care).first(where: { $0.key == item.key }) { return found }
        let family = currentFamily()
        let new = Guide(context: context)
        place(new, with: family)
        new.id = UUID()
        new.family = family
        new.kindRaw = GuideKind.care.rawValue
        new.key = item.key
        new.name = item.name
        new.readAt = .now
        new.updatedAt = .now
        return new
    }

    /// A booked visit, marked done: it happened when it was booked for, unless that is still to come.
    func markDone(_ event: Event, at now: Date = .now) {
        guard event.isBooked else { return }
        event.dose = nil
        if let at = event.startedAt, at > now { event.startedAt = now }
        saveEdit(event)
    }
}

/// What the Today card says about one item for one child.
enum CareLine {
    /// "Yesterday", "Today", "9 days ago", "3 weeks ago", "12 March".
    static func since(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        switch days {
        case ..<1: return "Today"
        case 1: return "Yesterday"
        case 2..<14: return "\(days) days ago"
        case 14..<60: return "\(days / 7) weeks ago"
        default: return date.formatted(.dateTime.day().month(.wide))
        }
    }

    /// "Booked · Tuesday 10:30", "Booked · 12 March".
    static func booked(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        let time = date.formatted(date: .omitted, time: .shortened)
        switch days {
        case ..<1: return "Booked · today \(time)"
        case 1: return "Booked · tomorrow \(time)"
        case 2..<7: return "Booked · \(date.formatted(.dateTime.weekday(.wide))) \(time)"
        default: return "Booked · \(date.formatted(.dateTime.day().month(.wide)))"
        }
    }

    /// Past the usual gap by a quarter or more. Shown as a soft mark, never as "overdue".
    static func pastUsual(last: Date, gap: CareGap?, now: Date = .now) -> Bool {
        guard let gap, gap.days >= 1 else { return false }
        return now.timeIntervalSince(last) / 86_400 >= gap.days * 1.25
    }
}
