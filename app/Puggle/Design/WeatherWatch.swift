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
    nonisolated static let onKey = "weatherOn"
    /// The last weather found, as a `Weather` raw value, and when.
    static let liveKey = "liveWeather"
    static let liveAtKey = "liveWeatherAt"
    /// The temperature that went with it, in Celsius, for the line at the top of Today.
    static let degreesKey = "liveDegrees"
    /// Today's sunrise and sunset where the family is, as seconds since 1970, for the scene's sky.
    nonisolated static let sunriseKey = "liveSunrise"
    nonisolated static let sunsetKey = "liveSunset"

    /// The sun's times for the day `moment` falls on, if the weather is on and it has them. Otherwise nil,
    /// and the sky keeps to fixed hours.
    nonisolated static func sun(on moment: Date) -> (rise: Date, set: Date)? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: onKey) else { return nil }
        let rise = defaults.double(forKey: sunriseKey), set = defaults.double(forKey: sunsetKey)
        guard rise > 0, set > rise else { return nil }
        let sunrise = Date(timeIntervalSince1970: rise), sunset = Date(timeIntervalSince1970: set)
        // Yesterday's times are close enough for a day or two; older than that, the season has moved.
        guard abs(moment.timeIntervalSince(sunrise)) < 3 * 86_400 else { return nil }
        let calendar = Calendar.current
        func today(_ time: Date) -> Date? {
            let parts = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: moment)
        }
        guard let a = today(sunrise), let b = today(sunset), b > a else { return nil }
        return (a, b)
    }

    private let manager = CLLocationManager()
    private var asking = false

    /// Shown in Settings when it cannot work: location refused, or no weather to be had.
    @Published var trouble: String?
    /// The weather service's own words for the last failure, shown under the message in test builds only.
    @Published var troubleDetail: String?

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

    /// The real weather in words for the top of Today, if it is on and under three hours old: "18° and
    /// raining outside." Nil when the weather is off or stale; a made-up fine day is not reported.
    static func words(now: Date = .now) -> String? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: onKey), let kind = Weather(rawValue: defaults.string(forKey: liveKey) ?? ""),
              now.timeIntervalSince1970 - defaults.double(forKey: liveAtKey) < 3 * 3600 else { return nil }
        let degrees = defaults.object(forKey: degreesKey) as? Double
        return TodayHeading.weather(kind, degrees: degrees.map { Int(Units.temperatureValue($0).rounded()) })
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
        UserDefaults.standard.removeObject(forKey: Self.degreesKey)
        UserDefaults.standard.removeObject(forKey: Self.sunriseKey)
        UserDefaults.standard.removeObject(forKey: Self.sunsetKey)
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
            let (now, days) = try await WeatherService.shared.weather(for: place, including: .current, .daily)
            let found = Self.kind(of: now)
            if let sun = days.first?.sun, let rise = sun.sunrise, let set = sun.sunset {
                UserDefaults.standard.set(rise.timeIntervalSince1970, forKey: Self.sunriseKey)
                UserDefaults.standard.set(set.timeIntervalSince1970, forKey: Self.sunsetKey)
            }
            UserDefaults.standard.set(found.rawValue, forKey: Self.liveKey)
            UserDefaults.standard.set(now.temperature.converted(to: .celsius).value, forKey: Self.degreesKey)
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Self.liveAtKey)
            trouble = nil
            troubleDetail = nil
        } catch {
            trouble = "Couldn't get the weather just now. It will try again later."
            let detail = error as NSError
            troubleDetail = "\(detail.domain) \(detail.code): \(detail.localizedDescription)"
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
        case .sunShowers:
            return .showers
        case .rain, .heavyRain, .drizzle, .freezingDrizzle, .freezingRain, .hail:
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
