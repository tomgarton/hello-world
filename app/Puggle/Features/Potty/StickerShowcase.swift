import SwiftUI

/// A sticker held up to look at: drawn large, with a little thickness, a
/// highlight that moves as it turns, and a plain back with what it was for.
/// Drag to turn it any way; let go and it settles face up or face down.
struct StickerTurntable: View, Animatable {
    var yaw: Double
    var pitch: Double
    let sticker: EarnedSticker
    var size: CGFloat = 240

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(yaw, pitch) }
        set { yaw = newValue.first; pitch = newValue.second }
    }

    private var showsFront: Bool { cos(yaw) * cos(pitch) >= 0 }
    private var silhouette: some View { Image(sticker.style.shape).resizable().scaledToFit() }

    var body: some View {
        ZStack {
            // The edge: copies of the outline behind, each a shade darker, shifted the way it is turned.
            ForEach((1...7).reversed(), id: \.self) { layer in
                turned(silhouette.foregroundStyle(Color(hex: 0xBDB6A8).opacity(0.55 + Double(layer) * 0.05)))
                    .offset(x: CGFloat(-sin(yaw)) * CGFloat(layer) * 1.1,
                            y: CGFloat(sin(pitch)) * CGFloat(layer) * 1.1)
            }
            turned(face)
        }
        .frame(width: size, height: size)
        // One shadow for the whole sticker, not one per layer.
        .compositingGroup()
        .shadow(color: .black.opacity(0.16), radius: 12, y: 10)
    }

    private func turned<V: View>(_ view: V) -> some View {
        view
            .frame(width: size, height: size)
            .rotation3DEffect(.radians(pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.35)
            .rotation3DEffect(.radians(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
    }

    @ViewBuilder private var face: some View {
        if showsFront {
            ZStack {
                StickerView(style: sticker.style, size: size)
                    .shadow(radius: 0)
                // The highlight sweeps across as it turns, like light on foil.
                // At rest it sits just off the edge, and sweeps in as the sticker turns.
                LinearGradient(colors: [.white.opacity(0), .white.opacity(0.45), .white.opacity(0)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: size * 0.4, height: size * 1.6)
                    .rotationEffect(.degrees(25))
                    .offset(x: CGFloat(0.95 - sin(yaw) * 1.7 + sin(pitch) * 0.6) * size * 0.75)
                    .blendMode(.plusLighter)
                    .mask(silhouette.scaleEffect(0.86))
            }
        } else {
            // The back: plain card, with what the sticker was for.
            ZStack {
                silhouette.foregroundStyle(Color(hex: 0xF4EFE4))
                silhouette.foregroundStyle(Color(hex: 0xE7E0D2)).scaleEffect(0.86)
                VStack(spacing: 6) {
                    Text(sticker.title)
                        .font(.system(size: size * 0.075, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    if !sticker.detail.isEmpty {
                        Text(sticker.detail)
                            .font(.system(size: size * 0.052, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .opacity(0.75)
                    }
                    Text("puggle")
                        .font(.system(size: size * 0.05, weight: .heavy, design: .rounded))
                        .opacity(0.4)
                        .padding(.top, 4)
                }
                .foregroundStyle(Palette.fixedInk)
                .frame(width: size * 0.58)
            }
            // Mirrored, so it reads the right way round once turned over.
            .scaleEffect(x: -1)
        }
    }
}

/// One earned sticker, large, to turn over in your fingers.
struct StickerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let sticker: EarnedSticker

    @State private var yaw: Double = 0
    @State private var pitch: Double = 0
    @State private var start: (yaw: Double, pitch: Double)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                StickerTurntable(yaw: yaw, pitch: pitch, sticker: sticker)
                    .contentShape(Rectangle())
                    .gesture(turn)
                    .accessibilityElement()
                    .accessibilityLabel("\(sticker.title) sticker")
                    .accessibilityHint("Drag to turn it over")
                    .accessibilityAction(named: "Turn over") { spin(to: yaw + .pi) }
                VStack(spacing: 6) {
                    Text(sticker.title)
                        .displayFont(26)
                        .multilineTextAlignment(.center)
                    if !sticker.detail.isEmpty {
                        Text(sticker.detail)
                            .foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
                Text("Turn it with your finger")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .onAppear {
            // It spins in once, as it is handed over.
            guard !reduceMotion else { return }
            yaw = -2 * .pi
            withAnimation(.interpolatingSpring(stiffness: 30, damping: 8).delay(0.1)) { yaw = 0 }
        }
    }

    private var turn: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if start == nil { start = (yaw, pitch) }
                guard let start else { return }
                yaw = start.yaw + value.translation.width * 0.012
                pitch = max(-0.55, min(0.55, start.pitch - value.translation.height * 0.006))
            }
            .onEnded { value in
                start = nil
                // A flick keeps it spinning; it settles face up or face down.
                let flick = (value.predictedEndTranslation.width - value.translation.width) * 0.012
                spin(to: ((yaw + flick) / .pi).rounded() * .pi)
            }
    }

    private func spin(to target: Double) {
        Haptics.tap()
        withAnimation(.interpolatingSpring(stiffness: 40, damping: 7)) {
            yaw = target
            pitch = 0
        }
    }
}
