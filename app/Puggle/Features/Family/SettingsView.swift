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
            #if DEBUG
            Section {
                NavigationLink("Developer") { DeveloperView() }
            } footer: {
                Text("Test builds only. Forces the scene, the splash and more, so each can be checked.")
            }
            .listRowBackground(Palette.paper)
            #endif
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
            Text("Shown beside what you log, so the family can see who added it. Optional.")
        }
        .listRowBackground(Palette.input)
    }

    private var lookSection: some View {
        Section {
            NavigationLink("Appearance and night") { AppearanceSettingsView() }
            NavigationLink("Units and words") { UnitsSettingsView() }
            NavigationLink("Weather on Today") { WeatherSettingsView() }
            NavigationLink("Reminders") { RemindersView() }
            Toggle("Touch feedback", isOn: $hapticsOn)
        } header: {
            Text("Look and feel")
        } footer: {
            Text("A small tap you feel when something is saved.")
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
                 ? "Just the buttons for logging. No timers, totals or Insights. Everything is still saved."
                 : "Timers, totals for the day, and Insights for the week.")
        }
        .listRowBackground(Palette.paper)
    }

    @ViewBuilder private var glanceSection: some View {
        if !justLog {
            Section {
                Toggle("Last feed on the Lock Screen", isOn: $glanceOn)
                    .onChange(of: glanceOn) { _, _ in LiveTimers.shared.sync(with: FamilyStore.live) }
            } footer: {
                Text("Time since the last feed, on the Lock Screen and in the Dynamic Island. Sleep and feed timers always show there.")
            }
            .listRowBackground(Palette.paper)
        }
    }

    private var stampsSection: some View {
        Section {
            Toggle("Stamps after the potty", isOn: $stickersOn)
        } footer: {
            Text("After the potty, your child stamps a card. Five stamps earn a shiny sticker.")
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
            Text("Face ID each time the app opens. Siri and the Lock Screen timer still work.")
        }
        .listRowBackground(Palette.paper)
    }

    private var outsideSection: some View {
        Section {
            NavigationLink { SiriView() } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Siri and shortcuts")
                    Text("Ready to use. See what to say.").font(.footnote).foregroundStyle(Palette.muted)
                }
            }
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
                 ? "These entries are made up. Your own family comes back when you leave."
                 : "Two made-up children and two weeks of entries, to see every screen filled in. Your family is untouched.")
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
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        if sample.isOn {
            // At the largest text sizes the button goes underneath, so words don't break.
            let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                                                      : AnyLayout(HStackLayout(spacing: 10))
            layout {
                Image(systemName: "eye")
                VStack(alignment: .leading, spacing: 1) {
                    Text("Sample family").font(.subheadline.weight(.semibold))
                    Text("Made-up entries. Yours are safe.").font(.footnote)
                }
                Spacer(minLength: 0)
                // The size goes inside the label, so the whole capsule can be tapped.
                Button { sample.leave() } label: {
                    Text("Leave")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(Palette.bannerButton, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Leave the sample family")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
            .foregroundStyle(Palette.bannerText)
            .background(Palette.banner, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.wattle.opacity(0.6), lineWidth: 1))
            .accessibilityElement(children: .contain)
        }
    }
}

extension Palette {
    /// The sample family banner: wattle by day, a deep mustard with wattle text after dark.
    static let banner = Color(light: 0xF4BE2C, dark: 0x3A2E0E, night: 0x241D09)
    static let bannerText = Color(light: 0x3A2A20, dark: 0xF6D57A, night: 0xD2B466)
    static let bannerButton = Color(light: 0xFBF6E9, dark: 0x564417, night: 0x3A2E10)
}
