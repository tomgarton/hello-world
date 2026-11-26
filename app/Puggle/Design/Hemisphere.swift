import Foundation

/// Which half of the world the family is in, for the seasons and the night sky: the aurora australis and the
/// Southern Cross in the south, the aurora borealis and the Plough in the north.
///
/// From where the weather last looked, if the weather is on (kept as whole degrees of latitude only, and only
/// which side of the equator is used). Otherwise from the phone's region.
enum Hemisphere {
    /// Whole degrees of latitude where the weather last looked.
    nonisolated static let latitudeKey = "liveLatitude"

    static let southernRegions: Set<String> = ["AU", "NZ", "ZA", "AR", "CL", "UY", "PY", "BO", "PE", "BR", "FJ", "PG",
                                                "NA", "BW", "ZW", "MZ", "MG", "LS", "SZ"]

    static var isSouth: Bool {
        let defaults = UserDefaults.standard
        #if DEBUG
        // For checking: launch with "-debugSouth 1" or "-debugSouth 0".
        if let forced = defaults.string(forKey: "debugSouth") { return forced == "1" }
        #endif
        if defaults.bool(forKey: WeatherWatch.onKey), let latitude = defaults.object(forKey: latitudeKey) as? Double {
            return latitude < 0
        }
        return isSouth(region: Locale.current.region?.identifier)
    }

    static func isSouth(region: String?) -> Bool { southernRegions.contains(region ?? "") }

    /// Roughly how far from the equator the family is, in degrees (south negative), for how the moon lies:
    /// where the weather last looked if it is on, otherwise a typical latitude for the phone's region.
    static var latitude: Double {
        let defaults = UserDefaults.standard
        #if DEBUG
        // For checking: "-debugLatitude 0" (the equator), "-34" (Sydney), "51" (London).
        if let forced = defaults.string(forKey: "debugLatitude").flatMap(Double.init) { return forced }
        #endif
        if defaults.bool(forKey: WeatherWatch.onKey), let latitude = defaults.object(forKey: latitudeKey) as? Double {
            return latitude
        }
        if let typical = typicalLatitude[Locale.current.region?.identifier ?? ""] {
            // A region that spans the equator still follows the family's choice of half, where forced.
            return isSouth == (typical < 0) ? typical : -typical
        }
        return isSouth ? -35 : 45
    }

    /// Where most people live, by region, to the nearest few degrees.
    static let typicalLatitude: [String: Double] = [
        "AU": -33, "NZ": -40, "ZA": -29, "AR": -34, "CL": -33, "UY": -34, "PY": -25, "BO": -17, "PE": -12, "BR": -20,
        "FJ": -18, "PG": -6, "NA": -22, "BW": -24, "ZW": -18, "MZ": -20, "MG": -19, "LS": -29, "SZ": -26,
        "SG": 1, "MY": 3, "ID": -6, "KE": -1, "UG": 0, "EC": -1, "CO": 5, "GH": 6, "NG": 8, "LK": 7, "PH": 14, "TH": 14, "IN": 22,
        "GB": 52, "IE": 53, "US": 38, "CA": 45, "FR": 46, "DE": 51, "NL": 52, "ES": 40, "IT": 42, "JP": 36, "CN": 32, "SE": 59, "NO": 60,
    ]
}
