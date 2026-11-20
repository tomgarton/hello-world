import BackgroundTasks
import UIKit

/// More time for sending to iCloud once Puggle leaves the screen (Tom, 15 November 2026: a big import sat
/// on the phone it was made on, because iOS stops an app's sending soon after it is closed).
///
/// Core Data does the sending. All this does is ask iOS to keep Puggle running while entries are waiting:
/// - straight away, for the half minute or so iOS allows any app that asks as it leaves the screen;
/// - later, as a background task iOS runs when it chooses, usually on charge and on Wi-Fi, for a few minutes.
///
/// iOS decides when and whether the later one runs, so this makes a big send finish sooner without the app
/// open. It is not a promise. Fetching in the background already works, through iCloud's silent pushes.
@MainActor
enum BackgroundSync {
    /// Also listed in Info.plist, under BGTaskSchedulerPermittedIdentifiers.
    static let taskID = "com.tomgarton.puggle.sync"

    private static var assertion = UIBackgroundTaskIdentifier.invalid

    private static func waiting() async -> Int { await SyncProgress.count(in: FamilyStore.live).waiting }

    /// At launch, before the app has finished starting: iOS needs to know what to run.
    static func register() {
        guard Persistence.cloudSyncEnabled else { return }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: .main) { task in
            Task { @MainActor in run(task) }
        }
    }

    /// When Puggle leaves the screen. Does nothing when everything is already in iCloud.
    /// The hold is taken first and the counting done after, away from the main thread, so leaving is never slowed.
    static func leftScreen() {
        guard Persistence.cloudSyncEnabled, !FamilyStore.live.isSample, assertion == .invalid else { return }
        assertion = UIApplication.shared.beginBackgroundTask(withName: "Sending to iCloud") { release() }
        Task {
            guard await waiting() > 0 else { release(); return }
            schedule()
            // Let go as soon as it has all gone, so no time is held that is not needed.
            while assertion != .invalid {
                try? await Task.sleep(for: .seconds(10))
                if await waiting() == 0 { break }
            }
            release()
        }
    }

    /// When Puggle is back on screen: it sends freely there, so the hold is let go.
    static func backOnScreen() { release() }

    private static func release() {
        guard assertion != .invalid else { return }
        UIApplication.shared.endBackgroundTask(assertion)
        assertion = .invalid
    }

    private static func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskID)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func run(_ task: BGTask) {
        // Loading the store is what starts Core Data sending again.
        let work = Task { @MainActor in
            var left = await waiting()
            while !Task.isCancelled, left > 0 {
                try? await Task.sleep(for: .seconds(10))
                left = await waiting()
            }
            if left > 0 { schedule() }
            task.setTaskCompleted(success: left == 0)
        }
        task.expirationHandler = { work.cancel() }
    }
}
