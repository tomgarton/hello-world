import SwiftUI

/// First run: from install to Today in under a minute. No account, no email,
/// no password. The only required step is adding a child.
struct OnboardingView: View {
    @EnvironmentObject private var store: FamilyStore
    @EnvironmentObject private var sample: SampleFamily
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>
    @AppStorage(Setting.yourName) private var yourName = ""
    @AppStorage(Setting.justLog) private var justLog = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinish: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var forward = true
    @State private var draft = ChildDraft()
    @State private var nameDraft = ""
    @FocusState private var nameFocused: Bool

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Palette.sand.ignoresSafeArea()
            VStack(spacing: 0) {
                if step != .welcome {
                    topBar
                }
                ZStack {
                    stepView
                        .id(step)
                        .transition(stepTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(Palette.ink)
        .onAppear { nameDraft = yourName }
    }

    // MARK: Moving between steps

    private var stepTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func go(_ next: OnboardingStep) {
        nameFocused = false
        forward = next.rawValue > step.rawValue
        withAnimation(.easeInOut(duration: reduceMotion ? 0.2 : 0.3)) {
            step = next
        }
    }

    /// Where Back leads. Once a child exists, the form is only for adding another.
    private var previous: OnboardingStep {
        switch step {
        case .welcome: return .welcome
        case .logging: return .welcome
        case .sharing: return .logging
        case .name: return .sharing
        case .child: return children.isEmpty ? .name : .more
        case .more: return .name
        case .amount: return .more
        case .done: return .amount
        }
    }

    /// The step after your name: the first child, or the list once one exists.
    private var afterName: OnboardingStep { children.isEmpty ? .child : .more }

    private var canSkip: Bool {
        step == .logging || step == .sharing || step == .name
    }

    private func skip() {
        // Skipping always lands on the one required step.
        go(afterName)
    }

    // MARK: Top bar

    private var topBar: some View {
        ZStack {
            OnboardingDots(current: step.rawValue - 1, count: OnboardingStep.allCases.count - 1)
            HStack {
                Button {
                    go(previous)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
                if canSkip {
                    Button("Skip") { skip() }
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
    }

    // MARK: Steps

    @ViewBuilder private var stepView: some View {
        switch step {
        case .welcome: welcome
        case .logging: loggingPage
        case .sharing: sharingPage
        case .name: namePage
        case .child: childPage
        case .more: morePage
        case .amount: amountPage
        case .done: donePage
        }
    }

    /// The only place in the app, with Help and the icon, where the name shows.
    private var welcome: some View {
        VStack(spacing: 12) {
            Spacer()
            PuggleMark()
            Wordmark()
            Text("A calm place for your family's day")
                .font(.title3)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Get started") { go(.logging) }
                .buttonStyle(PillButtonStyle())
            Button("Look around a sample family first") {
                Haptics.tap()
                sample.start()
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(24)
    }

    private var loggingPage: some View {
        OnboardingPage {
            OnboardingTiles()
                .padding(.vertical, 20)
            Text("Log the day in a tap or two").displayFont(34)
            Text("Feeds, sleeps, nappies and the potty, for every child you have.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
        } actions: {
            Button("Continue") { go(.sharing) }
                .buttonStyle(PillButtonStyle())
        }
    }

    private var sharingPage: some View {
        OnboardingPage {
            OnboardingSampleDay(showsWho: Persistence.cloudSyncEnabled)
                .padding(.vertical, 20)
            Text(Persistence.cloudSyncEnabled ? "Everyone sees the same day" : "The whole day in one place")
                .displayFont(34)
            Text(Persistence.cloudSyncEnabled
                 ? "Invite a partner or a helper later from the Family tab. No account to make."
                 : "This build keeps everything on this iPhone. No account, no email, no password.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
        } actions: {
            Button("Continue") { go(.name) }
                .buttonStyle(PillButtonStyle())
        }
    }

    private var namePage: some View {
        OnboardingPage {
            Text("What should we call you?").displayFont(34)
                .padding(.top, 20)
            Text("Optional. It shows beside what you log, so the family can see who added it.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            TextField("Your name", text: $nameDraft)
                .textContentType(.givenName)
                .submitLabel(.done)
                .focused($nameFocused)
                .onSubmit { saveName() }
                .font(.title3)
                .padding(.horizontal, 18)
                .frame(minHeight: 56)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 8)
            Text("You can change it any time in Settings.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
        } actions: {
            Button("Continue") { saveName() }
                .buttonStyle(PillButtonStyle())
        }
    }

    private func saveName() {
        yourName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        go(afterName)
    }

    private var childPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(children.isEmpty ? "Add your first child" : "Add another child")
                .displayFont(28)
                .padding(.horizontal, 24)
                .padding(.top, 12)
            Form { ChildForm(draft: $draft) }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .background(Palette.sand)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Add") { addChild() }
                .buttonStyle(PillButtonStyle())
                .disabled(!draft.isComplete)
                .opacity(draft.isComplete ? 1 : 0.5)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Palette.sand)
        }
    }

    @MainActor private func addChild() {
        guard draft.isComplete else { return }
        store.addChild(name: draft.trimmedName, birthDate: draft.birthDate, colourIndex: draft.colour,
                       feeding: draft.feedingToSave, pottyTraining: draft.pottyToSave)
        Haptics.success()
        go(.more)
    }

    /// Twins and siblings are first-class: add them now or later.
    private var morePage: some View {
        OnboardingPage {
            Text("Anyone else?").displayFont(34)
                .padding(.top, 20)
            Text("Twins and siblings share one Today. Add them now, or later from the Family tab.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            childList
                .padding(.top, 6)
            if Persistence.cloudSyncEnabled {
                Text("You can invite a partner or a helper later from the Family tab.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        } actions: {
            Button("Add another child") { startAnotherChild() }
                .buttonStyle(PillButtonStyle(primary: false))
            Button("Continue") { go(.amount) }
                .buttonStyle(PillButtonStyle())
        }
    }

    private var childList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(children) { child in
                HStack(spacing: 12) {
                    ChildAvatar(child: child, size: 40)
                    Text(child.displayName).font(.headline)
                    Spacer(minLength: 8)
                    Text(child.ageTextFull)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func startAnotherChild() {
        var next = ChildDraft()
        next.colour = children.count % Palette.childColours.count
        draft = next
        go(.child)
    }

    /// Asked once in setup. Either choice logs the same things.
    private var amountPage: some View {
        OnboardingPage {
            Text("How much to see").displayFont(34)
                .padding(.top, 20)
            Text("Both log the same things.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            OnboardingChoice(title: "Everything",
                             text: "Time since the last feed, each child's day so far, and the week in Insights.",
                             isOn: !justLog) {
                choose(justLogging: false)
            }
            .padding(.top, 6)
            OnboardingChoice(title: "Just logging",
                             text: "Names and tiles only. Nothing counts up and nothing is totalled.",
                             isOn: justLog) {
                choose(justLogging: true)
            }
            Text("You can change this any time in Settings.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
        } actions: {
            Button("Continue") { go(.done) }
                .buttonStyle(PillButtonStyle())
        }
    }

    @MainActor private func choose(justLogging: Bool) {
        guard justLog != justLogging else { return }
        Haptics.selection()
        justLog = justLogging
    }

    private var donePage: some View {
        OnboardingPage {
            PuggleStanding(height: 180)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            Text("You're set").displayFont(34)
            Text("Tap a tile on Today to log something. Anything you chose here can be changed later.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
        } actions: {
            Button("Go to Today") {
                Haptics.tap()
                onFinish()
            }
            .buttonStyle(PillButtonStyle())
        }
    }
}
