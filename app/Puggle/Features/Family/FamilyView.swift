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

    var body: some View {
        NavigationStack {
            List {
                Section("Children") {
                    ForEach(children) { child in
                        HStack(spacing: 12) {
                            ChildAvatar(child: child, size: 40)
                            VStack(alignment: .leading) {
                                Text(child.displayName).font(.headline)
                                Text(child.ageText).font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                        .listRowBackground(Palette.paper)
                    }
                    .onDelete { offsets in offsets.map { children[$0] }.forEach(store.delete) }
                    Button("Add a child") { addingChild = true }
                        .listRowBackground(Palette.paper)
                }
                Section {
                    Button("Invite someone") { Task { await startSharing() } }
                        .listRowBackground(Palette.paper)
                } header: {
                    Text("Sharing")
                } footer: {
                    Text("Anyone you invite sees and logs the same day, on their own iPhone, with their own Apple Account.")
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

struct AddChildView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: []) private var children: FetchedResults<Child>

    @State private var name = ""
    @State private var birthDate = Calendar.current.date(byAdding: .month, value: -6, to: .now) ?? .now
    @State private var colour = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textContentType(.givenName)
                DatePicker("Birth date", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                Section("Colour") {
                    HStack(spacing: 14) {
                        ForEach(Palette.childColours.indices, id: \.self) { index in
                            Button {
                                colour = index
                            } label: {
                                Circle()
                                    .fill(Palette.childColours[index])
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(Palette.ink, lineWidth: colour == index ? 3 : 0))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(["Sky", "Shell", "Mint", "Sun"][index])
                        }
                    }
                }
            }
            .navigationTitle("Add a child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addChild(name: name, birthDate: birthDate, colourIndex: colour)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { colour = children.count % Palette.childColours.count }
        }
    }
}
