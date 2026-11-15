import CloudKit
import PhotosUI
import SwiftUI
import UIKit

/// A person's photo, or their initial. Dashed until they have joined.
struct PersonAvatar: View {
    @ObservedObject var person: Person
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let image = person.image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(person.initial)
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.field)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if !person.hasJoined {
                Circle().strokeBorder(Palette.muted, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
        .accessibilityHidden(true)
    }
}

/// "Add a photo": from the camera or the photo library, or take it away.
struct PhotoMenu: View {
    let hasPhoto: Bool
    /// The front camera suits a photo of yourself.
    var front = true
    let onImage: (UIImage?) -> Void

    @State private var taking = false
    @State private var choosing = false
    @State private var choosingCharacter = false
    @State private var picked: PhotosPickerItem?

    var body: some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { taking = true } label: { Label("Take a photo", systemImage: "camera") }
            }
            Button { choosing = true } label: { Label("Choose a photo", systemImage: "photo") }
            Button { choosingCharacter = true } label: { Label("Choose a character", systemImage: "face.smiling") }
            if hasPhoto {
                Button(role: .destructive) { onImage(nil) } label: { Label("Remove photo", systemImage: "trash") }
            }
        } label: {
            Text(hasPhoto ? "Change photo" : "Add a photo")
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        }
        .photosPicker(isPresented: $choosing, selection: $picked, matching: .images)
        .sheet(isPresented: $choosingCharacter) { CharacterPicker { onImage($0) } }
        .fullScreenCover(isPresented: $taking) {
            CameraPicker(front: front) { onImage($0) }
                .ignoresSafeArea()
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    onImage(image)
                }
                picked = nil
            }
        }
    }
}

/// One row in "Family and friends".
struct PersonRow: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var person: Person
    var isMe: Bool
    var opens: Bool

    private var detail: String? {
        guard !person.hasJoined else { return nil }
        guard let invited = person.invitedAt else { return "Not joined yet" }
        return "Invited \(invited.formatted(.dateTime.weekday(.wide))) · Not joined yet"
    }

    var body: some View {
        HStack(spacing: 12) {
            PersonAvatar(person: person, size: 40)
            VStack(alignment: .leading) {
                // Their name, and "You" after it on the person's own row (Tom, 15 November 2026).
                NameAndYou(name: person.displayName, isMe: isMe).font(.headline)
                // The line under the name is only for someone still to join.
                if let detail { Text(detail).font(.subheadline).foregroundStyle(Palette.muted) }
            }
            Spacer(minLength: 8)
            // Roles down the right-hand side, so the list can be read down one edge (Tom, 15 November 2026).
            RoleChip(person.role.title)
            if opens {
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// "Alex · You" on the person's own row, their name alone on anyone else's, and "You" where no name is set.
struct NameAndYou: View {
    let name: String
    let isMe: Bool

    var body: some View {
        let known = !name.trimmingCharacters(in: .whitespaces).isEmpty && name != "You"
        if isMe, known {
            (Text(name) + Text(" · You").foregroundStyle(Palette.muted)).lineLimit(1)
        } else {
            Text(isMe ? "You" : name).lineLimit(1)
        }
    }
}

/// A small pill beside a name, holding the person's role: Parent, Helper or Viewer.
struct RoleChip: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Palette.field, in: Capsule())
            .fixedSize()
    }
}

/// One person: their photo and name, what they can do, and the way out.
struct PersonSheet: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var person: Person
    @AppStorage(Setting.yourName) private var yourName = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = true
    @ObservedObject private var myPhoto = YourPhoto.shared

    @State private var name = ""
    @State private var busy = false
    @State private var problem: String?
    @State private var confirmingRemove = false
    @State private var confirmingLeave = false

    private var isMe: Bool { store.isMe(person) }
    /// Your own row, or anyone's if you are a parent. A viewer's phone can't save a change.
    private var canEditDetails: Bool { store.role == .parent || (isMe && store.role != .viewer) }
    private var canManage: Bool { store.managesPeople && !person.holdsFamily }
    private var first: String { person.displayName }

    private var since: String {
        if person.holdsFamily { return "Started the family" }
        if let joined = person.joinedAt { return "Joined \(joined.formatted(.dateTime.day().month(.wide)))" }
        if let invited = person.invitedAt { return "Invited \(invited.formatted(.dateTime.day().month(.wide))). Not joined yet" }
        return ""
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        if isMe && store.role == .viewer {
                            YourAvatar(size: 96)
                        } else {
                            PersonAvatar(person: person, size: 96)
                        }
                        if canEditDetails {
                            PhotoMenu(hasPhoto: person.photo != nil, front: isMe) { setPhoto($0) }
                        }
                        if !since.isEmpty {
                            Text(since).font(.footnote).foregroundStyle(Palette.muted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderless)
                    .listRowBackground(Color.clear)
                }

                Section {
                    if canEditDetails {
                        LabeledContent(isMe ? "Your name" : "Name") {
                            TextField("Name", text: $name)
                                .multilineTextAlignment(.trailing)
                                .textContentType(.givenName)
                                .submitLabel(.done)
                                .onSubmit(saveName)
                        }
                    } else {
                        LabeledContent("Name") { Text(isMe && !yourName.isEmpty ? yourName : first) }
                    }
                    if !canManage {
                        LabeledContent(isMe ? "What you can do" : "What \(first) can do") { Text(person.role.title) }
                    }
                } footer: {
                    if isMe {
                        Text(store.role == .viewer
                             ? "As a viewer, your name and photo stay on this iPhone. \(store.holderName) can add them for the family."
                             : "Your name and photo are shown to your family, beside what you log.")
                    }
                }
                .listRowBackground(Palette.paper)

                if canManage {
                    Section {
                        ForEach(Role.allCases) { role in
                            Button {
                                choose(role)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: role.symbol)
                                        .font(.body.weight(.semibold))
                                        .frame(width: 36, height: 36)
                                        .background(Palette.field, in: Circle())
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(role.title).font(.headline)
                                        Text(role.about).font(.subheadline).foregroundStyle(Palette.muted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 8)
                                    if person.role == role {
                                        Image(systemName: "checkmark").font(.body.weight(.bold))
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(person.role == role ? .isSelected : [])
                        }
                    } header: {
                        Text("What \(first) can do")
                    } footer: {
                        Text(person.hasJoined ? "Changes on \(first)'s iPhone the next time it syncs."
                                              : "Ready for when \(first) joins.")
                    }
                    .listRowBackground(Palette.paper)
                    .disabled(busy)

                    Section {
                        Button("Remove \(first) from the family", role: .destructive) { confirmingRemove = true }
                            .foregroundStyle(Palette.waratah)
                    } footer: {
                        Text("Ends \(first)'s access. What \(first) logged is kept.")
                    }
                    .listRowBackground(Palette.paper)
                    .disabled(busy)
                }

                if isMe && !store.holdsFamily && !store.isSample {
                    Section {
                        Button("Leave this family", role: .destructive) { confirmingLeave = true }
                            .foregroundStyle(Palette.waratah)
                    } footer: {
                        Text("Takes the family off this iPhone. What you logged is kept for them.")
                    }
                    .listRowBackground(Palette.paper)
                    .disabled(busy)
                }

                if let problem {
                    Text(problem).font(.footnote).foregroundStyle(Palette.waratah)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .navigationTitle(isMe ? "You" : first)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        saveName()
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Remove \(first)?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove \(first)", role: .destructive) { remove() }
                Button("Keep", role: .cancel) {}
            } message: {
                Text("\(first) won't see the family on their iPhone any more. What \(first) logged is kept. This can't be undone, but you can invite \(first) again.")
            }
            .confirmationDialog("Leave this family?", isPresented: $confirmingLeave, titleVisibility: .visible) {
                Button("Leave", role: .destructive) { leave() }
                Button("Stay", role: .cancel) {}
            } message: {
                Text("The children come off this iPhone. What you logged is kept for the family. To come back, ask \(store.holderName) for a new invite.")
            }
            .onAppear { name = isMe && !yourName.isEmpty ? yourName : (person.name ?? "") }
            .onDisappear(perform: saveName)
        }
        .presentationDetents([.large])
    }

    private func saveName() {
        guard canEditDetails, person.managedObjectContext != nil, !person.isDeleted else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if isMe { yourName = trimmed }
        store.rename(person, to: trimmed)
    }

    private func setPhoto(_ image: UIImage?) {
        if isMe {
            // Your photo is also what Today shows, top right.
            myPhoto.set(image)
            person.photo = myPhoto.data
            store.persistence.save()
        } else {
            store.setPhoto(image, for: person)
        }
    }

    private func choose(_ role: Role) {
        guard role != person.role else { return }
        if store.isSample {
            person.role = role
            store.persistence.save()
            return
        }
        run { try await store.setRole(role, for: person) }
    }

    private func remove() {
        if store.isSample {
            dismiss()
            store.context.delete(person)
            store.persistence.save()
            return
        }
        run {
            try await store.remove(person)
            dismiss()
        }
    }

    private func leave() {
        run {
            let nothingLeft = try await store.leaveFamily()
            dismiss()
            if nothingLeft { hasOnboarded = false }
        }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        busy = true
        problem = nil
        Task {
            do {
                try await work()
            } catch {
                problem = "That didn't go through. Check this iPhone is online and signed in to iCloud, then try again."
                print("People change failed: \(error)")
            }
            busy = false
        }
    }
}

/// Choose what they can do, then Apple's share sheet sends the link.
struct InviteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSend: (PendingInvite) -> Void
    @State private var name = ""
    @State private var role: Role = .helper

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Their name", text: $name)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                } footer: {
                    Text("Shown in your list until they join.")
                }
                .listRowBackground(Palette.input)

                Section {
                    ForEach(Role.allCases) { option in
                        Button {
                            role = option
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: option.symbol)
                                    .font(.body.weight(.semibold))
                                    .frame(width: 36, height: 36)
                                    .background(Palette.field, in: Circle())
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.title).font(.headline)
                                    Text(option.whoFor).font(.subheadline).foregroundStyle(Palette.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                if role == option {
                                    Image(systemName: "checkmark").font(.body.weight(.bold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(role == option ? .isSelected : [])
                    }
                } header: {
                    Text("What can they do?")
                } footer: {
                    Text("You can change this later, or remove them.")
                }
                .listRowBackground(Palette.paper)

                Section {
                    Text("They need an iPhone signed in to iCloud. On the next screen, send the invite to the email or number they use for iCloud.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(Palette.fixedInk)
                        .listRowBackground(Palette.wattle.opacity(0.45))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Invite someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Send the invite") {
                    dismiss()
                    onSend(PendingInvite(name: name, role: role))
                }
                .buttonStyle(PillButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

/// What iCloud said went wrong, for test builds. It is left off App Store builds: it means nothing to a parent,
/// but it tells whoever is testing which of a dozen causes this was.
enum TesterDetail {
    /// True in builds from Xcode and from TestFlight.
    static var on: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    static func of(_ error: Error) -> String {
        guard on else { return "" }
        let detail = error as NSError
        let partial = (detail.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: NSError])?.values.first
        let inner = partial.map { " Inside: \($0.domain) \($0.code)." } ?? ""
        return "\n\nFor testing: \(detail.domain) \(detail.code). \(detail.localizedDescription)\(inner)"
    }
}

struct SharingItem: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
    /// A viewer is invited to look only, which iCloud itself enforces.
    var lookOnly = false
    var title = "Our family"
}

/// Apple's standard sharing sheet: invite by Messages, Mail or a link.
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var lookOnly = false
    var title = "Our family"
    /// Called when the sheet has saved a change to who is in the family.
    var onSaved: () -> Void = {}
    /// Called when iCloud would not save the invite, with what it said.
    var onFailed: (Error) -> Void = { _ in }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        // Only the people invited, never "anyone with the link".
        controller.availablePermissions = [lookOnly ? .allowReadOnly : .allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: CloudSharingView
        init(_ parent: CloudSharingView) { self.parent = parent }

        func itemTitle(for csc: UICloudSharingController) -> String? { parent.title }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Saving the share failed: \(error)")
            parent.onFailed(error)
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) { parent.onSaved() }
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) { parent.onSaved() }
    }
}
