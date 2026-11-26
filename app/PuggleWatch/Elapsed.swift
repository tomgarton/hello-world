import Foundation

/// How long, kept short: "8 min", "1h 05m". The same words as the iPhone app (its copy is in Model.swift).
enum Elapsed {
    static func short(from start: Date, to end: Date) -> String {
        let minutes = max(Int(end.timeIntervalSince(start) / 60), 0)
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h \(String(format: "%02d", m))m" : "\(m) min"
    }
}
