import SwiftUI

/// After joining a family, for a phone that already had children of its own:
/// bring them in, so everyone sees them, or keep them on this phone out of sight.
struct BringInView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @State private var done: FamilyStore.Restored?

    private var names: String { ListFormatter.localizedString(byJoining: store.ownChildrenBesideJoined.map(\.displayName)) }

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "arrow.triangle.merge")
                .font(.system(size: 30, weight: .semibold))
                .frame(width: 80, height: 80)
                .background(Palette.field, in: Circle())
                .accessibilityHidden(true)
            if let done {
                Text("Done").displayFont(28)
                Text("\(BackupsView.count(done.children, "child", "children")) and \(BackupsView.count(done.entries, "entry", "entries")) are in the family now.")
                    .foregroundStyle(Palette.muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            } else if store.canLog {
                Text("Bring \(names) into this family?")
                    .displayFont(28).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Text("\(names) \(store.ownChildrenBesideJoined.count == 1 ? "is" : "are") saved on this iPhone from before you joined. Bringing them in moves them, and everything logged for them, into \(store.holderName)'s family, so everyone in it can see them. A backup is made first.")
                    .foregroundStyle(Palette.muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(names) \(store.ownChildrenBesideJoined.count == 1 ? "stays" : "stay") on this iPhone")
                    .displayFont(28).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Text("As a viewer you can't add to this family, so \(names) \(store.ownChildrenBesideJoined.count == 1 ? "is" : "are") kept on this iPhone, out of sight. Leave the family to see them again.")
                    .foregroundStyle(Palette.muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if done == nil && store.canLog {
                Button("Bring them in") {
                    Haptics.success()
                    done = store.bringOwnChildrenIn()
                }
                .buttonStyle(PillButtonStyle())
                Button("Not now") { dismiss() }
                    .buttonStyle(PillButtonStyle(primary: false))
                Text("Not now keeps them on this iPhone, out of sight. You can bring them in later from the Family tab.")
                    .font(.footnote).foregroundStyle(Palette.muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            } else {
                Button(done == nil ? "OK" : "Done") { dismiss() }.buttonStyle(PillButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
    }
}
