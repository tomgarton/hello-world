import CloudKit
import SwiftUI
import UIKit

@main
struct PuggleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = FamilyStore.live
    @StateObject private var sample = SampleFamily()
    @AppStorage(Setting.appearance) private var appearance = "system"
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Navigation titles are drawn by UIKit; give them the warm ink too.
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.foregroundColor: Palette.inkUI]
        bar.titleTextAttributes = [.foregroundColor: Palette.inkUI]
        // The Lock Screen buttons run here, even when the app is opened in the background for them.
        TimerActions.perform = { kind, childID in
            FamilyStore.live.handleTimerAction(kind: kind, childID: childID)
        }
    }

    private var scheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some Scene {
        WindowGroup {
            // The sample family is a separate, in-memory store swapped in whole.
            let active = sample.store ?? store
            RootView()
                .id(sample.isOn)
                .environment(\.managedObjectContext, active.persistence.viewContext)
                .environmentObject(active)
                .environmentObject(sample)
                .preferredColorScheme(scheme)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { LiveTimers.shared.sync(with: store) }
                }
                .tint(Palette.ink)
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

    var body: some View {
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
