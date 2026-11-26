import Foundation

/// A link from a widget or the Lock Screen, waiting for Today to open its sheet. Today may not be on screen
/// yet (the app was closed, or first run, or the lock is up), so the link is held here until it is.
@MainActor
final class OpenedLink: ObservableObject {
    static let shared = OpenedLink()

    struct Pending: Equatable {
        let fact: String
        let childID: String
    }

    @Published var pending: Pending?

    /// True if the address was one of Puggle's links.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let link = PuggleLink.parse(url) else { return false }
        pending = Pending(fact: link.fact, childID: link.child)
        return true
    }

    func take() -> Pending? {
        defer { pending = nil }
        return pending
    }
}
