import CoreData
import SwiftUI

/// How much of this phone's family is in iCloud, for Settings (Tom, 15 November 2026: a big import can take a
/// while to send, and nothing said so). It counts the entries on this phone and how many of them iCloud has a
/// record of, and says when the last send and fetch were. It reads only; nothing here changes the data.
struct SyncProgress: Equatable {
    var total = 0
    var sent = 0

    var waiting: Int { max(0, total - sent) }
    var fraction: Double { total == 0 ? 1 : Double(sent) / Double(total) }

    @MainActor
    static func count(in store: FamilyStore) -> SyncProgress {
        #if DEBUG
        // For looking at the screen part-way through: "-debugSync 0.4" shows two fifths sent.
        if let part = UserDefaults.standard.string(forKey: "debugSync").flatMap(Double.init) {
            return SyncProgress(total: 3120, sent: Int(3120 * part))
        }
        #endif
        guard Persistence.cloudSyncEnabled, !store.isSample, let family = store.existingFamily() else { return SyncProgress() }
        let ids = (family.events ?? []).filter { !$0.isDeleted }.map(\.objectID)
        // One question for all of them: which of these does iCloud have a record of.
        let sent = store.persistence.container.recordIDs(for: ids).count
        return SyncProgress(total: ids.count, sent: sent)
    }
}

/// The row in Settings: "iCloud sync", with where it stands beside it.
struct SyncRow: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var cloud = CloudStatus.shared
    @State private var progress = SyncProgress()

    var body: some View {
        NavigationLink { SyncView() } label: {
            LabeledContent("iCloud sync") {
                Text(SyncView.short(progress, cloud: cloud, sample: store.isSample))
            }
        }
        .task { progress = SyncProgress.count(in: store) }
    }
}

struct SyncView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var cloud = CloudStatus.shared
    @ObservedObject private var watch = SyncWatch.shared
    @State private var progress = SyncProgress()

    /// The few words beside the row in Settings.
    static func short(_ progress: SyncProgress, cloud: CloudStatus, sample: Bool) -> String {
        if sample || !Persistence.cloudSyncEnabled { return "Off" }
        if cloud.problem != nil { return "Not syncing" }
        return progress.waiting == 0 ? "Up to date" : "\(progress.waiting.formatted()) to send"
    }

    private var off: String? {
        #if DEBUG
        if UserDefaults.standard.string(forKey: "debugSync") != nil { return nil }
        #endif
        if store.isSample { return "The sample family stays on this phone. Your own family syncs as usual." }
        if !Persistence.cloudSyncEnabled { return "This build has iCloud switched off, so everything stays on this phone." }
        return cloud.problem
    }

    var body: some View {
        List {
            if let off {
                Section { Text(off).foregroundStyle(Palette.muted) }
                    .listRowBackground(Palette.paper)
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: headlineSymbol)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                                .accessibilityHidden(true)
                            Text(headline).font(.headline).foregroundStyle(Palette.ink)
                        }
                        if progress.waiting > 0 {
                            ProgressView(value: progress.fraction)
                                .tint(Palette.ink)
                                .accessibilityLabel("Sent to iCloud")
                                .accessibilityValue("\(progress.sent.formatted()) of \(progress.total.formatted()) entries")
                            Text("\(progress.sent.formatted()) of \(progress.total.formatted()) entries are in iCloud.")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                                .monospacedDigit()
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text(footer)
                }
                .listRowBackground(Palette.paper)

                Section {
                    LabeledContent("Entries on this phone", value: progress.total.formatted())
                    LabeledContent("In iCloud", value: progress.sent.formatted())
                    LabeledContent("Still to send", value: progress.waiting.formatted())
                    LabeledContent("Last sent", value: when(watch.lastSend))
                    LabeledContent("Last fetched", value: when(watch.lastFetch))
                } footer: {
                    Text("Last sent and last fetched start again each time Puggle is opened.")
                }
                .listRowBackground(Palette.paper)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("iCloud sync")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Counted again every few seconds while the screen is open, so the bar moves as batches go up.
            while !Task.isCancelled {
                progress = SyncProgress.count(in: store)
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    private var failed: Bool { progress.waiting > 0 && watch.lastSend?.ok == false }

    private var headline: String {
        if progress.waiting == 0 { return "Up to date" }
        if failed { return "The last send did not go through" }
        return watch.sending ? "Sending to iCloud" : "Waiting to send"
    }

    private var headlineSymbol: String {
        if progress.waiting == 0 { return "checkmark.icloud" }
        return failed ? "exclamationmark.icloud" : "icloud.and.arrow.up"
    }

    private var footer: String {
        if progress.waiting == 0 { return "Everything on this phone is in iCloud. Family members get it the next time they open Puggle." }
        if failed { return "Puggle tries again by itself. If this stays for more than a few minutes, close Puggle and open it again." }
        return "Entries go up in batches. Keep Puggle open to finish sooner: iOS pauses sending when the app is closed. A big import can take several minutes."
    }

    private func when(_ last: SyncWatch.Last?) -> String {
        guard let last else { return "Not since opening" }
        let time = last.ended.formatted(date: .omitted, time: .shortened)
        return last.ok ? time : "Tried at \(time)"
    }
}
