import SwiftUI

/// The keys for what a person chooses for themselves, on their own phone.
enum Setting {
    static let yourName = "yourName"
    static let appearance = "appearance"
    static let justLog = "justLog"
    static let pottyStickers = "pottyStickers"
    static let lockScreenGlance = "lockScreenGlance"
    static let haptics = "haptics"
    static let tilesCustom = "tilesCustom"
    static let tilesMain = "tilesMain"
    static let tilesHidden = "tilesHidden"
    static let appLock = "appLock"
    /// Set by the "Night look" Focus filter, not by a switch in the app.
    static let focusNight = "focusNight"

    /// When the night look comes on by itself: "off", "hours", "sleep" or "both".
    static let nightMode = "nightMode"
    /// The night hours, as minutes after midnight. The range may wrap past midnight.
    static let nightFrom = "nightFrom"
    static let nightUntil = "nightUntil"
    static let nightModeDefault = "hours"
    /// 21:00 to 06:00, so the small hours are covered.
    static let nightFromDefault = 21 * 60
    static let nightUntilDefault = 6 * 60

    /// Stored for later. Entries are still shown in millilitres, grams and Celsius.
    static let volumeUnit = "volumeUnit"           // "ml" or "oz"
    static let weightUnit = "weightUnit"           // "g" or "lb"
    static let temperatureUnit = "temperatureUnit" // "c" or "f"
}

/// Settings, reached from the Family tab. Short on purpose: who you are,
/// how the app looks, how much it shows, and where your data is.
/// Appearance, night and units each have a small screen of their own.
struct SettingsView: View {
    @EnvironmentObject private var sample: SampleFamily
    @AppStorage(Setting.yourName) private var yourName = ""
    @AppStorage(Setting.justLog) private var justLog = false
    @AppStorage(Setting.pottyStickers) private var stickersOn = true
    @AppStorage(Setting.lockScreenGlance) private var glanceOn = true
    @AppStorage(Setting.haptics) private var hapticsOn = true
    @AppStorage(Setting.appLock) private var lockOn = false
    @EnvironmentObject private var store: FamilyStore
    @State private var choosingTiles = false

    var body: some View {
        List {
            youSection
            lookSection
            todaySection
            glanceSection
            stampsSection
            lockSection
            outsideSection
            sampleSection
            moreSection
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $choosingTiles) {
            TileChooserView(available: Tile.all)
        }
    }

    private var youSection: some View {
        Section {
            TextField("Your name", text: $yourName)
                .textContentType(.givenName)
                .submitLabel(.done)
        } header: {
            Text("You")
        } footer: {
            Text("Shown beside what you log from now on, so the family can see who added it. Leave it empty to add entries without a name.")
        }
        .listRowBackground(Palette.paper)
    }

    private var lookSection: some View {
        Section {
            NavigationLink("Appearance and night") { AppearanceSettingsView() }
            NavigationLink("Units") { UnitsSettingsView() }
            NavigationLink("Reminders") { RemindersView() }
            Toggle("Touch feedback", isOn: $hapticsOn)
        } header: {
            Text("Look and feel")
        } footer: {
            Text("Touch feedback is a small tap you can feel when something is saved or a choice changes.")
        }
        .listRowBackground(Palette.paper)
    }

    private var todaySection: some View {
        Section {
            Picker("How much to see", selection: $justLog) {
                Text("Everything").tag(false)
                Text("Just logging").tag(true)
            }
            .onChange(of: justLog) { _, _ in LiveTimers.shared.sync(with: FamilyStore.live) }
            Button("Tiles on Today") { choosingTiles = true }
        } header: {
            Text("Today")
        } footer: {
            Text(justLog
                 ? "Today shows names and tiles only. Nothing counts up and nothing is totalled, and Insights is hidden. Everything is still saved."
                 : "Today shows how long since the last feed and each child's day so far, and Insights shows the week.")
        }
        .listRowBackground(Palette.paper)
    }

    @ViewBuilder private var glanceSection: some View {
        if !justLog {
            Section {
                Toggle("Last feed on the Lock Screen", isOn: $glanceOn)
                    .onChange(of: glanceOn) { _, _ in LiveTimers.shared.sync(with: FamilyStore.live) }
            } footer: {
                Text("For babies: how long since the last feed and since they woke, on the Lock Screen and in the Dynamic Island, for up to eight hours. Running sleeps and feeds always show there.")
            }
            .listRowBackground(Palette.paper)
        }
    }

    private var stampsSection: some View {
        Section {
            Toggle("Stamps after the potty", isOn: $stickersOn)
        } footer: {
            Text("After a wee, a poo or a try, the phone offers a stamp for their card. Five stamps earn a shiny sticker.")
        }
        .listRowBackground(Palette.paper)
    }

    private var lockSection: some View {
        Section {
            Toggle("Lock with Face ID", isOn: Binding(get: { lockOn }, set: { wanted in
                // Ask before changing it either way, so only the phone's owner can.
                Task {
                    if await AppLock.authenticate(reason: wanted ? "Turn on the lock" : "Turn off the lock") {
                        lockOn = wanted
                    }
                }
            }))
        } header: {
            Text("Privacy")
        } footer: {
            Text("Asks for Face ID or your passcode each time the app is opened. The Lock Screen timer and Siri keep working.")
        }
        .listRowBackground(Palette.paper)
    }

    private var outsideSection: some View {
        Section {
            Text("Siri, the Action button and Shortcuts can start a sleep, log a nappy or a bottle, and tell you the last feed. For a dark look at night, add the Night look filter to your Sleep Focus in the Settings app. Help has the words to say.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
        } header: {
            Text("Without opening the app")
        }
        .listRowBackground(Palette.paper)
    }

    private var sampleSection: some View {
        Section {
            if sample.isOn {
                Button("Leave the sample family") { sample.leave() }
            } else {
                Button("Look around a sample family") { sample.start() }
            }
        } footer: {
            Text(sample.isOn
                 ? "You are looking at made-up entries. Your own family is untouched and comes back when you leave."
                 : "Two made-up children with two weeks of entries, so you can see every screen with something in it. Your own family is untouched, and nothing you do there is kept.")
        }
        .listRowBackground(Palette.paper)
    }

    private var moreSection: some View {
        Section {
            NavigationLink("Your data") { YourDataView() }
            NavigationLink("Help and about") { HelpView() }
        }
        .listRowBackground(Palette.paper)
    }
}

/// Shown wherever the sample family is on screen, so it is never mistaken for real entries.
struct SampleBanner: View {
    @EnvironmentObject private var sample: SampleFamily

    var body: some View {
        if sample.isOn {
            HStack(spacing: 10) {
                Image(systemName: "eye")
                VStack(alignment: .leading, spacing: 1) {
                    Text("Sample family").font(.subheadline.weight(.semibold))
                    Text("Made-up entries. Yours are safe.").font(.footnote)
                }
                Spacer(minLength: 0)
                Button("Leave") { sample.leave() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Palette.fixedPaper, in: Capsule())
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
            .foregroundStyle(Palette.fixedInk)
            .background(Palette.wattle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .contain)
        }
    }
}
