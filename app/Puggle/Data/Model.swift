import CoreData

// The data model is built in code so it is easy to read and review.
// CloudKit rules: every attribute is optional or has a default, every
// relationship is optional and has an inverse, and there are no unique
// constraints.

@objc(Family)
final class Family: NSManagedObject, Identifiable {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var createdAt: Date?
    @NSManaged var children: Set<Child>?
    @NSManaged var events: Set<Event>?
}

@objc(Child)
final class Child: NSManagedObject, Identifiable {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var birthDate: Date?
    @NSManaged var colourIndex: Int16
    @NSManaged var createdAt: Date?
    /// Answers to the setup questions. `feedingRaw` is nil for children added
    /// before the questions existed; they keep every tile.
    @NSManaged var feedingRaw: String?
    @NSManaged var pottyTraining: Bool
    /// Hidden from Today, with all their history kept. Can be undone.
    @NSManaged var archived: Bool
    @NSManaged var family: Family?
    @NSManaged var events: Set<Event>?
}

/// "How do they feed?", asked once per child. It decides which tiles they get.
enum Feeding: String, CaseIterable, Identifiable {
    case bottle, breast, both, neither

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bottle: "Bottle"
        case .breast: "Breastfeeding"
        case .both: "Both"
        case .neither: "Neither now"
        }
    }
}

@objc(Event)
final class Event: NSManagedObject, Identifiable {
    @NSManaged var id: UUID?
    @NSManaged var kindRaw: String?
    @NSManaged var startedAt: Date?
    @NSManaged var endedAt: Date?
    @NSManaged var amountML: Double
    @NSManaged var detail: String?
    @NSManaged var note: String?
    /// Medicine: the dose as the parent wrote it ("5 ml", "1 tablet").
    @NSManaged var dose: String?
    /// Temperature in °C, or weight in grams.
    @NSManaged var value: Double
    /// Potty: the sticker the child chose, if any.
    @NSManaged var sticker: String?
    /// Breastfeed timers: time on each side so far, which side is running
    /// (nil when paused or finished) and when that side was started.
    @NSManaged var leftSeconds: Double
    @NSManaged var rightSeconds: Double
    @NSManaged var runningSide: String?
    @NSManaged var sideStartedAt: Date?
    /// The name of whoever added the entry, from their Settings. Optional.
    @NSManaged var loggedBy: String?
    @NSManaged var createdAt: Date?
    @NSManaged var family: Family?
    @NSManaged var children: Set<Child>?
}

enum EventKind: String, CaseIterable, Identifiable {
    case bottle, breastfeed, solids, sleep, nappy, potty, note
    case weight, medicine, temperature, vaccination, milestone

    /// Health entries share one tile on Today.
    static let health: [EventKind] = [.medicine, .temperature, .vaccination]
    var isHealth: Bool { Self.health.contains(self) }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bottle: "Bottle"
        case .breastfeed: "Breastfeed"
        case .solids: "Solids"
        case .sleep: "Sleep"
        case .nappy: "Nappy"
        case .potty: "Potty"
        case .note: "Note"
        case .weight: "Weight"
        case .medicine: "Medicine"
        case .temperature: "Temperature"
        case .vaccination: "Vaccination"
        case .milestone: "Milestone"
        }
    }

    /// SF Symbol stand-ins until the custom Puggle activity icons are added.
    var symbol: String {
        switch self {
        case .bottle: "waterbottle"
        case .breastfeed: "heart"
        case .solids: "fork.knife"
        case .sleep: "moon"
        case .nappy: "drop"
        case .potty: "toilet"
        case .note: "note.text"
        case .weight: "scalemass"
        case .medicine: "pills"
        case .temperature: "thermometer.medium"
        case .vaccination: "syringe"
        case .milestone: "star"
        }
    }
}

extension Event {
    var kind: EventKind {
        get { EventKind(rawValue: kindRaw ?? "") ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    /// False once the entry has been deleted, here or on another phone.
    var isLive: Bool { !isDeleted && managedObjectContext != nil }

    var sortedChildren: [Child] {
        (children ?? []).sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    /// A breastfeed timer that has not been finished.
    var isRunningFeed: Bool { kind == .breastfeed && endedAt == nil }

    /// Time on one side so far, counting the stretch that is running now.
    func feedSeconds(_ side: String, now: Date = .now) -> Double {
        let banked = side == "Left" ? leftSeconds : rightSeconds
        guard runningSide == side, let since = sideStartedAt else { return banked }
        return banked + max(now.timeIntervalSince(since), 0)
    }

    /// The shortest useful form, for a child's row on Today: "Bottle · 150 ml".
    /// The rest (which milk, which side) is one tap away in the entry.
    var brief: String {
        switch kind {
        case .bottle:
            return amountML > 0 ? "Bottle · \(Int(amountML)) ml" : "Bottle"
        case .breastfeed:
            let timed = leftSeconds + rightSeconds
            if timed > 0 { return "Breastfeed · \(Elapsed.minutes(timed))" }
            if let start = startedAt, let end = endedAt { return "Breastfeed · \(Elapsed.short(from: start, to: end))" }
            return "Breastfeed"
        case .sleep:
            if let start = startedAt, let end = endedAt { return "Slept · \(Elapsed.short(from: start, to: end))" }
            return "Asleep"
        case .nappy, .potty, .solids:
            return (detail ?? "").isEmpty ? kind.title : "\(kind.title) · \(detail!.lowercased())"
        default:
            return summary
        }
    }

    /// A short, human summary for timelines: "Bottle, 150 ml formula".
    var summary: String {
        switch kind {
        case .bottle:
            let ml = amountML > 0 ? ", \(Int(amountML)) ml" : ""
            let what = (detail ?? "").isEmpty ? "" : " \(detail!.lowercased())"
            return "Bottle\(ml)\(what)"
        case .sleep:
            if let start = startedAt, let end = endedAt {
                return "Slept \(Elapsed.short(from: start, to: end))"
            }
            return "Asleep"
        case .breastfeed:
            if endedAt == nil { return "Feeding" }
            if leftSeconds > 0 || rightSeconds > 0 {
                var parts: [String] = []
                if leftSeconds > 0 { parts.append("left \(Elapsed.minutes(leftSeconds))") }
                if rightSeconds > 0 { parts.append("right \(Elapsed.minutes(rightSeconds))") }
                return "Breastfeed, " + parts.joined(separator: ", ")
            }
            let side = (detail ?? "").isEmpty ? "" : ", \(detail!.lowercased())"
            let length = (startedAt.flatMap { start in endedAt.map { Elapsed.short(from: start, to: $0) } }).map { ", \($0)" } ?? ""
            return "Breastfeed\(side)\(length)"
        case .nappy, .potty, .solids:
            let what = (detail ?? "").isEmpty ? "" : ", \(detail!.lowercased())"
            return "\(kind.title)\(what)"
        case .note:
            return note ?? "Note"
        case .weight:
            return "Weight \(Int(value).formatted()) g"
        case .medicine:
            let name = (detail ?? "").isEmpty ? "Medicine" : detail!
            let amount = (dose ?? "").isEmpty ? "" : ", \(dose!)"
            return "\(name)\(amount)"
        case .temperature:
            let place = (detail ?? "").isEmpty ? "" : ", \(detail!.lowercased())"
            return "Temperature \(value.formatted(.number.precision(.fractionLength(1)))) °C\(place)"
        case .vaccination:
            return (detail ?? "").isEmpty ? "Vaccination" : "Vaccination, \(detail!)"
        case .milestone:
            return (detail ?? "").isEmpty ? "Milestone" : detail!
        }
    }
}

extension Child {
    var feeding: Feeding? {
        get { feedingRaw.flatMap(Feeding.init(rawValue:)) }
        set { feedingRaw = newValue?.rawValue }
    }

    var ageMonths: Int {
        guard let birth = birthDate else { return 0 }
        return max(Calendar.current.dateComponents([.month], from: birth, to: .now).month ?? 0, 0)
    }

    /// Whether this activity belongs on this child's Today. Follows the setup
    /// answers and their age; a child who was never asked keeps everything.
    func uses(_ kind: EventKind) -> Bool {
        switch kind {
        case .bottle: return feeding == nil || feeding == .bottle || feeding == .both
        case .breastfeed: return feeding == nil || feeding == .breast || feeding == .both
        case .solids: return ageMonths >= 4
        case .nappy: return !pottyTraining || ageMonths < 36
        case .potty: return pottyTraining || feeding == nil
        case .weight: return ageMonths < 24
        case .sleep, .note, .medicine, .temperature, .vaccination, .milestone: return true
        }
    }

    var displayName: String { name ?? "Child" }
    var initial: String { String(displayName.prefix(1)).uppercased() }

    /// Compact age for tight spots: "6mo", "1y 3mo", "3w", "2½".
    var ageText: String { age(.abbreviated) }

    /// Their age on a given day, spelled out: for milestones and measurements.
    func ageText(at date: Date) -> String { age(.full, at: date) }

    /// Spelled-out age where there is room: "6 months", "3 weeks", "2½ years".
    var ageTextFull: String { age(.full) }

    /// Uses Apple's formatter so the wording follows the phone's language.
    /// The one exception is the half year for children of two and over.
    private func age(_ style: DateComponentsFormatter.UnitsStyle, at date: Date = .now) -> String {
        guard let birth = birthDate else { return "" }
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: birth, to: max(date, birth))
        let years = comps.year ?? 0, months = comps.month ?? 0

        if years >= 2, months >= 6 {
            return style == .full ? "\(years)½ years" : "\(years)½"
        }

        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = style
        var parts = DateComponents()
        if years >= 2 {
            formatter.allowedUnits = [.year]
            parts.year = years
        } else if years * 12 + months >= 1 {
            formatter.allowedUnits = [.year, .month]
            parts.year = years
            parts.month = months
        } else if let weeks = comps.weekOfYear, weeks >= 1 {
            formatter.allowedUnits = [.weekOfMonth]
            parts.weekOfMonth = weeks
        } else {
            formatter.allowedUnits = [.day]
            parts.day = max(comps.day ?? 0, 0)
        }
        return formatter.string(from: parts) ?? ""
    }
}

enum Elapsed {
    static func short(from start: Date, to end: Date) -> String {
        let minutes = max(Int(end.timeIntervalSince(start) / 60), 0)
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h \(String(format: "%02d", m))m" : "\(m) min"
    }

    /// How long ago, kept short: "just now", "8 min ago", "1h 05m ago", then the day.
    static func ago(_ date: Date, now: Date = .now) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 24 * 3600 { return "\(short(from: date, to: now)) ago" }
        return date.formatted(.dateTime.weekday(.wide).hour().minute())
    }

    /// Whole minutes for a length in seconds, never less than one: "8 min".
    static func minutes(_ seconds: Double) -> String {
        "\(max(Int((seconds / 60).rounded()), 1)) min"
    }

    /// A running clock: "4:05".
    static func clock(_ seconds: Double) -> String {
        let total = max(Int(seconds), 0)
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }
}

enum PuggleModel {
    static let shared: NSManagedObjectModel = build()

    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        if let defaultValue { a.defaultValue = defaultValue }
        return a
    }

    private static func relationship(_ name: String, to entity: NSEntityDescription, toMany: Bool) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name
        r.destinationEntity = entity
        r.isOptional = true
        r.minCount = 0
        r.maxCount = toMany ? 0 : 1
        r.deleteRule = .nullifyDeleteRule
        return r
    }

    private static func build() -> NSManagedObjectModel {
        let family = NSEntityDescription()
        family.name = "Family"
        family.managedObjectClassName = NSStringFromClass(Family.self)

        let child = NSEntityDescription()
        child.name = "Child"
        child.managedObjectClassName = NSStringFromClass(Child.self)

        let event = NSEntityDescription()
        event.name = "Event"
        event.managedObjectClassName = NSStringFromClass(Event.self)

        // Family
        let familyChildren = relationship("children", to: child, toMany: true)
        let familyEvents = relationship("events", to: event, toMany: true)
        familyChildren.deleteRule = .cascadeDeleteRule
        familyEvents.deleteRule = .cascadeDeleteRule

        // Child
        let childFamily = relationship("family", to: family, toMany: false)
        let childEvents = relationship("events", to: event, toMany: true)

        // Event
        let eventFamily = relationship("family", to: family, toMany: false)
        let eventChildren = relationship("children", to: child, toMany: true)

        familyChildren.inverseRelationship = childFamily
        childFamily.inverseRelationship = familyChildren
        familyEvents.inverseRelationship = eventFamily
        eventFamily.inverseRelationship = familyEvents
        childEvents.inverseRelationship = eventChildren
        eventChildren.inverseRelationship = childEvents

        family.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            familyChildren, familyEvents,
        ]
        child.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("birthDate", .dateAttributeType),
            attribute("colourIndex", .integer16AttributeType, optional: false, defaultValue: 0),
            attribute("createdAt", .dateAttributeType),
            attribute("feedingRaw", .stringAttributeType),
            attribute("pottyTraining", .booleanAttributeType, optional: false, defaultValue: false),
            attribute("archived", .booleanAttributeType, optional: false, defaultValue: false),
            childFamily, childEvents,
        ]
        event.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("kindRaw", .stringAttributeType),
            attribute("startedAt", .dateAttributeType),
            attribute("endedAt", .dateAttributeType),
            attribute("amountML", .doubleAttributeType, optional: false, defaultValue: 0.0),
            attribute("detail", .stringAttributeType),
            attribute("note", .stringAttributeType),
            attribute("dose", .stringAttributeType),
            attribute("value", .doubleAttributeType, optional: false, defaultValue: 0.0),
            attribute("sticker", .stringAttributeType),
            attribute("leftSeconds", .doubleAttributeType, optional: false, defaultValue: 0.0),
            attribute("rightSeconds", .doubleAttributeType, optional: false, defaultValue: 0.0),
            attribute("runningSide", .stringAttributeType),
            attribute("sideStartedAt", .dateAttributeType),
            attribute("loggedBy", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            eventFamily, eventChildren,
        ]

        let model = NSManagedObjectModel()
        model.entities = [family, child, event]
        return model
    }
}
