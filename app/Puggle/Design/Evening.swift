import Foundation

/// Puggle's evening follows the real children's (Tom, 19 November 2026). If the family logs sleep, she goes to
/// bed when they are all asleep; if not, at a usual bedtime for the oldest child's age. For half an hour before
/// that she sits up in bed reading, and she stirs when a child is seen to in the night.
///
/// Today sets what it knows about the children here; the scenes read it, as they read the clock.
struct Evening: Equatable {
    /// Minutes after midnight the oldest child would usually go to sleep.
    var bedtime = 19 * 60 + 15
    /// The family has logged a sleep in the last two days, so the logs are followed rather than the clock.
    var followsLogs = false
    /// Every child on Today has a sleep running.
    var allAsleep = false
    /// When something was last logged for a child, for her stirring in the night.
    var lastLogged: Date?

    /// What Today last said. Read by the rooms and the scene.
    nonisolated(unsafe) static var now = Evening()

    /// A usual bedtime by age, as minutes after midnight: babies about seven, toddlers a little after, four to
    /// six year olds by eight.
    static func bedtime(ageMonths: Int) -> Int {
        switch ageMonths {
        case ..<12: 19 * 60
        case ..<36: 19 * 60 + 15
        case ..<72: 19 * 60 + 45
        default: 20 * 60
        }
    }

    /// How long she reads in bed before she sleeps.
    static let windDown = 30

    /// Minutes after midnight, from the clock or the Developer menu ("-debugHour 20" is 20:00).
    static var minuteNow: Int {
        #if DEBUG
        if UserDefaults.standard.string(forKey: "debugHour") != nil {
            let minute = UserDefaults.standard.string(forKey: "debugMinute").flatMap(Int.init) ?? 0
            return Room.hourNow * 60 + minute
        }
        #endif
        let parts = Calendar.current.dateComponents([.hour, .minute], from: .now)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// True from the start of her wind-down in the evening until six in the morning: she is in her bedroom.
    func inBedroom(minute: Int) -> Bool {
        if minute < 6 * 60 { return true }
        if minute < 18 * 60 + 30 { return false }
        // Asleep already, as logged, after tea.
        if followsLogs && allAsleep { return true }
        return minute >= bedtime - Self.windDown
    }

    /// What she is doing in her bedroom at this minute.
    func pose(minute: Int, at date: Date = .now) -> BedPose {
        #if DEBUG
        // For checking: "-debugBed reading", "asleep", "stirring" or "up".
        if let forced = UserDefaults.standard.string(forKey: "debugBed").flatMap(BedPose.init(rawValue:)) { return forced }
        #endif
        let night = minute < 6 * 60 || minute >= 22 * 60
        // A child seen to in the night: she sits up, sleepy, for a few minutes.
        if night, let lastLogged, date.timeIntervalSince(lastLogged) < 8 * 60, date >= lastLogged { return .stirring }
        if followsLogs {
            if allAsleep { return .asleep }
            return night ? .stirring : .reading
        }
        let asleep = minute < 6 * 60 || minute >= bedtime
        return asleep ? .asleep : .reading
    }

    /// One evening in five a friend comes for tea and stays the night.
    static var sleepover: CastMember? {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now.addingTimeInterval(-6 * 3600)) ?? 0
        let friends: [CastMember] = [.kip, .quill, .digby, .sunny, .pebble]
        #if DEBUG
        // For checking: "-debugSleepover kip", or "none".
        if let forced = UserDefaults.standard.string(forKey: "debugSleepover") { return CastMember(rawValue: forced) }
        #endif
        guard day % 5 == 2 else { return nil }
        return friends[(day / 5) % friends.count]
    }
}

/// Puggle in her bedroom.
enum BedPose: String {
    /// Standing on the rug, as before bed.
    case up
    /// Sitting up in bed with her book.
    case reading
    /// Tucked in, the quilt up to her chin.
    case asleep
    /// Sitting up, sleepy, while a child is seen to in the night.
    case stirring
}
