import SwiftUI

/// Light or dark, and when the dim night look comes on by itself.
struct AppearanceSettingsView: View {
    @AppStorage(Setting.appearance) private var appearance = "system"
    @AppStorage(Setting.nightMode) private var nightMode = Setting.nightModeDefault
    @AppStorage(Setting.nightFrom) private var nightFrom = Setting.nightFromDefault
    @AppStorage(Setting.nightUntil) private var nightUntil = Setting.nightUntilDefault

    private var usesHours: Bool { nightMode == "hours" || nightMode == "both" }

    var body: some View {
        List {
            appearanceSection
            nightSection
            if usesHours { hoursSection }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Appearance and night")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $appearance) {
                Text("Same as iPhone").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        } footer: {
            Text("How the app looks during the day.")
        }
        .listRowBackground(Palette.paper)
    }

    private var nightSection: some View {
        Section {
            Picker("Night look", selection: $nightMode) {
                Text("Off").tag("off")
                Text("At set times").tag("hours")
                Text("While a child sleeps").tag("sleep")
                Text("Both").tag("both")
            }
        } header: {
            Text("Night")
        } footer: {
            Text(nightFooter)
        }
        .listRowBackground(Palette.paper)
    }

    private var nightFooter: String {
        switch nightMode {
        case "off":
            return "The night look stays off. The Night look filter in a Focus still turns the app dark."
        case "sleep":
            return "Very dim, warm text on near-black while any child has a sleep running. It comes on by itself, whatever is chosen above."
        case "both":
            return "Very dim, warm text on near-black between these times and while any child has a sleep running. It comes on by itself, whatever is chosen above."
        default:
            return "Very dim, warm text on near-black between these times. It comes on by itself, whatever is chosen above."
        }
    }

    private var hoursSection: some View {
        Section {
            DatePicker("From", selection: time($nightFrom), displayedComponents: .hourAndMinute)
            DatePicker("Until", selection: time($nightUntil), displayedComponents: .hourAndMinute)
        } footer: {
            Text("The times can run past midnight, such as 9 pm until 6 am.")
        }
        .listRowBackground(Palette.paper)
    }

    /// A time of day for the picker, kept as minutes after midnight.
    private func time(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(get: {
            let value = minutes.wrappedValue
            return Calendar.current.date(bySettingHour: value / 60, minute: value % 60, second: 0, of: .now) ?? .now
        }, set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        })
    }
}

/// The units a person prefers. Kept for later: nothing is converted yet.
struct UnitsSettingsView: View {
    @AppStorage(Setting.volumeUnit) private var volumeUnit = "ml"
    @AppStorage(Setting.weightUnit) private var weightUnit = "g"
    @AppStorage(Setting.temperatureUnit) private var temperatureUnit = "c"
    /// Only to redraw when the words change; the choice itself lives in Terms.
    @State private var words = Terms.style.rawValue

    var body: some View {
        List {
            Section {
                volumePicker
                weightPicker
                temperaturePicker
            } footer: {
                Text("Changes how amounts are shown and typed. Entries already saved don't change.")
            }
            .listRowBackground(Palette.paper)
            Section {
                Picker("Words", selection: Binding(get: { Terms.style }, set: { Terms.style = $0; words = $0.rawValue })) {
                    Text("As this iPhone's region").tag(Terms.Style.auto)
                    Text("Nappy, Mum").tag(Terms.Style.nappy)
                    Text("Diaper, Mom").tag(Terms.Style.diaper)
                }
                .id(words)
            } footer: {
                Text("Now: \(Terms.nappy), \(Terms.mum).")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Units and words")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var volumePicker: some View {
        Picker("Volume", selection: $volumeUnit) {
            Text("Millilitres").tag("ml")
            Text("Ounces").tag("oz")
        }
    }

    private var weightPicker: some View {
        Picker("Weight", selection: $weightUnit) {
            Text("Grams and kilograms").tag("g")
            Text("Pounds and ounces").tag("lb")
        }
    }

    private var temperaturePicker: some View {
        Picker("Temperature", selection: $temperatureUnit) {
            Text("Celsius").tag("c")
            Text("Fahrenheit").tag("f")
        }
    }
}

/// The one place the app asks about location: to show the weather outside at the top of Today.
struct WeatherSettingsView: View {
    @AppStorage(WeatherWatch.onKey) private var isOn = false
    @AppStorage(WeatherWatch.liveKey) private var live = ""
    @ObservedObject private var watch = WeatherWatch.shared

    var body: some View {
        List {
            Section {
                Toggle("Match the weather outside", isOn: Binding(get: { isOn }, set: { on in
                    if on { watch.turnOn() } else { watch.turnOff() }
                }))
            } footer: {
                Text("The picture at the top of Today shows rain, sun, wind or snow, as it is where you are, and the little platypus dresses for it.")
            }
            .listRowBackground(Palette.paper)

            Section {
                Label("It uses your rough location, to within a few kilometres.", systemImage: "location")
                Label("Your location isn't saved, and isn't shared with your family or with us.", systemImage: "lock")
                Label("Nothing else in the app uses it. Switch this off and it stops.", systemImage: "hand.raised")
            } header: {
                Text("What this uses")
            }
            .font(.subheadline)
            .foregroundStyle(Palette.ink)
            .listRowBackground(Palette.paper)

            if isOn {
                Section {
                    if let trouble = watch.trouble {
                        Text(trouble).foregroundStyle(Palette.ink)
                    } else if let now = Weather(rawValue: live) {
                        Text("Now: \(now.name.lowercased()).").foregroundStyle(Palette.ink)
                    } else {
                        Text("Looking outside.").foregroundStyle(Palette.muted)
                    }
                } footer: {
                    // Apple asks that its weather service is named wherever its data is used.
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weather from \u{F8FF} Weather.")
                        if let link = URL(string: "https://weatherkit.apple.com/legal-attribution.html") {
                            Link("Where the weather comes from", destination: link)
                        }
                    }
                }
                .listRowBackground(Palette.paper)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Weather on Today")
        .navigationBarTitleDisplayMode(.inline)
    }
}
