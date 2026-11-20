import CloudKit
import CoreData
import SwiftUI

/// First run: from install to Today in under a minute. No account, no email,
/// no password. Up to five pages about the app, each acting out one feature on a field of
/// pattern, then the setup screens on the same skeleton, then the family drops into place. Everything can be skipped; nothing is asked twice.
struct OnboardingView: View {
    @EnvironmentObject private var store: FamilyStore
    @EnvironmentObject private var sample: SampleFamily
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var allChildren: FetchedResults<Child>
    private var children: [Child] { store.onScreen(allChildren) }
    @AppStorage(Setting.yourName) private var yourName = ""
    /// The screen to come back to if first run is left half way.
    @AppStorage("firstRunStep") private var savedStep = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    let onFinish: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var forward = true
    @State private var draft = ChildDraft()
    @State private var nameDraft = ""
    @State private var familyDraft = ""
    @FocusState private var nameFocused: Bool
    /// True once a child is added on this phone; children arriving otherwise came from iCloud.
    @State private var addedHere = false
    /// Joining a family, or a family come back from iCloud: no children to add.
    @State private var foundFamily = false
    @State private var showingPromise = false
    @State private var inviting = false
    @State private var pending: PendingInvite?
    @State private var sharing: SharingItem?
    @State private var shareError: String?
    @State private var invited = 0
    @State private var showName = false
    @State private var heapRound = 0
    @State private var heapLanded = false
    @StateObject private var hatchling = HatchlingController()
    @StateObject private var puggle = PuggleController()
    @ObservedObject private var cloud = CloudStatus.shared

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Palette.sand.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack {
                    stepView
                        .id(step)
                        .transition(stepTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if step != .welcome && step != .family { topBar }
        }
        .foregroundStyle(Palette.ink)
        .onAppear {
            nameDraft = yourName
            familyDraft = store.familyName
            cloud.refresh()
            resume()
        }
        // Children arriving without being added here came from iCloud: an invite
        // accepted, or this family's own entries returning to a new phone.
        .onChange(of: children.count) { _, count in
            guard count > 0, !addedHere, !foundFamily else { return }
            foundFamily = true
            Haptics.success()
            go(.found)
        }
        .sheet(isPresented: $showingPromise) { DataPromiseView() }
        .sheet(isPresented: $inviting) {
            InviteSheet { invite in
                pending = invite
                Task { await startSharing(invite) }
            }
        }
        .sheet(item: $sharing, onDismiss: {
            store.reconcilePeople(pending: pending)
            pending = nil
            invited += 1
        }) { item in
            CloudSharingView(share: item.share, container: item.container, lookOnly: item.lookOnly, title: item.title) {
                Task { @MainActor in store.reconcilePeople(pending: pending) }
            }
            .ignoresSafeArea()
        }
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
        // Only the screens worth coming back to; joining and the finish start again.
        if OnboardingStep.pages.contains(next) || [.you, .child, .more, .invite].contains(next) { savedStep = next.rawValue }
    }

    /// Back where first run was left, with any child already added kept.
    private func resume() {
        #if DEBUG
        // For checking the finish: "-debugFirstRun 1 -debugHeap 1".
        if UserDefaults.standard.string(forKey: "debugHeap") == "1" {
            if yourName.isEmpty { yourName = "Alex" }
            step = .family
            return
        }
        #endif
        guard let saved = OnboardingStep(rawValue: savedStep), saved != .welcome else { return }
        // A page this build does not show (sharing, without iCloud) starts the pages again.
        if saved.rawValue < OnboardingStep.you.rawValue, !OnboardingStep.pages.contains(saved) { step = .logging; return }
        if saved == .child, !children.isEmpty { step = .more } else { step = saved }
    }

    private func finish() {
        savedStep = 0
        Haptics.tap()
        onFinish()
    }

    /// Where Back leads. Once a child exists, the form is only for adding another.
    private var previous: OnboardingStep {
        switch step {
        case .welcome, .joining, .found: return .welcome
        case .logging, .everyChild, .together, .lookingBack, .privacy: return step.previousPage
        case .you: return foundFamily ? .found : (OnboardingStep.pages.last ?? .welcome)
        case .child: return children.isEmpty ? .you : .more
        case .more: return .you
        case .invite: return .more
        case .family: return .welcome
        }
    }

    private var afterYou: OnboardingStep? {
        if foundFamily { return joinedSomeone ? .family : nil }
        return children.isEmpty ? .child : .more
    }

    private var canSkip: Bool {
        switch step {
        case .logging, .everyChild, .together, .lookingBack, .privacy, .you, .invite: true
        case .child: children.isEmpty
        default: false
        }
    }

    private func skip() {
        switch step {
        case .logging, .everyChild, .together, .lookingBack, .privacy: go(.you)
        case .you: saveYou()
        // Skipping the first child leads to Today, which offers to add one.
        case .child: finish()
        case .invite: go(.family)
        default: break
        }
    }

    // MARK: Top bar

    /// Back and Skip, as pills in the top corners, over the pattern. Skip sits where the profile button is on Today.
    private var topBar: some View {
        HStack {
            Button {
                go(previous)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .background(Palette.paper, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Back")
            Spacer()
            if canSkip {
                Button { skip() } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 15)
                        .frame(minHeight: 36)
                        .background(Palette.paper, in: Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Steps

    @ViewBuilder private var stepView: some View {
        switch step {
        case .welcome: welcome
        case .joining: joiningPage
        case .found: foundPage
        case .logging, .everyChild, .together, .lookingBack, .privacy: featurePage(step)
        case .you: youPage
        case .child: childPage
        case .more: morePage
        case .invite: invitePage
        case .family: familyPage
        }
    }

    private var large: Bool { typeSize.isAccessibilitySize }
    private var dark: Bool { scheme == .dark }

    /// The only place in the app, with Help and the icon, where the name shows.
    private var welcome: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                PuggleScene(kind: .hills, dark: dark)
                HatchlingView(controller: hatchling)
                    .frame(height: large ? 110 : 170)
                    .padding(.bottom, 4)
            }
            .frame(height: large ? 200 : 330)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            VStack(spacing: 6) {
                Wordmark()
                Text("Baby tracker for the whole family")
                    .font(.title3)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
            }
            .opacity(showName ? 1 : 0)
            .offset(y: showName || reduceMotion ? 0 : 8)
            .accessibilityHidden(!showName)
            Spacer(minLength: 12)
            Button("Start a new family") { go(.logging) }
                .buttonStyle(PillButtonStyle())
            if Persistence.cloudSyncEnabled {
                Button("Join with an invite") { go(.joining) }
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
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .onAppear {
            guard !showName else { return }
            hatchling.hatch()
            if reduceMotion { showName = true; return }
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.4)) { showName = true }
            }
        }
    }

    /// The pages about the app. Each has its own pattern and colour, and a piece of the app that acts out the heading.
    @ViewBuilder private func featurePage(_ page: OnboardingStep) -> some View {
        let last = page.nextPage == .you
        switch page {
        case .logging:
            FirstRunPage(tile: .pills, colour: .sun, progress: page.dots, heading: "Log the day\nin a tap or two",
                         text: "Feeds, sleeps, \(Terms.nappiesLower) and the potty, with\u{00A0}one\u{00A0}hand.") { LogPiece(t: $0) }
                content: { EmptyView() } actions: { next(page, last: last) }
        case .everyChild:
            FirstRunPage(tile: .mix, colour: .sky, progress: page.dots, heading: "Every child\non one screen",
                         text: "A baby and a toddler side by side, each\u{00A0}with their own sleep\u{00A0}timer.") { KidsPiece(t: $0) }
                content: { EmptyView() } actions: { next(page, last: last) }
        case .together:
            FirstRunPage(tile: .bloom, colour: .shell, progress: page.dots, heading: "Share the day\nwith your family",
                         text: "Invite a partner, a grandparent or a carer. You\u{00A0}choose what each\u{00A0}can\u{00A0}do.") { SharePiece(t: $0) }
                content: { EmptyView() } actions: { next(page, last: last) }
        case .lookingBack:
            FirstRunPage(tile: .comb, colour: .mint, progress: page.dots, heading: "Look back\nover the week",
                         text: "Totals and patterns for each child, whenever\u{00A0}you\u{00A0}want\u{00A0}them.") { WeekPiece(t: $0) }
                content: { EmptyView() } actions: { next(page, last: last) }
        default:
            FirstRunPage(tile: .sparkle, colour: .lilac, progress: page.dots, heading: "Your entries\nstay private",
                         text: Persistence.cloudSyncEnabled ? "Kept on this iPhone and in iCloud." : "Kept on this iPhone.") {
                PrivatePiece(t: $0) { showingPromise = true }
            } content: { EmptyView() } actions: { next(page, last: last) }
        }
    }

    private func next(_ page: OnboardingStep, last: Bool) -> some View {
        Button(last ? "Set up your family" : "Continue") { go(page.nextPage) }
            .buttonStyle(PillButtonStyle())
    }

    /// A page with no piece of the app: a short band of pattern, then the words.
    private func plainPage<Content: View, Actions: View>(_ tile: PatternTile, _ colour: PatternColour, heading: String, text: String,
                                                         @ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) -> some View {
        FirstRunPage(tile: tile, colour: colour, band: true, progress: step.dots, heading: heading, text: text) { _ in EmptyView() }
            content: { content() } actions: { actions() }
    }

    /// For anyone helping: the invite does the work.
    private var joiningPage: some View {
        plainPage(.bloom, .shell, heading: "Join\nyour family",
                  text: "There's no account to make. The family's entries come to this iPhone through\u{00A0}iCloud.") {
            VStack(alignment: .leading, spacing: 14) {
                numbered(1, "Ask them to tap Invite someone on the Family tab.")
                numbered(2, "Open the invite on this iPhone, in Messages or Mail.")
                numbered(3, "Their children appear here.")
            }
            .padding(16)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
            Button("Start a new family") { go(.logging) }
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
        plainPage(.mix, .sky, heading: joinedSomeone ? "You've joined\nthe family" : "Welcome\nback",
                  text: joinedSomeone ? "You'll see and log the same day as everyone else." : "This iPhone found your family in iCloud.") {
            childList(ticks: true)
        } actions: {
            Button("Continue") { go(.you) }
                .buttonStyle(PillButtonStyle())
        }
    }

    // MARK: Setting up

    private var youPage: some View {
        plainPage(.check, .sand, heading: "Who's logging\non this iPhone?", text: "Your name shows beside what you log.") {
            if Persistence.cloudSyncEnabled { CloudProblemCard() }
            field("Your name", text: $nameDraft)
                .textContentType(.givenName)
                .focused($nameFocused)
            if !foundFamily {
                field("Family name, if you like", text: $familyDraft).padding(.top, 10)
            }
            Text(Persistence.cloudSyncEnabled && !foundFamily ? "Both are optional. The family name shows on invites."
                 : "Optional. Change it any time in Settings.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .padding(.top, 10)
        } actions: {
            Button("Continue") { saveYou() }
                .buttonStyle(PillButtonStyle())
        }
    }

    private func field(_ prompt: String, text: Binding<String>) -> some View {
        TextField(prompt, text: text)
            .submitLabel(.done)
            .font(.title3)
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(Palette.input, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func saveYou() {
        yourName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !foundFamily {
            _ = store.currentFamily()
            store.setFamilyName(familyDraft)
        }
        if let next = afterYou { go(next) } else { finish() }
    }

    private var childPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The band takes the colour chosen for this child, and changes as they pick one.
            PatternField(tile: .scales, colour: .forChild(draft.colour))
                .ignoresSafeArea(edges: .top)
                .frame(height: 76)
            VStack(alignment: .leading, spacing: 0) {
                if let dots = step.dots { FirstRunProgress(current: dots.current, count: dots.count).padding(.bottom, 18) }
                Text(children.isEmpty ? "Add your\nfirst child" : "Add\nanother child").firstRunHeading()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            Form { ChildForm(draft: $draft) }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .background(Palette.sand)
        }
        .safeAreaInset(edge: .bottom) {
            Button(draft.trimmedName.isEmpty ? "Add" : "Add \(draft.trimmedName)") { addChild() }
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
        plainPage(.scales, .forChild(children.count), heading: "Anyone else\nto add?", text: "Twins and siblings share one Today.") {
            childList(ticks: true).padding(.bottom, 10)
            Button {
                startAnotherChild()
            } label: {
                Label("Add another child", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(.horizontal, 14)
                    .background(Palette.paper.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        } actions: {
            Button("Continue") { go(Persistence.cloudSyncEnabled ? .invite : .family) }
                .buttonStyle(PillButtonStyle())
        }
    }

    private func childList(ticks: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(children) { child in
                HStack(spacing: 12) {
                    ChildAvatar(child: child, size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(child.displayName).font(.headline)
                        Text(child.ageTextFull).font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 8)
                    if ticks {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.gum).accessibilityHidden(true)
                    }
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

    /// Who else looks after them: an invite now, or later from the Family tab.
    private var invitePage: some View {
        plainPage(.bloom, .shell, heading: "Who else\nlooks after them?", text: "They use their own iPhone. You choose what each\u{00A0}person\u{00A0}can\u{00A0}do.") {
            VStack(spacing: 0) {
                level("Parent", "Can do everything you can")
                Divider().padding(.leading, 16)
                level("Helper", "Logs the day")
                Divider().padding(.leading, 16)
                level("Viewer", "Sees the day, can't log")
            }
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            CloudProblemCard()
            if let shareError {
                Text(shareError).font(.footnote).foregroundStyle(Palette.waratah)
            }
            Text(invited > 0 ? "Invite sent. Add someone else, or carry on." : "You can invite people any time from the Family tab.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .padding(.top, 10)
        } actions: {
            if cloud.isAvailable {
                Button(invited > 0 ? "Invite someone else" : "Invite someone") { inviting = true }
                    .buttonStyle(PillButtonStyle(primary: invited == 0))
                if invited > 0 {
                    Button("Continue") { go(.family) }
                        .buttonStyle(PillButtonStyle())
                }
            } else {
                Button("Continue") { go(.family) }
                    .buttonStyle(PillButtonStyle())
            }
        }
    }

    private func level(_ title: String, _ text: String) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer(minLength: 8)
            Text(text).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .accessibilityElement(children: .combine)
    }

    private func startSharing(_ invite: PendingInvite) async {
        do {
            let family = store.currentFamily()
            if store.persistence.existingShare(for: family) == nil { store.backUpQuietly(.beforeInvite) }
            let (share, container) = try await store.persistence.share(family)
            let title = store.shareTitle
            share[CKShare.SystemFieldKey.title] = title as CKRecordValue
            sharing = SharingItem(share: share, container: container, lookOnly: invite.role == .viewer, title: title)
            shareError = nil
        } catch {
            shareError = "The invite couldn't be made. Check this iPhone is signed in to iCloud, then try again." + TesterDetail.of(error)
        }
    }

    // MARK: The finish

    /// You and the children, and for someone who joined, everyone already in the family.
    private var heapPeople: [(name: String, colour: Color)] {
        var list: [(String, Color)] = []
        let me = yourName.trimmingCharacters(in: .whitespaces)
        if !me.isEmpty { list.append((me, Palette.wattle)) }
        if foundFamily, let family = store.existingFamily() {
            for person in (family.people ?? []).sorted(by: FamilyStore.listOrder)
            where person.joinedAt != nil && !person.isDeleted && person.displayName != me && person.displayName != "Someone" {
                list.append((person.displayName, Palette.harbour))
            }
        }
        for child in children { list.append((child.displayName, Palette.childColours[Int(child.colourIndex) % Palette.childColours.count])) }
        return list
    }

    private var familyTitle: String {
        if !store.familyName.isEmpty { return store.familyName }
        let names = children.map(\.displayName)
        guard !names.isEmpty else { return "Your family" }
        return "\(ListFormatter.localizedString(byJoining: names))'s family"
    }

    private var familyPage: some View {
        let people = heapPeople
        let names = ListFormatter.localizedString(byJoining: people.map(\.name))
        return VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(heapLanded || reduceMotion ? familyTitle : "Building your family")
                    .displayFont(32)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                if !names.isEmpty {
                    Text(names).font(.title3).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            FamilyHeap(letters: people.map { .init(initial: String($0.name.prefix(1)).uppercased(), colour: $0.colour) },
                       names: names.isEmpty ? "Shapes in a heap" : "A heap of shapes for \(names)",
                       round: heapRound) {
                withAnimation(.easeOut(duration: 0.3)) { heapLanded = true }
                Haptics.success()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 6) {
                Button("Open Today") { finish() }
                    .buttonStyle(PillButtonStyle())
                HStack(spacing: 4) {
                    Text("Tilt the phone, or throw a shape.").foregroundStyle(Palette.muted)
                    Button("Drop again") {
                        heapLanded = false
                        heapRound += 1
                    }
                    .fontWeight(.semibold)
                    .frame(minHeight: 44)
                }
                .font(.footnote)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
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
