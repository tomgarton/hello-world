import CloudKit
import SwiftUI
import UIKit

/// An invite that has been opened, waiting for a yes.
struct Invite: Identifiable {
    let id = UUID()
    /// Nil only for the made-up invites used to check these screens.
    var metadata: CKShare.Metadata?
    var inviter: String
    var familyTitle: String
    var lookOnly: Bool

    init(_ metadata: CKShare.Metadata) {
        self.metadata = metadata
        let components = metadata.ownerIdentity.nameComponents
        let name = components.map { PersonNameComponentsFormatter.localizedString(from: $0, style: .short) } ?? ""
        inviter = name
        familyTitle = (metadata.share[CKShare.SystemFieldKey.title] as? String) ?? ""
        lookOnly = metadata.participantPermission == .readOnly
    }

    init(inviter: String, familyTitle: String, lookOnly: Bool) {
        self.inviter = inviter
        self.familyTitle = familyTitle
        self.lookOnly = lookOnly
    }

    /// "Alex invited you to Ollie and Bea's family".
    var headline: String {
        let who = inviter.isEmpty ? "You've been invited" : "\(inviter) invited you"
        let generic = familyTitle.isEmpty || familyTitle == "Our family"
        // "The Wattle family" reads as "to the Wattle family" inside the sentence.
        let title = familyTitle.hasPrefix("The ") ? "the " + familyTitle.dropFirst(4) : familyTitle
        return generic ? "\(who) to their family" : "\(who) to \(title)"
    }
}

/// Holds an opened invite until the app can show it.
@MainActor
final class InviteCenter: ObservableObject {
    static let shared = InviteCenter()
    @Published var invite: Invite?

    func received(_ metadata: CKShare.Metadata) {
        invite = Invite(metadata)
    }

    /// When an invite was accepted on this phone, until the family has arrived or the wait is given up.
    @Published private(set) var joinedAt: Date? = UserDefaults.standard.object(forKey: "joinedAt") as? Date

    /// True for a quarter of an hour after joining: long enough for a family to come down from iCloud.
    var awaitingFamily: Bool { joinedAt.map { Date.now.timeIntervalSince($0) < 15 * 60 } ?? false }

    func markJoined() {
        joinedAt = .now
        UserDefaults.standard.set(joinedAt, forKey: "joinedAt")
    }

    func stopWaiting() {
        joinedAt = nil
        UserDefaults.standard.removeObject(forKey: "joinedAt")
    }
}

/// Why joining didn't work, in terms of what to do next.
enum JoinProblem: String {
    case used, noICloud, offline, other

    var title: String {
        switch self {
        case .used: "This invite can't be used any more"
        case .noICloud: "Sign in to iCloud to join"
        case .offline: "Couldn't reach iCloud"
        case .other: "Joining didn't work"
        }
    }

    func detail(inviter: String) -> String {
        let them = inviter.isEmpty ? "the person who invited you" : inviter
        switch self {
        case .used:
            return "It may have been sent to a different email or number than the one this iPhone uses for iCloud, or it may have been withdrawn. Ask \(them) to send a new one from Family, then Invite someone."
        case .noICloud:
            return "The family is shared through iCloud. Open the Settings app, sign in at the top, then tap the invite link again."
        case .offline:
            return "Check this iPhone is online, then try again. The invite will still work."
        case .other:
            return "Try again in a moment. If it keeps happening, ask \(them) to send a new invite."
        }
    }

    init(_ error: Error) {
        guard let cloud = error as? CKError else { self = .other; return }
        switch cloud.code {
        case .notAuthenticated, .accountTemporarilyUnavailable:
            self = .noICloud
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
            self = .offline
        case .unknownItem, .participantMayNeedVerification, .permissionFailure, .tooManyParticipants, .alreadyShared, .invalidArguments:
            self = .used
        default:
            self = .other
        }
    }
}

/// Opening an invite: who it is from, what it is to, and one button.
struct JoinView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Setting.yourName) private var yourName = ""
    @ObservedObject private var cloud = CloudStatus.shared
    let invite: Invite

    enum Stage: Equatable { case asking, joining, joined, failed(JoinProblem) }
    @State var stage: Stage = .asking

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    switch stage {
                    case .asking, .joining: asking
                    case .joined: joined
                    case .failed(let problem): failed(problem)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 10) { buttons }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .interactiveDismissDisabled(stage == .joining)
    }

    @ViewBuilder private var asking: some View {
        Image(systemName: "person.2.fill")
            .font(.system(size: 34))
            .frame(width: 84, height: 84)
            .background(Palette.field, in: Circle())
            .accessibilityHidden(true)
        Text(invite.headline)
            .displayFont(28)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        Text(invite.lookOnly
             ? "You'll be a viewer. You'll see their day on this iPhone, and you can't add or change anything."
             : "You'll see their day on this iPhone, and you can add to it.")
            .foregroundStyle(Palette.muted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        VStack(alignment: .leading, spacing: 4) {
            Text("Your name").font(.footnote).foregroundStyle(Palette.muted)
            TextField("Your name", text: $yourName)
                .textContentType(.givenName)
                .submitLabel(.done)
            Text(invite.lookOnly ? "Kept on this iPhone." : "Shown beside what you log.")
                .font(.footnote).foregroundStyle(Palette.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.input, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.top, 8)
    }

    @ViewBuilder private var joined: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 34, weight: .bold))
            .frame(width: 84, height: 84)
            .background(Palette.field, in: Circle())
            .accessibilityHidden(true)
        Text("You're in").displayFont(28)
        Text("The family is on its way to this iPhone. It can take a minute to arrive.")
            .foregroundStyle(Palette.muted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func failed(_ problem: JoinProblem) -> some View {
        Image(systemName: problem == .noICloud ? "icloud.slash" : "envelope.open")
            .font(.system(size: 34))
            .frame(width: 84, height: 84)
            .background(Palette.field, in: Circle())
            .accessibilityHidden(true)
        Text(problem.title)
            .displayFont(28)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        Text(problem.detail(inviter: invite.inviter))
            .foregroundStyle(Palette.muted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var buttons: some View {
        switch stage {
        case .asking, .joining:
            Button {
                join()
            } label: {
                if stage == .joining {
                    ProgressView().tint(Palette.paper)
                } else {
                    Text("Join the family")
                }
            }
            .buttonStyle(PillButtonStyle())
            .disabled(stage == .joining)
            Button("Not now") { dismiss() }
                .buttonStyle(PillButtonStyle(primary: false))
                .disabled(stage == .joining)
        case .joined:
            Button("Done") { dismiss() }.buttonStyle(PillButtonStyle())
        case .failed(.noICloud):
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .buttonStyle(PillButtonStyle())
            Button("Not now") { dismiss() }.buttonStyle(PillButtonStyle(primary: false))
        case .failed(.offline), .failed(.other):
            Button("Try again") { join() }.buttonStyle(PillButtonStyle())
            Button("Not now") { dismiss() }.buttonStyle(PillButtonStyle(primary: false))
        case .failed(.used):
            Button("OK") { dismiss() }.buttonStyle(PillButtonStyle())
        }
    }

    private func join() {
        guard let metadata = invite.metadata else { return }
        if cloud.state == .signedOut || cloud.state == .restricted {
            stage = .failed(.noICloud)
            return
        }
        stage = .joining
        Task {
            do {
                try await Persistence.shared.acceptShare(metadata)
                InviteCenter.shared.markJoined()
                Me.refreshCloudID()
                stage = .joined
            } catch {
                print("Accepting share failed: \(error)")
                stage = .failed(JoinProblem(error))
            }
        }
    }
}

/// After joining, while the family is on its way from iCloud. Without this a new
/// phone would land back on the welcome screen with "Start a new family" in front of it.
struct ArrivingView: View {
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(Palette.ink)
            Text("Getting the family")
                .displayFont(28)
                .multilineTextAlignment(.center)
            Text("The children and their entries are coming to this iPhone from iCloud. It can take a few minutes, and needs a connection.")
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Stop waiting") { onStop() }
                .buttonStyle(PillButtonStyle(primary: false))
            Text("If they don't arrive, ask whoever invited you to check the invite went to the email or number you use for iCloud.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
    }
}
