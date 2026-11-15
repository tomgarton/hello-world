import SwiftUI

/// Light or dark, and when the dim night look comes on by itself.
struct AppearanceSettingsView: View {
    @AppStorage(Setting.appearance) private var appearance = "system"
    @AppStorage(Setting.nightMode) private var nightMode = Setting.nightModeDefault
    @AppStorage(Setting.nightFrom) private var nightFrom = Setting.nightFromDefault
    @AppStorage(Setting.nightUntil) private var nightUntil = Setting.nightUntilDefault
    @AppStorage(Setting.iconColour) private var iconColour = IconColour.yellow.rawValue
    @AppStorage(Setting.iconColourOwn) private var iconOwn = IconColour.ownDefault

    private var usesHours: Bool { nightMode == "hours" || nightMode == "both" }

    var body: some View {
        List {
            appearanceSection
            iconSection
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
            Text("How the app looks by day.")
        }
        .listRowBackground(Palette.paper)
    }

    private var iconSection: some View {
        Section {
            Picker("Icon colour", selection: $iconColour) {
                ForEach(IconColour.allCases) { Text($0.title).tag($0.rawValue) }
            }
            if iconColour == IconColour.own.rawValue {
                ColorPicker("Colour", selection: ownColour, supportsOpacity: false)
            }
            HStack(spacing: 14) {
                ForEach([EventKind.bottle, .sleep, .nappy, .solids, .potty, .breastfeed]) { kind in
                    ActivityIcon(kind, size: 36)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .environment(\.iconChildColour, Palette.childColour(0))
            .accessibilityHidden(true)
        } header: {
            Text("Icons")
        } footer: {
            Text(iconFooter)
        }
        .listRowBackground(Palette.paper)
    }

    private var iconFooter: String {
        switch IconColour(rawValue: iconColour) ?? .yellow {
        case .yellow: "The colour inside each icon. Skin tones stay as they are."
        case .own: "Choose any colour. Skin tones stay as they are."
        case .child: "Each child's icons take their colour. Anything shared stays yellow."
        }
    }

    /// The person's own colour for the picker, kept as 0xRRGGBB.
    private var ownColour: Binding<Color> {
        Binding(get: {
            Color(hex: UInt32(truncatingIfNeeded: iconOwn))
        }, set: { colour in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(colour).getRed(&r, green: &g, blue: &b, alpha: &a)
            let byte = { (v: CGFloat) in Int((min(max(v, 0), 1) * 255).rounded()) }
            iconOwn = byte(r) << 16 | byte(g) << 8 | byte(b)
        })
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
            return "A Focus with the Night look filter can still turn it on."
        case "sleep":
            return "Dim, warm text on black while a child is asleep, whatever Appearance is set to."
        case "both":
            return "Dim, warm text on black between these times and while a child is asleep, whatever Appearance is set to."
        default:
            return "Dim, warm text on black between these times, whatever Appearance is set to."
        }
    }

    private var hoursSection: some View {
        Section {
            DatePicker("From", selection: time($nightFrom), displayedComponents: .hourAndMinute)
            DatePicker("Until", selection: time($nightUntil), displayedComponents: .hourAndMinute)
        } footer: {
            Text("The times can run past midnight.")
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
                Text("How amounts are shown and typed. Saved entries don't change.")
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
                WeatherPreview(live: isOn && watch.trouble == nil ? Weather(rawValue: live) : nil)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                Toggle("Match the weather outside", isOn: Binding(get: { isOn }, set: { on in
                    if on { watch.turnOn() } else { watch.turnOff() }
                }))
                if isOn {
                    if let trouble = watch.trouble {
                        Text(trouble).foregroundStyle(Palette.ink)
                        // Test builds only: why, in the weather service's own words.
                        if TesterDetail.on, let detail = watch.troubleDetail {
                            Text(detail).font(.footnote.monospaced()).foregroundStyle(Palette.muted).textSelection(.enabled)
                        }
                    } else if Weather(rawValue: live) == nil {
                        LabeledContent("Now", value: "Checking")
                    }
                }
            } footer: {
                Text("The picture at the top of Today shows the weather where you are: rain, sun, wind or snow.")
            }
            .listRowBackground(Palette.paper)

            Section {
                Text("Uses your rough location, to within a few kilometres.")
                Text("It isn't saved or shared, and nothing else in the app uses it.")
            } header: {
                Text("Location")
            } footer: {
                // Apple asks that its weather service is named, with this link, wherever its data is used.
                if isOn, let link = URL(string: "https://weatherkit.apple.com/legal-attribution.html") {
                    HStack(spacing: 6) {
                        Text("\u{F8FF} Weather")
                        Link("Data sources", destination: link)
                    }
                    .font(.footnote)
                    .padding(.top, 6)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Palette.ink)
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Weather on Today")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Puggle in her scene, at the top of the weather page, showing what the switch does (Tom, 15 November 2026).
/// With the weather on it is the weather outside now. With it off, it steps through a few kinds as examples,
/// by day so each can be seen. With Reduce Motion it holds on rain.
private struct WeatherPreview: View {
    /// The real weather, when it is on and known.
    let live: Weather?

    @StateObject private var controller = PuggleController()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.puggleNight) private var night
    @State private var step = 0
    private static let examples: [Weather] = [.rain, .clear, .windy, .snow, .hot]

    private var weather: Weather { live ?? Self.examples[step % Self.examples.count] }

    var body: some View {
        let dark = live != nil && (scheme == .dark || night)
        let after = live != nil && PuggleScene.isNight(dark: dark)
        let wearing = weather.outfit(night: after)
        ZStack(alignment: .bottom) {
            PuggleScene(kind: .today, dark: dark, hourOverride: live == nil ? 11 : nil, weather: weather)
            PuggleView(controller: controller)
                .environment(\.moonlit, after)
                .environment(\.outfit, wearing)
                .environment(\.shades, Shades.forOutfit(wearing))
                .frame(height: 104)
                .padding(.bottom, 22)
                .id(wearing)
        }
        .frame(height: 190)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text(live == nil ? "For example: \(weather.name.lowercased())" : weather.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.fixedInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Palette.fixedPaper.opacity(0.9), in: Capsule())
                .padding(10)
        }
        .animation(.easeInOut(duration: 0.6), value: weather)
        .accessibilityElement()
        .accessibilityLabel(live == nil ? "A picture of Puggle in the \(weather.name.lowercased())" : "Puggle in today's weather: \(weather.name.lowercased())")
        .task(id: live == nil) {
            guard live == nil, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.5))
                step += 1
            }
        }
    }
}
