import SwiftUI

/// A note made while testing: what was noticed, when, and on which build.
struct FeedbackNote: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var at = Date.now
    var build: String

    /// "0.1.0 (9)", from the app itself.
    static var currentBuild: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }
}

/// Notes kept on this phone only. They are never sent anywhere by the app: the person copies them out.
enum FeedbackNotes {
    private static let key = "feedbackNotes"

    static func load() -> [FeedbackNote] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([FeedbackNote].self, from: data)) ?? []
    }

    static func save(_ notes: [FeedbackNote]) {
        UserDefaults.standard.set(try? JSONEncoder().encode(notes), forKey: key)
    }

    /// Every note as plain text, newest first, for pasting into a message.
    static func text(_ notes: [FeedbackNote]) -> String {
        notes.map { "\($0.at.formatted(date: .abbreviated, time: .shortened)) · Build \($0.build)\n\($0.text)" }.joined(separator: "\n\n")
    }
}

/// Test builds only (Tom, 15 November 2026): somewhere to write down what was noticed at the moment it is
/// noticed, with the build it was noticed on, to copy out later. Nothing here leaves the phone by itself.
struct FeedbackView: View {
    @State private var notes = FeedbackNotes.load()
    @State private var draft = ""
    @State private var copied = false
    @FocusState private var writing: Bool

    var body: some View {
        List {
            Section {
                TextField("What did you notice?", text: $draft, axis: .vertical)
                    .lineLimit(3...8)
                    .focused($writing)
                Button("Save note") { add() }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("Saved on this iPhone with the date and build \(FeedbackNote.currentBuild). Nothing is sent.")
            }
            .listRowBackground(Palette.paper)

            if !notes.isEmpty {
                Section {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(note.text).foregroundStyle(Palette.ink)
                            Text("\(note.at.formatted(date: .abbreviated, time: .shortened)) · Build \(note.build)")
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        notes.remove(atOffsets: offsets)
                        FeedbackNotes.save(notes)
                    }
                } header: {
                    Text(notes.count == 1 ? "1 note" : "\(notes.count) notes")
                } footer: {
                    Text("Swipe a note to delete it.")
                }
                .listRowBackground(Palette.paper)

                Section {
                    Button(copied ? "Copied" : "Copy all notes") {
                        UIPasteboard.general.string = FeedbackNotes.text(notes)
                        copied = true
                    }
                }
                .listRowBackground(Palette.paper)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Feedback notes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func add() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        notes.insert(FeedbackNote(text: text, build: FeedbackNote.currentBuild), at: 0)
        FeedbackNotes.save(notes)
        draft = ""
        copied = false
        Haptics.success()
    }
}
