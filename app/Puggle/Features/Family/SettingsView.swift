import SwiftUI

/// The keys for what a person chooses for themselves, on their own phone.
enum Setting {
    static let yourName = "yourName"
    static let appearance = "appearance"
    static let justLog = "justLog"
    /// A notice two days before a child reaches a new row on a saved tin.
    static let rowNotices = "rowNotices"
    static let pottyStickers = "pottyStickers"
    /// On the play pad, a stamp fades and stops after eight presses until an ink pad is pressed. Off unless chosen.
    static let stampInkRunsOut = "stampInkRunsOut"
    static let lockScreenGlance = "lockScreenGlance"
    static let haptics = "haptics"
    static let tilesCustom = "tilesCustom"
    static let tilesMain = "tilesMain"
    static let tilesHidden = "tilesHidden"
    static let appLock = "appLock"
    /// The fill in the activity icons: "yellow", "own" or "child". See `IconColour`.
    static let iconColour = "iconColour"
    /// The person's own colour for the icons, as 0xRRGGBB.
    static let iconColourOwn = "iconColourOwn"
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

/// Settings, reached from the Family tab.
///
/// Grouped by what a parent is trying to do (Tom, 15 November 2026: it felt crammed and confusing):
/// what Today shows, how the app looks, what shows away from the app, the children, privacy
/// and data, and help. Every section has a heading. A line of help sits inside the row it explains, so it
/// is never read as being about the whole group. Appearance, units, weather and reminders have their own screens.
struct SettingsView: View {
    @EnvironmentObject private var sample: SampleFamily
    @AppStorage(Setting.justLog) private var justLog = false
    @AppStorage(Setting.pottyStickers) private var stickersOn = true
    @AppStorage(Setting.stampInkRunsOut) private var inkRunsOut = false
    @AppStorage(Setting.lockScreenGlance) private var glanceOn = true
    @AppStorage(Setting.haptics) private var hapticsOn = true
    @AppStorage(Setting.appLock) private var lockOn = false
    @AppStorage(Setting.appearance) private var appearance = "system"
    @AppStorage(WeatherWatch.onKey) private var weatherOn = false
    @EnvironmentObject private var store: FamilyStore

    var body: some View {
        List {
            todaySection
            lookSection
            awaySection
            childrenSection
            privacySection
            helpSection
            testSection
        }
        .listSectionSpacing(28)
        .environment(\.defaultMinListRowHeight, 50)
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A group's heading, with a small icon so the groups can be told apart at a glance (Tom, 15 November 2026).
    private func heading(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).font(.footnote.weight(.semibold)).frame(width: 20).accessibilityHidden(true)
            Text(title).font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Palette.ink)
        .textCase(nil)
        .padding(.bottom, 2)
    }

    /// A row's name with one line of help under it.
    private func named(_ title: String, _ help: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).foregroundStyle(Palette.ink)
            Text(help).font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 3)
    }

    private var todaySection: some View {
        Section {
            HStack {
                named("Show", justLog ? "Only the buttons for logging. Everything is still saved."
                                      : "Timers, the day's totals and Insights.")
                Spacer(minLength: 8)
                Picker("Show", selection: $justLog) {
                    Text("Everything").tag(false)
                    Text("Just logging").tag(true)
                }
                .labelsHidden()
                .tint(Palette.muted)
            }
            .onChange(of: justLog) { _, _ in LiveTimers.shared.sync(with: FamilyStore.live) }
            NavigationLink { WeatherSettingsView() } label: {
                LabeledContent("Weather", value: weatherOn ? "On" : "Off")
            }
        } header: {
            heading("Today", "sun.max")
        }
        .listRowBackground(Palette.paper)
    }

    private var lookSection: some View {
        Section {
            NavigationLink { AppearanceSettingsView() } label: {
                LabeledContent("Appearance and night", value: appearance == "light" ? "Light" : appearance == "dark" ? "Dark" : "Same as iPhone")
            }
            NavigationLink("Units and words") { UnitsSettingsView() }
            Toggle(isOn: $hapticsOn) { named("Touch feedback", "A small tap when something is saved.") }
        } header: {
            heading("Look and feel", "paintbrush")
        }
        .listRowBackground(Palette.paper)
    }

    private var awaySection: some View {
        Section {
            if !justLog {
                Toggle(isOn: $glanceOn) {
                    named("Last feed on the Lock Screen", "Also in the Dynamic Island. Sleep and feed timers always show.")
                }
                .onChange(of: glanceOn) { _, _ in LiveTimers.shared.sync(with: FamilyStore.live) }
            }
            NavigationLink("Reminders") { RemindersView() }
            NavigationLink("Siri and shortcuts") { SiriView() }
        } header: {
            heading("Away from the app", "iphone")
        }
        .listRowBackground(Palette.paper)
    }

    private var childrenSection: some View {
        Section {
            Toggle(isOn: $stickersOn) { named("Stamps after the potty", "Five stamps earn a sticker.") }
            Toggle(isOn: $inkRunsOut) { named("Stamps run out of ink", "On the play pad, a stamp fades until an ink pad is pressed again.") }
        } header: {
            heading("Children", "figure.and.child.holdinghands")
        }
        .listRowBackground(Palette.paper)
    }

    private var privacySection: some View {
        Section {
            Toggle(isOn: Binding(get: { lockOn }, set: { wanted in
                // Ask before changing it either way, so only the phone's owner can.
                Task {
                    if await AppLock.authenticate(reason: wanted ? "Turn on the lock" : "Turn off the lock") {
                        lockOn = wanted
                    }
                }
            })) {
                named("Lock with Face ID", "Asked each time the app opens. Siri and Lock Screen timers still work.")
            }
            SyncRow()
            NavigationLink("Your data") { YourDataView() }
        } header: {
            heading("Privacy and data", "lock")
        }
        .listRowBackground(Palette.paper)
    }

    private var helpSection: some View {
        Section {
            NavigationLink("Help and about") { HelpView() }
            Button { if sample.isOn { sample.leave() } else { sample.start() } } label: {
                sample.isOn
                    ? named("Leave the sample family", "Your own family comes back.")
                    : named("Look around a sample family", "Two made-up children and two weeks of entries. Your family is untouched.")
            }
        } header: {
            heading("Help", "questionmark.circle")
        }
        .listRowBackground(Palette.paper)
    }

    @ViewBuilder private var testSection: some View {
        if TesterDetail.on {
            Section {
                NavigationLink { FeedbackView() } label: {
                    LabeledContent("Feedback notes", value: FeedbackNotes.load().isEmpty ? "" : "\(FeedbackNotes.load().count)")
                }
                NavigationLink("iCloud check") { CloudCheckView() }
                #if DEBUG
                NavigationLink("Developer") { DeveloperView() }
                #endif
            } header: {
                heading("Test builds only", "hammer")
            }
            .listRowBackground(Palette.paper)
        }
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
