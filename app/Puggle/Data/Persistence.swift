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

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Puggle", managedObjectModel: PuggleModel.shared)

        let base = NSPersistentContainer.defaultDirectoryURL()
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
        } else if Self.cloudSyncEnabled {
            let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerID)
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions

            let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerID)
            sharedOptions.databaseScope = .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions
        }

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]
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

    func save() {
        guard viewContext.hasChanges else { return }
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
        if let existing = existingShare(for: family) { return (existing, ckContainer) }
        let (_, share, shareContainer) = try await container.share([family], to: nil)
        share[CKShare.SystemFieldKey.title] = (family.name ?? "Our family") as CKRecordValue
        return (share, shareContainer)
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
