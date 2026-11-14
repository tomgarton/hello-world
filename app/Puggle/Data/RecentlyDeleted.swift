import CoreData
import SwiftUI

/// A copy of a deleted entry, kept on this phone for 30 days so it can be
/// brought back. The entry itself is deleted as normal (and from iCloud); this
/// copy is only on the phone that deleted it.
struct DeletedEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let deletedAt: Date
    let summary: String
    let childNames: [String]
    let childIDs: [UUID]
    let kindRaw: String
    let startedAt: Date?
    let endedAt: Date?
    let amountML: Double
    let detail: String?
    let note: String?
    let dose: String?
    let value: Double
    let sticker: String?
    let leftSeconds: Double
    let rightSeconds: Double
    let loggedBy: String?
    let wakings: String?

    init(_ event: Event) {
        id = event.id ?? UUID()
        deletedAt = .now
        summary = event.summary
        childNames = event.sortedChildren.map(\.displayName)
        childIDs = event.sortedChildren.compactMap(\.id)
        kindRaw = event.kindRaw ?? EventKind.note.rawValue
        startedAt = event.startedAt
        endedAt = event.endedAt
        amountML = event.amountML
        detail = event.detail
        note = event.note
        dose = event.dose
        value = event.value
        sticker = event.sticker
        leftSeconds = event.leftSeconds
        rightSeconds = event.rightSeconds
        loggedBy = event.loggedBy
        wakings = event.wakings
    }
}

/// The deleted copies, on this phone only. The sample family's are never kept.
@MainActor
final class RecentlyDeleted: ObservableObject {
    static let shared = RecentlyDeleted()
    static let keepDays = 30

    @Published private(set) var entries: [DeletedEntry] = []

    private var url: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("recently-deleted.json")
    }

    private init() {
        entries = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode([DeletedEntry].self, from: $0) } ?? []
        prune()
    }

    func add(_ entry: DeletedEntry) {
        entries.insert(entry, at: 0)
        prune()
        save()
    }

    func remove(_ entry: DeletedEntry) {
        entries.removeAll { $0.id == entry.id && $0.deletedAt == entry.deletedAt }
        save()
    }

    func removeAll() {
        entries = []
        save()
    }

    private func prune() {
        let cutoff = Date.now.addingTimeInterval(-Double(Self.keepDays) * 24 * 3600)
        entries.removeAll { $0.deletedAt < cutoff }
        if entries.count > 500 { entries = Array(entries.prefix(500)) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

extension FamilyStore {
    /// Brings a deleted entry back, for the same children if they are still here.
    @discardableResult
    func restore(_ entry: DeletedEntry) -> Event? {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "id IN %@", entry.childIDs)
        let children = (try? context.fetch(request)) ?? []
        let kind = EventKind(rawValue: entry.kindRaw) ?? .note
        // A pump belongs to the parent and has no children; anything else needs one.
        guard kind == .pump || !children.isEmpty else { return nil }
        let event = log(kind, for: children, at: entry.startedAt ?? .now, end: entry.endedAt, amountML: entry.amountML,
                        detail: entry.detail, note: entry.note, dose: entry.dose, value: entry.value)
        event.id = entry.id
        event.sticker = entry.sticker
        event.leftSeconds = entry.leftSeconds
        event.rightSeconds = entry.rightSeconds
        event.loggedBy = entry.loggedBy
        event.wakings = entry.wakings
        persistence.save()
        if !isSample { RecentlyDeleted.shared.remove(entry) }
        lastSaved = LastSaved(events: [event], undo: .delete)
        return event
    }
}

/// Recently deleted entries, to bring back.
struct RecentlyDeletedView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var deleted = RecentlyDeleted.shared
    @State private var couldNotRestore = false
    @State private var confirmingEmpty = false

    var body: some View {
        List {
            if deleted.entries.isEmpty {
                Text("Nothing deleted in the last \(RecentlyDeleted.keepDays) days.")
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Palette.paper)
            } else {
                Section {
                    ForEach(deleted.entries, id: \.deletedAt) { entry in
                        HStack(spacing: 12) {
                            ActivityIcon(EventKind(rawValue: entry.kindRaw) ?? .note, size: 22, plain: true)
                                .frame(width: 40, height: 40)
                                .background(Palette.field, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.summary).font(.body.weight(.medium))
                                Text(([entry.childNames.joined(separator: ", ")].filter { !$0.isEmpty }
                                      + [entry.startedAt.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? ""])
                                    .joined(separator: " · "))
                                    .font(.footnote)
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength: 8)
                            Button("Restore") {
                                Haptics.success()
                                if store.restore(entry) == nil { couldNotRestore = true }
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Palette.paper)
                } footer: {
                    Text("Kept on this iPhone for \(RecentlyDeleted.keepDays) days after deleting, then gone for good.")
                }
                Section {
                    Button("Empty now", role: .destructive) { confirmingEmpty = true }
                        .foregroundStyle(Palette.waratah)
                }
                .listRowBackground(Palette.paper)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Recently deleted")
        .navigationBarTitleDisplayMode(.inline)
        .alert("This one can't come back", isPresented: $couldNotRestore) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The child it was for is no longer in the family.")
        }
        .confirmationDialog("Empty Recently deleted?", isPresented: $confirmingEmpty, titleVisibility: .visible) {
            Button("Empty now", role: .destructive) { deleted.removeAll() }
            Button("Keep them", role: .cancel) {}
        } message: {
            Text("These entries can't be brought back afterwards.")
        }
    }
}
