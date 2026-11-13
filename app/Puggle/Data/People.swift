import CloudKit
import CoreData
import CryptoKit
import SwiftUI

/// What a person can do in a family.
///
/// iCloud itself knows two levels: can change, and can't. A viewer is the
/// second, so nothing a viewer's phone does can change the family. A parent
/// and a helper are both the first; the difference between them is a rule
/// this app follows (it hides Edit and Delete from a helper), not one iCloud
/// enforces.
enum Role: String, CaseIterable, Identifiable {
    case parent, helper, viewer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .parent: "Parent"
        case .helper: "Helper"
        case .viewer: "Viewer"
        }
    }

    var symbol: String {
        switch self {
        case .parent: "person.2"
        case .helper: "pencil"
        case .viewer: "eye"
        }
    }

    /// One line for the person choosing.
    var about: String {
        switch self {
        case .parent: "Everything, including children and settings"
        case .helper: "Logs the day and fixes their own entries. Can't change anyone else's"
        case .viewer: "Sees the day. Can't add or change anything"
        }
    }

    /// One line for the person inviting.
    var whoFor: String {
        switch self {
        case .parent: "For another parent or carer. Can do everything you can"
        case .helper: "For anyone who looks after them. Logs the day"
        case .viewer: "For someone who likes to follow along"
        }
    }

    var canLog: Bool { self != .viewer }
}

extension Person {
    var role: Role {
        get { Role(rawValue: roleRaw ?? "") ?? .helper }
        set { roleRaw = newValue.rawValue }
    }

    var displayName: String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Someone" : trimmed
    }

    var initial: String { String(displayName.prefix(1)).uppercased() }
    var hasJoined: Bool { holdsFamily || joinedAt != nil }
    var image: UIImage? { photo.flatMap(UIImage.init(data:)) }
}

/// How this phone knows which entries and which row are its own.
enum Me {
    private static let cloudKey = "cloudUserID"
    private static let installKey = "installID"

    /// This person's iCloud user record name for the app, once it has been asked for.
    static var cloudID: String? { UserDefaults.standard.string(forKey: cloudKey) }

    /// Made once per install, for builds and moments with no iCloud.
    static var installID: String {
        if let id = UserDefaults.standard.string(forKey: installKey) { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: installKey)
        return id
    }

    static var ids: Set<String> { Set([cloudID, installID].compactMap { $0 }) }

    /// Asked away from the main thread, like the account check.
    static func refreshCloudID() {
        guard Persistence.cloudSyncEnabled else { return }
        Task.detached(priority: .utility) {
            guard let id = try? await CKContainer(identifier: Persistence.cloudKitContainerID).userRecordID() else { return }
            let known = UserDefaults.standard.string(forKey: cloudKey)
            guard id.recordName != known else { return }
            UserDefaults.standard.set(id.recordName, forKey: cloudKey)
            await MainActor.run { FamilyStore.live.refreshRole() }
        }
    }

    /// An address or number, hashed, so it can be matched without being kept.
    static func hash(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !text.isEmpty else { return nil }
        return SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// A square photo, 300 points across: plenty for a round avatar, small enough to sync.
enum SmallPhoto {
    static func data(from picked: UIImage) -> Data? {
        let side = min(picked.size.width, picked.size.height)
        guard side > 0 else { return nil }
        let crop = CGRect(x: (picked.size.width - side) / 2, y: (picked.size.height - side) / 2, width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300), format: format)
        let small = renderer.image { _ in
            picked.draw(in: CGRect(x: -crop.minX * 300 / side, y: -crop.minY * 300 / side,
                                   width: picked.size.width * 300 / side, height: picked.size.height * 300 / side))
        }
        return small.jpegData(compressionQuality: 0.8)
    }
}

/// What the invite sheet chose, held until the share sheet has saved.
struct PendingInvite {
    var name: String
    var role: Role
}

enum PeopleError: LocalizedError {
    case notHolder, noShare, notFound

    var errorDescription: String? {
        switch self {
        case .notHolder: "Only the person who started the family can do that."
        case .noShare: "The family isn't shared yet."
        case .notFound: "That person isn't in the family any more."
        }
    }
}

extension FamilyStore {
    // MARK: Who I am

    /// The ids that mark an entry as this person's own.
    var myIDs: Set<String> {
        isSample ? ["sample-\(author ?? "")"] : Me.ids
    }

    /// Written on each new entry.
    var stampID: String {
        isSample ? "sample-\(author ?? "")" : (Me.cloudID ?? Me.installID)
    }

    /// True when the family on screen lives in this person's own iCloud.
    var holdsFamily: Bool {
        guard let family = existingFamily() else { return true }
        return family.objectID.persistentStore != persistence.sharedStore
    }

    func people(in family: Family? = nil) -> [Person] {
        guard let family = family ?? existingFamily() else { return [] }
        return (family.people ?? []).filter { !$0.isDeleted }.sorted(by: Self.listOrder)
    }

    /// Whoever holds the family first, then parents, helpers and viewers, oldest first.
    nonisolated static func listOrder(_ a: Person, _ b: Person) -> Bool {
        func rank(_ p: Person) -> Int {
            if p.holdsFamily { return 0 }
            switch p.role { case .parent: return 1; case .helper: return 2; case .viewer: return 3 }
        }
        if rank(a) != rank(b) { return rank(a) < rank(b) }
        return (a.createdAt ?? .distantPast) < (b.createdAt ?? .distantPast)
    }

    /// This person's own row, if it can be found.
    var me: Person? {
        let all = people()
        if isSample {
            if let name = authorOverride, let match = all.first(where: { $0.name == name }) { return match }
            return all.first(where: \.holdsFamily)
        }
        if holdsFamily { return all.first(where: \.holdsFamily) }
        if let match = all.first(where: { $0.userID.map(Me.ids.contains) ?? false }) { return match }
        // Before the ids line up: the address the invite went to.
        guard let family = existingFamily(),
              let mine = persistence.existingShare(for: family)?.currentUserParticipant?.userIdentity.lookupInfo else { return nil }
        let hashes = Set([Me.hash(mine.emailAddress), Me.hash(mine.phoneNumber)].compactMap { $0 })
        return all.first { $0.lookup.map(hashes.contains) ?? false }
    }

    func isMe(_ person: Person) -> Bool { person == me }

    /// Works out what this person can do, and locks saving for a viewer.
    func refreshRole() {
        let new: Role
        if let roleOverride {
            new = roleOverride
        } else if isSample || holdsFamily {
            new = .parent
        } else if let family = existingFamily() {
            let permission = persistence.existingShare(for: family)?.currentUserParticipant?.permission
            if permission == .readOnly {
                new = .viewer
            } else {
                // Not found yet, or marked a viewer while iCloud says otherwise: the careful middle.
                let saved = me?.role ?? .helper
                new = saved == .viewer ? .helper : saved
            }
        } else {
            new = .parent
        }
        noteMembership()
        // A viewer's changes would never reach iCloud, so they are not kept here either.
        persistence.readOnly = new == .viewer && !isSample
        if new != role { role = new }
    }

    /// True on the one phone that can invite people, remove them and change what they can do.
    var managesPeople: Bool { roleOverride == nil && holdsFamily }

    /// Remembers that this phone is in someone else's family, so it can say so if that ends.
    private func noteMembership() {
        guard !isSample, roleOverride == nil else { return }
        let key = "inSharedFamily", defaults = UserDefaults.standard
        if hasJoinedFamily {
            if !defaults.bool(forKey: key) { defaults.set(true, forKey: key) }
        } else if defaults.bool(forKey: key) {
            defaults.set(false, forKey: key)
            removedNotice = true
        }
    }

    var canLog: Bool { role.canLog }
    var isParent: Bool { role == .parent }

    func isMine(_ event: Event) -> Bool {
        guard let id = event.loggedByID else { return false }
        return myIDs.contains(id)
    }

    /// Whether this person may edit or delete an entry.
    func canChange(_ event: Event) -> Bool {
        switch role {
        case .parent: true
        case .helper: isMine(event)
        case .viewer: false
        }
    }

    /// One plain line naming who to ask, for helpers and viewers.
    var whoToAsk: String {
        let parents = people().filter { $0.role == .parent && $0 != me }.map(\.displayName)
        return parents.isEmpty ? "a parent" : ListFormatter.localizedOr(parents)
    }

    /// The parent whose iCloud holds the family.
    var holderName: String {
        people().first(where: \.holdsFamily)?.displayName ?? "Whoever invited you"
    }

    // MARK: My own row

    /// Makes this person's row if they hold the family and it is missing.
    func ensureMe() {
        guard !isSample, holdsFamily, let family = existingFamily() else { return }
        let all = people(in: family)
        if let mine = all.first(where: \.holdsFamily) {
            if mine.userID == nil, let id = Me.cloudID {
                mine.userID = id
                persistence.save()
            }
            return
        }
        let person = Person(context: context)
        place(person, with: family)
        person.id = UUID()
        person.name = author
        person.role = .parent
        person.holdsFamily = true
        person.userID = Me.cloudID
        person.photo = YourPhoto.shared.data
        person.createdAt = .now
        person.joinedAt = .now
        person.family = family
        persistence.save()
    }

    /// Copies this person's name and photo onto their row, for the rest of the family.
    func shareMyDetails() {
        guard !isSample, role != .viewer else { return }
        ensureMe()
        guard let mine = me else { return }
        let name = author
        let photo = YourPhoto.shared.data
        var changed = false
        if let name, mine.name != name { mine.name = name; changed = true }
        if mine.photo != photo { mine.photo = photo; changed = true }
        if changed { persistence.save() }
    }

    func rename(_ person: Person, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, person.name != trimmed else { return }
        person.name = trimmed
        persistence.save()
    }

    func setPhoto(_ image: UIImage?, for person: Person) {
        person.photo = image.flatMap(SmallPhoto.data(from:))
        persistence.save()
    }

    // MARK: Sharing, on the phone that holds the family

    /// The name a parent gave the family ("The Wattle family"), or "" if they haven't.
    var familyName: String {
        let name = (existingFamily()?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name == "Our family" ? "" : name
    }

    func setFamilyName(_ name: String) {
        guard isParent, let family = existingFamily() else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let wanted = trimmed.isEmpty ? "Our family" : trimmed
        guard family.name != wanted else { return }
        family.name = wanted
        persistence.save()
    }

    /// What the person invited sees before they join: the family's own name,
    /// or "Ollie and Bea's family" from the children when it has none.
    var shareTitle: String {
        if !familyName.isEmpty { return familyName }
        return childrenTitle
    }

    var childrenTitle: String {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        request.predicate = self.scoped(request.predicate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let names = ((try? context.fetch(request)) ?? []).map(\.displayName)
        return names.isEmpty ? "Our family" : "\(ListFormatter.localizedString(byJoining: names))'s family"
    }

    private func participant(for person: Person, in share: CKShare) -> CKShare.Participant? {
        share.participants.first { participant in
            guard participant.role != .owner else { return false }
            let keys = Self.keys(for: participant)
            if let id = person.userID, id == keys.userID { return true }
            if let lookup = person.lookup, keys.lookups.contains(lookup) { return true }
            return false
        }
    }

    private static func keys(for participant: CKShare.Participant) -> (userID: String?, lookups: [String]) {
        let identity = participant.userIdentity
        var userID = identity.userRecordID?.recordName
        if userID == CKCurrentUserDefaultName { userID = nil }
        let lookups = [Me.hash(identity.lookupInfo?.emailAddress), Me.hash(identity.lookupInfo?.phoneNumber)].compactMap { $0 }
        return (userID, lookups)
    }

    /// Lines the list of people up with who iCloud says is in the share.
    /// Only the phone that holds the family does this.
    func reconcilePeople(pending: PendingInvite? = nil) {
        guard !isSample, Persistence.cloudSyncEnabled, holdsFamily, let family = existingFamily() else { return }
        ensureMe()
        guard let share = persistence.existingShare(for: family) else { return }
        var seen = Set<NSManagedObjectID>()
        var all = people(in: family)
        for participant in share.participants where participant.role != .owner {
            let keys = Self.keys(for: participant)
            // With nothing to tell them apart by, a row could never be found again.
            guard keys.userID != nil || !keys.lookups.isEmpty else { continue }
            let found = all.first { person in
                guard !person.holdsFamily else { return false }
                if let id = person.userID, id == keys.userID { return true }
                if let lookup = person.lookup, keys.lookups.contains(lookup) { return true }
                return false
            }
            let person: Person
            if let found {
                person = found
            } else {
                person = Person(context: context)
                place(person, with: family)
                person.id = UUID()
                person.createdAt = .now
                person.invitedAt = .now
                person.family = family
                person.role = pending?.role ?? (participant.permission == .readOnly ? .viewer : .helper)
                let typed = pending?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !typed.isEmpty { person.name = typed }
                all.append(person)
            }
            if person.userID == nil, let id = keys.userID { person.userID = id }
            if person.lookup == nil, let lookup = keys.lookups.first { person.lookup = lookup }
            if (person.name ?? "").isEmpty, let components = participant.userIdentity.nameComponents {
                let name = PersonNameComponentsFormatter.localizedString(from: components, style: .short)
                if !name.isEmpty { person.name = name }
            }
            if participant.acceptanceStatus == .accepted, person.joinedAt == nil { person.joinedAt = .now }
            // What iCloud allows wins: the list never promises more than it does.
            if participant.permission == .readOnly, person.role != .viewer { person.role = .viewer }
            if participant.permission == .readWrite, person.role == .viewer { person.role = .helper }
            seen.insert(person.objectID)
        }
        // Someone who left, or was removed in the share sheet.
        for person in all where !person.holdsFamily && !seen.contains(person.objectID) {
            context.delete(person)
        }
        persistence.save()
    }

    private func holderShare() throws -> (CKShare, Family) {
        guard holdsFamily, let family = existingFamily() else { throw PeopleError.notHolder }
        guard let share = persistence.existingShare(for: family) else { throw PeopleError.noShare }
        return (share, family)
    }

    /// Changes what someone can do. Viewer and back is a change iCloud enforces;
    /// Parent and Helper differ only in what this app shows.
    func setRole(_ role: Role, for person: Person) async throws {
        let (share, _) = try holderShare()
        guard let participant = participant(for: person, in: share) else { throw PeopleError.notFound }
        let wanted: CKShare.ParticipantPermission = role == .viewer ? .readOnly : .readWrite
        if participant.permission != wanted {
            participant.permission = wanted
            try await persistence.saveShare(share)
        }
        person.role = role
        persistence.save()
    }

    /// Ends someone's access. What they logged stays.
    func remove(_ person: Person) async throws {
        let (share, _) = try holderShare()
        if let participant = participant(for: person, in: share) {
            share.removeParticipant(participant)
            try await persistence.saveShare(share)
        }
        context.delete(person)
        persistence.save()
    }

    // MARK: Leaving, on an invited phone

    /// Takes the shared family off this phone. Nothing is deleted for the family.
    /// Returns true if no children are left here afterwards.
    func leaveFamily() async throws -> Bool {
        guard !holdsFamily, let family = existingFamily() else { throw PeopleError.notFound }
        lastSaved = nil
        // Leaving by choice needs no notice afterwards.
        UserDefaults.standard.set(false, forKey: "inSharedFamily")
        try await persistence.leave(family)
        context.refreshAllObjects()
        refreshRole()
        let request = NSFetchRequest<Child>(entityName: "Child")
        return ((try? context.count(for: request)) ?? 0) == 0
    }
}

extension ListFormatter {
    /// "Alex or Robin".
    static func localizedOr(_ items: [String]) -> String {
        switch items.count {
        case 0: ""
        case 1: items[0]
        default: items.dropLast().joined(separator: ", ") + " or " + items[items.count - 1]
        }
    }
}

// MARK: Joining with children of your own

extension FamilyStore {
    /// This phone's own family, when it has also joined someone else's and still has children of its own.
    func ownFamilyBesideJoined() -> Family? {
        guard !isSample, hasJoinedFamily, let shared = persistence.sharedStore else { return nil }
        let request = NSFetchRequest<Family>(entityName: "Family")
        return ((try? context.fetch(request)) ?? []).first { family in
            family.objectID.persistentStore != shared && (family.children ?? []).contains { !$0.isDeleted }
        }
    }

    /// The children kept on this phone from before it joined, oldest first.
    var ownChildrenBesideJoined: [Child] {
        (ownFamilyBesideJoined()?.children ?? []).filter { !$0.isDeleted }
            .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    /// Moves this phone's own children and everything logged for them into the family it joined.
    /// A backup of them is made first. Medicine rules come too when this person is a parent.
    @discardableResult
    func bringOwnChildrenIn() -> Restored {
        guard canLog, let own = ownFamilyBesideJoined(), let joined = existingFamily(), joined != own,
              let copy = snapshot(reason: .beforeBringingIn, of: own) else { return Restored() }
        backups.save(copy)
        let result = restore(copy, into: joined, rules: isParent)
        lastSaved = nil
        for event in own.events ?? [] { context.delete(event) }
        for child in own.children ?? [] { context.delete(child) }
        for guide in own.guides ?? [] { context.delete(guide) }
        for person in own.people ?? [] { context.delete(person) }
        context.delete(own)
        persistence.save()
        return result
    }
}
