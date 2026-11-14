import SwiftUI

/// Decides when the night look is on: between two times of day, while a child
/// sleeps, or both. The look itself is the `night:` values in `Palette`.
@MainActor
final class NightMode: ObservableObject {
    @Published private(set) var isNight: Bool

    private var anyChildAsleep: Bool
    private var timer: Timer?
    private var settingsObserver: NSObjectProtocol?

    init(anyChildAsleep: Bool = false) {
        self.anyChildAsleep = anyChildAsleep
        let night = NightMode.wanted(at: .now, anyChildAsleep: anyChildAsleep)
        isNight = night
        Palette.isNight = night

        // Any setting changing, here or in a Focus filter, asks again.
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // Once a minute is enough to catch the two times of day. It does not run while the app is suspended.
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer.tolerance = 10
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit {
        timer?.invalidate()
        if let settingsObserver { NotificationCenter.default.removeObserver(settingsObserver) }
    }

    /// True when the setting takes sleeping children into account.
    var usesSleep: Bool {
        let mode = NightMode.mode
        return mode == "sleep" || mode == "both"
    }

    func refresh(anyChildAsleep: Bool) {
        self.anyChildAsleep = anyChildAsleep
        refresh()
    }

    func refresh() {
        let night = NightMode.wanted(at: .now, anyChildAsleep: anyChildAsleep)
        guard night != isNight else { return }
        // The colours must know before the views are rebuilt.
        Palette.isNight = night
        Palette.nightChangedAt = .now
        isNight = night
    }

    // MARK: Working it out

    private static var mode: String {
        UserDefaults.standard.string(forKey: Setting.nightMode) ?? Setting.nightModeDefault
    }

    private static func minutes(_ key: String, default fallback: Int) -> Int {
        let stored = UserDefaults.standard.object(forKey: key) as? Int ?? fallback
        return min(max(stored, 0), 24 * 60 - 1)
    }

    private static func wanted(at date: Date, anyChildAsleep: Bool) -> Bool {
        let mode = self.mode
        let byHours = (mode == "hours" || mode == "both") && inHours(date)
        let bySleep = (mode == "sleep" || mode == "both") && anyChildAsleep
        return byHours || bySleep
    }

    /// Whether a time of day falls in the chosen range, which may wrap past midnight.
    static func inHours(_ date: Date) -> Bool {
        let from = minutes(Setting.nightFrom, default: Setting.nightFromDefault)
        let until = minutes(Setting.nightUntil, default: Setting.nightUntilDefault)
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let now = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if from == until { return false }
        return from < until ? (now >= from && now < until) : (now >= from || now < until)
    }
}
