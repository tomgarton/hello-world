import SwiftUI

/// Your own photo, kept small, on this phone only.
@MainActor
final class YourPhoto: ObservableObject {
    static let shared = YourPhoto()
    @Published private(set) var image: UIImage?
    /// The saved file, as it is: the same bytes each time, so it can be compared.
    var data: Data? { image == nil ? nil : try? Data(contentsOf: url) }

    private var url: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("you.jpg")
    }

    private init() {
        image = (try? Data(contentsOf: url)).flatMap(UIImage.init(data:))
    }

    func set(_ picked: UIImage?) {
        guard let picked else {
            try? FileManager.default.removeItem(at: url)
            image = nil
            return
        }
        // A square, 300 points across, is plenty for a round avatar.
        guard let small = SmallPhoto.data(from: picked) else { return }
        try? small.write(to: url, options: .atomic)
        image = UIImage(data: small)
    }
}

/// Your photo, or your initial, or a plain person.
struct YourAvatar: View {
    var size: CGFloat
    @AppStorage(Setting.yourName) private var yourName = ""
    @ObservedObject private var photo = YourPhoto.shared

    var body: some View {
        Group {
            if let image = photo.image {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let first = yourName.trimmingCharacters(in: .whitespaces).first {
                Text(String(first).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.field)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.field)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// You: your photo and name. Settings and Help are one row away.
struct YouView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Setting.yourName) private var yourName = ""
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var photo = YourPhoto.shared

    private var version: String {
        let info = Bundle.main.infoDictionary
        return "Version \(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 10) {
                        YourAvatar(size: 104)
                        PhotoMenu(hasPhoto: photo.image != nil) { image in
                            photo.set(image)
                            store.shareMyDetails()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderless)
                    .listRowBackground(Color.clear)
                }
                Section {
                    TextField("Your name", text: $yourName)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .onSubmit { store.shareMyDetails() }
                } footer: {
                    Text(store.role == .viewer
                         ? "As a viewer, your name and photo stay on this iPhone."
                         : "Your name and photo are shown to your family, beside what you log.")
                }
                .listRowBackground(Palette.input)

                // One way in to everything else. A shortlist here repeated half of Settings and left the
                // other half a second tap away (Tom, 15 November 2026).
                Section {
                    NavigationLink("Settings") { SettingsView() }
                    NavigationLink("Help and about") { HelpView() }
                }
                .listRowBackground(Palette.paper)

                Section {
                    EmptyView()
                } footer: {
                    VStack(spacing: 6) {
                        Text("Everything stays on this phone, and in your own iCloud once sharing is on. There is no account to make.")
                        Text(version).monospacedDigit()
                        Text("This app is not a substitute for medical advice.")
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onDisappear { store.shareMyDetails() }
        }
        .foregroundStyle(Palette.ink)
    }
}
