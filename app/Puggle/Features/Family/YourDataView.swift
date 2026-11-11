import SwiftUI

/// One screen with plain answers about the family's data, and two buttons:
/// a copy of everything, and delete everything.
struct YourDataView: View {
    @EnvironmentObject private var store: FamilyStore
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var exportURL: URL?
    @State private var confirmingDelete = false

    var body: some View {
        List {
            Section("Where it lives") {
                Text(Persistence.cloudSyncEnabled
                     ? "Everything you log is kept on this iPhone and in your own iCloud, so it reaches the people you invite. We hold none of it."
                     : "Everything you log is kept on this iPhone only. This build does not use iCloud, so nothing leaves the phone and nothing is shared.")
                Text("No ads, no tracking, no analytics.")
            }
            .listRowBackground(Palette.paper)

            Section {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Export everything", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Text("Preparing the export…").foregroundStyle(Palette.muted)
                }
            } footer: {
                Text("A plain CSV file of every entry, which opens in Numbers, Excel or any text editor.")
            }
            .listRowBackground(Palette.paper)

            Section {
                Button("Delete everything", role: .destructive) { confirmingDelete = true }
                    .confirmationDialog("Delete everything?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                        Button("Delete every child and entry", role: .destructive) {
                            store.deleteEverything()
                            hasOnboarded = false
                        }
                        Button("Keep it", role: .cancel) {}
                    } message: {
                        Text(Persistence.cloudSyncEnabled
                             ? "This removes every child and every entry from this iPhone and from iCloud, for everyone in the family. It cannot be undone. Export a copy first if you want one."
                             : "This removes every child and every entry from this iPhone. It cannot be undone. Export a copy first if you want one.")
                    }
            } footer: {
                Text("The app goes back to the start afterwards.")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Your data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { exportURL = store.exportCSV() }
    }
}

/// Short answers and the name. With the splash and the icon, the only place
/// the app's name appears.
struct HelpView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "\(short) (\(build))"
    }

    private var answers: [(String, String)] {
        [
            ("How do I fix a mistake?",
             "Tap any entry on Today or in History to change or delete it. Straight after saving, use Undo or Change on the Last saved row."),
            ("I forgot to start the sleep timer",
             "Tap + on the Sleep tile and enter when they fell asleep and woke up."),
            ("I forgot to stop the sleep timer",
             "Tap the sleep on the Sleep tile, switch off Still asleep and set when they woke."),
            ("Can someone else log too?",
             Persistence.cloudSyncEnabled
                ? "Yes. Invite them from the Family tab. They need an iPhone and their own Apple Account."
                : "Not in this build. It keeps everything on this iPhone."),
            ("Is this medical advice?",
             "No. The app records what you tell it and never advises. For anything about your child's health, ask your GP or child health nurse."),
        ]
    }

    var body: some View {
        List {
            Section("Help") {
                ForEach(answers, id: \.0) { question, answer in
                    DisclosureGroup(question) {
                        Text(answer).foregroundStyle(Palette.muted)
                    }
                }
            }
            .listRowBackground(Palette.paper)
            Section("About") {
                LabeledContent("Puggle", value: "Version \(version)")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Help and about")
        .navigationBarTitleDisplayMode(.inline)
    }
}
