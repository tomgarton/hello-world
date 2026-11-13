import CoreData
import Foundation

/// A copy of a whole family at one moment: children, entries and medicine rules.
/// iCloud keeps phones in step, which means a mistake reaches every phone too.
/// These copies are what make it possible to go back.
struct FamilySnapshot: Codable {
    var version = 1
    var takenAt: Date
    var reason: String
    var familyName: String?
    var children: [ChildCopy]
    var events: [EventCopy]
    var guides: [GuideCopy]

    struct ChildCopy: Codable {
        var id: UUID
        var name: String?
        var birthDate: Date?
        var colourIndex: Int16
        var createdAt: Date?
        var feedingRaw: String?
        var pottyTraining: Bool
        var archived: Bool
    }

    struct EventCopy: Codable {
        var id: UUID
        var kindRaw: String?
        var startedAt: Date?
        var endedAt: Date?
        var amountML: Double
        var detail: String?
        var note: String?
        var dose: String?
        var value: Double
        var sticker: String?
        var leftSeconds: Double
        var rightSeconds: Double
        var runningSide: String?
        var sideStartedAt: Date?
        var loggedBy: String?
        var loggedByID: String?
        var wakings: String?
        var createdAt: Date?
        var children: [UUID]
    }

    struct GuideCopy: Codable {
        var id: UUID
        var kindRaw: String?
        var name: String?
        var key: String?
        var gapHours: Double
        var doseLimit: Int16
        var strength: String?
        var rows: String?
        var photo: Data?
        var readAt: Date?
        var updatedAt: Date?
    }
}

/// One line in the list of backups, kept apart from the copy itself so the list opens at once.
struct BackupEntry: Codable, Identifiable, Equatable {
    var id: String { file }
    var file: String
    var takenAt: Date
    var reason: String
    var children: Int
    var entries: Int
}

/// Why a backup was taken. The raw value is what the list shows.
enum BackupReason: String {
    case daily = "Daily"
    case manual = "Made by you"
    case beforeDeleteEverything = "Before deleting everything"
    case beforeDeleteChild = "Before deleting a child"
    case beforeInvite = "Before the first invite"
    case beforeRestore = "Before going back"
    case beforeImport = "Before an import"
}

/// Where the copies are kept: a folder on this iPhone, which the phone's own iCloud backup includes.
struct BackupShelf {
    let directory: URL

    static var standard: BackupShelf {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return BackupShelf(directory: base.appendingPathComponent("Backups", isDirectory: true))
    }

    private var indexURL: URL { directory.appendingPathComponent("index.json") }

    private static var coder: (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    /// Newest first.
    var entries: [BackupEntry] {
        guard let data = try? Data(contentsOf: indexURL),
              let list = try? Self.coder.1.decode([BackupEntry].self, from: data) else { return [] }
        return list.sorted { $0.takenAt > $1.takenAt }
    }

    func url(for entry: BackupEntry) -> URL { directory.appendingPathComponent(entry.file) }

    func load(_ entry: BackupEntry) -> FamilySnapshot? {
        guard let data = try? Data(contentsOf: url(for: entry)) else { return nil }
        return try? Self.coder.1.decode(FamilySnapshot.self, from: data)
    }

    @discardableResult
    func save(_ snapshot: FamilySnapshot) -> BackupEntry? {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: snapshot.takenAt).replacingOccurrences(of: ":", with: "")
        let file = "family-\(stamp)-\(UUID().uuidString.prefix(4)).json"
        guard let data = try? Self.coder.0.encode(snapshot),
              (try? data.write(to: directory.appendingPathComponent(file), options: .atomic)) != nil else { return nil }
        let entry = BackupEntry(file: file, takenAt: snapshot.takenAt, reason: snapshot.reason,
                                children: snapshot.children.count, entries: snapshot.events.count)
        write(prune(entries + [entry], now: snapshot.takenAt))
        return entry
    }

    func remove(_ entry: BackupEntry) {
        try? FileManager.default.removeItem(at: url(for: entry))
        write(entries.filter { $0 != entry })
    }

    private func write(_ list: [BackupEntry]) {
        guard let data = try? Self.coder.0.encode(list) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    /// Keeps everything from the last 14 days, then the newest of each week for 12 weeks. Older ones go.
    private func prune(_ list: [BackupEntry], now: Date) -> [BackupEntry] {
        let calendar = Calendar.current
        var kept: [BackupEntry] = [], weeks = Set<String>()
        for entry in list.sorted(by: { $0.takenAt > $1.takenAt }) {
            let age = now.timeIntervalSince(entry.takenAt)
            if age < 14 * 86_400 {
                kept.append(entry)
            } else if age < 98 * 86_400 {
                let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.takenAt)
                let week = "\(parts.yearForWeekOfYear ?? 0)-\(parts.weekOfYear ?? 0)"
                if weeks.insert(week).inserted { kept.append(entry) } else { try? FileManager.default.removeItem(at: url(for: entry)) }
            } else {
                try? FileManager.default.removeItem(at: url(for: entry))
            }
        }
        return kept
    }
}

extension FamilyStore {
    // MARK: Taking a copy

    /// The family on screen, as it is now. Nil if there is nothing worth keeping.
    func snapshot(reason: BackupReason, at date: Date = .now) -> FamilySnapshot? {
        guard let family = existingFamily() else { return nil }
        let children = (family.children ?? []).filter { !$0.isDeleted }
        let events = (family.events ?? []).filter { !$0.isDeleted }
        guard !children.isEmpty || !events.isEmpty else { return nil }
        return FamilySnapshot(
            takenAt: date, reason: reason.rawValue, familyName: family.name,
            children: children.compactMap { child in
                guard let id = child.id else { return nil }
                return .init(id: id, name: child.name, birthDate: child.birthDate, colourIndex: child.colourIndex,
                             createdAt: child.createdAt, feedingRaw: child.feedingRaw,
                             pottyTraining: child.pottyTraining, archived: child.archived)
            },
            events: events.compactMap { event in
                guard let id = event.id else { return nil }
                return .init(id: id, kindRaw: event.kindRaw, startedAt: event.startedAt, endedAt: event.endedAt,
                             amountML: event.amountML, detail: event.detail, note: event.note, dose: event.dose,
                             value: event.value, sticker: event.sticker, leftSeconds: event.leftSeconds,
                             rightSeconds: event.rightSeconds, runningSide: event.runningSide,
                             sideStartedAt: event.sideStartedAt, loggedBy: event.loggedBy, loggedByID: event.loggedByID,
                             wakings: event.wakings, createdAt: event.createdAt,
                             children: (event.children ?? []).compactMap(\.id))
            },
            guides: (family.guides ?? []).filter { !$0.isDeleted }.compactMap { guide in
                guard let id = guide.id else { return nil }
                return .init(id: id, kindRaw: guide.kindRaw, name: guide.name, key: guide.key, gapHours: guide.gapHours,
                             doseLimit: guide.doseLimit, strength: guide.strength, rows: guide.rows, photo: guide.photo,
                             readAt: guide.readAt, updatedAt: guide.updatedAt)
            })
    }

    @discardableResult
    func backUp(_ reason: BackupReason) -> BackupEntry? {
        guard let copy = snapshot(reason: reason) else { return nil }
        return backups.save(copy)
    }

    /// A copy taken by the app itself: never for the sample family, and never while a viewer.
    func backUpQuietly(_ reason: BackupReason) {
        guard !isSample, roleOverride == nil else { return }
        backUp(reason)
    }

    /// Once a day, when the app opens.
    func backUpIfDue(now: Date = .now) {
        guard !isSample, roleOverride == nil else { return }
        let last = backups.entries.first { $0.reason == BackupReason.daily.rawValue }?.takenAt
        if let last, Calendar.current.isDate(last, inSameDayAs: now) { return }
        backUp(.daily)
    }

    // MARK: Going back

    struct Restored: Equatable {
        var children = 0, entries = 0, rules = 0
        var isNothing: Bool { children == 0 && entries == 0 && rules == 0 }
    }

    /// Adds back whatever is in the copy and not in the app now. Nothing is removed.
    @discardableResult
    func restoreMissing(from copy: FamilySnapshot) -> Restored {
        guard isParent else { return Restored() }
        let family = currentFamily()
        var result = Restored()
        var childByID: [UUID: Child] = [:]
        for child in family.children ?? [] where !child.isDeleted { if let id = child.id { childByID[id] = child } }
        for saved in copy.children where childByID[saved.id] == nil {
            let child = Child(context: context)
            place(child, with: family)
            child.id = saved.id
            child.name = saved.name
            child.birthDate = saved.birthDate
            child.colourIndex = saved.colourIndex
            child.createdAt = saved.createdAt
            child.feedingRaw = saved.feedingRaw
            child.pottyTraining = saved.pottyTraining
            child.archived = saved.archived
            child.family = family
            childByID[saved.id] = child
            result.children += 1
        }
        let have = Set((family.events ?? []).filter { !$0.isDeleted }.compactMap(\.id))
        for saved in copy.events where !have.contains(saved.id) {
            let event = Event(context: context)
            place(event, with: family)
            event.id = saved.id
            event.kindRaw = saved.kindRaw
            event.startedAt = saved.startedAt
            event.endedAt = saved.endedAt
            event.amountML = saved.amountML
            event.detail = saved.detail
            event.note = saved.note
            event.dose = saved.dose
            event.value = saved.value
            event.sticker = saved.sticker
            event.leftSeconds = saved.leftSeconds
            event.rightSeconds = saved.rightSeconds
            event.runningSide = saved.runningSide
            event.sideStartedAt = saved.sideStartedAt
            event.loggedBy = saved.loggedBy
            event.loggedByID = saved.loggedByID
            event.wakings = saved.wakings
            event.createdAt = saved.createdAt
            event.family = family
            event.children = Set(saved.children.compactMap { childByID[$0] })
            result.entries += 1
        }
        let keys = Set((family.guides ?? []).filter { !$0.isDeleted }.compactMap(\.key))
        for saved in copy.guides where !(saved.key.map(keys.contains) ?? true) {
            let guide = Guide(context: context)
            place(guide, with: family)
            guide.id = saved.id
            guide.kindRaw = saved.kindRaw
            guide.name = saved.name
            guide.key = saved.key
            guide.gapHours = saved.gapHours
            guide.doseLimit = saved.doseLimit
            guide.strength = saved.strength
            guide.rows = saved.rows
            guide.photo = saved.photo
            guide.readAt = saved.readAt
            guide.updatedAt = saved.updatedAt
            guide.family = family
            result.rules += 1
        }
        persistence.save()
        return result
    }

    /// Makes the family exactly what the copy holds. Anything logged since goes.
    /// A copy of how things are now is taken first, so this can itself be taken back.
    @discardableResult
    func restoreExactly(from copy: FamilySnapshot) -> Bool {
        guard isParent else { return false }
        backUp(.beforeRestore)
        let family = currentFamily()
        lastSaved = nil
        justDeleted = nil
        for event in family.events ?? [] { context.delete(event) }
        for child in family.children ?? [] { context.delete(child) }
        for guide in family.guides ?? [] { context.delete(guide) }
        persistence.save()
        restoreMissing(from: copy)
        return true
    }
}
