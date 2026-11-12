import LocalAuthentication
import SwiftUI

/// An optional lock on opening the app, using Face ID or the phone's passcode.
/// It covers the app's screens. The Lock Screen timer and Siri still work
/// while locked, as they would for a timer or a reminder.
@MainActor
final class AppLock: ObservableObject {
    @Published private(set) var isLocked: Bool
    private var asking = false

    static var isOn: Bool { UserDefaults.standard.bool(forKey: Setting.appLock) }

    init() {
        isLocked = Self.isOn
    }

    /// Called when the app leaves the screen.
    func lockIfNeeded() {
        if Self.isOn { isLocked = true }
    }

    func unlock() {
        guard isLocked, !asking else { return }
        asking = true
        Task {
            if await Self.authenticate(reason: "Open your family's entries") { isLocked = false }
            asking = false
        }
    }

    /// Asks for Face ID, Touch ID or the passcode. False if it was cancelled or failed.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode on the phone: there is nothing to lock with.
            return true
        }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }
}

struct LockedView: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Palette.sand.ignoresSafeArea()
            VStack(spacing: 18) {
                PuggleMark(size: 96)
                Text("Locked").font(.title3.weight(.semibold))
                Button("Unlock", action: onUnlock)
                    .buttonStyle(PillButtonStyle())
                    .frame(maxWidth: 220)
            }
            .foregroundStyle(Palette.ink)
            .padding(24)
        }
    }
}

/// A cover over everything, sheets included, while a locked app is away from
/// the front: nothing shows in the app switcher, and nothing flashes up before
/// Face ID. It sits in its own window above the app.
@MainActor
final class PrivacyShield {
    static let shared = PrivacyShield()
    private var window: UIWindow?

    func show(lock: AppLock) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        let cover = UIWindow(windowScene: scene)
        cover.windowLevel = .alert + 1
        let host = UIHostingController(rootView: ShieldView(lock: lock))
        host.view.backgroundColor = .clear
        cover.rootViewController = host
        cover.isHidden = false
        window = cover
    }

    func hide() {
        guard let cover = window else { return }
        window = nil
        UIView.animate(withDuration: 0.2, animations: { cover.alpha = 0 }, completion: { _ in cover.isHidden = true })
    }
}

private struct ShieldView: View {
    @ObservedObject var lock: AppLock

    var body: some View {
        if lock.isLocked {
            LockedView { lock.unlock() }
        } else {
            ZStack {
                Palette.sand.ignoresSafeArea()
                PuggleMark(size: 96)
            }
        }
    }
}
