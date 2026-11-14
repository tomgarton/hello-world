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

    private let kinds: [EventKind] = [.bottle, .breastfeed, .sleep, .nappy, .solids, .weight, .milestone, .vaccination, .medicine, .temperature, .pump]

    private var mine: [Child] { children.filter { $0.family == store.existingFamily() } }

    var body: some View {
        List {
            Section {
                Text("Entries from the Baby Tracker app can be brought in from its CSV export: the zip file it makes, or the CSV files inside.")
                Text("The file is read on this iPhone and nothing is sent anywhere.")
            }
            .listRowBackground(Palette.paper)

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
                busy = false
            }
        }
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

            Section {
                let count = reading.drafts.filter { match[$0.baby] != nil || $0.kind == .pump }.count
                Button("Import \(BackupsView.count(count, "entry", "entries"))") {
                    Haptics.success()
                    result = store.importDrafts(reading.drafts, children: match)
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
