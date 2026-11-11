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
                if store.isSample {
                    Text("You are looking at the sample family. An export from here holds the made-up entries, not yours.")
                }
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

            if !store.isSample {
            Section {
                Button("Delete everything", role: .destructive) { confirmingDelete = true }
                    .foregroundStyle(Palette.waratah)
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
             "Straight after saving, use Undo or Change on the Last saved bar. Later, tap the entry in History, or touch and hold its tile on Today."),
            ("I forgot to start the sleep timer",
             "Tap the child's row on Today and choose Add a past sleep, then enter when they fell asleep and woke up."),
            ("I forgot to stop the sleep timer",
             "Open History, tap the sleep, switch off Still asleep and set when they woke. The app also asks about a timer left running for 14 hours."),
            ("Can someone else log too?",
             Persistence.cloudSyncEnabled
                ? "Yes. Invite them from the Family tab. They need an iPhone and their own Apple Account."
                : "Not in this build. It keeps everything on this iPhone."),
            ("Can I log without opening the app?",
             "Yes. Say \"Start a sleep in Puggle\", \"Woke up in Puggle\", \"Log a nappy in Puggle\", \"Log a bottle in Puggle\" or \"Last feed in Puggle\" to Siri. The same actions are in the Shortcuts app, so you can put one on the Action button or on an NFC tag by the change table. A running sleep or feed also has buttons on the Lock Screen."),
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
                HStack(spacing: 14) {
                    PuggleMark(size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Wordmark(size: 26)
                        Text("Version \(version)").font(.subheadline).foregroundStyle(Palette.muted)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Help and about")
        .navigationBarTitleDisplayMode(.inline)
    }
}
