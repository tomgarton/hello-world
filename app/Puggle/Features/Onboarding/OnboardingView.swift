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
    /// True once a child is added on this phone; children arriving otherwise came from iCloud.
    @State private var addedHere = false
    /// Joining a family, or a family come back from iCloud: no children to add.
    @State private var foundFamily = false
    @State private var sharing: SharingItem?
    @State private var shareError: String?
    @State private var showingPromise = false
    @ObservedObject private var cloud = CloudStatus.shared

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
        .onAppear {
            nameDraft = yourName
            cloud.refresh()
        }
        // Children arriving without being added here came from iCloud: an invite
        // accepted, or this family's own entries returning to a new phone.
        .onChange(of: children.count) { _, count in
            guard count > 0, !addedHere, !foundFamily else { return }
            foundFamily = true
            Haptics.success()
            go(.found)
        }
        .sheet(item: $sharing) { item in
            CloudSharingView(share: item.share, container: item.container).ignoresSafeArea()
        }
        .sheet(isPresented: $showingPromise) { DataPromiseView() }
    }

    /// Whether any child here belongs to a family someone else shared.
    private var joinedSomeone: Bool {
        children.contains { $0.objectID.persistentStore == store.persistence.sharedStore }
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
        case .joining: return .welcome
        case .found: return .welcome
        case .logging: return .welcome
        case .sharing: return .logging
        case .name: return foundFamily ? .found : .sharing
        case .child: return children.isEmpty ? .name : .more
        case .more: return .name
        case .invite: return .more
        case .amount: return Persistence.cloudSyncEnabled ? .invite : .more
        case .done: return foundFamily ? .name : .amount
        }
    }

    /// The step after your name: the first child, the list once one exists, or
    /// straight to the end for a family that came from iCloud.
    private var afterName: OnboardingStep {
        if foundFamily { return .done }
        return children.isEmpty ? .child : .more
    }

    private var canSkip: Bool {
        step == .logging || step == .sharing || step == .name || step == .invite
    }

    private func skip() {
        // Skipping always lands on the one required step (or past the invite).
        go(step == .invite ? .amount : afterName)
    }

    // MARK: Top bar

    private var topBar: some View {
        ZStack {
            let path = foundFamily ? OnboardingStep.foundPath : OnboardingStep.newFamily
            if let index = path.firstIndex(of: step) {
                OnboardingDots(current: index, count: path.count)
            }
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
        case .joining: joiningPage
        case .found: foundPage
        case .invite: invitePage
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
            Button("Start a new family") { go(.logging) }
                .buttonStyle(PillButtonStyle())
            if Persistence.cloudSyncEnabled {
                Button("I've been invited") { go(.joining) }
                    .buttonStyle(PillButtonStyle(primary: false))
            }
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
                 ? "A partner, Nan or the nanny can log on their own iPhone. No account to make."
                 : "This build keeps everything on this iPhone. No account, no email, no password.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            if Persistence.cloudSyncEnabled { CloudProblemCard() }
            Button("How your data is kept") { showingPromise = true }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        } actions: {
            Button("Continue") { go(.name) }
                .buttonStyle(PillButtonStyle())
        }
    }

    /// For a partner, Nan or the nanny: the invite does the work.
    private var joiningPage: some View {
        OnboardingPage {
            Text("Join your family").displayFont(34)
                .padding(.top, 20)
            Text("No account to make. Your family's entries come to this iPhone through iCloud.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            VStack(alignment: .leading, spacing: 14) {
                numbered(1, "Ask them to tap Invite someone on the Family tab, and send it to you.")
                numbered(2, "Open the invite on this iPhone, in Messages or Mail.")
                numbered(3, "Their children appear here, and you can log straight away.")
            }
            .padding(16)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 6)
            CloudProblemCard()
            if cloud.isAvailable {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Waiting for the invite")
                        .foregroundStyle(Palette.muted)
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
            }
        } actions: {
            Button("Start a new family instead") { go(.logging) }
                .buttonStyle(PillButtonStyle(primary: false))
        }
    }

    private func numbered(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .frame(width: 26, height: 26)
                .background(Palette.field, in: Circle())
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The family arrived from iCloud: someone's invite, or this family's own
    /// entries on a new or reset iPhone. Nothing to add.
    private var foundPage: some View {
        OnboardingPage {
            PuggleStanding(height: 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            Text(joinedSomeone ? "You've joined the family" : "Welcome back").displayFont(34)
            Text(joinedSomeone
                 ? "You'll see and log the same day as everyone else."
                 : "Your family's entries are coming back from iCloud.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            childList
                .padding(.top, 6)
        } actions: {
            Button("Continue") { go(.name) }
                .buttonStyle(PillButtonStyle())
        }
    }

    /// Log together: an invite now, or later from the Family tab.
    private var invitePage: some View {
        OnboardingPage {
            OnboardingSampleDay(showsWho: true)
                .padding(.vertical, 12)
            Text("Log together").displayFont(34)
            Text("Invite a partner, Nan or the nanny. They see and log the same day on their own iPhone.")
                .font(.title3)
                .foregroundStyle(Palette.muted)
            CloudProblemCard()
            if let shareError {
                Text(shareError).font(.footnote).foregroundStyle(Palette.waratah)
            }
            Text("You can invite people any time from the Family tab.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
        } actions: {
            if cloud.isAvailable {
                Button("Invite someone") { Task { await startSharing() } }
                    .buttonStyle(PillButtonStyle())
                Button("Not now") { go(.amount) }
                    .buttonStyle(PillButtonStyle(primary: false))
            } else {
                Button("Continue") { go(.amount) }
                    .buttonStyle(PillButtonStyle())
            }
        }
    }

    private func startSharing() async {
        do {
            let (share, container) = try await store.persistence.share(store.currentFamily())
            sharing = SharingItem(share: share, container: container)
            shareError = nil
        } catch {
            shareError = "The invite couldn't be made. Check this iPhone is signed in to iCloud, then try again."
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
                .padding(.horizontal, 16)
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
        addedHere = true
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
        } actions: {
            Button("Add another child") { startAnotherChild() }
                .buttonStyle(PillButtonStyle(primary: false))
            Button("Continue") { go(Persistence.cloudSyncEnabled ? .invite : .amount) }
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
            Text("Tap a tile on Today to log something. You can change any of this later.")
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

/// What happens to the family's entries, in a few plain lines.
struct DataPromiseView: View {
    @Environment(\.dismiss) private var dismiss

    private let promises: [(String, String, String)] = [
        ("iphone", "On your phone", "Everything you log is kept on this iPhone first, so logging works without a signal."),
        ("icloud", "In your own iCloud", "Copies go to your iCloud, which only you and people you invite can see. Not to a server of ours."),
        ("person.2", "Only who you invite", "Nobody sees your family's day unless you send them an invite, and you can stop sharing any time."),
        ("nosign", "No account, no ads", "No email or password, no adverts, and nothing sold or shared."),
        ("square.and.arrow.up", "Yours to take", "Export every entry as a spreadsheet file whenever you like, from Your data."),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(promises, id: \.1) { symbol, title, text in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: symbol)
                            .font(.title3)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title).font(.headline)
                            Text(text).font(.subheadline).foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
                .listRowBackground(Palette.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Your family's data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
