import Foundation

/// The words at the top of Today. The heading is a greeting for the time of day; the date is not shown, since
/// the phone has it. Under it, one thing at a time, whichever comes first of: a medicine that is due, who is
/// asleep or feeding, last night's sleep (early in the morning), the day in numbers, and the weather when
/// nothing has been logged yet (Tom's choices, 15 November 2026).
enum TodayHeading {
    /// "Morning, Tom". From 10 at night to 5 in the morning it is a plain "Hello".
    static func greeting(hour: Int, name: String) -> String {
        let word = switch hour {
        case 5..<12: "Morning"
        case 12..<17: "Afternoon"
        case 17..<22: "Evening"
        default: "Hello"
        }
        let name = name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? word : "\(word), \(name)"
    }

    /// Last night's sleep is the news until ten; after that the day has its own numbers.
    static func isEarly(hour: Int) -> Bool { (5..<10).contains(hour) }

    /// What there is to say, in the order it is chosen from. Each is empty or nil when it does not apply.
    struct Facts {
        /// "Due for Ollie · Calpol · 14:00", one for each.
        var due: [String] = []
        /// Who is asleep, with how long for when counting is on: ("Bea", "40 min").
        var asleep: [(name: String, length: String?)] = []
        var feeding: [String] = []
        /// "Ollie slept 9h 20m last night · Woke twice". Only given early in the morning.
        var lastNight: String?
        /// "Ollie: 4 feeds, 510 ml · 3 nappies", one for each child with anything logged today.
        var numbers: [String] = []
        /// "18° and raining outside."
        var weather: String?
    }

    static func line(_ facts: Facts) -> String {
        if !facts.due.isEmpty { return facts.due.prefix(2).joined(separator: "\n") }
        if facts.asleep.count == 1, let one = facts.asleep.first {
            return one.length.map { "\(one.name) has been asleep for \($0)." } ?? "\(one.name) is asleep."
        }
        if facts.asleep.count > 1 {
            return "\(ListFormatter.localizedString(byJoining: facts.asleep.map(\.name))) are asleep."
        }
        if !facts.feeding.isEmpty {
            return "\(ListFormatter.localizedString(byJoining: facts.feeding)) \(facts.feeding.count == 1 ? "is" : "are") feeding."
        }
        if let night = facts.lastNight { return night }
        // A line for each child, three at most: more than that is the day's page, not a glance.
        if !facts.numbers.isEmpty { return facts.numbers.prefix(3).joined(separator: "\n") }
        return facts.weather ?? ""
    }

    /// "18° and raining outside." The number is left out when there is none.
    static func weather(_ kind: Weather, degrees: Int?) -> String {
        let word = switch kind {
        case .clear: "fine"
        case .rain: "raining"
        case .storm: "stormy"
        case .hot: "hot"
        case .windy: "windy"
        case .cold: "cold"
        case .snow: "snowing"
        case .fog: "foggy"
        case .showers: "showery"
        }
        guard let degrees else { return word.prefix(1).uppercased() + word.dropFirst() + " outside." }
        return "\(degrees)° and \(word) outside."
    }
}
