#if DEBUG
import SwiftUI

/// Test builds only: how she moves now beside how the research proposes she should, played in a loop.
/// Developer menu, or launch with "-debugAnimTest 1". Nothing here changes the app itself.
struct AnimationTestView: View {
    @MainActor
    final class Side {
        let puggle: RigRuntime?
        let kip: RigRuntime?
        init(refined: Bool) {
            puggle = Rig.load("puggle").map(RigRuntime.init)
            kip = Rig.load("kip").map(RigRuntime.init)
            puggle?.refined = refined
            kip?.refined = refined
        }
        func each(_ body: (RigRuntime) -> Void) { [puggle, kip].compactMap { $0 }.forEach(body) }
    }

    @State private var now = Side(refined: false)
    @State private var proposed = Side(refined: true)
    @State private var title = "Blink"
    @State private var note = ""
    @State private var together = false

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(title).displayFont(30)
                Text(note).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    .frame(height: 44, alignment: .top)
            }
            .padding(.top, 24)
            HStack(spacing: 10) {
                panel("Now", now)
                panel("Proposed", proposed)
            }
            .padding(.horizontal, 12)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .environment(\.lineStyle, .chosen)
        .task { await run() }
    }

    private func panel(_ label: String, _ side: Side) -> some View {
        let tall: CGFloat = together ? 112 : 180
        return VStack(spacing: 8) {
            Text(label).font(.headline)
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 0) {
                    if let puggle = side.puggle {
                        RigView(runtime: puggle).frame(width: tall * 0.8, height: tall)
                    }
                    if together, let kip = side.kip {
                        let height = tall / 300 * kip.rig.size[1] * 1.06
                        RigView(runtime: kip).frame(width: height * kip.rig.size[0] / kip.rig.size[1], height: height)
                    }
                }
                Capsule().fill(Palette.ink.opacity(0.18)).frame(height: 2).offset(y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300, alignment: .bottom)
            .padding(.bottom, 18)
        }
        .padding(.top, 14)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func wait(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }

    private func show(_ title: String, _ note: String, together: Bool = false) {
        self.title = title
        self.note = note
        self.together = together
    }

    private func run() async {
        // Hold the random blinks and tilts off, so only what is being shown happens.
        while !Task.isCancelled {
            show("Blink", "Now it snaps shut and open.\nProposed: shut quickly, open slowly.")
            await wait(1.2)
            for _ in 0..<3 {
                let at = Date.now
                now.puggle?.blinkAt = at
                proposed.puggle?.blinkAt = at
                await wait(1.3)
            }
            show("Head tilt", "Now everything tips at once.\nProposed: eyes, a blink, head, then her clip.")
            await wait(1.0)
            for side in [1.0, -1.0] {
                let at = Date.now
                now.puggle?.tiltAt = (at, side)
                proposed.puggle?.tiltAt = (at, side)
                await wait(3.0)
            }
            show("Hop", "Proposed: wider as she squashes, head keeps its shape,\nand she stops at the ground.")
            await wait(1.0)
            for _ in 0..<2 {
                now.puggle?.play("celebrate")
                proposed.puggle?.play("celebrate-refined")
                await wait(3.2)
            }
            show("Two together", "Now both wave at once, at you.\nProposed: a look, a wave, a look back, an answer.", together: true)
            await wait(1.2)
            for _ in 0..<2 {
                now.puggle?.play("greet")
                now.kip?.play("greet")
                proposed.puggle?.look = CGPoint(x: 1, y: 0)
                await wait(0.55)
                proposed.puggle?.play("greet")
                await wait(1.9)
                proposed.kip?.look = CGPoint(x: -1, y: 0)
                proposed.kip?.blinkAt = .now
                await wait(0.6)
                proposed.kip?.play("greet-left")
                await wait(1.9)
                proposed.puggle?.play("nod")
                await wait(1.6)
                proposed.puggle?.look = .zero
                proposed.kip?.look = .zero
                await wait(1.2)
            }
        }
    }
}
#endif
