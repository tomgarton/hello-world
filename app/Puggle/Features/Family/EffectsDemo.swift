#if DEBUG
import SwiftUI

/// The icon effects playing by themselves, for recording: "-debugFx 1". A tile that bounces as if an entry
/// had just been saved, a tile whose colour breathes as if a feed were running, and the sleep button turning
/// from moon to sun and back.
struct EffectsDemoView: View {
    @State private var saves = 0
    @State private var asleep = false

    var body: some View {
        VStack(spacing: 26) {
            Text("Icons that move").font(.title2.weight(.bold))
            HStack(spacing: 14) {
                tile("icon-nappy", "Nappy", "Draw on: saved", bounce: saves)
                tile("icon-bottle", "Feeding", "Breathe: running", breathing: true)
            }
            HStack(spacing: 14) {
                tile("icon-sleep", "Sleep", "Draw on", bounce: saves)
                tile("icon-solids", "Solids", "Draw on", bounce: saves)
            }
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: asleep ? "sun.max" : "moon")
                        .contentTransition(.symbolEffect(.replace.downUp))
                    Text(asleep ? "Woke up" : "Start sleep")
                }
                .animation(.default, value: asleep)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 46)
                .foregroundStyle(asleep ? Palette.fixedInk : Palette.ink)
                .background(asleep ? Palette.moon : Palette.paper, in: Capsule())
                Text("Replace: the state changed").font(.footnote).foregroundStyle(Palette.muted)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.0))
                saves += 1
                try? await Task.sleep(for: .seconds(1.6))
                asleep.toggle()
            }
        }
    }

    private func tile(_ icon: String, _ title: String, _ note: String, bounce: Int = 0, breathing: Bool = false) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                ActivityIcon(named: icon, size: 44, bounce: bounce, breathing: breathing)
                Text(title).font(.headline)
            }
            .frame(width: 130, height: 110)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text(note).font(.footnote).foregroundStyle(Palette.muted)
        }
    }
}
#endif
