import CloudKit
import CoreData
import SwiftUI
import UIKit

@main
struct PuggleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = FamilyStore.live
    @StateObject private var sample = SampleFamily()
    @StateObject private var lock = AppLock()
    @StateObject private var night = NightMode(anyChildAsleep: PuggleApp.anyChildAsleep(in: FamilyStore.live))
    @AppStorage(Setting.focusNight) private var focusNight = false
    @AppStorage(Setting.appearance) private var appearance = "system"
    @AppStorage(Setting.nightMode) private var nightSetting = Setting.nightModeDefault
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Navigation titles are drawn by UIKit; give them the warm ink too.
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.foregroundColor: Palette.inkUI]
        bar.titleTextAttributes = [.foregroundColor: Palette.inkUI]
        // Unselected tabs in warm muted ink, so nothing is near-white at night.
        UITabBar.appearance().unselectedItemTintColor = Palette.mutedUI
        // The Lock Screen buttons run here, even when the app is opened in the background for them.
        TimerActions.perform = { action, childID in
            FamilyStore.live.handleTimerAction(action, childID: childID)
        }
    }

    private var scheme: ColorScheme? {
        // The night look, or a Focus with the Night look filter, wins over the usual choice.
        if night.isNight || focusNight { return .dark }
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    /// For the night look: whether any child on Today has a sleep running.
    @MainActor private static func anyChildAsleep(in store: FamilyStore) -> Bool {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        let children = (try? store.context.fetch(request)) ?? []
        return children.contains { store.activeSleep(for: $0) != nil }
    }

    @MainActor private func refreshNight(with store: FamilyStore) {
        night.refresh(anyChildAsleep: PuggleApp.anyChildAsleep(in: store))
    }

    var body: some Scene {
        WindowGroup {
            // The sample family is a separate, in-memory store swapped in whole.
            let active = sample.store ?? store
            RootView()
                .id(sample.isOn)
                // The night look reaches every colour as a trait, so the app is not rebuilt.
                .environment(\.puggleNight, night.isNight)
                .environment(\.managedObjectContext, active.persistence.viewContext)
                .environmentObject(active)
                .environmentObject(sample)
                .environmentObject(night)
                .overlay {
                    if lock.isLocked {
                        LockedView { lock.unlock() }
                    }
                }
                .preferredColorScheme(scheme)
                // A sleep starting or ending, or the sample family swapping in, may change the night look.
                .onReceive(store.objectWillChange) { _ in
                    // A feed logged here or on another phone moves the "time since a feed" reminder.
                    Task { @MainActor in ReminderStore.shared.reschedule(with: store) }
                }
                .onReceive(active.objectWillChange) { _ in
                    // Only looked up when sleep is part of the setting.
                    guard night.usesSleep else { return }
                    Task { @MainActor in refreshNight(with: active) }
                }
                .onChange(of: nightSetting) { _, _ in refreshNight(with: active) }
                .onChange(of: sample.isOn) { _, _ in
                    Task { @MainActor in refreshNight(with: sample.store ?? store) }
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        LiveTimers.shared.sync(with: store)
                        ReminderStore.shared.reschedule(with: store)
                        refreshNight(with: active)
                        lock.unlock()
                        PuggleShortcuts.updateAppShortcutParameters()
                    case .background:
                        lock.lockIfNeeded()
                    default:
                        break
                    }
                }
                .tint(Palette.ink)
                // Switches with clear contrast in day, dark and night.
                .toggleStyle(PuggleToggleStyle())
                // Warm ink everywhere by default, so nothing falls back to white in dark.
                .foregroundStyle(Palette.ink)
        }
    }
}

struct RootView: View {
    @FetchRequest(sortDescriptors: []) private var children: FetchedResults<Child>
    @EnvironmentObject private var sample: SampleFamily
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage(Setting.justLog) private var justLog = false
    @State private var inFirstRun = false
    @State private var splashing = !Palette.nightJustChanged
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .environment(\.splashing, splashing)
            .overlay {
                if splashing {
                    SplashView().transition(.opacity)
                }
            }
            .task {
                guard splashing else { return }
                try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.1))
                withAnimation(.easeOut(duration: 0.35)) { splashing = false }
            }
    }

    @ViewBuilder private var content: some View {
        // First run shows until it is finished, even once the first child exists.
        if !sample.isOn && !hasOnboarded && (children.isEmpty || inFirstRun) {
            OnboardingView {
                hasOnboarded = true
                inFirstRun = false
            }
            .onAppear { inFirstRun = true }
        } else {
            TabView {
                TodayView()
                    .tabItem { Label("Today", systemImage: "house") }
                HistoryView()
                    .tabItem { Label("History", systemImage: "calendar") }
                if !justLog {
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar") }
                }
                FamilyView()
                    .tabItem { Label("Family", systemImage: "person.2") }
            }
        }
    }
}

/// Accepting an invitation arrives through the scene delegate.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task {
            do {
                try await Persistence.shared.acceptShare(metadata)
            } catch {
                print("Accepting share failed: \(error)")
            }
        }
    }
}

#Preview {
    let persistence = Persistence.preview
    let store = FamilyStore(persistence: persistence)
    return RootView()
        .environment(\.managedObjectContext, persistence.viewContext)
        .environmentObject(store)
        .environmentObject(SampleFamily())
}

private struct SplashingKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// True while the splash covers the app, so entrances wait until they can be seen.
    var splashing: Bool {
        get { self[SplashingKey.self] }
        set { self[SplashingKey.self] = newValue }
    }
}
