import Foundation
import SwiftUI
import WatchConnectivity
import WatchKit
import WidgetKit

/// The Watch's side of the link to the iPhone (see `WatchLink`). Holds the latest summary the iPhone sent,
/// kept between launches so the app opens on something, and sends taps back.
@MainActor
final class WatchModel: NSObject, ObservableObject {
    static let shared = WatchModel()

    @Published private(set) var snapshot: WidgetSnapshot?
    /// Said for a moment after a tap that could not reach the iPhone.
    @Published var trouble: String?

    /// For screenshots and the simulator: "-preview 1" shows the sample family.
    static let previewing = UserDefaults.standard.bool(forKey: "preview")
    private static let keptKey = "snapshot"

    override init() {
        super.init()
        if Self.previewing {
            snapshot = WatchModel.sample
            return
        }
        if let data = UserDefaults.standard.data(forKey: Self.keptKey) {
            snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Ollie and Bea, as in the app's sample family: Ollie awake, Bea asleep.
    static var sample: WidgetSnapshot {
        var preview = WidgetSnapshot.preview
        if UserDefaults.standard.string(forKey: "previewFeed") == "1" {
            preview.children[0].feedingSince = Date.now.addingTimeInterval(-9 * 60)
            preview.children[0].feedSide = "Left"
        }
        preview.children[0].breastfeeds = true
        preview.children[0].lastBottleML = 150
        for index in preview.children.indices { DayFigures.fillSample(&preview.children[index]) }
        return preview
    }

    fileprivate func take(_ data: Data) {
        guard let fresh = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return }
        snapshot = fresh
        UserDefaults.standard.set(data, forKey: Self.keptKey)
        // For the watch-face shortcuts, which read it from the shared App Group.
        fresh.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Sends a tap. What it does shows at once; the iPhone's answer then puts everything right.
    func send(_ request: WatchLink.Request) {
        apply(request)
        WKInterfaceDevice.current().play(request.action == .wokeUp || request.action == .finishFeed ? .stop : .start)
        guard !Self.previewing else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { trouble = "Can't reach your iPhone"; return }
        if session.isReachable {
            session.sendMessage(request.message, replyHandler: { reply in
                if let data = reply[WatchLink.snapshotKey] as? Data {
                    Task { @MainActor in self.take(data) }
                }
            }, errorHandler: { _ in
                Task { @MainActor in self.failed(request) }
            })
        } else {
            failed(request)
        }
    }

    /// A nappy or a bottle waits to be delivered; a timer needs the iPhone now, so it is put back.
    private func failed(_ request: WatchLink.Request) {
        if request.needsReply {
            if let data = UserDefaults.standard.data(forKey: Self.keptKey) { take(data) }
            trouble = "Can't reach your iPhone"
            WKInterfaceDevice.current().play(.failure)
        } else {
            WCSession.default.transferUserInfo(request.message)
        }
    }

    /// The tap's effect on the summary, shown before the iPhone answers.
    private func apply(_ request: WatchLink.Request) {
        guard var snapshot, let index = snapshot.children.firstIndex(where: { $0.id == request.childID }) else { return }
        var child = snapshot.children[index]
        let now = request.at
        switch request.action {
        case .startSleep: child.asleepSince = now
        case .wokeUp: child.asleepSince = nil; child.lastWoke = now
        case .feedLeft, .feedRight:
            let side = request.action == .feedLeft ? "Left" : "Right"
            if child.feedingSince == nil { child.feedingSince = now }
            child.feedSide = child.feedSide == side ? nil : side
        case .finishFeed:
            if let start = child.feedingSince { child.lastFeed = start; child.lastFeedText = "Breastfeed" }
            child.feedingSince = nil; child.feedSide = nil
        case .nappy: child.lastNappy = now
        case .bottle:
            child.lastFeed = now
            child.lastFeedText = request.ml.map { "Bottle · \($0) ml" } ?? "Bottle"
            child.lastBottleML = request.ml
        }
        snapshot.children[index] = child
        self.snapshot = snapshot
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension WatchModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            if let data = context[WatchLink.snapshotKey] as? Data { self.take(data) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let data = applicationContext[WatchLink.snapshotKey] as? Data { self.take(data) }
        }
    }
}
