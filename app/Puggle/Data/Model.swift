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
    /// Everyone in the family: whoever holds it in their iCloud, and each person invited.
    @NSManaged var people: Set<Person>?
    /// What the family has saved about each medicine and formula.
    @NSManaged var guides: Set<Guide>?
}

/// What the family has saved about one medicine or formula, shared so every
/// phone checks against the same thing: the smallest gap and most doses for a
/// medicine now, and later the table read from its box or tin, and the photo.
@objc(Guide)
final class Guide: NSManagedObject, Identifiable {
    @NSManaged var id: UUID?
    /// "medicine" or "formula".
    @NSManaged var kindRaw: String?
    @NSManaged var name: String?
    /// The name in lower case with no spaces at the ends, to find it by.
    @NSManaged var key: String?
    /// Hours. 0 means none set.
    @NSManaged var gapHours: Double
    /// Most doses in 24 hours. 0 means none set.
    @NSManaged var doseLimit: Int16
    /// As on the front of the box: "120 mg in 5 ml".
    @NSManaged var strength: String?
    /// The table from the box or tin, as JSON rows. Not used yet.
    @NSManaged var rows: String?
    /// The photo of the box or tin, if the family chose to keep it. Not used yet.
    @NSManaged var photo: Data?
    @NSManaged var readAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var family: Family?
}

/// One grown-up in the family, saved with the family so every phone sees the
/// same list. It carries what they can do (Parent, Helper or Viewer), and
/// their name and photo.
@objc(Person)
final class Person: NSManagedObject, Identifiable {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var roleRaw: String?
    /// Their iCloud user record name in this app's container, once known.
    /// It is how a phone finds its own row. Never shown.
    @NSManaged var userID: String?
    /// A one-way hash of the email or number the invite went to, to match a
    /// person who has not joined yet. The address itself is not kept.
    @NSManaged var lookup: String?
    /// True for the person whose iCloud holds the family. Only their phone
    /// can invite people, remove them or change what they can do.
    @NSManaged var holdsFamily: Bool
    /// A small square photo, 300 points across.
    @NSManaged var photo: Data?
    @NSManaged var invitedAt: Date?
    @NSManaged var joinedAt: Date?
    @NSManaged var createdAt: Date?
    @NSManaged var family: Family?
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
    /// Solids: how it went. Nappy: the colour, if noted.
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
    /// Who added the entry, as an id that does not change when a name does.
    /// A helper can change the entries that carry their own id. Optional.
    @NSManaged var loggedByID: String?
    /// Sleep: times the child woke and went back to sleep inside this sleep,
    /// as "start-end" seconds since 1970, separated by commas. Optional.
    @NSManaged var wakings: String?
    @NSManaged var createdAt: Date?
    @NSManaged var family: Family?
    @NSManaged var children: Set<Child>?
}

enum EventKind: String, CaseIterable, Identifiable {
    case bottle, breastfeed, solids, sleep, nappy, potty, note
    case weight, medicine, temperature, vaccination, milestone
    /// Pumping belongs to the parent, not a child: it has no children.
    case pump

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
        case .nappy: Terms.nappy
        case .potty: "Potty"
        case .note: "Note"
        case .weight: "Weight"
        case .medicine: "Medicine"
        case .temperature: "Temperature"
        case .vaccination: "Vaccination"
        case .milestone: "Milestone"
        case .pump: "Pump"
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
        case .pump: "drop.halffull"
        }
    }
}

extension Event {
    var kind: EventKind {
        get { EventKind(rawValue: kindRaw ?? "") ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    /// The moment an entry is listed at, in Today and History. A finished sleep
    /// is listed when it ended, so last night's sleep is in this morning's list
    /// and not back in yesterday's.
    var listedAt: Date? {
        if kind == .sleep, let endedAt { return endedAt }
        return startedAt
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

    /// Night wakings inside this sleep, oldest first.
    var wakingIntervals: [DateInterval] {
        (wakings ?? "").split(separator: ",").compactMap { pair in
            let parts = pair.split(separator: "-").compactMap { Double($0) }
            guard parts.count == 2, parts[1] >= parts[0] else { return nil }
            return DateInterval(start: Date(timeIntervalSince1970: parts[0]), end: Date(timeIntervalSince1970: parts[1]))
        }
    }

    func addWaking(from start: Date, to end: Date) {
        let pair = "\(Int(start.timeIntervalSince1970))-\(Int(max(end, start).timeIntervalSince1970))"
        wakings = (wakings ?? "").isEmpty ? pair : "\(wakings!),\(pair)"
    }

    /// "woke once", "woke 3 times", or nil.
    var wokeText: String? {
        switch wakingIntervals.count {
        case 0: nil
        case 1: "woke once"
        case 2: "woke twice"
        case let n: "woke \(n) times"
        }
    }

    /// The stretches of this sleep inside a window, split around any wakings.
    func asleepPieces(from: Date = .distantPast, to: Date = .distantFuture, now: Date = .now) -> [DateInterval] {
        guard let start = startedAt else { return [] }
        let end = min(endedAt ?? now, to)
        var cursor = max(start, from)
        var pieces: [DateInterval] = []
        for waking in wakingIntervals.sorted(by: { $0.start < $1.start }) {
            if waking.start > cursor { pieces.append(DateInterval(start: cursor, end: min(waking.start, end))) }
            cursor = max(cursor, waking.end)
        }
        if end > cursor { pieces.append(DateInterval(start: cursor, end: end)) }
        return pieces.filter { $0.duration > 0 }
    }

    /// Time asleep between two moments, leaving out any wakings.
    func asleepSeconds(from: Date, to: Date) -> Double {
        asleepPieces(from: from, to: to, now: to).reduce(0) { $0 + $1.duration }
    }

    /// The shortest useful form, for a child's row on Today: "Bottle · 150 ml".
    /// The rest (which milk, which side) is one tap away in the entry.
    var brief: String {
        switch kind {
        case .bottle:
            return amountML > 0 ? "Bottle · \(Units.volume(amountML))" : "Bottle"
        case .breastfeed:
            let timed = leftSeconds + rightSeconds
            if timed > 0 { return "Breastfeed · \(Elapsed.minutes(timed))" }
            if let start = startedAt, let end = endedAt { return "Breastfeed · \(Elapsed.short(from: start, to: end))" }
            return "Breastfeed"
        case .sleep:
            if let start = startedAt, let end = endedAt { return "Slept · \(Elapsed.short(seconds: asleepSeconds(from: start, to: end)))" }
            return "Asleep"
        case .nappy, .potty, .solids:
            return (detail ?? "").isEmpty ? kind.title : "\(kind.title) · \(detail!.lowercased())"
        default:
            return summary
        }
    }

    /// A short, human summary for timelines: "Bottle · 150 ml · formula".
    var summary: String {
        switch kind {
        case .bottle:
            let ml = amountML > 0 ? " · \(Units.volume(amountML))" : ""
            let what = (detail ?? "").isEmpty ? "" : " · \(detail!.lowercased())"
            return "Bottle\(ml)\(what)"
        case .sleep:
            if let start = startedAt, let end = endedAt {
                return "Slept \(Elapsed.short(seconds: asleepSeconds(from: start, to: end)))\(wokeText.map { " · \($0)" } ?? "")"
            }
            return "Asleep"
        case .breastfeed:
            if endedAt == nil { return "Feeding" }
            if leftSeconds > 0 || rightSeconds > 0 {
                var parts: [String] = []
                if leftSeconds > 0 { parts.append("left \(Elapsed.minutes(leftSeconds))") }
                if rightSeconds > 0 { parts.append("right \(Elapsed.minutes(rightSeconds))") }
                return "Breastfeed · " + parts.joined(separator: " · ")
            }
            let side = (detail ?? "").isEmpty ? "" : " · \(detail!.lowercased())"
            let length = (startedAt.flatMap { start in endedAt.map { Elapsed.short(from: start, to: $0) } }).map { " · \($0)" } ?? ""
            return "Breastfeed\(side)\(length)"
        case .nappy, .potty, .solids:
            let what = (detail ?? "").isEmpty ? "" : " · \(detail!.lowercased())"
            let extra = kind != .potty && !(dose ?? "").isEmpty ? " · \(dose!.lowercased())" : ""
            return "\(kind.title)\(what)\(extra)"
        case .note:
            return note ?? "Note"
        case .weight:
            return "Weight \(Units.weight(value))"
        case .medicine:
            let name = (detail ?? "").isEmpty ? "Medicine" : detail!
            let amount = (dose ?? "").isEmpty ? "" : " · \(dose!)"
            return "\(name)\(amount)"
        case .temperature:
            let place = (detail ?? "").isEmpty ? "" : " · \(detail!.lowercased())"
            return "Temperature \(Units.temperature(value))\(place)"
        case .vaccination:
            return (detail ?? "").isEmpty ? "Vaccination" : "Vaccination · \(detail!)"
        case .milestone:
            return (detail ?? "").isEmpty ? "Milestone" : detail!
        case .pump:
            if detail == Pump.count {
                return "Milk on hand · fridge \(Units.volume(value)) · freezer \(Units.volume(amountML))"
            }
            let place = (detail ?? "").isEmpty ? "" : " · \(Pump.placeText(detail!))"
            return "Pumped · \(Units.volume(amountML))\(place)"
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
        case .pump: return feeding == .breast || feeding == .both
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
        short(seconds: end.timeIntervalSince(start))
    }

    static func short(seconds: Double) -> String {
        let minutes = max(Int(seconds / 60), 0)
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

        let person = NSEntityDescription()
        person.name = "Person"
        person.managedObjectClassName = NSStringFromClass(Person.self)

        // Family
        let familyPeople = relationship("people", to: person, toMany: true)
        let personFamily = relationship("family", to: family, toMany: false)
        familyPeople.deleteRule = .cascadeDeleteRule
        familyPeople.inverseRelationship = personFamily
        personFamily.inverseRelationship = familyPeople
        let photo = attribute("photo", .binaryDataAttributeType)
        photo.allowsExternalBinaryDataStorage = true
        person.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("roleRaw", .stringAttributeType),
            attribute("userID", .stringAttributeType),
            attribute("lookup", .stringAttributeType),
            attribute("holdsFamily", .booleanAttributeType, optional: false, defaultValue: false),
            photo,
            attribute("invitedAt", .dateAttributeType),
            attribute("joinedAt", .dateAttributeType),
            attribute("createdAt", .dateAttributeType),
            personFamily,
        ]

        let guide = NSEntityDescription()
        guide.name = "Guide"
        guide.managedObjectClassName = NSStringFromClass(Guide.self)
        let familyGuides = relationship("guides", to: guide, toMany: true)
        let guideFamily = relationship("family", to: family, toMany: false)
        familyGuides.deleteRule = .cascadeDeleteRule
        familyGuides.inverseRelationship = guideFamily
        guideFamily.inverseRelationship = familyGuides
        let guidePhoto = attribute("photo", .binaryDataAttributeType)
        guidePhoto.allowsExternalBinaryDataStorage = true
        guide.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("kindRaw", .stringAttributeType),
            attribute("name", .stringAttributeType),
            attribute("key", .stringAttributeType),
            attribute("gapHours", .doubleAttributeType, optional: false, defaultValue: 0.0),
            attribute("doseLimit", .integer16AttributeType, optional: false, defaultValue: 0),
            attribute("strength", .stringAttributeType),
            attribute("rows", .stringAttributeType),
            guidePhoto,
            attribute("readAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
            guideFamily,
        ]

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
            familyChildren, familyEvents, familyPeople, familyGuides,
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
            attribute("loggedByID", .stringAttributeType),
            attribute("wakings", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            eventFamily, eventChildren,
        ]

        let model = NSManagedObjectModel()
        model.entities = [family, child, event, person, guide]
        return model
    }
}
