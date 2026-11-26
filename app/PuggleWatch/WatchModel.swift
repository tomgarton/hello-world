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
            if var kept = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) {
                settle(&kept)
                snapshot = kept
            }
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
        preview.children[0].usesBottle = true
        if preview.children[0].feedingSince != nil {
            preview.children[0].feedBanked = 0
            preview.children[0].feedSideSince = preview.children[0].feedingSince
        }
        preview.children[0].lastBottleML = 150
        for index in preview.children.indices { DayFigures.fillSample(&preview.children[index]) }
        return preview
    }

    /// Takes a summary from the iPhone. Nappies and bottles tapped here that it does not have yet are put
    /// back on top, so one waiting to be delivered does not vanish and get logged twice.
    fileprivate func take(_ data: Data) {
        guard var fresh = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return }
        UserDefaults.standard.set(data, forKey: Self.keptKey)
        settle(&fresh)
        snapshot = fresh
        // For the watch-face shortcuts, which read it from the shared App Group.
        fresh.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Nappies and bottles tapped here that the iPhone has not answered for, kept between launches.
    private var waiting: [WatchLink.Request] = {
        guard let data = UserDefaults.standard.data(forKey: "waiting") else { return [] }
        return (try? JSONDecoder().decode([WatchLink.Request].self, from: data)) ?? []
    }() {
        didSet { UserDefaults.standard.set(try? JSONEncoder().encode(waiting), forKey: "waiting") }
    }

    /// Drops what the summary now has (or what is two days old), and applies the rest to it.
    private func settle(_ fresh: inout WidgetSnapshot) {
        let cutoff = Date.now.addingTimeInterval(-2 * 86400)
        let children = fresh.children
        let still = waiting.filter { request in
            guard request.at > cutoff, let child = children.first(where: { $0.id == request.childID }) else { return false }
            return !child.has(request)
        }
        if still.count != waiting.count { waiting = still }
        for request in still {
            if let index = fresh.children.firstIndex(where: { $0.id == request.childID }) {
                fresh.children[index].apply(request, ounces: fresh.ounces == true)
            }
        }
    }

    /// Timer taps held for a moment while the link to the iPhone comes up: just after the app opens or the
    /// wrist is raised it is not there yet, and the tap used to be lost or refused.
    private var held: [WatchLink.Request] = []
    private static let patience = 4.0

    /// Sends a tap. What it does shows at once; the iPhone's answer then puts everything right.
    func send(_ request: WatchLink.Request) {
        let pausing = (request.action == .feedLeft && child(request)?.feedSide == "Left")
            || (request.action == .feedRight && child(request)?.feedSide == "Right")
        apply(request)
        // One tick a tap: a start, a stop, a pause, or saved.
        let tick: WKHapticType = switch request.action {
        case .wokeUp, .finishFeed: .stop
        case .nappy, .bottle: .success
        default: pausing ? .click : .start
        }
        WKInterfaceDevice.current().play(tick)
        guard !Self.previewing else { return }
        let session = WCSession.default
        if !request.needsReply {
            waiting.append(request)
            if session.activationState == .activated, session.isReachable {
                session.sendMessage(request.message, replyHandler: { reply in
                    if let data = reply[WatchLink.snapshotKey] as? Data { Task { @MainActor in self.take(data) } }
                }, errorHandler: { _ in
                    // The iPhone saves a tap once, so sending it again by the queue is safe.
                    WCSession.default.transferUserInfo(request.message)
                })
            } else {
                session.transferUserInfo(request.message)
            }
        } else if session.activationState == .activated, session.isReachable {
            message(request)
        } else {
            if session.activationState != .activated { session.activate() }
            held.append(request)
            Task {
                try? await Task.sleep(for: .seconds(Self.patience))
                guard let index = self.held.firstIndex(where: { $0.key == request.key }) else { return }
                self.held.remove(at: index)
                self.failed(request)
            }
        }
    }

    private func child(_ request: WatchLink.Request) -> WidgetSnapshot.Child? {
        snapshot?.children.first { $0.id == request.childID }
    }

    private func message(_ request: WatchLink.Request) {
        WCSession.default.sendMessage(request.message, replyHandler: { reply in
            if let data = reply[WatchLink.snapshotKey] as? Data { Task { @MainActor in self.take(data) } }
        }, errorHandler: { _ in
            Task { @MainActor in self.failed(request) }
        })
    }

    /// The link is up: send what was held, and ask how things are now.
    fileprivate func linked() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        let ready = held
        held = []
        ready.forEach(message)
        if ready.isEmpty { refresh() }
    }

    private var lastAsked = Date.distantPast

    /// Asks the iPhone for the summary as it is now. Called as the app comes to the front, since the iPhone
    /// only sends one when something is logged: after midnight, or with a guess gone by, the Watch was behind.
    func refresh() {
        guard !Self.previewing, WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable, Date.now.timeIntervalSince(lastAsked) > 20 else { return }
        lastAsked = .now
        session.sendMessage([WatchLink.refreshKey: true], replyHandler: { reply in
            if let data = reply[WatchLink.snapshotKey] as? Data { Task { @MainActor in self.take(data) } }
        }, errorHandler: { _ in })
    }

    /// A timer needs the iPhone now, so one that could not reach it is put back, and says so.
    private func failed(_ request: WatchLink.Request) {
        if let data = UserDefaults.standard.data(forKey: Self.keptKey) { take(data) }
        trouble = "Can't reach your iPhone"
        WKInterfaceDevice.current().play(.failure)
    }

    /// The tap's effect on the summary, shown before the iPhone answers.
    private func apply(_ request: WatchLink.Request) {
        guard var snapshot, let index = snapshot.children.firstIndex(where: { $0.id == request.childID }) else { return }
        snapshot.children[index].apply(request, ounces: snapshot.ounces == true)
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
            self.linked()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.linked() }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let data = applicationContext[WatchLink.snapshotKey] as? Data { self.take(data) }
        }
    }
}
