import CoreLocation
import SwiftUI
#if !LOCAL_ONLY
import WeatherKit
#endif

/// Finds out what the weather is doing outside, for the scene on Today.
///
/// Only when the parent has switched it on. It asks the phone for a rough
/// location (a few kilometres is plenty), asks Apple's weather service about
/// that spot, and keeps one word: "rain", "windy" and so on. The location is
/// not saved, and nothing else in the app sees it.
@MainActor
final class WeatherWatch: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherWatch()

    /// The parent's switch in Settings.
    static let onKey = "weatherOn"
    /// The last weather found, as a `Weather` raw value, and when.
    static let liveKey = "liveWeather"
    static let liveAtKey = "liveWeatherAt"

    private let manager = CLLocationManager()
    private var asking = false

    /// Shown in Settings when it cannot work: location refused, or no weather to be had.
    @Published var trouble: String?

    override private init() {
        super.init()
        manager.delegate = self
        // A few kilometres is all the weather needs.
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    var isOn: Bool { UserDefaults.standard.bool(forKey: Self.onKey) }

    /// The weather to show: the Developer menu's choice if one is made, else the
    /// real weather if it is on and recent, else a fine day.
    static func resolve(chosen: String, live: String, on: Bool) -> Weather {
        if let forced = Weather(rawValue: chosen) { return forced }
        guard on, let real = Weather(rawValue: live) else { return .clear }
        // Weather from hours ago is no longer the weather.
        let age = Date.now.timeIntervalSince1970 - UserDefaults.standard.double(forKey: liveAtKey)
        return age < 3 * 3600 ? real : .clear
    }

    /// Switched on in Settings: ask for the location, then look.
    func turnOn() {
        UserDefaults.standard.set(true, forKey: Self.onKey)
        trouble = nil
        refresh(force: true)
    }

    func turnOff() {
        UserDefaults.standard.set(false, forKey: Self.onKey)
        UserDefaults.standard.removeObject(forKey: Self.liveKey)
        UserDefaults.standard.removeObject(forKey: Self.liveAtKey)
        trouble = nil
    }

    /// Looks again if it is on and the last look was a while ago. Called when the app comes to the front.
    func refresh(force: Bool = false) {
        guard isOn, !asking else { return }
        let age = Date.now.timeIntervalSince1970 - UserDefaults.standard.double(forKey: Self.liveAtKey)
        guard force || age > 30 * 60 else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            trouble = "Location is off for this app. You can allow it in the Settings app, under Privacy, Location Services."
        default:
            asking = true
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways: self.refresh(force: true)
            case .denied, .restricted:
                if self.isOn { self.trouble = "Location is off for this app. You can allow it in the Settings app, under Privacy, Location Services." }
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let place = locations.last else { return }
        Task { @MainActor in await self.look(at: place) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.asking = false
            self.trouble = "Couldn't find where you are just now. It will try again later."
        }
    }

    private func look(at place: CLLocation) async {
        defer { asking = false }
        #if LOCAL_ONLY
        // The free test build has no weather service.
        trouble = "This test build can't reach the weather service."
        #else
        do {
            let now = try await WeatherService.shared.weather(for: place, including: .current)
            let found = Self.kind(of: now)
            UserDefaults.standard.set(found.rawValue, forKey: Self.liveKey)
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Self.liveAtKey)
            trouble = nil
        } catch {
            trouble = "Couldn't get the weather just now. It will try again later."
        }
        #endif
    }

    #if !LOCAL_ONLY
    /// Turns Apple's many kinds of weather into the few the scenes can show.
    static func kind(of now: CurrentWeather) -> Weather {
        let degrees = now.temperature.converted(to: .celsius).value
        let wind = now.wind.speed.converted(to: .kilometersPerHour).value
        switch now.condition {
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .tropicalStorm, .hurricane:
            return .storm
        case .rain, .heavyRain, .drizzle, .freezingDrizzle, .freezingRain, .sunShowers, .hail:
            return .rain
        case .snow, .heavySnow, .flurries, .sleet, .blizzard, .blowingSnow, .wintryMix, .sunFlurries:
            return .snow
        case .foggy, .haze, .smoky, .blowingDust:
            return .fog
        case .windy, .breezy:
            return .windy
        case .hot:
            return .hot
        case .frigid:
            return .cold
        default:
            break
        }
        return kind(degrees: degrees, wind: wind)
    }
    #endif

    /// For a dry, clear-ish day: is it windy, hot or cold enough to show?
    static func kind(degrees: Double, wind: Double) -> Weather {
        if wind >= 35 { return .windy }
        if degrees >= 30 { return .hot }
        if degrees <= 8 { return .cold }
        return .clear
    }
}
