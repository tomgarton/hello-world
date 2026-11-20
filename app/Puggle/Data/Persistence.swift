import CloudKit
import CoreData

/// Core Data, synced through the family's own iCloud.
///
/// Two stores, following Apple's "Sharing Core Data objects between iCloud users":
/// - private: families this person created
/// - shared: families someone else shared with them (a partner, Nan)
///
/// A family is shared as one unit: the Family object plus its children and events.
final class Persistence {
    static let shared = Persistence()
    static let preview = Persistence(inMemory: true)

    /// Must match the iCloud container in Puggle.entitlements and the Developer portal.
    static let cloudKitContainerID = "iCloud.com.tomgarton.puggle"

    /// Off in the "Puggle Local" scheme, which builds without the iCloud entitlement
    /// (a free Apple ID cannot sign it). The stores are then plain local files.
    /// The same files should pick up CloudKit when a build with sync on is installed over the top (untested).
    #if LOCAL_ONLY
    static let cloudSyncEnabled = false
    #else
    static let cloudSyncEnabled = true
    #endif

    let container: NSPersistentCloudKitContainer
    private(set) var privateStore: NSPersistentStore?
    private(set) var sharedStore: NSPersistentStore?

    var viewContext: NSManagedObjectContext { container.viewContext }

    /// Set for a viewer, who iCloud lets look and not change. Their changes
    /// could never be sent, so they are dropped here and the phone stays in
    /// step with the family.
    var readOnly = false

    /// `scratch` is for checking speed with a long history ("-debugBig"): real files on disk, in a folder of
    /// their own that is thrown away, and no iCloud. An in-memory store hides how slow reading from disk is.
    init(inMemory: Bool = false, scratch: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Puggle", managedObjectModel: PuggleModel.shared)

        var base = NSPersistentContainer.defaultDirectoryURL()
        if scratch {
            base = FileManager.default.temporaryDirectory.appendingPathComponent("scratch-\(UUID().uuidString)")
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        let privateDescription = NSPersistentStoreDescription(url: base.appendingPathComponent("puggle-private.sqlite"))
        let sharedDescription = NSPersistentStoreDescription(url: base.appendingPathComponent("puggle-shared.sqlite"))

        for description in [privateDescription, sharedDescription] {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        if inMemory {
            privateDescription.url = URL(fileURLWithPath: "/dev/null/private")
            sharedDescription.url = URL(fileURLWithPath: "/dev/null/shared")
            privateDescription.type = NSInMemoryStoreType
            sharedDescription.type = NSInMemoryStoreType
        } else if Self.cloudSyncEnabled, !scratch {
            let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerID)
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions

            let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerID)
            sharedOptions.databaseScope = .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions
        }

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        // Before the stores load, so the first fetch from iCloud is not missed.
        if !inMemory, !scratch, Self.cloudSyncEnabled { SyncWatch.shared.start(for: self) }
        container.loadPersistentStores { [weak self] description, error in
            if let error {
                // During development, crash loudly so problems are found early.
                fatalError("Could not load store \(description.url?.lastPathComponent ?? ""): \(error)")
            }
            guard let self, let url = description.url else { return }
            let store = self.container.persistentStoreCoordinator.persistentStore(for: url)
            if url == privateDescription.url { self.privateStore = store }
            if url == sharedDescription.url { self.sharedStore = store }
        }

        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.transactionAuthor = "app"
    }

    /// True while many entries are being made at once (the sample family): each save waits, and one
    /// save at the end keeps them all. Saving after each of hundreds made opening the sample take seconds.
    var holdingSaves = false

    func save() {
        guard viewContext.hasChanges, !holdingSaves else { return }
        if readOnly {
            viewContext.rollback()
            return
        }
        do { try viewContext.save() } catch { print("Save failed: \(error)") }
    }

    // MARK: - Sharing

    func isShared(_ object: NSManagedObject) -> Bool {
        if object.objectID.persistentStore == sharedStore { return true }
        let shares = (try? container.fetchShares(matching: [object.objectID])) ?? [:]
        return shares[object.objectID] != nil
    }

    func existingShare(for family: Family) -> CKShare? {
        let shares = (try? container.fetchShares(matching: [family.objectID])) ?? [:]
        return shares[family.objectID]
    }

    /// Creates (or returns) the share for a family, ready for UICloudSharingController.
    func share(_ family: Family) async throws -> (CKShare, CKContainer) {
        let ckContainer = CKContainer(identifier: Self.cloudKitContainerID)
        if let existing = existingShare(for: family) { return (try await confirmed(existing, in: ckContainer), ckContainer) }
        let (_, share, shareContainer) = try await container.share([family], to: nil)
        share[CKShare.SystemFieldKey.title] = (family.name ?? "Our family") as CKRecordValue
        return (share, shareContainer)
    }

    /// The invite this phone holds, checked against iCloud. It can be on the phone and not in iCloud: a phone that
    /// moved from a build made in Xcode to one from TestFlight keeps its data, but the two use different sides of
    /// iCloud, and the invite was only ever made on the first. Apple's sharing sheet then fails with "Couldn't
    /// communicate with a helper application". When iCloud has no such invite, a new one is made for the same
    /// zone, so the family's entries stay where they are and people are invited afresh.
    private func confirmed(_ share: CKShare, in cloud: CKContainer) async throws -> CKShare {
        guard let privateStore, share.recordID.zoneID.ownerName == CKCurrentUserDefaultName else { return share }
        let database = cloud.privateCloudDatabase
        do {
            return (try await database.record(for: share.recordID) as? CKShare) ?? share
        } catch let error as CKError where error.code == .unknownItem {
            let fresh = CKShare(recordZoneID: share.recordID.zoneID)
            fresh[CKShare.SystemFieldKey.title] = share[CKShare.SystemFieldKey.title]
            fresh.publicPermission = .none
            let made = (try await database.save(fresh) as? CKShare) ?? fresh
            try await container.persistUpdatedShare(made, in: privateStore)
            return made
        } catch {
            // Offline, or iCloud is busy: carry on with what the phone has, as before.
            return share
        }
    }

    /// Sends a change to the share (who is in it, what they can do) to iCloud,
    /// then keeps the copy Core Data holds in step. Only the family's holder can.
    func saveShare(_ share: CKShare) async throws {
        guard let privateStore else { return }
        let database = CKContainer(identifier: Self.cloudKitContainerID).privateCloudDatabase
        let saved = try await database.save(share)
        try await container.persistUpdatedShare((saved as? CKShare) ?? share, in: privateStore)
    }

    /// Leaves a family someone else shared. For the person leaving, the shared
    /// zone goes from their iCloud and this phone; the family's own copy is untouched.
    func leave(_ family: Family) async throws {
        guard let sharedStore, family.objectID.persistentStore == sharedStore,
              let share = existingShare(for: family) else { return }
        _ = try await container.purgeObjectsAndRecordsInZone(with: share.recordID.zoneID, in: sharedStore)
    }

    /// Called when someone taps an invitation link.
    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        guard let sharedStore else { return }
        try await container.acceptShareInvitations(from: [metadata], into: sharedStore)
    }
}

/// Whether a joined family's entries are still coming down from iCloud. The import screen waits on this,
/// so someone who has just joined does not import a file whose entries are already on their way.
final class SyncWatch: ObservableObject {
    static let shared = SyncWatch()

    /// True until one fetch of the shared family has finished since launch, and while any is running.
    /// Always false with iCloud off, in the sample family and in tests.
    @Published private(set) var arriving = false

    /// The last send and fetch for each store since the app opened, for the iCloud check. No names, only times and codes.
    struct Last { var ended: Date; var ok: Bool; var error: String? }
    private(set) var last: [String: Last] = [:]
    private(set) var failures = 0

    /// True while a send to iCloud is running, for the sync screen in Settings.
    @Published private(set) var sending = false
    private var sends = Set<UUID>()

    /// The newest send, and the newest fetch, of either store since the app opened.
    var lastSend: Last? { newest("Send") }
    var lastFetch: Last? { newest("Fetch") }
    private func newest(_ what: String) -> Last? {
        last.filter { $0.key.hasPrefix(what) && !$0.key.hasSuffix("last failure") }.values.max { $0.ended < $1.ended }
    }

    /// An iCloud error in full: its code, and when it covers many records, how many failed each way
    /// and iCloud's own words for the first of each. Record names are random ids, so nothing personal is here.
    nonisolated static func explain(_ error: Error, depth: Int = 0) -> String {
        let detail = error as NSError
        var text = "\(detail.domain) \(detail.code): \(detail.localizedDescription)"
        if let server = detail.userInfo["ServerErrorDescription"] as? String { text += " Server: \(server)" }
        else if let debug = detail.userInfo[NSDebugDescriptionErrorKey] as? String { text += " (\(debug))" }
        if let items = detail.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary, depth == 0 {
            var groups: [String: (count: Int, first: String)] = [:]
            for (_, value) in items {
                guard let item = value as? NSError else { continue }
                let key = "\(item.domain) \(item.code)"
                let words = (item.userInfo["ServerErrorDescription"] as? String) ?? (item.userInfo[NSDebugDescriptionErrorKey] as? String) ?? item.localizedDescription
                groups[key] = ((groups[key]?.count ?? 0) + 1, groups[key]?.first ?? words)
            }
            text += " Items: " + groups.sorted { $0.key < $1.key }.map { "\($0.value.count) × \($0.key) [\($0.value.first)]" }.joined(separator: "; ")
        }
        if let under = detail.userInfo[NSUnderlyingErrorKey] as? NSError, depth < 2 { text += " Under: " + explain(under, depth: depth + 1) }
        return text
    }

    private var finishedOnce = false
    private var running = Set<UUID>()
    private var observer: NSObjectProtocol?

    func start(for persistence: Persistence) {
        guard observer == nil else { return }
        arriving = true
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification, object: persistence.container, queue: .main
        ) { [weak self, weak persistence] note in
            guard let self,
                  let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
            if event.type == .export {
                if event.endDate == nil { self.sends.insert(event.identifier) } else { self.sends.remove(event.identifier) }
                if self.sending == self.sends.isEmpty { self.sending = !self.sends.isEmpty }
            }
            // The sync screen reads the times below, so it is told on every event.
            self.objectWillChange.send()
            if let ended = event.endDate {
                let what = ["Setup", "Fetch", "Send"][min(event.type.rawValue, 2)]
                let whose = event.storeIdentifier == persistence?.sharedStore?.identifier ? "shared with you" : "your own"
                let problem = event.error.map { Self.explain($0) }
                self.last["\(what), \(whose)"] = Last(ended: ended, ok: event.succeeded, error: problem)
                if !event.succeeded {
                    self.failures += 1
                    // Kept apart, so a later try that works does not hide why this one did not.
                    self.last["\(what), \(whose), last failure"] = Last(ended: ended, ok: false, error: problem)
                }
            }
            guard event.type == .import,
                  event.storeIdentifier == persistence?.sharedStore?.identifier else { return }
            if event.endDate == nil {
                self.running.insert(event.identifier)
            } else {
                self.running.remove(event.identifier)
                if event.succeeded { self.finishedOnce = true }
            }
            let now = !self.finishedOnce || !self.running.isEmpty
            if now != self.arriving { self.arriving = now }
        }
    }

    #if DEBUG
    /// For checking the import screen's wait: "-debugImport catching".
    func hold() { arriving = true }
    #endif
}
