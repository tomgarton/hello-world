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

    static func write(from store: FamilyStore) {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let children = (try? store.context.fetch(request)) ?? []
        let rows = children.map { child -> WidgetSnapshot.Child in
            let feeds = [store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)].compactMap { $0 }
            let feed = feeds.max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
            return WidgetSnapshot.Child(
                id: child.id?.uuidString ?? "",
                name: child.displayName,
                colourIndex: Int(child.colourIndex),
                asleepSince: store.activeSleep(for: child)?.startedAt,
                lastFeed: feed?.startedAt,
                lastFeedText: feed?.brief,
                lastNappy: store.latest(.nappy, for: child)?.startedAt,
                usesNappies: child.uses(.nappy))
        }
        WidgetSnapshot(children: rows, updatedAt: .now).save()
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) { ControlCenter.shared.reloadAllControls() }
    }
}
