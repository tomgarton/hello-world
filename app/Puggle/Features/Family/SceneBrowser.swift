import SwiftUI

/// Every scene in one place, for testers (Tom, 20 November 2026): pick a place, then see it at each time of
/// day, with any weather, season, moon and part of the world. In builds from Xcode and from TestFlight only
/// (`TesterDetail.on`); the App Store build never shows it. It changes nothing outside this page: every choice
/// is passed to the scenes directly, so Today is untouched.
struct SceneBrowserView: View {
    enum Place: String, CaseIterable, Identifiable {
        case hills = "Hills", beach = "Beach", backyard = "Backyard", bush = "Bush"
        case tea = "Tea", living = "Living room", playroom = "Play room", bedroom = "Bedroom"
        var id: String { rawValue }
        var outdoors: SceneKind? {
            switch self {
            case .hills: .hills
            case .beach: .beach
            case .backyard: .backyard
            case .bush: .bush
            default: nil
            }
        }
        var room: Room? {
            switch self {
            case .tea: .dining
            case .living: .living
            case .playroom: .playroom
            case .bedroom: .bedroom
            default: nil
            }
        }
    }

    /// The moon on the nights chosen: tonight's, or a phase.
    enum MoonChoice: String, CaseIterable, Identifiable {
        case tonight = "Tonight's", new = "New", crescent = "Crescent", half = "First quarter", gibbous = "Gibbous",
             full = "Full", waning = "Waning", last = "Last quarter"
        var id: String { rawValue }
        var age: Double? {
            switch self {
            case .tonight: nil
            case .new: 0.01
            case .crescent: 0.14
            case .half: 0.25
            case .gibbous: 0.38
            case .full: 0.5
            case .waning: 0.65
            case .last: 0.75
            }
        }
    }

    /// Where in the world, for which way up the moon is and how it lies.
    enum Where: String, CaseIterable, Identifiable {
        case here = "Here", north = "North (London)", equator = "Equator (Singapore)", south = "South (Sydney)"
        var id: String { rawValue }
        var latitude: Double? {
            switch self {
            case .here: nil
            case .north: 51
            case .equator: 1
            case .south: -34
            }
        }
    }

    /// The times shown, each its own picture. The night ones are a few hours apart, so the moon can be seen
    /// rising, crossing and setting.
    private static let times: [(name: String, hour: Int, dark: Bool)] = [
        ("Morning, 7:00", 7, false), ("Day, 13:00", 13, false), ("Evening, 18:00", 18, false),
        ("Night, 21:00", 21, false), ("Midnight", 0, false), ("Small hours, 3:00", 3, false), ("Dark mode by day", 13, true),
    ]

    @State private var place = Place.hills
    @State private var weather = Weather.clear
    @State private var season: SplashLook.Season?
    @State private var moon = MoonChoice.tonight
    @State private var whereOn = Where.here
    @State private var pull: CGFloat = 0
    @StateObject private var puggle = PuggleController()

    private var sky: SkyNow {
        var sky = SkyNow()
        if let age = moon.age { sky.age = age }
        if let latitude = whereOn.latitude { sky.latitude = latitude }
        return sky
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                controls
                ForEach(Self.times, id: \.name) { time in
                    picture(time)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Palette.sand)
        .navigationTitle("Every scene")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// One choice a row, each named on the left and its value on the right, like Settings.
    private var controls: some View {
        VStack(spacing: 0) {
            row("Place") {
                Picker("Place", selection: $place) { ForEach(Place.allCases) { Text($0.rawValue).tag($0) } }
            }
            row("Weather") {
                Picker("Weather", selection: $weather) { ForEach(Weather.allCases) { Text($0.name).tag($0) } }
            }
            row("Season") {
                Picker("Season", selection: $season) {
                    Text("This season").tag(SplashLook.Season?.none)
                    Text("Spring").tag(SplashLook.Season?.some(.spring))
                    Text("Summer").tag(SplashLook.Season?.some(.summer))
                    Text("Autumn").tag(SplashLook.Season?.some(.autumn))
                    Text("Winter").tag(SplashLook.Season?.some(.winter))
                }
                .disabled(place.outdoors == nil)
            }
            row("Moon") {
                Picker("Moon", selection: $moon) { ForEach(MoonChoice.allCases) { Text($0.rawValue).tag($0) } }
            }
            row("Where") {
                Picker("Where", selection: $whereOn) { ForEach(Where.allCases) { Text($0.rawValue).tag($0) } }
            }
            row("Pulled down") {
                Slider(value: $pull, in: 0...460).frame(maxWidth: 200)
            }
        }
        .pickerStyle(.menu)
        .tint(Palette.ink)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func row<Control: View>(_ name: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(name).foregroundStyle(Palette.ink)
            Spacer()
            control()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
    }

    @ViewBuilder private func picture(_ time: (name: String, hour: Int, dark: Bool)) -> some View {
        let night = PuggleScene.isNight(dark: time.dark, hour: time.hour)
        ZStack(alignment: .bottom) {
            if let kind = place.outdoors {
                PuggleScene(kind: kind, dark: time.dark, pull: pull, hourOverride: time.hour, weather: weather, season: season)
            } else if let room = place.room {
                RoomFrame(room: room, dark: time.dark || time.hour >= 21 || time.hour < 5, pull: pull, hour: time.hour, weather: weather)
            }
            PuggleView(controller: puggle).frame(height: 118).padding(.bottom, 26)
                .environment(\.outfit, place.outdoors == nil ? "none" : weather.outfit(night: night))
                .environment(\.moonlit, night && place.outdoors != nil)
                .environment(\.warmLight, place.outdoors.flatMap { PuggleScene.lamp(for: $0, night: night) } ?? place.room?.lamp)
        }
        .frame(height: PuggleHeader.sceneHeight + pull)
        .clipped()
        .overlay(alignment: .topLeading) {
            Text(time.name).font(.caption2.weight(.semibold)).padding(.horizontal, 7).padding(.vertical, 3)
                .background(.black.opacity(0.35), in: Capsule()).foregroundStyle(.white).padding(8)
        }
        .environment(\.colorScheme, time.dark ? .dark : .light)
        .environment(\.skyNow, sky)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(place.rawValue), \(time.name)")
    }
}
