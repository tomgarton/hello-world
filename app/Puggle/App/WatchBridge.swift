import CoreData
import Foundation
import WatchConnectivity

/// The iPhone's side of the link to the Watch (see `WatchLink`). Sends the Watch the widgets' summary whenever it
/// is written, and saves what is tapped on the Watch through the same store, so it reaches the family as usual.
/// A tap can arrive with Puggle closed: the system opens it in the background to take it.
@MainActor
final class WatchBridge: NSObject {
    static let shared = WatchBridge()

    /// Starts listening. Called as the app starts, so a tap waiting on the Watch is taken straight away.
    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends the latest summary, if there is a Watch with Puggle on it to send it to.
    func send(_ snapshot: WidgetSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? session.updateApplicationContext([WatchLink.snapshotKey: data])
    }

    /// Saves a tap from the Watch, and answers with the summary as it now is.
    fileprivate func handle(_ request: WatchLink.Request) -> Data? {
        let store = FamilyStore.live
        switch request.action {
        case .startSleep: store.handleTimerAction(TimerActions.startSleep, childID: request.childID)
        case .wokeUp: store.handleTimerAction(TimerActions.wokeUp, childID: request.childID)
        case .feedLeft: store.handleTimerAction(TimerActions.feedLeft, childID: request.childID)
        case .feedRight: store.handleTimerAction(TimerActions.feedRight, childID: request.childID)
        case .finishFeed: store.handleTimerAction(TimerActions.finishFeed, childID: request.childID)
        case .nappy, .bottle:
            store.refreshRole()
            let children = (try? store.context.fetch(NSFetchRequest<Child>(entityName: "Child"))) ?? []
            guard store.canLog, let child = children.first(where: { $0.id?.uuidString == request.childID }) else { break }
            if request.action == .nappy {
                store.logEach(.nappy, for: [child], at: request.at, detail: request.detail ?? "Wet")
            } else {
                let last = store.latest(.bottle, for: child)
                store.logEach(.bottle, for: [child], at: request.at, amountML: Double(request.ml ?? Int(last?.amountML ?? 0)),
                              detail: last?.detail ?? "Formula")
            }
            LiveTimers.shared.sync(with: store)
        }
        let snapshot = WidgetFeed.write(from: store)
        return try? JSONEncoder().encode(snapshot)
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Once linked, the Watch gets the summary as it is now.
        Task { @MainActor in if !FamilyStore.live.isSample { WidgetFeed.write(from: FamilyStore.live) } }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // A different Watch paired: listen to that one.
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = WatchLink.Request(message: message) else { replyHandler([:]); return }
        Task { @MainActor in
            let data = self.handle(request)
            replyHandler(data.map { [WatchLink.snapshotKey: $0] } ?? [:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let request = WatchLink.Request(message: userInfo) else { return }
        Task { @MainActor in _ = self.handle(request) }
    }
}
