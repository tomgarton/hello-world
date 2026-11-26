import Foundation

/// A fact tapped in a widget or on the Lock Screen opens Puggle at the sheet that logs the next one, for that
/// child (Tom, 15 November 2026). The tap only opens the sheet: nothing is logged until it is saved.
///
/// `puggle://log/fed?child=<id>`. The fact is one of Today's: fed, ate, awake, asleep, nappy, potty.
enum PuggleLink {
    static let scheme = "puggle"
    static let facts: Set<String> = ["fed", "ate", "awake", "asleep", "nappy", "potty"]

    static func log(_ fact: String, child: String) -> URL {
        var parts = URLComponents()
        parts.scheme = scheme
        parts.host = "log"
        parts.path = "/" + fact
        parts.queryItems = [URLQueryItem(name: "child", value: child)]
        return parts.url ?? URL(string: "\(scheme)://")!
    }

    /// The fact and the child's id, or nil for anything that is not such a link.
    static func parse(_ url: URL) -> (fact: String, child: String)? {
        guard url.scheme == scheme, url.host == "log",
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let child = parts.queryItems?.first(where: { $0.name == "child" })?.value, !child.isEmpty else { return nil }
        let fact = url.lastPathComponent
        return facts.contains(fact) ? (fact, child) : nil
    }
}
