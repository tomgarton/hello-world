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
        MedicineRules.onSet = { name, gap, limit in
            Task { @MainActor in FamilyStore.live.shareRule(name: name, gap: gap, limit: limit) }
        }
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
        request.predicate = store.scoped(request.predicate)
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
                .environment(\.appLocked, lock.isLocked)
                .overlay {
                    if lock.isLocked {
                        LockedView { lock.unlock() }
                    }
                }
                .preferredColorScheme(scheme)
                // A sleep starting or ending, or the sample family swapping in, may change the night look.
                .onReceive(store.objectWillChange) { _ in
                    // A feed logged here or on another phone moves the "time since a feed" reminder.
                    Task { @MainActor in
                        ReminderStore.shared.reschedule(with: store)
                        WidgetFeed.update(from: store)
                    }
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
                        if !lock.isLocked { PrivacyShield.shared.hide() }
                        LiveTimers.shared.sync(with: store)
                        ReminderStore.shared.reschedule(with: store)
                        WidgetFeed.update(from: store)
                        // Only does anything if the parent has switched the weather on.
                        WeatherWatch.shared.refresh()
                        // Who this person is in the family, and their name and photo for the others.
                        Me.refreshCloudID()
                        store.refreshRole()
                        store.reconcilePeople()
                        store.shareMyDetails()
                        store.syncMedicineRules()
                        store.backUpIfDue()
                        refreshNight(with: active)
                        lock.unlock()
                        PuggleShortcuts.updateAppShortcutParameters()
                    case .background:
                        lock.lockIfNeeded()
                        if AppLock.isOn { PrivacyShield.shared.show(lock: lock) }
                    case .inactive:
                        // Covered as soon as the app leaves the front, so nothing shows in the app switcher.
                        if AppLock.isOn { PrivacyShield.shared.show(lock: lock) }
                    @unknown default:
                        break
                    }
                }
                .onChange(of: lock.isLocked) { _, locked in
                    if !locked, scenePhase == .active { PrivacyShield.shared.hide() }
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
    @EnvironmentObject private var store: FamilyStore
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage(Setting.justLog) private var justLog = false
    @State private var inFirstRun = false
    @State private var splashing = !Palette.nightJustChanged
    @ObservedObject private var invites = InviteCenter.shared
    /// Asked once per family joined: whether to bring this phone's own children in.
    @AppStorage("bringInAskedFor") private var bringInAskedFor = ""
    @State private var askingBringIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appLocked) private var appLocked

    var body: some View {
        content
            .environment(\.splashing, splashing)
            .overlay {
                // The shape of Today while the sample family is being made.
                if sample.loading {
                    TodaySkeleton().transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.25), value: sample.loading)
            .fullScreenCover(item: $invites.invite) { JoinView(invite: $0) }
            .sheet(isPresented: $askingBringIn) { BringInView() }
            .onChange(of: children.count) { _, _ in checkBringIn() }
            .onAppear { checkBringIn() }
            // The family arrived after an invite: no first run to go through.
            .onChange(of: children.count) { _, count in
                guard count > 0, invites.joinedAt != nil else { return }
                invites.stopWaiting()
                hasOnboarded = true
            }
            .alert("You're no longer in this family", isPresented: $store.removedNotice) {
                Button("OK") {}
            } message: {
                Text("Whoever started it has removed you or stopped sharing. Their children have come off this iPhone. What you logged is still with them.")
            }
            .overlay {
                if splashing {
                    SplashView().transition(.opacity)
                }
            }
            #if DEBUG
            // For the automated audit: "-uitest 1" opens the sample family with no splash.
            .task {
                // For reviewing the drawings: "-debugSheet 1" saves every scene to Documents.
                if UserDefaults.standard.string(forKey: "debugSheet") == "1" {
                    RefinementSheets.writeAll()
                    SceneGalleryView.writeWardrobe(name: "wardrobe.png")
                    SceneGalleryView.writePortraits(name: "portraits.png")
                    SceneGalleryView.writeCast(name: "cast.png")
                    SceneGalleryView.writeFirework(name: "firework.png")
                    SceneGalleryView.writeRooms(pull: 240, name: "rooms-pulled.png")
                    SceneGalleryView.writeRooms(pull: 0, name: "rooms.png")
                    SceneGalleryView.writeOptions(name: "options.png")
                    SceneGalleryView.writeWeather(name: "weather.png", dark: false)
                    SceneGalleryView.writeWeather(name: "weather-night.png", dark: true)
                    SceneGalleryView.writeStrip(move: "splash", seconds: 1.3, every: 0.1, name: "strip-splash.png")
                    SceneGalleryView.writeDrawingStyles(name: "drawing.png")
                    SceneGalleryView.writeLineStyles(name: "lines.png")
                    SceneGalleryView.writeStrip(move: "greet", seconds: 1.8, every: 0.1, name: "strip-greet.png")
                    SceneGalleryView.writeStrip(move: "nod", seconds: 0.8, every: 0.05, name: "strip-nod.png")
                    SceneGalleryView.writeStrip(move: "proud", seconds: 2.2, every: 0.1, name: "strip-proud.png")
                    SceneGalleryView.writeStrip(move: "celebrate", seconds: 2.2, every: 0.1, name: "strip-celebrate.png")
                    SceneGalleryView.writeStrip(move: "wake", seconds: 1.6, every: 0.1, name: "strip-wake.png")
                    SceneGalleryView.writeStrip(move: "asleep", seconds: 0.25, every: 0.1, name: "strip-asleep.png")
                    SceneGalleryView.writeStrip(move: "walk", seconds: 0.7, every: 0.08, name: "strip-walk.png")
                    SceneGalleryView.writeStrip(move: "greet", seconds: 1.8, every: 0.1, name: "film-greet.png", clear: true)
                    SceneGalleryView.writeStrip(move: "celebrate", seconds: 2.2, every: 0.1, name: "film-celebrate.png", clear: true)
                    SceneGalleryView.writeStrip(move: "nod", seconds: 0.8, every: 0.05, name: "film-nod.png", clear: true)
                    SceneGalleryView.writeSheet(pull: 220, name: "scenes-empty.png", empty: true)
                    SceneGalleryView.writeStrip(move: "hatch", seconds: 4.75, every: 0.25, name: "strip-hatch.png",
                                                rig: "hatchling", frame: CGSize(width: 200, height: 134), ground: Color(hex: 0x8FA7C4))
                    SceneGalleryView.writeSheet(pull: 0, name: "scenes.png")
                    SceneGalleryView.writeSheet(pull: 220, name: "scenes-pulled.png")
                }
            }
            .task {
                guard UserDefaults.standard.string(forKey: "uitest") == "1" else { return }
                splashing = false
                // "-debugRole helper" (or viewer) shows the sample family as that person sees it.
                sample.start(as: UserDefaults.standard.string(forKey: "debugRole").flatMap(Role.init(rawValue:)))
            }
            #endif
            // The splash waits behind the lock, so it is seen once Face ID is done.
            .task(id: appLocked) {
                guard splashing, !appLocked else { return }
                try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.5))
                withAnimation(.easeOut(duration: 0.35)) { splashing = false }
            }
    }

    /// A phone that joined a family while holding children of its own is asked, once, what to do with them.
    private func checkBringIn() {
        guard !sample.isOn, let joined = store.existingFamily(), store.hasJoinedFamily,
              !store.ownChildrenBesideJoined.isEmpty else { return }
        let key = joined.id?.uuidString ?? "joined"
        guard bringInAskedFor != key, !(joined.children ?? []).isEmpty else { return }
        bringInAskedFor = key
        askingBringIn = true
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
        // For checking the play pad: launch with "-debugPad 1".
        if UserDefaults.standard.string(forKey: "debugFirstRun") == "1" {
            // For checking the first-run demo: launch with "-debugFirstRun 1".
            OnboardingDemoView()
        } else if let join = UserDefaults.standard.string(forKey: "debugJoin") {
            // For checking the join screens: "-debugJoin ask" (or viewer, joined, used, noICloud, offline).
            let invite = Invite(inviter: "Alex", familyTitle: "Ollie and Bea's family", lookOnly: join == "viewer")
            JoinView(invite: invite,
                     stage: join == "joined" ? .joined : JoinProblem(rawValue: join).map { .failed($0) } ?? .asking)
        } else if UserDefaults.standard.string(forKey: "debugPad") == "1" {
            PlayPadView()
        } else if UserDefaults.standard.string(forKey: "debugMoves") == "1" {
            // For checking her moves: launch with "-debugMoves 1".
            NavigationStack { MovesGalleryView() }
        } else if let scene = UserDefaults.standard.string(forKey: "debugGallery").flatMap(Int.init) {
            // For checking the scenes: launch with "-debugGallery 0" (to 3).
            SceneGalleryView(kind: SceneKind(rawValue: scene) ?? .hills)
        } else if UserDefaults.standard.string(forKey: "debugSticker") == "dry" {
            StickerDetailView(sticker: EarnedSticker(id: "dry-1", title: "First potty day",
                                                     style: StickerStyle(shape: "shape-soft-square", foil: .sea, emblem: "sun"),
                                                     detail: "A day with a wee or a poo on the potty.", child: "Bea", earnedOn: .now))
        } else if UserDefaults.standard.string(forKey: "debugSticker") == "food" {
            StickerDetailView(sticker: EarnedSticker(id: "food-1", title: "First food",
                                                     style: StickerStyle(shape: "shape-soft-hexagon", foil: .gold, emblem: "icon-solids"),
                                                     detail: "A first taste of something new.", child: "Ollie", earnedOn: .now))
        } else if UserDefaults.standard.string(forKey: "debugSticker") == "1" {
            // For checking the sticker viewer: launch with "-debugSticker 1" (or "food").
            StickerDetailView(sticker: EarnedSticker(id: "card-1", title: "First card", style: .card(0),
                                                     detail: "Five stamps on a card, and the shiny one on the end.",
                                                     child: "Bea", earnedOn: .now))
        } else {
            mainContent
        }
        #else
        mainContent
        #endif
    }

    @ViewBuilder private var mainContent: some View {
        if !sample.isOn && invites.awaitingFamily && children.isEmpty {
            // An invite was accepted and the family has not come down from iCloud yet.
            ArrivingView { invites.stopWaiting() }
        } else if !sample.isOn && !hasOnboarded && (children.isEmpty || inFirstRun) {
            // First run shows until it is finished, even once the first child exists.
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
    /// Upright everywhere, except while the play pad is open.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Orientation.landscapeAllowed ? .allButUpsideDown : .portrait
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    /// The invite link opened the app from cold.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let metadata = connectionOptions.cloudKitShareMetadata else { return }
        Task { @MainActor in InviteCenter.shared.received(metadata) }
    }

    /// The invite link was opened while the app was already running.
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task { @MainActor in InviteCenter.shared.received(metadata) }
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
private struct AppLockedKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// True while the app lock covers the app.
    var appLocked: Bool {
        get { self[AppLockedKey.self] }
        set { self[AppLockedKey.self] = newValue }
    }
}

extension EnvironmentValues {
    /// True while the splash covers the app, so entrances wait until they can be seen.
    var splashing: Bool {
        get { self[SplashingKey.self] }
        set { self[SplashingKey.self] = newValue }
    }
}
