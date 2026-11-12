import PhotosUI
import SwiftUI

/// Your own photo, kept small, on this phone only.
@MainActor
final class YourPhoto: ObservableObject {
    static let shared = YourPhoto()
    @Published private(set) var image: UIImage?

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
        let side = min(picked.size.width, picked.size.height)
        let crop = CGRect(x: (picked.size.width - side) / 2, y: (picked.size.height - side) / 2, width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        let small = renderer.image { _ in
            picked.draw(in: CGRect(x: -crop.minX * 300 / side, y: -crop.minY * 300 / side,
                                   width: picked.size.width * 300 / side, height: picked.size.height * 300 / side))
        }
        try? small.jpegData(compressionQuality: 0.8)?.write(to: url, options: .atomic)
        image = small
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

/// You: your photo and name, then everything about how the app works for you.
/// The full list of settings is one row away.
struct YouView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Setting.yourName) private var yourName = ""
    @State private var picked: PhotosPickerItem?
    @State private var choosingTiles = false
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
                        PhotosPicker(selection: $picked, matching: .images) {
                            Text(photo.image == nil ? "Add a photo" : "Change photo")
                                .font(.subheadline.weight(.semibold))
                        }
                        if photo.image != nil {
                            Button("Remove photo", role: .destructive) { photo.set(nil) }
                                .font(.footnote)
                                .foregroundStyle(Palette.waratah)
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
                } footer: {
                    Text("Shown beside what you log, so the family can see who added it. Your photo stays on this phone.")
                }
                .listRowBackground(Palette.paper)

                Section("Make it yours") {
                    NavigationLink("Appearance and night") { AppearanceSettingsView() }
                    NavigationLink("Reminders") { RemindersView() }
                    NavigationLink("Units") { UnitsSettingsView() }
                    Button("Tiles on Today") { choosingTiles = true }
                }
                .listRowBackground(Palette.paper)

                Section("Need help?") {
                    NavigationLink("Help and about") { HelpView() }
                    NavigationLink("Your data") { YourDataView() }
                }
                .listRowBackground(Palette.paper)

                Section {
                    NavigationLink("All settings") { SettingsView() }
                }
                .listRowBackground(Palette.paper)

                Section {
                    EmptyView()
                } footer: {
                    VStack(spacing: 6) {
                        Text("Everything you log is kept on this phone, and in your own iCloud once sharing is on. There is no account with us.")
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
            .sheet(isPresented: $choosingTiles) { TileChooserView(available: Tile.all) }
            .onChange(of: picked) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        photo.set(image)
                    }
                    picked = nil
                }
            }
        }
        .foregroundStyle(Palette.ink)
    }
}
