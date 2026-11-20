#if DEBUG
import SwiftUI

/// Test builds only: first run, played through from the Developer menu without
/// touching the real family. Children go into a family kept in memory, and the
/// name and "how much to see" choices go into settings of their own. All of it
/// is thrown away when the demo closes.
struct OnboardingDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var demo = Demo()

    @MainActor
    final class Demo: ObservableObject {
        let store: FamilyStore
        let sample = SampleFamily()
        let settings: UserDefaults

        init() {
            store = FamilyStore(persistence: Persistence(inMemory: true))
            // Marked as a sample so nothing reaches Recently deleted, the widgets or reminders.
            store.isSample = true
            let suite = "onboarding-demo"
            UserDefaults.standard.removePersistentDomain(forName: suite)
            settings = UserDefaults(suiteName: suite) ?? .standard
        }
    }

    var body: some View {
        OnboardingView { dismiss() }
            .environment(\.managedObjectContext, demo.store.persistence.viewContext)
            .environmentObject(demo.store)
            .environmentObject(demo.sample)
            .defaultAppStorage(demo.settings)
            // No banner while the flow is being refined: it took a seventh of the screen and pulled the eye.
            // A small, faint cross in the bottom corner closes the demo. Nothing here is kept.
            .overlay(alignment: .bottomLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(Palette.muted.opacity(0.55))
                .padding(.leading, 6)
                // Below the screen's main button, in the strip beside the home bar.
                .offset(y: 24)
                .accessibilityLabel("Close the demo")
            }
            .tint(Palette.ink)
            .toggleStyle(SwitchToggleStyle(tint: Color(.systemGreen)))
            .foregroundStyle(Palette.ink)
    }
}
#endif
