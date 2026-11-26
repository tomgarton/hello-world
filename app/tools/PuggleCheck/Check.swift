import CloudKit
import CoreData
import SwiftUI

/// Asks iCloud, as the signed-in person, what it holds for the family and which fields it will accept.
/// It reads the family's zone and never writes to it. The only things it writes are small test records in
/// the default zone, which Puggle never reads, and it deletes them straight away. It prints counts, field
/// names and iCloud's error text: no names, notes or times.
@main
struct PuggleCheckApp: App {
    var body: some Scene { WindowGroup { CheckView() } }
}

struct CheckView: View {
    @State private var lines: [String] = ["Checking…"]

    var body: some View {
        ScrollView {
            Text(lines.joined(separator: "\n"))
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .task {
            lines = []
            await Checker { line in
                print("CHECK " + line)
                lines.append(line)
            }.run()
        }
    }
}

struct Checker {
    let say: (String) -> Void
    private let cloud = CKContainer(identifier: "iCloud.com.tomgarton.puggle")

    private func code(_ error: Error) -> String {
        let e = error as NSError
        let server = (e.userInfo["ServerErrorDescription"] as? String) ?? (e.userInfo[NSDebugDescriptionErrorKey] as? String) ?? e.localizedDescription
        return "\(e.domain) \(e.code): \(server)"
    }

    /// Every field Puggle's data model can send, by record type: S text, D date, F number, I whole number, B bytes.
    static let model: [(type: String, fields: [(String, Character)])] = [
        ("CD_Family", [("id", "S"), ("name", "S"), ("createdAt", "D")]),
        ("CD_Child", [("id", "S"), ("name", "S"), ("birthDate", "D"), ("colourIndex", "I"), ("createdAt", "D"), ("feedingRaw", "S"),
                      ("pottyTraining", "I"), ("archived", "I"), ("family", "S")]),
        ("CD_Event", [("id", "S"), ("kindRaw", "S"), ("startedAt", "D"), ("endedAt", "D"), ("amountML", "F"), ("detail", "S"), ("note", "S"),
                      ("dose", "S"), ("value", "F"), ("sticker", "S"), ("leftSeconds", "F"), ("rightSeconds", "F"), ("runningSide", "S"),
                      ("sideStartedAt", "D"), ("loggedBy", "S"), ("loggedByID", "S"), ("wakings", "S"), ("createdAt", "D"), ("family", "S")]),
        ("CD_Person", [("id", "S"), ("name", "S"), ("roleRaw", "S"), ("userID", "S"), ("lookup", "S"), ("holdsFamily", "I"), ("photo", "B"),
                       ("invitedAt", "D"), ("joinedAt", "D"), ("createdAt", "D"), ("family", "S")]),
        ("CD_Guide", [("id", "S"), ("kindRaw", "S"), ("name", "S"), ("key", "S"), ("gapHours", "F"), ("doseLimit", "I"), ("strength", "S"),
                      ("rows", "S"), ("photo", "B"), ("readAt", "D"), ("updatedAt", "D"), ("family", "S")]),
    ]

    func run() async {
        say("Puggle Check, \(Date().formatted(date: .abbreviated, time: .standard))")
        do {
            let status = try await cloud.accountStatus()
            say("Account: " + ["could not tell", "available", "restricted", "none", "temporarily unavailable"][min(status.rawValue, 4)])
        } catch { say("Account: failed. \(code(error))") }

        // 1. What the family's zone holds, and which fields are in use on each kind of record.
        let database = cloud.privateCloudDatabase
        var familyZone: CKRecordZone.ID?
        do {
            let zones = try await database.allRecordZones()
            say("Zones: " + zones.map(\.zoneID.zoneName).sorted().joined(separator: ", "))
            familyZone = zones.first { $0.zoneID.zoneName.hasPrefix("com.apple.coredata.cloudkit.share.") }?.zoneID
        } catch { say("Zones: failed. \(code(error))") }
        if let familyZone {
            do {
                var counts: [String: Int] = [:], keys: [String: Set<String>] = [:], people: [String] = []
                var since: CKServerChangeToken?, more = true
                while more {
                    let page = try await database.recordZoneChanges(inZoneWith: familyZone, since: since)
                    for result in page.modificationResultsByID.values {
                        guard let record = try? result.get().record else { continue }
                        counts[record.recordType, default: 0] += 1
                        keys[record.recordType, default: []].formUnion(record.allKeys())
                        if record.recordType == "CD_Person" { people.append(record.allKeys().sorted().joined(separator: " ")) }
                    }
                    since = page.changeToken
                    more = page.moreComing
                }
                say("In the family's zone: " + counts.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", "))
                for (type, used) in keys.sorted(by: { $0.key < $1.key }) where type.hasPrefix("CD") {
                    say("  \(type) uses: " + used.sorted().joined(separator: " "))
                }
                for (index, person) in people.enumerated() { say("  Person \(index + 1) has: \(person)") }
            } catch { say("Reading the family's zone failed. \(code(error))") }
        } else {
            say("No shared family zone in this iCloud.")
        }

        // 2. Which fields iCloud will accept. One small record for each field, in the default zone, then deleted.
        var probes: [CKRecord] = [], label: [CKRecord.ID: String] = [:]
        let stamp = UUID().uuidString.prefix(8)
        func probe(_ type: String, _ field: String, _ value: CKRecordValue) {
            let id = CKRecord.ID(recordName: "check-\(stamp)-\(type)-\(field)")
            let record = CKRecord(recordType: type, recordID: id)
            record[field] = value
            probes.append(record)
            label[id] = "\(type).\(field)"
        }
        for (type, fields) in Self.model {
            probe(type, "CD_entityName", "x" as NSString)
            for (name, kind) in fields {
                switch kind {
                case "D": probe(type, "CD_" + name, Date() as NSDate)
                case "F": probe(type, "CD_" + name, 1.5 as NSNumber)
                case "I": probe(type, "CD_" + name, 1 as NSNumber)
                case "B": probe(type, "CD_" + name, Data([1, 2, 3]) as NSData)
                default: probe(type, "CD_" + name, "x" as NSString)
                }
            }
        }
        for field in ["CD_entityNames", "CD_recordNames", "CD_relationships"] { probe("CDMR", field, "x" as NSString) }
        say("Asking iCloud about \(probes.count) fields…")
        var refused: [String] = [], accepted: [CKRecord.ID] = []
        do {
            let (saved, _) = try await database.modifyRecords(saving: probes, deleting: [], savePolicy: .allKeys, atomically: false)
            for (id, result) in saved {
                switch result {
                case .success: accepted.append(id)
                case .failure(let error): refused.append("\(label[id] ?? id.recordName): \(code(error))")
                }
            }
        } catch { say("Asking failed altogether. \(code(error))") }
        say("Accepted: \(accepted.count) of \(probes.count)")
        if refused.isEmpty {
            say("Refused: none. iCloud accepts every field.")
        } else {
            say("Refused: \(refused.count)")
            refused.sorted().forEach { say("  " + $0) }
        }
        if !accepted.isEmpty {
            do {
                _ = try await database.modifyRecords(saving: [], deleting: accepted, savePolicy: .allKeys, atomically: false)
                say("Test records deleted.")
            } catch { say("Deleting the test records failed. \(code(error))") }
        }
        #if SCHEMA
        await addMissing()
        #endif
        say("Done.")
    }

    #if SCHEMA
    /// The Development build only. Hands Puggle's own data model to Core Data and asks it to make sure iCloud's
    /// Development side has every record type and field. The store is a scratch file in this app's own storage.
    /// It adds to the schema and holds no family data. The Production side is changed only by deploying the
    /// schema in Apple's CloudKit Console.
    func addMissing() async {
        say("Adding Puggle's model to the Development schema…")
        let container = NSPersistentCloudKitContainer(name: "Puggle", managedObjectModel: PuggleModel.shared)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("schema-\(UUID().uuidString).sqlite")
        let description = NSPersistentStoreDescription(url: file)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.tomgarton.puggle")
        container.persistentStoreDescriptions = [description]
        let failure: Error? = await withCheckedContinuation { done in
            container.loadPersistentStores { _, error in done.resume(returning: error) }
        }
        if let failure { say("Opening the scratch store failed. \(code(failure))"); return }
        do {
            try container.initializeCloudKitSchema(options: [])
            say("Schema: Development now has every field in Puggle's model.")
        } catch { say("Schema: failed. \(code(error))") }
    }
    #endif
}
