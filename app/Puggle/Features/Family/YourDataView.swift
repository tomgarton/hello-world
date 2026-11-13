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
                    Text("This is the sample family, so an export holds the made-up entries.")
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
                Text("Every entry as a spreadsheet file (CSV), for Numbers or Excel.")
            }
            .listRowBackground(Palette.paper)

            if !store.isSample {
            Section {
                NavigationLink("Recently deleted") { RecentlyDeletedView() }
            } footer: {
                Text("Deleted entries can be brought back for \(RecentlyDeleted.keepDays) days.")
            }
            .listRowBackground(Palette.paper)
            Section {
                Button("Delete everything", role: .destructive) { confirmingDelete = true }
                    .foregroundStyle(Palette.waratah)
                    .confirmationDialog("Delete everything?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                        Button(store.hasJoinedFamily ? "Delete what I own" : "Delete every child and entry", role: .destructive) {
                            // Back to the start only if nothing is left to show.
                            if store.deleteEverything() { hasOnboarded = false }
                        }
                        Button("Keep it", role: .cancel) {}
                    } message: {
                        Text(store.hasJoinedFamily
                             ? "This removes the children and entries you own, from this iPhone and from iCloud. It cannot be undone. The family you were invited to belongs to someone else, so it is not deleted. To stop seeing it, open Family, tap your own name, then Leave this family."
                             : Persistence.cloudSyncEnabled
                             ? "This removes every child and every entry from this iPhone and from iCloud, for everyone in the family. It cannot be undone. Export a copy first if you want one."
                             : "This removes every child and every entry from this iPhone. It cannot be undone. Export a copy first if you want one.")
                    }
            } footer: {
                Text(store.hasJoinedFamily
                     ? "A family you were invited to stays as it is."
                     : "The app goes back to the start afterwards.")
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

/// Where "Contact us" sends feedback: an iCloud alias for now, a domain address later.
enum Support {
    static let email = "puggle.support@icloud.com"
}

/// Short answers by topic, a search, and a way to get in touch. With the
/// splash and the icon, the only place the app's name appears.
struct HelpView: View {
    @State private var search = ""
    @State private var composing = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "\(short) (\(build))"
    }

    private struct Topic: Identifiable {
        let id: String
        let symbol: String
        let answers: [(String, String)]
    }

    private var topics: [Topic] {
        [
            Topic(id: "Logging", symbol: "square.and.pencil", answers: [
                ("How do I log something?",
                 "Tap a tile on Today. Feeding and \(Terms.nappy) are always there; everything else is in each child's panel, so tap their name."),
                ("How do I fix a mistake?",
                 "Straight after saving, use Undo or Change on the bar at the bottom of Today. Later, tap the entry in History or Today so far, then Edit."),
                ("I deleted something by mistake",
                 "Tap Undo on the Deleted bar straight away. Later, go to You, Your data, Recently deleted: entries stay there for 30 days."),
                ("Can I log the same thing again?",
                 "Swipe right on it in History or Today so far and tap Again. It logs the same bottle, \(Terms.nappyLower) or food at the time now."),
            ]),
            Topic(id: "Sleep and feeds", symbol: "moon", answers: [
                ("I forgot to start the sleep timer",
                 "Tap the child's row on Today and choose Past sleep, then enter when they fell asleep and woke."),
                ("I forgot to stop the sleep timer",
                 "Open the sleep in History, tap Edit, switch off Still asleep and set when they woke. The app also asks about a timer left running for 14 hours."),
                ("They woke in the night and went back down",
                 "Tap Start sleep again within 90 minutes and choose Carry on the same sleep. The waking is kept inside it."),
                ("A feed timer is still running",
                 "Tap Finish on Today or the Lock Screen. After 90 minutes the app asks if you're still feeding."),
            ]),
            Topic(id: "Medicines", symbol: "pills", answers: [
                ("Can it remind me of a dose?",
                 "Yes. In Reminders, add a regular medicine with its times. It shows as due on Today and goes once a dose is logged."),
                ("Can it check the gap between doses?",
                 "If you enter the smallest gap or the most doses in 24 hours from the box, the app asks once before a dose that goes past them. It never suggests a dose."),
                ("Is this medical advice?",
                 "No. The app records what you tell it. For anything about your child's health, ask your GP, pharmacist or child health nurse."),
            ]),
            Topic(id: "Family and sharing", symbol: "person.2", answers: [
                ("Can someone else log too?",
                 Persistence.cloudSyncEnabled
                    ? "Yes. Tap Invite someone on the Family tab. They need an iPhone with their own Apple Account, and open the invite on it."
                    : "Not in this build. It keeps everything on this iPhone."),
                ("Where are our entries kept?",
                 "On your iPhone, and in your own iCloud once sharing is on. Nobody else can see them unless you invite them."),
                ("How do I take everything with me?",
                 "You, Your data, Export everything: a spreadsheet file of every entry."),
            ]),
            Topic(id: "Without opening the app", symbol: "iphone", answers: [
                ("Can I log with Siri?",
                 "Yes, with nothing to set up. Say \"Start sleep for Ollie in Puggle\" with your child's name, or see Siri and shortcuts in Settings for every phrase."),
                ("Can I add it to my Home Screen?",
                 "Yes. Touch and hold the Home Screen, tap Edit, Add Widget, and choose Puggle: one child, or the whole family with buttons."),
                ("Can I start a sleep from Control Centre?",
                 "Yes. Open Control Centre, tap + at the top, Add a Control, and search for Puggle."),
            ]),
            Topic(id: "Finding support", symbol: "heart", answers: [
                ("I'm finding this hard",
                 "Lots of parents and carers do, and it is worth telling someone. Your GP or child health nurse can help, and most places have a free helpline for parents."),
                ("The numbers are getting to me",
                 "In Settings, set How much to see to Just logging. The counters, totals and Insights go, and logging stays the same."),
                ("Is something wrong with my child?",
                 "The app can't tell you. It records what you log and never judges a day. If you're worried, ask your GP or child health nurse."),
            ]),
            Topic(id: "What the app can't do", symbol: "questionmark.circle", answers: [
                ("Can two homes each be in charge?",
                 "No. The family lives in one person's iCloud, and only that person can invite or remove people, or delete it. Anyone in the family can keep their own copy: You, Your data, Export everything."),
                ("Can I hand a child's record to someone else?",
                 "Not from app to app. Export everything from You, Your data and pass on the file, or use Summary for the doctor on the child's page."),
                ("My baby was born early",
                 "The app counts ages from the birth date and doesn't use a corrected age. That affects the ages shown and when the Solids tile appears."),
                ("I don't know the exact birth date",
                 "Use your best guess. It only sets the age shown and which tiles appear, and you can change it at any time."),
            ]),
            Topic(id: "Stamps and play", symbol: "star.circle", answers: [
                ("How do stamps work?",
                 "After a wee, a poo or a try on the potty, your child presses a stamp onto their card. Five fill a card and earn a shiny sticker."),
                ("Where are the crayons?",
                 "Tap Play on Today, then Draw. To close it, hold the X."),
                ("Can my child leave the app by accident?",
                 "A swipe up first shows the Home bar, and a second leaves. For a full lock, use Guided Access in the Settings app, under Accessibility."),
            ]),
        ]
    }

    private var matches: [Topic] {
        let words = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !words.isEmpty else { return topics }
        return topics.compactMap { topic in
            let hits = topic.answers.filter { "\($0.0) \($0.1)".lowercased().contains(words) }
            return hits.isEmpty ? nil : Topic(id: topic.id, symbol: topic.symbol, answers: hits)
        }
    }

    var body: some View {
        List {
            if matches.isEmpty {
                Text("Nothing found. Try another word, or get in touch below.")
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Palette.paper)
            }
            ForEach(matches) { topic in
                Section {
                    ForEach(topic.answers, id: \.0) { question, answer in
                        DisclosureGroup(question) {
                            Text(answer)
                                .foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Label(topic.id, systemImage: topic.symbol)
                }
                .listRowBackground(Palette.paper)
            }
            Section {
                Button {
                    contact()
                } label: {
                    Label("Contact us", systemImage: "envelope")
                }
            } footer: {
                Text("Opens an email with the app and iOS version filled in, so it's easy to help.")
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Puggle, version \(version)")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .searchable(text: $search, prompt: "Search help")
        .navigationTitle("Help and about")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func contact() {
        let body = """


        ---
        App: \(version)
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = Support.email
        parts.queryItems = [URLQueryItem(name: "subject", value: "Puggle feedback"),
                            URLQueryItem(name: "body", value: body)]
        if let url = parts.url { UIApplication.shared.open(url) }
    }
}
