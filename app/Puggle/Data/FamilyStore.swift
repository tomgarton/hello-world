import CoreData
import SwiftUI

/// All writes go through here, so new objects always land in the same
/// store (private or shared) as the family they belong to.
@MainActor
final class FamilyStore: ObservableObject {
    let persistence: Persistence
    var context: NSManagedObjectContext { persistence.viewContext }

    init(persistence: Persistence = .shared) {
        self.persistence = persistence
    }

    /// The family on screen: a shared family if this person joined one, otherwise their own.
    func currentFamily() -> Family {
        let request = NSFetchRequest<Family>(entityName: "Family")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let families = (try? context.fetch(request)) ?? []
        if let joined = families.first(where: { $0.objectID.persistentStore == persistence.sharedStore }) {
            return joined
        }
        if let own = families.first { return own }

        let family = Family(context: context)
        family.id = UUID()
        family.name = "Our family"
        family.createdAt = .now
        if let store = persistence.privateStore { context.assign(family, to: store) }
        persistence.save()
        return family
    }

    private func place(_ object: NSManagedObject, with family: Family) {
        if let store = family.objectID.persistentStore {
            context.assign(object, to: store)
        }
    }

    @discardableResult
    func addChild(name: String, birthDate: Date, colourIndex: Int) -> Child {
        let family = currentFamily()
        let child = Child(context: context)
        place(child, with: family)
        child.id = UUID()
        child.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        child.birthDate = birthDate
        child.colourIndex = Int16(colourIndex)
        child.createdAt = .now
        child.family = family
        persistence.save()
        return child
    }

    @discardableResult
    func log(_ kind: EventKind,
             for children: [Child],
             at start: Date = .now,
             end: Date? = nil,
             amountML: Double = 0,
             detail: String? = nil,
             note: String? = nil) -> Event {
        let family = currentFamily()
        let event = Event(context: context)
        place(event, with: family)
        event.id = UUID()
        event.kind = kind
        event.startedAt = start
        event.endedAt = end
        event.amountML = amountML
        event.detail = detail
        event.note = note
        event.createdAt = .now
        event.family = family
        event.children = Set(children)
        persistence.save()
        return event
    }

    /// Sleep is a timer: start now, finish later. One open sleep per child.
    func startSleep(for child: Child) {
        guard activeSleep(for: child) == nil else { return }
        log(.sleep, for: [child], at: .now)
    }

    func endSleep(for child: Child) {
        guard let sleep = activeSleep(for: child) else { return }
        sleep.endedAt = .now
        persistence.save()
    }

    func activeSleep(for child: Child) -> Event? {
        (child.events ?? []).first { $0.kind == .sleep && $0.endedAt == nil }
    }

    func latest(_ kind: EventKind, for child: Child) -> Event? {
        (child.events ?? [])
            .filter { $0.kind == kind }
            .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    func delete(_ event: Event) {
        context.delete(event)
        persistence.save()
    }

    func delete(_ child: Child) {
        context.delete(child)
        persistence.save()
    }
}
