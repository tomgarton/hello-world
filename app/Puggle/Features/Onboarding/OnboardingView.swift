import SwiftUI

/// First run: from install to the first log in under a minute. No account,
/// no email, no password. The only required step is adding a child.
struct OnboardingView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>
    let onFinish: () -> Void

    private enum Step { case splash, hello, shared, child, more }

    @State private var step: Step = .splash
    @State private var draft = ChildDraft()

    var body: some View {
        ZStack {
            Palette.sand.ignoresSafeArea()
            switch step {
            case .splash: splash
            case .hello:
                page(title: "A calm place for the day",
                     text: "Feeds, sleeps, nappies and the potty, for every child you have, in a tap or two.",
                     next: .shared)
            case .shared:
                page(title: "Everyone sees the same day",
                     text: Persistence.cloudSyncEnabled
                        ? "Invite a partner or a helper later from the Family tab. No account to make."
                        : "This build keeps everything on this iPhone. Sharing with a partner comes with iCloud.",
                     next: .child)
            case .child: childStep
            case .more: moreStep
            }
        }
        .foregroundStyle(Palette.ink)
        .animation(.default, value: step)
    }

    // MARK: Steps

    /// The only place in the app, with Help and the icon, where the name shows.
    private var splash: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Puggle")
                .font(.display(56))
            Text("Baby and family tracker")
                .foregroundStyle(Palette.muted)
            Spacer()
            Button("Get started") { step = .hello }
                .buttonStyle(PillButtonStyle())
        }
        .padding(24)
    }

    private func page(title: String, text: String, next: Step) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer()
                Button("Skip") { step = .child }
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
            }
            Spacer()
            Text(title).font(.display(34))
            Text(text).font(.title3).foregroundStyle(Palette.muted)
            Spacer()
            Button("Continue") { step = next }
                .buttonStyle(PillButtonStyle())
        }
        .padding(24)
    }

    private var childStep: some View {
        NavigationStack {
            Form { ChildForm(draft: $draft) }
                .scrollContentBackground(.hidden)
                .background(Palette.sand)
                .navigationTitle(children.isEmpty ? "Add your first child" : "Add another child")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !children.isEmpty {
                        ToolbarItem(placement: .cancellationAction) { Button("Back") { step = .more } }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button("Add") {
                        store.addChild(name: draft.trimmedName, birthDate: draft.birthDate, colourIndex: draft.colour,
                                       feeding: draft.feedingToSave, pottyTraining: draft.pottyToSave)
                        step = .more
                    }
                    .buttonStyle(PillButtonStyle())
                    .disabled(!draft.isComplete)
                    .opacity(draft.isComplete ? 1 : 0.5)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Palette.sand)
                }
        }
    }

    /// Twins and siblings are first-class: add them now or later.
    private var moreStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Text("Anyone else?").font(.display(34))
            Text("Twins and siblings share one Today. Add them now, or later from the Family tab.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(children) { child in
                    HStack(spacing: 12) {
                        ChildAvatar(child: child, size: 40)
                        Text(child.displayName).font(.headline)
                        Text(child.ageTextFull).foregroundStyle(Palette.muted)
                    }
                }
            }
            .padding(.top, 6)
            Spacer()
            Button("Add another child") {
                draft = ChildDraft()
                draft.colour = children.count % Palette.childColours.count
                step = .child
            }
            .buttonStyle(PillButtonStyle(primary: false))
            Button("Go to Today") { onFinish() }
                .buttonStyle(PillButtonStyle())
        }
        .padding(24)
    }
}
