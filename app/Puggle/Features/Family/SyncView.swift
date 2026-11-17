import CoreData
import SwiftUI

/// How much of this phone's family is in iCloud, for Settings (Tom, 15 November 2026: a big import can take a
/// while to send, and nothing said so). It counts the entries on this phone and how many of them iCloud has a
/// record of, by kind, and says when the last send and fetch were. It reads only; nothing here changes the data.
struct SyncProgress: Equatable {
    /// One line of the breakdown: a kind of entry, how many are on this phone and how many are in iCloud.
    struct Part: Equatable, Identifiable {
        let group: Group
        var total = 0
        var sent = 0
        var id: Group { group }
        var waiting: Int { max(0, total - sent) }
    }

    enum Group: String, CaseIterable {
        case feeds = "Feeds", sleep = "Sleep", changes = "Nappies and potty", health = "Health", other = "Notes, milestones and care"

        init(_ kind: EventKind) {
            switch kind {
            case .bottle, .breastfeed, .solids, .pump: self = .feeds
            case .sleep: self = .sleep
            case .nappy, .potty: self = .changes
            case .medicine, .temperature, .vaccination, .weight: self = .health
            case .note, .milestone, .care: self = .other
            }
        }

        var title: String { self == .changes ? "\(Terms.nappy) and potty" : rawValue }

        var colour: Color {
            switch self {
            case .feeds: Palette.harbour
            case .sleep: Color(hex: 0x7B6BC4)
            case .changes: Palette.gum
            case .health: Palette.waratahFill
            case .other: Palette.wattle
            }
        }
    }

    var parts: [Part] = []
    /// Entries on this phone with no child attached, of the kinds that always have one. An entry and the
    /// child it is for travel to iCloud as separate records, so on another phone the entry can arrive first.
    var childless = 0

    var total: Int { parts.reduce(0) { $0 + $1.total } }
    var sent: Int { parts.reduce(0) { $0 + $1.sent } }
    var waiting: Int { max(0, total - sent) }
    var fraction: Double { total == 0 ? 1 : Double(sent) / Double(total) }
    /// Rounded down, so it only says 100% when nothing is waiting.
    var percent: Int { waiting == 0 ? 100 : min(99, Int(fraction * 100)) }

    /// Counted away from the main thread, on a context of its own: after a big import there are thousands
    /// of entries, and counting them where the screen is drawn made the app stutter.
    @MainActor
    static func count(in store: FamilyStore) async -> SyncProgress {
        #if DEBUG
        // For looking at the screen part-way through: "-debugSync 0.4" starts two fifths sent and climbs,
        // "-debugSync 1" is up to date.
        if let part = UserDefaults.standard.string(forKey: "debugSync").flatMap(Double.init) {
            let climbed = part >= 1 ? 1 : min(1, part + Date.now.timeIntervalSince(debugStart) / 600)
            let totals: [(Group, Int)] = [(.feeds, 1204), (.sleep, 742), (.changes, 986), (.health, 96), (.other, 92)]
            return SyncProgress(parts: totals.map { Part(group: $0.0, total: $0.1, sent: Int(Double($0.1) * climbed)) })
        }
        #endif
        guard Persistence.cloudSyncEnabled, !store.isSample, let family = store.existingFamily(),
              !family.objectID.isTemporaryID else { return SyncProgress() }
        let familyID = family.objectID
        let container = store.persistence.container
        let context = container.newBackgroundContext()
        return await context.perform {
            // Only each entry's id and kind are read, not the entries themselves.
            let id = NSExpressionDescription()
            id.name = "id"
            id.expression = NSExpression.expressionForEvaluatedObject()
            id.expressionResultType = .objectIDAttributeType
            let request = NSFetchRequest<NSDictionary>(entityName: "Event")
            request.predicate = NSPredicate(format: "family == %@", familyID)
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [id, "kindRaw"]
            let rows = (try? context.fetch(request)) ?? []
            let ids = rows.compactMap { $0["id"] as? NSManagedObjectID }
            // One question for all of them: which of these does iCloud have a record of.
            let inCloud = container.recordIDs(for: ids)
            var parts = Dictionary(uniqueKeysWithValues: Group.allCases.map { ($0, Part(group: $0)) })
            for row in rows {
                guard let id = row["id"] as? NSManagedObjectID else { continue }
                let group = Group(EventKind(rawValue: row["kindRaw"] as? String ?? "") ?? .note)
                parts[group]?.total += 1
                if inCloud[id] != nil { parts[group]?.sent += 1 }
            }
            let lone = NSFetchRequest<NSNumber>(entityName: "Event")
            lone.resultType = .countResultType
            lone.predicate = NSPredicate(format: "family == %@ AND children.@count == 0 AND NOT (kindRaw IN %@)",
                                         familyID, [Event.removedKind, EventKind.pump.rawValue, EventKind.note.rawValue])
            let childless = (try? context.count(for: lone)) ?? 0
            return SyncProgress(parts: Group.allCases.compactMap { parts[$0] }.filter { $0.total > 0 }, childless: childless)
        }
    }

    #if DEBUG
    private static let debugStart = Date.now
    #endif
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
        .task { progress = await SyncProgress.count(in: store) }
    }
}

struct SyncView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var cloud = CloudStatus.shared
    @ObservedObject private var watch = SyncWatch.shared
    @State private var progress = SyncProgress()
    @State private var open = true
    /// Where the count stood when the screen opened, and when it last moved, to work out the pace.
    @State private var first: (at: Date, sent: Int)?
    @State private var moved = Date.now

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
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let off {
                    card { Text(off).foregroundStyle(Palette.muted) }
                } else {
                    heading("This phone")
                    card { sending }
                    Text(note)
                        .font(.body)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    if progress.childless > 0 {
                        card {
                            Text("\(progress.childless.formatted()) \(progress.childless == 1 ? "entry has" : "entries have") no child on this phone")
                                .font(.headline)
                            Text("An entry and who it is for arrive from iCloud separately. If this number is not going down, compare it with the phone the entries were added on.")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    heading("Since Puggle was opened")
                    card { activity }
                }
            }
            .padding(16)
        }
        .background(Palette.sand)
        .navigationTitle("iCloud sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Count again")
            }
        }
        .task {
            // Counted again every few seconds while the screen is open, so the bar moves as batches go up.
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    private func refresh() async {
        let now = await SyncProgress.count(in: store)
        if first == nil { first = (.now, now.sent) }
        if now.sent != progress.sent { moved = .now }
        progress = now
    }

    // MARK: - The card for what has been sent

    @ViewBuilder private var sending: some View {
        Button {
            withAnimation(.spring(duration: 0.3, bounce: 0)) { open.toggle() }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text("Sent to iCloud").font(.title3.weight(.medium)).foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                Text(progress.waiting == 0 ? "Up to date" : "\(progress.percent)% sent")
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                    .rotationEffect(.degrees(open ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(open ? "Hides the breakdown" : "Shows the breakdown")

        SyncBar(progress: progress, split: open)
            .frame(height: 8)
            .accessibilityElement()
            .accessibilityLabel("Sent to iCloud")
            .accessibilityValue("\(progress.sent.formatted()) of \(progress.total.formatted()) entries")

        Text("\(progress.sent.formatted()) of \(progress.total.formatted()) entries")
            .font(.subheadline)
            .foregroundStyle(Palette.muted)
            .monospacedDigit()

        if open, !progress.parts.isEmpty {
            Divider().padding(.vertical, 4)
            ForEach(progress.parts) { part in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(part.group.colour)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(part.group.title).foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    Text(part.total.formatted()).foregroundStyle(Palette.ink)
                    Text(part.waiting == 0 ? "sent" : "\(part.waiting.formatted()) to send")
                        .foregroundStyle(Palette.muted)
                        .frame(minWidth: 92, alignment: .trailing)
                }
                .font(.subheadline)
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Palette.field)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text("Still to send").foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                Text(progress.waiting.formatted()).foregroundStyle(Palette.ink)
            }
            .font(.subheadline)
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - The plain sentence under the card

    private var failed: Bool { progress.waiting > 0 && watch.lastSend?.ok == false }

    /// Entries a minute, from what has gone up while this screen has been open.
    private var pace: Double? {
        guard let first else { return nil }
        let seconds = Date.now.timeIntervalSince(first.at)
        let gone = progress.sent - first.sent
        guard seconds >= 9, gone > 0 else { return nil }
        return Double(gone) / seconds * 60
    }

    private var note: String {
        if progress.waiting == 0 {
            return "Everything on this phone is in iCloud. Family members get it the next time they open Puggle."
        }
        if failed {
            return "The last send did not go through. Puggle tries again by itself. If this stays for a few minutes, close Puggle and open it again."
        }
        if let pace {
            let minutes = max(1, Int((Double(progress.waiting) / pace).rounded(.up)))
            let left = minutes == 1 ? "about a minute" : minutes < 90 ? "about \(minutes) minutes" : "about \(Int((Double(minutes) / 60).rounded())) hours"
            return "At this pace, \(left) to go. Keep Puggle open to finish sooner."
        }
        if Date.now.timeIntervalSince(moved) > 60 {
            return "Nothing has gone up in the last minute. Entries go up in batches, and iCloud sometimes makes a big send wait. Puggle keeps trying."
        }
        return "Entries go up in batches. Keep Puggle open to finish sooner: iOS slows sending once the app is closed."
    }

    // MARK: - The card for when it last sent and fetched

    @ViewBuilder private var activity: some View {
        line("Sending now", watch.sending ? "Yes" : "No")
        Divider()
        line("Last sent", when(watch.lastSend))
        Divider()
        line("Last fetched", when(watch.lastFetch))
    }

    private func line(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            Text(value).foregroundStyle(Palette.muted).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func when(_ last: SyncWatch.Last?) -> String {
        guard let last else { return "Not since opening" }
        let time = last.ended.formatted(date: .omitted, time: .shortened)
        return last.ok ? time : "Tried at \(time)"
    }

    // MARK: - Pieces

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.muted)
            .padding(.horizontal, 4)
            .padding(.top, 6)
            .accessibilityAddTraits(.isHeader)
    }

    private func card(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// The bar: what is in iCloud, in each kind's colour when the breakdown is open, and the rest left empty.
private struct SyncBar: View {
    let progress: SyncProgress
    let split: Bool

    var body: some View {
        GeometryReader { box in
            let total = max(1, progress.total)
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.field)
                HStack(spacing: 0) {
                    if split {
                        ForEach(progress.parts) { part in
                            part.group.colour.frame(width: box.size.width * Double(part.sent) / Double(total))
                        }
                    } else {
                        Palette.harbour.frame(width: box.size.width * progress.fraction)
                    }
                }
                .clipShape(Capsule())
            }
        }
    }
}
