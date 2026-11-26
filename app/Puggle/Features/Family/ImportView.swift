import CoreData
import SwiftUI
import UniformTypeIdentifiers

/// Bringing entries in from another tracker: choose the file, see what it holds, then import.
struct ImportView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>
    @State private var choosing = false
    @State private var reading: Importer.Reading?
    @State private var match: [String: Child] = [:]
    @State private var result: FamilyStore.Imported?
    @State private var busy = false
    @State private var undone: Int?
    @State private var confirmingUndo = false
    /// Entries in the file that look like ones already here, and the ones chosen to come in anyway.
    @State private var overlaps: [FamilyStore.Overlap] = []
    @State private var kept: Set<Int> = []
    @ObservedObject private var sync = SyncWatch.shared
    /// "Import now" was chosen: the wait for iCloud is lifted for this visit.
    @State private var waived = false
    #if DEBUG
    /// For screenshots: "-debugImport overlaps" (a file already read, with overlaps) or "catching".
    var debug: String?
    @State private var showingPairs = false
    init(debug: String? = nil) { self.debug = debug }
    #endif

    private let kinds: [EventKind] = [.bottle, .breastfeed, .sleep, .nappy, .solids, .weight, .milestone, .vaccination, .medicine, .temperature, .pump]

    /// For the overlaps screenshot, the top of the screen is left off so the section is in view.
    private var trimmed: Bool {
        #if DEBUG
        return debug == "overlaps"
        #else
        return false
        #endif
    }

    private var mine: [Child] { children.filter { $0.family == store.existingFamily() } }

    /// Someone in another person's family, whose entries are still coming down from iCloud.
    private var catchingUp: Bool { waiting && !waived }
    private var waiting: Bool {
        #if DEBUG
        if debug == "catching" { return true }
        #endif
        return !store.holdsFamily && sync.arriving
    }

    /// The file's entries without the overlaps that are being left out.
    private func chosen(_ drafts: [Importer.Draft]) -> [Importer.Draft] {
        let out = Set(overlaps.map(\.index)).subtracting(kept)
        return out.isEmpty ? drafts : drafts.enumerated().filter { !out.contains($0.offset) }.map(\.element)
    }

    private func findOverlaps() {
        overlaps = reading.map { store.overlaps(in: $0.drafts, children: match) } ?? []
        kept = kept.intersection(overlaps.map(\.index))
    }

    var body: some View {
        List {
            if !trimmed {
            Section {
                Text("Entries from the Baby Tracker app can be brought in from its CSV export: the zip file it makes, or the CSV files inside.")
                Text("The file is read on this iPhone and nothing is sent anywhere.")
            }
            .listRowBackground(Palette.paper)
            }

            if !store.isParent {
                Section {
                    Text("\(store.whoToAsk.prefix(1).uppercased() + store.whoToAsk.dropFirst()) can import entries.").foregroundStyle(Palette.muted)
                }
                .listRowBackground(Palette.paper)
            } else if mine.isEmpty {
                Section {
                    Text("Add the child on the Family tab first, then come back here.").foregroundStyle(Palette.muted)
                }
                .listRowBackground(Palette.paper)
            } else if catchingUp {
                Section {
                    HStack {
                        Text("Catching up with the family")
                        Spacer()
                        ProgressView()
                    }
                    Button("Choose the export file") {}.disabled(true)
                } footer: {
                    Text("Entries are still arriving from iCloud. Importing now could add entries that are already on their way.")
                }
                .listRowBackground(Palette.paper)
                Section {
                    Button("Import now") { waived = true }
                } footer: {
                    Text("For when this phone has no connection and the wait will not end.")
                }
                .listRowBackground(Palette.paper)
            } else {
                Section {
                    Button(reading == nil ? "Choose the export file" : "Choose a different file") { choosing = true }
                }
                .listRowBackground(Palette.paper)
            }

            if let reading, result == nil {
                preview(reading)
            }

            if let result {
                Section {
                    Text("Imported \(BackupsView.count(result.added, "entry", "entries")).").font(.headline)
                    if result.repeats > 0 { Text("\(BackupsView.count(result.repeats, "entry was", "entries were")) already imported from this file before.") }
                    if result.alreadyHere > 0 { Text("\(BackupsView.count(result.alreadyHere, "entry was", "entries were")) already logged here at the same minute, and left as they are.") }
                    if result.removed > 0 { Text("\(BackupsView.count(result.removed, "entry was", "entries were")) imported before and deleted since, and left out.") }
                    Text("They are in History and Insights now. A backup was made first.")
                        .foregroundStyle(Palette.muted)
                }
                .listRowBackground(Palette.paper)
            }

            if store.isParent, let batch = store.lastImportBatch, store.importedCount(batch: batch) > 0 {
                Section {
                    Button("Undo the last import", role: .destructive) { confirmingUndo = true }
                        .foregroundStyle(Palette.waratah)
                } footer: {
                    Text("Takes out the \(BackupsView.count(store.importedCount(batch: batch), "entry", "entries")) it added. Entries logged here are not touched.")
                }
                .listRowBackground(Palette.paper)
                .confirmationDialog("Undo the last import?", isPresented: $confirmingUndo, titleVisibility: .visible) {
                    Button("Undo the import", role: .destructive) {
                        undone = store.undoImport(batch: batch)
                        result = nil
                    }
                    Button("Keep it", role: .cancel) {}
                }
            }
            if let undone {
                Text("Took out \(BackupsView.count(undone, "imported entry", "imported entries")).")
                    .font(.footnote.weight(.semibold))
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $choosing, allowedContentTypes: [.zip, .commaSeparatedText, .plainText], allowsMultipleSelection: true) { chosen in
            guard case .success(let urls) = chosen, !urls.isEmpty else { return }
            busy = true
            result = nil
            undone = nil
            Task {
                let found = await Task.detached(priority: .userInitiated) { Importer.read(urls) }.value
                reading = found
                // A child here with the same first name is the likely match.
                match = [:]
                for baby in found.babies {
                    let first = baby.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
                    match[baby] = mine.first { $0.displayName.lowercased() == first } ?? (mine.count == 1 ? mine.first : nil)
                }
                kept = []
                findOverlaps()
                busy = false
            }
        }
        .onChange(of: match) { _, _ in findOverlaps() }
        #if DEBUG
        .task { if debug == "overlaps" || debug == "list", reading == nil { readSample() } }
        .navigationDestination(isPresented: $showingPairs) {
            ImportOverlapsView(overlaps: overlaps, kept: $kept, severalChildren: false)
        }
        #endif
        .overlay { if busy { ProgressView().controlSize(.large) } }
    }

    @ViewBuilder private func preview(_ reading: Importer.Reading) -> some View {
        if reading.drafts.isEmpty {
            Section {
                Text("Nothing that can be imported was found in that file.").foregroundStyle(Palette.muted)
                ForEach(reading.leftOut, id: \.self) { Text($0).font(.footnote).foregroundStyle(Palette.muted) }
            }
            .listRowBackground(Palette.paper)
        } else {
            if !trimmed {
            Section {
                if let range = reading.range {
                    LabeledContent("From") { Text(range.lowerBound.formatted(date: .abbreviated, time: .omitted)) }
                    LabeledContent("To") { Text(range.upperBound.formatted(date: .abbreviated, time: .omitted)) }
                }
                ForEach(kinds.filter { reading.count($0) > 0 }) { kind in
                    LabeledContent(label(kind)) { Text("\(reading.count(kind))").monospacedDigit() }
                }
            } header: {
                Text("What the file holds")
            } footer: {
                Text("Check the dates look right before importing.")
            }
            .listRowBackground(Palette.paper)
            }

            Section {
                ForEach(reading.babies.filter { !$0.isEmpty }, id: \.self) { baby in
                    Picker(baby, selection: Binding(get: { match[baby]?.objectID }, set: { id in match[baby] = mine.first { $0.objectID == id } })) {
                        Text("Leave out").tag(NSManagedObjectID?.none)
                        ForEach(mine) { child in Text(child.displayName).tag(Optional(child.objectID)) }
                    }
                }
            } header: {
                Text("Who is this in the app?")
            } footer: {
                Text("The name on the left is from the file. Choose which child here it is.")
            }
            .listRowBackground(Palette.paper)

            if !reading.leftOut.isEmpty {
                Section("Left out") {
                    ForEach(reading.leftOut, id: \.self) { Text($0).font(.subheadline) }
                }
                .listRowBackground(Palette.paper)
            }

            if !overlaps.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(BackupsView.count(overlaps.count, "entry overlaps", "entries overlap")) with ones already in the family")
                            .fontWeight(.semibold)
                        Picker("Overlapping entries", selection: Binding(get: { kept.count == overlaps.count },
                                                                        set: { kept = $0 ? Set(overlaps.map(\.index)) : [] })) {
                            Text("Leave them out").tag(false)
                            Text("Bring them in").tag(true)
                        }
                        .pickerStyle(.segmented)
                        if !kept.isEmpty, kept.count < overlaps.count {
                            Text("Bringing in \(kept.count) of them.").font(.footnote).foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(.vertical, 4)
                    NavigationLink("Look at the \(overlaps.count)") {
                        ImportOverlapsView(overlaps: overlaps, kept: $kept, severalChildren: Set(match.values).count > 1)
                    }
                } header: {
                    Text("Possibly already here")
                } footer: {
                    Text("A sleep or feed for the same child at a time that overlaps one logged here. It is likely the same one, entered in both apps.")
                }
                .listRowBackground(Palette.paper)
            }

            Section {
                let drafts = chosen(reading.drafts)
                let count = drafts.filter { match[$0.baby] != nil || $0.kind == .pump }.count
                Button("Import \(BackupsView.count(count, "entry", "entries"))") {
                    Haptics.success()
                    result = store.importDrafts(drafts, children: match)
                }
                .disabled(count == 0)
            } footer: {
                Text("A backup is made first, and the whole import can be undone from this screen. Entries already here are never changed.")
            }
            .listRowBackground(Palette.paper)
        }
    }

    private func label(_ kind: EventKind) -> String {
        switch kind {
        case .bottle: "Bottles"
        case .breastfeed: "Breastfeeds"
        case .sleep: "Sleeps"
        case .nappy: Terms.nappy + " changes"
        case .solids: "Food and drink"
        case .weight: "Weights"
        case .milestone: "Milestones"
        case .vaccination: "Vaccinations"
        case .medicine: "Medicines"
        case .temperature: "Temperatures"
        case .pump: "Pumping"
        default: kind.title
        }
    }
}

/// The entries in the file that overlap ones already here, pair by pair, each to leave out or keep.
struct ImportOverlapsView: View {
    let overlaps: [FamilyStore.Overlap]
    @Binding var kept: Set<Int>
    /// With more than one child in the file, each pair says whose it is.
    let severalChildren: Bool

    var body: some View {
        List {
            Text("Newest first. The entry already here is never changed.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .listRowBackground(Color.clear)
            ForEach(overlaps) { overlap in
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title(overlap)).fontWeight(.semibold)
                        line("In the file", Self.when(overlap.draft))
                        line("Already here", Self.when(overlap.existing))
                        Picker(title(overlap), selection: Binding(get: { kept.contains(overlap.index) },
                                                                   set: { if $0 { kept.insert(overlap.index) } else { kept.remove(overlap.index) } })) {
                            Text("Leave out").tag(false)
                            Text("Keep both").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 6)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Palette.paper)
            }
        }
        .listSectionSpacing(12)
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .navigationTitle("\(overlaps.count) overlap")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func title(_ overlap: FamilyStore.Overlap) -> String {
        let day = overlap.draft.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let who = severalChildren ? overlap.existing.sortedChildren.first?.displayName : nil
        return [who.map { "\($0): \(overlap.draft.kind.title.lowercased())" } ?? overlap.draft.kind.title, day].joined(separator: ", ")
    }

    private func line(_ label: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(.footnote).foregroundStyle(Palette.muted).frame(width: 84, alignment: .leading)
            Text(text).font(.subheadline)
        }
    }

    private static func clock(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }

    /// "1:10 pm to 2:40 pm", or a start and how long, or a start and how much.
    private static func span(start: Date, end: Date?, seconds: Double, amountML: Double) -> String {
        if let end, end > start {
            // A sleep over midnight or a feed: the end time is enough without its day.
            return "\(clock(start)) to \(clock(end))"
        }
        if seconds >= 60 { return "\(clock(start)), \(Elapsed.short(seconds: seconds))" }
        if amountML > 0 { return "\(clock(start)), \(Units.volume(amountML))" }
        return clock(start)
    }

    static func when(_ draft: Importer.Draft) -> String {
        span(start: draft.start, end: draft.kind == .bottle ? nil : draft.end,
             seconds: draft.leftSeconds + draft.rightSeconds, amountML: draft.amountML)
    }

    static func when(_ event: Event) -> String {
        guard let start = event.startedAt else { return "" }
        var text = event.kind == .sleep && event.endedAt == nil
            ? "\(clock(start)), still asleep"
            : span(start: start, end: event.kind == .bottle ? nil : event.endedAt,
                   seconds: event.leftSeconds + event.rightSeconds, amountML: event.amountML)
        if let who = event.loggedBy, !who.isEmpty { text += ", by \(who)" }
        return text
    }
}

#if DEBUG
extension ImportView {
    /// A made-up file for screenshots: a week of Ollie's sleeps and feeds as another app might hold them,
    /// a few minutes off the ones here, and a month of older entries that overlap nothing.
    fileprivate func readSample() {
        guard let ollie = mine.first(where: { $0.displayName == "Ollie" }) ?? mine.first else { return }
        let name = "Ollie B. Test"
        var drafts: [Importer.Draft] = []
        let recent = (ollie.events ?? [])
            .filter { [.sleep, .breastfeed, .bottle].contains($0.kind) && $0.startedAt != nil && $0.endedAt != nil || $0.kind == .bottle }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
        for (offset, event) in recent.prefix(40).enumerated() where offset % 4 == 0 {
            guard let start = event.startedAt else { continue }
            let shift = Double(4 + offset % 7) * 60
            drafts.append(Importer.Draft(baby: name, kind: event.kind, start: start.addingTimeInterval(shift),
                                         end: event.endedAt?.addingTimeInterval(shift - 180), amountML: event.amountML,
                                         leftSeconds: event.leftSeconds, rightSeconds: event.rightSeconds))
        }
        let before = (ollie.events ?? []).compactMap(\.startedAt).min() ?? .now
        for day in 1...30 {
            let morning = Calendar.current.startOfDay(for: before).addingTimeInterval(Double(-day) * 86_400)
            drafts.append(Importer.Draft(baby: name, kind: .sleep, start: morning.addingTimeInterval(13 * 3600), end: morning.addingTimeInterval(14.5 * 3600)))
            drafts.append(Importer.Draft(baby: name, kind: .bottle, start: morning.addingTimeInterval(7 * 3600), amountML: 120, detail: "Formula"))
            drafts.append(Importer.Draft(baby: name, kind: .nappy, start: morning.addingTimeInterval(9 * 3600), detail: "Wet"))
        }
        reading = Importer.Reading(drafts: drafts, files: 3)
        match = [name: ollie]
        findOverlaps()
        if debug == "list" {
            if let third = overlaps.dropFirst(2).first { kept = [third.index] }
            showingPairs = true
        }
    }
}
#endif
