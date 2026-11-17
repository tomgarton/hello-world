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
}
