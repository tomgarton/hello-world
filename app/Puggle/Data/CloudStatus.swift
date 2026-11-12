import CloudKit
import SwiftUI
import UIKit

/// Whether this iPhone can sync: signed in to iCloud, with iCloud allowed for
/// the app. Checked at launch and whenever the account changes. Logging works
/// either way; without iCloud, entries stay on this phone until it is on.
@MainActor
final class CloudStatus: ObservableObject {
    static let shared = CloudStatus()

    enum State { case checking, available, signedOut, restricted, unavailable }
    @Published private(set) var state: State = .checking

    var isAvailable: Bool { state == .available }

    private init() {
        guard Persistence.cloudSyncEnabled else { state = .unavailable; return }
        NotificationCenter.default.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { _ in
            Task { @MainActor in CloudStatus.shared.refresh() }
        }
        // Started on the next turn, once the app is up.
        Task { @MainActor in CloudStatus.shared.refresh() }
    }

    /// Asked away from the main thread: making an iCloud container on the main
    /// thread while Core Data sets up its own can deadlock, freezing the app at launch.
    func refresh() {
        guard Persistence.cloudSyncEnabled else { return }
        Task.detached(priority: .utility) {
            let status = (try? await CKContainer(identifier: Persistence.cloudKitContainerID).accountStatus()) ?? .couldNotDetermine
            await MainActor.run {
                CloudStatus.shared.state = switch status {
                case .available: .available
                case .noAccount: .signedOut
                case .restricted: .restricted
                case .temporarilyUnavailable, .couldNotDetermine: .unavailable
                @unknown default: .unavailable
                }
            }
        }
    }

    /// One plain sentence for when sync isn't possible, or nil when it is.
    var problem: String? {
        switch state {
        case .available, .checking: nil
        case .signedOut: "This iPhone isn't signed in to iCloud, so everything stays on this phone for now. Sign in to share with your family."
        case .restricted: "iCloud is turned off for this iPhone, perhaps by Screen Time. Entries stay on this phone."
        case .unavailable: Persistence.cloudSyncEnabled ? "iCloud isn't reachable right now. Logging still works and syncs when it's back." : nil
        }
    }
}

/// A quiet card explaining that iCloud isn't on, with a way to Settings.
struct CloudProblemCard: View {
    @ObservedObject private var cloud = CloudStatus.shared

    var body: some View {
        if let problem = cloud.problem {
            VStack(alignment: .leading, spacing: 10) {
                Label("Not syncing", systemImage: "icloud.slash")
                    .font(.subheadline.weight(.semibold))
                Text(problem)
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if cloud.state == .signedOut {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
