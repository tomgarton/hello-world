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
    @NSManaged var family: Family?
    @NSManaged var events: Set<Event>?
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
    @NSManaged var createdAt: Date?
    @NSManaged var family: Family?
    @NSManaged var children: Set<Child>?
}

enum EventKind: String, CaseIterable, Identifiable {
    case bottle, breastfeed, solids, sleep, nappy, potty, note

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
        }
    }
}

extension Event {
    var kind: EventKind {
        get { EventKind(rawValue: kindRaw ?? "") ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    var sortedChildren: [Child] {
        (children ?? []).sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
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
        case .nappy, .potty, .solids, .breastfeed:
            let what = (detail ?? "").isEmpty ? "" : ", \(detail!.lowercased())"
            return "\(kind.title)\(what)"
        case .note:
            return note ?? "Note"
        }
    }
}

extension Child {
    var displayName: String { name ?? "Child" }
    var initial: String { String(displayName.prefix(1)).uppercased() }

    /// "6 months", "2½", "3 weeks".
    var ageText: String {
        guard let birth = birthDate else { return "" }
        let comps = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day], from: birth, to: .now)
        if let y = comps.year, y >= 2 {
            let months = comps.month ?? 0
            return months >= 6 ? "\(y)½" : "\(y)"
        }
        let totalMonths = (comps.year ?? 0) * 12 + (comps.month ?? 0)
        if totalMonths >= 1 { return "\(totalMonths) mo" }
        if let w = comps.weekOfYear, w >= 1 { return "\(w) wk" }
        return "\(max(comps.day ?? 0, 0)) days"
    }
}

enum Elapsed {
    static func short(from start: Date, to end: Date) -> String {
        let minutes = max(Int(end.timeIntervalSince(start) / 60), 0)
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h \(String(format: "%02d", m))m" : "\(m) min"
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
            attribute("createdAt", .dateAttributeType),
            eventFamily, eventChildren,
        ]

        let model = NSManagedObjectModel()
        model.entities = [family, child, event]
        return model
    }
}
