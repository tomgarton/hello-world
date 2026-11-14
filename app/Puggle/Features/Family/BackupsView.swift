import SwiftUI

/// The copies of the family kept on this iPhone, and the two ways to go back to one.
struct BackupsView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var entries: [BackupEntry] = []
    @State private var opened: BackupEntry?
    @State private var note: String?

    var body: some View {
        List {
            Section {
                Text("A copy of the children, entries and medicine rules is kept each day the app is opened, and before anything that is hard to undo.")
                Text("Copies stay on this iPhone, and are part of the iPhone's own iCloud backup if that is on.")
            }
            .listRowBackground(Palette.paper)

            Section {
                Button("Back up now") {
                    Haptics.tap()
                    note = store.backUp(.manual) == nil ? "There's nothing to back up yet." : "Backed up."
                    reload()
                }
            } footer: {
                if let note { Text(note) }
            }
            .listRowBackground(Palette.paper)

            Section {
                if entries.isEmpty {
                    Text("No backups yet. The first is made the next time the app opens with something logged.")
                        .foregroundStyle(Palette.muted)
                }
                ForEach(entries) { entry in
                    Button {
                        opened = entry
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.takenAt.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute()))
                                    .font(.headline)
                                Text("\(entry.reason) · \(Self.count(entry.children, "child", "children")) · \(Self.count(entry.entries, "entry", "entries"))")
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Backups")
            } footer: {
                Text("Every one from the last 14 days is kept, then one a week for about three months.")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Backups")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
        .sheet(item: $opened, onDismiss: reload) { BackupSheet(entry: $0) }
    }

    private func reload() { entries = store.backups.entries }

    static func count(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }
}

/// One backup: what it holds, and what can be done with it.
private struct BackupSheet: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    let entry: BackupEntry
    @State private var confirmingExact = false
    @State private var confirmingAgain = false
    @State private var result: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Made") { Text(entry.takenAt.formatted(date: .abbreviated, time: .shortened)) }
                    LabeledContent("Why") { Text(entry.reason) }
                    LabeledContent("Holds") {
                        Text("\(BackupsView.count(entry.children, "child", "children")), \(BackupsView.count(entry.entries, "entry", "entries"))")
                    }
                }
                .listRowBackground(Palette.paper)

                if store.isParent {
                    Section {
                        Button("Bring back what's missing") { bringBack() }
                    } footer: {
                        Text("Adds back any child, entry or medicine rule that is in this backup and not in the app now. Nothing is removed, so what has been logged since is kept.")
                    }
                    .listRowBackground(Palette.paper)

                    Section {
                        Button("Go back to exactly this", role: .destructive) { confirmingExact = true }
                            .foregroundStyle(Palette.waratah)
                    } footer: {
                        Text("Makes the family what it was at this moment. Anything logged since goes. A backup of how things are now is made first, so this can be taken back.")
                    }
                    .listRowBackground(Palette.paper)
                } else {
                    Section {
                        Text("\(store.whoToAsk.prefix(1).uppercased() + store.whoToAsk.dropFirst()) can go back to a backup.")
                            .foregroundStyle(Palette.muted)
                    }
                    .listRowBackground(Palette.paper)
                }

                Section {
                    ShareLink(item: store.backups.url(for: entry)) {
                        Label("Save a copy to Files", systemImage: "square.and.arrow.up")
                    }
                } footer: {
                    Text("The whole backup as one file, to keep somewhere else such as iCloud Drive.")
                }
                .listRowBackground(Palette.paper)

                if let result {
                    Text(result).font(.footnote.weight(.semibold)).listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .confirmationDialog("Go back to this backup?", isPresented: $confirmingExact, titleVisibility: .visible) {
                Button("Go back", role: .destructive) { confirmingAgain = true }
                Button("Keep things as they are", role: .cancel) {}
            } message: {
                Text("Everything logged since \(entry.takenAt.formatted(date: .abbreviated, time: .shortened)) will go\(Persistence.cloudSyncEnabled ? ", on every phone in the family" : "").")
            }
            .alert("Are you sure?", isPresented: $confirmingAgain) {
                Button("Go back to this backup", role: .destructive) { goBack() }
                Button("Keep things as they are", role: .cancel) {}
            } message: {
                Text("A backup of how things are now is made first.")
            }
        }
        .presentationDetents([.large])
    }

    private func bringBack() {
        guard let copy = store.backups.load(entry) else { result = "This backup couldn't be read."; return }
        let back = store.restoreMissing(from: copy)
        Haptics.success()
        result = back.isNothing ? "Nothing was missing."
            : "Brought back \(BackupsView.count(back.children, "child", "children")), \(BackupsView.count(back.entries, "entry", "entries")) and \(BackupsView.count(back.rules, "medicine rule", "medicine rules"))."
    }

    private func goBack() {
        guard let copy = store.backups.load(entry) else { result = "This backup couldn't be read."; return }
        result = store.restoreExactly(from: copy) ? "Done. The family is as it was then." : "That didn't go through."
        Haptics.success()
    }
}
