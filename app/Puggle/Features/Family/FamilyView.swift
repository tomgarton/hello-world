import CloudKit
import CoreData
import SwiftUI
import UIKit

/// Children, and sharing the family with a partner, Nan or the nanny.
struct FamilyView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>

    @State private var addingChild = false
    @State private var sharing: SharingItem?
    @State private var shareError: String?
    @AppStorage("pottyStickers") private var stickersOn = true

    var body: some View {
        NavigationStack {
            List {
                Section("Children") {
                    ForEach(children) { child in
                        NavigationLink {
                            ChildDetailView(child: child)
                        } label: {
                            HStack(spacing: 12) {
                                ChildAvatar(child: child, size: 40)
                                VStack(alignment: .leading) {
                                    Text(child.displayName).font(.headline)
                                    Text(child.ageTextFull).font(.subheadline).foregroundStyle(Palette.muted)
                                }
                            }
                        }
                        .listRowBackground(Palette.paper)
                    }
                    Button("Add a child") { addingChild = true }
                        .listRowBackground(Palette.paper)
                }
                if Persistence.cloudSyncEnabled {
                    Section {
                        Button("Invite someone") { Task { await startSharing() } }
                            .listRowBackground(Palette.paper)
                    } header: {
                        Text("Sharing")
                    } footer: {
                        Text("Anyone you invite sees and logs the same day, on their own iPhone, with their own Apple Account.")
                    }
                } else {
                    Section {
                        Text("This is a local build. Everything stays on this iPhone, and sharing is switched off.")
                            .foregroundStyle(Palette.muted)
                            .listRowBackground(Palette.paper)
                    } header: {
                        Text("Sharing")
                    }
                }
                if children.contains(where: \.pottyTraining) {
                    Section {
                        Toggle("Stickers after the potty", isOn: $stickersOn)
                            .listRowBackground(Palette.paper)
                    } footer: {
                        Text("After a wee, a poo or a try, the phone offers a sticker to choose.")
                    }
                }
                Section {
                    NavigationLink("Your data") { YourDataView() }
                        .listRowBackground(Palette.paper)
                    NavigationLink("Help and about") { HelpView() }
                        .listRowBackground(Palette.paper)
                }
                if let shareError {
                    Text(shareError).font(.footnote).foregroundStyle(Palette.waratah)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("Family")
            .sheet(isPresented: $addingChild) { AddChildView() }
            .sheet(item: $sharing) { item in
                CloudSharingView(share: item.share, container: item.container)
                    .ignoresSafeArea()
            }
        }
    }

    private func startSharing() async {
        do {
            let family = store.currentFamily()
            let (share, container) = try await store.persistence.share(family)
            sharing = SharingItem(share: share, container: container)
        } catch {
            shareError = "Couldn't start sharing: \(error.localizedDescription). Check you're signed in to iCloud."
        }
    }
}

struct SharingItem: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}

/// Apple's standard sharing sheet: invite by Messages, Mail or a link.
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}
}
