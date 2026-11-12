import Foundation

/// Showing and typing amounts in the parent's units. Everything is stored in
/// millilitres, grams and Celsius; only what is shown changes, so switching
/// units never alters an entry.
enum Units {
    static let mlPerOz = 29.5735
    static let gramsPerPound = 453.592
    static let gramsPerOunce = 28.3495

    static var ounces: Bool { UserDefaults.standard.string(forKey: Setting.volumeUnit) == "oz" }
    static var pounds: Bool { UserDefaults.standard.string(forKey: Setting.weightUnit) == "lb" }
    static var fahrenheit: Bool { UserDefaults.standard.string(forKey: Setting.temperatureUnit) == "f" }

    /// "150 ml" or "5 oz" (to the nearest quarter ounce).
    static func volume(_ ml: Double) -> String {
        guard ounces else { return "\(Int(ml.rounded())) ml" }
        return "\(trim((ml / mlPerOz * 4).rounded() / 4)) oz"
    }

    /// The number shown in the amount field, and its unit.
    static func volumeValue(_ ml: Double) -> Double { ounces ? (ml / mlPerOz * 4).rounded() / 4 : ml.rounded() }
    static func volumeFromValue(_ value: Double) -> Double { ounces ? value * mlPerOz : value }
    static var volumeUnit: String { ounces ? "oz" : "ml" }
    /// One press of the − and + buttons.
    static var volumeStep: Double { ounces ? 0.5 * mlPerOz : 10 }

    /// "7.25 kg" (or "850 g" under a kilogram), or "15 lb 15 oz".
    static func weight(_ grams: Double) -> String {
        if pounds {
            let totalOunces = (grams / gramsPerOunce).rounded()
            let lb = Int(totalOunces / 16), oz = Int(totalOunces) % 16
            return lb > 0 ? "\(lb) lb \(oz) oz" : "\(oz) oz"
        }
        return grams >= 1000 ? "\(trim((grams / 10).rounded() / 100)) kg" : "\(Int(grams.rounded())) g"
    }

    /// A change in weight, signed: "+250 g" or "+9 oz".
    static func weightChange(_ grams: Double) -> String {
        let sign = grams > 0 ? "+" : (grams < 0 ? "−" : "")
        let size = abs(grams)
        if pounds {
            let totalOunces = (size / gramsPerOunce).rounded()
            let lb = Int(totalOunces / 16), oz = Int(totalOunces) % 16
            return sign + (lb > 0 ? "\(lb) lb \(oz) oz" : "\(oz) oz")
        }
        return sign + (size >= 1000 ? "\(trim((size / 10).rounded() / 100)) kg" : "\(Int(size.rounded())) g")
    }

    /// "37.2 °C" or "99.0 °F".
    static func temperature(_ celsius: Double) -> String {
        let value = fahrenheit ? celsius * 9 / 5 + 32 : celsius
        return "\(value.formatted(.number.precision(.fractionLength(1)))) \(temperatureUnit)"
    }

    static func temperatureValue(_ celsius: Double) -> Double { fahrenheit ? celsius * 9 / 5 + 32 : celsius }
    static func temperatureFromValue(_ value: Double) -> Double { fahrenheit ? (value - 32) * 5 / 9 : value }
    static var temperatureUnit: String { fahrenheit ? "°F" : "°C" }

    /// 5, 5.5, 5.25: no trailing zeros.
    private static func trim(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}
