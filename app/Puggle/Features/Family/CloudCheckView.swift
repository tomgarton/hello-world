import CloudKit
import CoreData
import SwiftUI

/// Test builds only: asks iCloud a few plain questions and lists the answers, so a sharing or sync problem
/// can be told apart from the others. Nothing is changed. The report has counts and codes, no names or links.
struct CloudCheckView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var lines: [String] = []
    @State private var running = false
    @State private var copied = false

    var body: some View {
        List {
            Section {
                if running && lines.isEmpty {
                    HStack { ProgressView(); Text("Asking iCloud…").foregroundStyle(Palette.muted) }
                }
                ForEach(lines, id: \.self) { line in
                    Text(line).font(.footnote.monospaced()).textSelection(.enabled)
                }
            } footer: {
                Text("Test builds only. Nothing here changes your data.")
            }
            .listRowBackground(Palette.paper)
            Section {
                Button(copied ? "Copied" : "Copy the report") {
                    UIPasteboard.general.string = lines.joined(separator: "\n")
                    copied = true
                }
                .disabled(lines.isEmpty || running)
                Button("Check again") { Task { await run() } }
                    .disabled(running)
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("iCloud check")
        .navigationBarTitleDisplayMode(.inline)
        .task { await run() }
    }

    private func say(_ line: String) { lines.append(line) }

    private func code(_ error: Error) -> String {
        let detail = error as NSError
        return "\(detail.domain) \(detail.code): \(detail.localizedDescription)"
    }

    private func run() async {
        running = true
        copied = false
        lines = []
        defer { running = false }
        let info = Bundle.main.infoDictionary
        say("Build \(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?")), " +
            (Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "TestFlight" : "Xcode or App Store"))
        guard Persistence.cloudSyncEnabled else { say("This build has iCloud switched off."); return }

        let cloud = CKContainer(identifier: Persistence.cloudKitContainerID)
        do {
            let status = try await cloud.accountStatus()
            say("iCloud account: " + ["could not tell", "available", "restricted", "none", "temporarily unavailable"][min(status.rawValue, 4)])
        } catch { say("iCloud account: failed. \(code(error))") }

        // What this phone holds.
        let family = store.existingFamily()
        let children = family?.children?.count ?? 0
        say(family == nil ? "On this phone: no family" : "On this phone: a family with \(children) children")
        let persistence = store.persistence
        if let family {
            let place = family.objectID.persistentStore == persistence.sharedStore ? "shared with you" : "your own"
            say("The family is \(place)")
            // Whether Core Data believes the family has been sent to iCloud.
            if let record = persistence.container.record(for: family.objectID) {
                say("Sent to iCloud: yes, in zone \(record.recordID.zoneID.zoneName)")
            } else {
                say("Sent to iCloud: no record yet")
            }
        }

        // What iCloud holds.
        do {
            let zones = try await cloud.privateCloudDatabase.allRecordZones()
            say("Your iCloud has \(zones.count) zones: " + zones.map(\.zoneID.zoneName).sorted().joined(separator: ", "))
        } catch { say("Listing your iCloud zones failed. \(code(error))") }
        do {
            let zones = try await cloud.sharedCloudDatabase.allRecordZones()
            say("Shared with you: \(zones.count) zones")
        } catch { say("Listing zones shared with you failed. \(code(error))") }

        // How much of the family iCloud holds, counted record by record.
        if let family {
            // Entries here that iCloud has no record of yet: these have not been sent.
            let events = (family.events ?? []).filter { !$0.isDeleted }
            let waiting = events.filter { persistence.container.record(for: $0.objectID) == nil }
            let newest = waiting.compactMap(\.createdAt).max()
            say("Entries on this phone: \(events.count). Not yet in iCloud: \(waiting.count)" +
                (newest.map { ", the newest made \($0.formatted(date: .omitted, time: .shortened))" } ?? ""))
        }
        // What has been sent and fetched since the app was opened.
        let watch = SyncWatch.shared
        if watch.last.isEmpty {
            say("Since opening: nothing sent or fetched yet")
        } else {
            for (what, last) in watch.last.sorted(by: { $0.key < $1.key }) {
                say("\(what): \(last.ok ? "worked" : "failed") at \(last.ended.formatted(date: .omitted, time: .standard))" + (last.error.map { ". \($0)" } ?? ""))
            }
            if watch.failures > 0 { say("Failures since opening: \(watch.failures)") }
        }
        if let family, let record = persistence.container.record(for: family.objectID) {
            let mine = family.objectID.persistentStore != persistence.sharedStore
            let database = mine ? cloud.privateCloudDatabase : cloud.sharedCloudDatabase
            do {
                var counts: [String: Int] = [:]
                var since: CKServerChangeToken?
                var more = true
                while more {
                    let page = try await database.recordZoneChanges(inZoneWith: record.recordID.zoneID, since: since)
                    for result in page.modificationResultsByID.values {
                        if let found = try? result.get().record { counts[found.recordType, default: 0] += 1 }
                    }
                    since = page.changeToken
                    more = page.moreComing
                }
                let total = counts.values.reduce(0, +)
                say("In iCloud for this family: \(total) records. " + counts.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", "))
            } catch { say("Counting the family's records in iCloud failed. \(code(error))") }
        }

        // The invite.
        guard let family else { return }
        guard let share = persistence.existingShare(for: family) else { say("Invite: none made on this phone"); return }
        say("Invite on this phone: yes, in zone \(share.recordID.zoneID.zoneName), \(share.participants.count) people, link \(share.url == nil ? "missing" : "present")")
        let database = family.objectID.persistentStore == persistence.sharedStore ? cloud.sharedCloudDatabase : cloud.privateCloudDatabase
        do {
            let found = try await database.record(for: share.recordID)
            let onServer = found as? CKShare
            say("Invite in iCloud: found, \(onServer?.participants.count ?? 0) people, link \(onServer?.url == nil ? "missing" : "present")")
        } catch { say("Invite in iCloud: not found. \(code(error))") }
    }
}
