import Foundation

/// Words that differ by region: a nappy in Australia and the UK is a diaper in
/// North America, and Mum is Mom. Follows the phone's region unless the parent
/// picks in Settings → Units and words. Spelling stays as written.
enum Terms {
    static let settingKey = "wordStyle"
    /// Shared with the widgets, so they use the same words.
    static let defaults = UserDefaults(suiteName: WidgetSnapshot.groupID) ?? .standard

    enum Style: String, CaseIterable, Identifiable {
        case auto, nappy, diaper
        var id: String { rawValue }
    }

    static var style: Style {
        get { Style(rawValue: defaults.string(forKey: settingKey) ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: settingKey) }
    }

    /// Regions where diaper and Mom are the everyday words.
    private static let diaperRegions: Set<String> = ["US", "CA", "PH", "PR", "GU", "VI", "AS", "MP"]

    static var usesDiaper: Bool {
        switch style {
        case .nappy: false
        case .diaper: true
        case .auto: diaperRegions.contains(Locale.current.region?.identifier ?? "")
        }
    }

    static var nappy: String { usesDiaper ? "Diaper" : "Nappy" }
    static var nappies: String { usesDiaper ? "Diapers" : "Nappies" }
    static var aNappy: String { usesDiaper ? "a diaper" : "a nappy" }
    static var nappyLower: String { usesDiaper ? "diaper" : "nappy" }
    static var nappiesLower: String { usesDiaper ? "diapers" : "nappies" }
    static var mum: String { usesDiaper ? "Mom" : "Mum" }
}
