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
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 10) {
                    Text("Demo. Nothing here is kept.")
                        .font(.footnote.weight(.semibold))
                    Spacer(minLength: 0)
                    Button("Close") { dismiss() }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 32)
                        .background(Palette.paper, in: Capsule())
                }
                .foregroundStyle(Palette.fixedInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Palette.wattle)
            }
            .tint(Palette.ink)
            .toggleStyle(PuggleToggleStyle())
            .foregroundStyle(Palette.ink)
    }
}
#endif
