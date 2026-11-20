import SwiftUI

/// Things to hand a child: one place for them, one tap from Today.
/// Each opens full screen behind the cover that holds back stray swipes.
/// Nothing here is logged or counted.
struct PlayShelfView: View {
    @Environment(\.dismiss) private var dismiss
    /// Children with a stamp book, if any. The book is left out when there are none.
    let stampChildren: [Child]

    @State private var drawing = false
    @State private var showingStamps = false

    private var bookSubtitle: String {
        let names = stampChildren.map(\.displayName)
        return names.isEmpty ? "Cards and stickers" : "\(ListFormatter.localizedString(byJoining: names))'s cards and stickers"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Hand over the phone. To come back, hold the close button for a moment.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        card("Draw", "Crayons, pens and colouring", symbol: "scribble.variable") { drawing = true }
                        if !stampChildren.isEmpty {
                            card("Stamp book", bookSubtitle, symbol: "star.circle") { showingStamps = true }
                        }
                    }
                    Text("Nothing here is counted or kept in the day.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .protectedCover(isPresented: $drawing) { PlayPadView() }
            .sheet(isPresented: $showingStamps) { StampBookView(children: stampChildren) }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func card(_ title: String, _ subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(Palette.field, in: Circle())
                    .accessibilityHidden(true)
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .foregroundStyle(Palette.ink)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressStyle(scale: 0.97))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens full screen")
    }
}
