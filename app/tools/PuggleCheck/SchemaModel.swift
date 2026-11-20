// Written by make_schema_model.py from Puggle/Data/Model.swift. Do not edit.
import CoreData

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
        family.managedObjectClassName = "NSManagedObject"

        let child = NSEntityDescription()
        child.name = "Child"
        child.managedObjectClassName = "NSManagedObject"

        let event = NSEntityDescription()
        event.name = "Event"
        event.managedObjectClassName = "NSManagedObject"

        let person = NSEntityDescription()
        person.name = "Person"
        person.managedObjectClassName = "NSManagedObject"

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
        guide.managedObjectClassName = "NSManagedObject"
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
