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
    @EnvironmentObject private var sample: SampleFamily
    @AppStorage(Setting.yourName) private var yourName = ""

    var body: some View {
        NavigationStack {
            List {
                if sample.isOn {
                    SampleBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 34))
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                Text(yourName.trimmingCharacters(in: .whitespaces).isEmpty ? "You" : yourName).font(.headline)
                                Text("Settings, your data and help").font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                    .listRowBackground(Palette.paper)
                }
                Section("Children") {
                    ForEach(children.filter { !$0.archived }) { child in
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
                if children.contains(where: \.archived) {
                    Section {
                        ForEach(children.filter(\.archived)) { child in
                            NavigationLink {
                                ChildDetailView(child: child)
                            } label: {
                                HStack(spacing: 12) {
                                    ChildAvatar(child: child, size: 40)
                                    Text(child.displayName).font(.headline)
                                }
                            }
                            .listRowBackground(Palette.paper)
                        }
                    } header: {
                        Text("Hidden from Today")
                    } footer: {
                        Text("Their history is kept. Open a child to bring them back.")
                    }
                }
                if sample.isOn {
                    EmptyView()
                } else if Persistence.cloudSyncEnabled {
                    Section {
                        Button("Invite someone") { Task { await startSharing() } }
                            .listRowBackground(Palette.paper)
                    } header: {
                        Text("Sharing")
                    } footer: {
                        Text("Anyone you invite sees and logs the same day on their own iPhone.")
                    }
                } else {
                    Section {
                        Text("Test build: sharing is off, and everything stays on this iPhone.")
                            .foregroundStyle(Palette.muted)
                            .listRowBackground(Palette.paper)
                    } header: {
                        Text("Sharing")
                    }
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
