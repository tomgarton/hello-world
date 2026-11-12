#if DEBUG
import SwiftUI

/// Test builds only: Puggle on her own, with a button for each of her moves.
struct MovesGalleryView: View {
    @StateObject private var puggle = PuggleController()
    @State private var asleep = false
    @State private var night = false
    @State private var quiet = false

    var body: some View {
        VStack(spacing: 16) {
            PuggleView(controller: puggle)
                .environment(\.moonlit, night)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(night ? Color(hex: 0x25275C) : Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                // Drag on her and her eyes follow.
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        puggle.look(x: Double((value.location.x - 180) / 140).clamped(), y: Double((value.location.y - 130) / 120).clamped())
                    }
                    .onEnded { _ in puggle.look(x: 0, y: 0) })
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(Array((puggle.rig?.rig.moves ?? [:]).keys).sorted(), id: \.self) { name in
                    Button(name.capitalized) { puggle.rig?.play(name) }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Palette.field, in: Capsule())
                        .foregroundStyle(Palette.ink)
                }
            }
            Toggle("Asleep", isOn: $asleep)
                .onChange(of: asleep) { _, now in if now { puggle.asleep = true } else { puggle.wake() } }
            Toggle("By moonlight", isOn: $night)
            Toggle("Quiet (half energy, as at night)", isOn: $quiet)
                .onChange(of: quiet) { _, now in puggle.setEnergy(now ? 0.5 : 1) }
            Text("Drag a finger over her and her eyes follow.")
                .font(.footnote).foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Palette.sand)
        .navigationTitle("Puggle's moves")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Double {
    func clamped() -> Double { Swift.min(1, Swift.max(-1, self)) }
}
#endif
