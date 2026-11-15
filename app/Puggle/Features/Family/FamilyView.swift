import CloudKit
import CoreData
import SwiftUI
import UIKit

/// Children, and sharing the family with a partner, Nan or the nanny.
struct FamilyView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var allChildren: FetchedResults<Child>
    private var children: [Child] { store.onScreen(allChildren) }

    @State private var addingChild = false
    @State private var showingYou = false
    @FetchRequest(sortDescriptors: [SortDescriptor(\Person.createdAt)]) private var allPeople: FetchedResults<Person>
    @State private var sharing: SharingItem?
    @State private var shareError: String?
    @State private var inviting = false
    @State private var pending: PendingInvite?
    @State private var opened: Person?
    @ObservedObject private var cloud = CloudStatus.shared
    @State private var familyName = ""
    @State private var bringingIn = false
    @FocusState private var namingFamily: Bool
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
                // You, at the head of your family, as the iPhone's own Settings has it (Tom, 15 November 2026).
                // Only the name and the family here. "You" and the role are on the person's row in Family and
                // friends, so nothing is said twice.
                Section {
                    Button { showingYou = true } label: {
                        HStack(spacing: 14) {
                            YourAvatar(size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(yourName.trimmingCharacters(in: .whitespaces).isEmpty ? "Add your name" : yourName)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text(store.familyName.isEmpty ? store.childrenTitle : store.familyName)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.muted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted.opacity(0.6))
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Your name and photo")
                    .listRowBackground(Palette.paper)
                }
                if store.isParent && !sample.isOn {
                    Section {
                        TextField(store.childrenTitle, text: $familyName)
                            .focused($namingFamily)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit { store.setFamilyName(familyName) }
                            .onChange(of: namingFamily) { _, focused in
                                if !focused { store.setFamilyName(familyName) }
                            }
                            .listRowBackground(Palette.input)
                    } header: {
                        Text("Family name")
                    } footer: {
                        Text("Shown on invites, such as \"The Wattle family\". Leave it empty to use the children's names.")
                    }
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
                    if store.isParent {
                        Button("Add a child") { addingChild = true }
                            .listRowBackground(Palette.paper)
                    }
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
                if !sample.isOn, Persistence.cloudSyncEnabled, cloud.problem != nil {
                    CloudProblemCard()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                let kept = store.ownChildrenBesideJoined
                if !kept.isEmpty {
                    Section {
                        ForEach(kept) { child in
                            HStack(spacing: 12) {
                                ChildAvatar(child: child, size: 40)
                                Text(child.displayName).font(.headline)
                            }
                            .listRowBackground(Palette.paper)
                        }
                        if store.canLog {
                            Button("Bring into this family") { bringingIn = true }
                                .listRowBackground(Palette.paper)
                        }
                    } header: {
                        Text("Only on this iPhone")
                    } footer: {
                        Text("Saved here from before you joined, and not shown with the family's children.")
                    }
                }
                Section {
                    ForEach(people) { person in
                        let opens = store.isParent || store.isMe(person)
                        Button {
                            // Your own row opens your photo and name, as the card at the top does.
                            if store.isMe(person) { showingYou = true } else if opens { opened = person }
                        } label: {
                            PersonRow(person: person, isMe: store.isMe(person), opens: opens)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Palette.paper)
                    }
                    if canInvite {
                        Button("Invite someone") { inviting = true }
                            .disabled(!cloud.isAvailable)
                            .listRowBackground(Palette.paper)
                    }
                } header: {
                    Text("Family and friends")
                } footer: {
                    if !store.managesPeople {
                        Text("\(store.holderName) can invite people and change what they can do.")
                    } else if sample.isOn {
                        Text("A made-up family. Nobody is invited from here.")
                    } else if !Persistence.cloudSyncEnabled {
                        Text("Test build: sharing is off, and everything stays on this iPhone.")
                    } else {
                        Text("Anyone you invite sees the same day on their own iPhone.")
                    }
                }
                if let shareError {
                    Text(shareError).font(.footnote).foregroundStyle(Palette.waratah)
                }
                Section {
                    NavigationLink { SettingsView() } label: { Label("Settings", systemImage: "gearshape") }
                    NavigationLink { HelpView() } label: { Label("Help and about", systemImage: "questionmark.circle") }
                }
                .foregroundStyle(Palette.ink)
                .listRowBackground(Palette.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("Family")
            .sheet(isPresented: $addingChild) { AddChildView() }
            .sheet(isPresented: $showingYou) { YouView() }
            .sheet(isPresented: $inviting) {
                InviteSheet { invite in
                    pending = invite
                    Task { await startSharing(invite) }
                }
            }
            .sheet(item: $opened) { PersonSheet(person: $0) }
            .sheet(isPresented: $bringingIn) { BringInView() }
            .sheet(item: $sharing, onDismiss: {
                // Whoever was added in the share sheet gets the name and level just chosen.
                store.reconcilePeople(pending: pending)
                pending = nil
            }) { item in
                CloudSharingView(share: item.share, container: item.container, lookOnly: item.lookOnly, title: item.title) {
                    Task { @MainActor in store.reconcilePeople(pending: pending) }
                } onFailed: { error in
                    Task { @MainActor in
                        shareError = "iCloud couldn't save the invite. Try again in a minute." + TesterDetail.of(error)
                    }
                }
                .ignoresSafeArea()
            }
            .onAppear {
                familyName = store.familyName
                store.reconcilePeople()
                store.ensureMe()
                store.refreshRole()
            }
        }
    }

    /// Everyone in the family on screen, in a steady order.
    private var people: [Person] {
        guard let family = store.existingFamily() else { return [] }
        return allPeople.filter { $0.family == family }.sorted(by: FamilyStore.listOrder)
    }

    private var canInvite: Bool {
        store.managesPeople && !sample.isOn && Persistence.cloudSyncEnabled
    }

    private func startSharing(_ invite: PendingInvite) async {
        do {
            let family = store.currentFamily()
            // The first time, keep a copy of the family as it was before anyone else could change it.
            if store.persistence.existingShare(for: family) == nil { store.backUpQuietly(.beforeInvite) }
            let (share, container) = try await store.persistence.share(family)
            let title = store.shareTitle
            share[CKShare.SystemFieldKey.title] = title as CKRecordValue
            sharing = SharingItem(share: share, container: container, lookOnly: invite.role == .viewer, title: title)
        } catch {
            shareError = "Couldn't start the invite. Check this iPhone is signed in to iCloud, then try again." + TesterDetail.of(error)
            print("Sharing failed: \(error)")
        }
    }
}
