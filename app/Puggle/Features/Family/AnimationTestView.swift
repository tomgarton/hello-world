#if DEBUG
import SwiftUI

/// Test builds only: how she moves now beside how the research proposes she should, played in a loop.
/// Developer menu, or launch with "-debugAnimTest 1". Nothing here changes the app itself.
struct AnimationTestView: View {
    @MainActor
    final class Side {
        let puggle: RigRuntime?
        let kip: RigRuntime?
        let pebble: RigRuntime?
        let quill: RigRuntime?
        init(refined: Bool) {
            puggle = Rig.load("puggle").map(RigRuntime.init)
            kip = Rig.load("kip").map(RigRuntime.init)
            pebble = Rig.load("pebble").map(RigRuntime.init)
            quill = Rig.load("quill").map(RigRuntime.init)
            each { $0.refined = refined }
        }
        var all: [RigRuntime] { [puggle, pebble, kip, quill].compactMap { $0 } }
        func each(_ body: (RigRuntime) -> Void) { all.forEach(body) }
    }

    @State private var now = Side(refined: false)
    @State private var proposed = Side(refined: true)
    @State private var title = "Blink"
    @State private var note = ""
    @State private var together = false
    @State private var close = false
    @State private var cast = false

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(title).displayFont(30)
                Text(note).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    .frame(height: 44, alignment: .top)
            }
            .padding(.top, 24)
            if cast {
                castPanel.padding(.horizontal, 12)
            } else {
                HStack(spacing: 10) {
                    panel("Now", now)
                    panel("Proposed", proposed)
                }
                .padding(.horizontal, 12)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .environment(\.lineStyle, .chosen)
        .environment(\.colorScheme, .light)
        .environment(\.puggleNight, false)
        .task { await run() }
    }

    private func panel(_ label: String, _ side: Side) -> some View {
        let tall: CGFloat = together ? 112 : close ? 226 : 180
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

    /// Four of the cast in a row, for what ears, spines and hair do. Today none of these parts move at all.
    private var castPanel: some View {
        VStack(spacing: 8) {
            Text("Proposed").font(.headline)
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(proposed.all.enumerated()), id: \.offset) { _, runtime in
                        let height = 112.0 / 300 * runtime.rig.size[1]
                        RigView(runtime: runtime).frame(width: height * runtime.rig.size[0] / runtime.rig.size[1], height: height)
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

    private static func pose(r: Double = 0, y: Double = 0, sx: Double = 1, sy: Double = 1) -> PartState {
        var s = PartState()
        s.r = r; s.y = y; s.sx = sx; s.sy = sy
        return s
    }

    /// What ears, spines and hair do for a feeling. `ears` turns them up (positive) or down, `lift` raises
    /// them, `spines` is their size, `tall` and `lean` are how the lick and curl stand. `one` is one ear
    /// and the spines on that side only, for noticing something.
    struct Feeling {
        let name: String, ears: Double, lift: Double, spines: Double, tall: Double, lean: Double, one: Bool

        var held: [String: PartState] {
            var held: [String: PartState] = [:]
            held["ear-left"] = AnimationTestView.pose(r: ears, y: -lift)
            held["ear-right"] = one ? .rest : AnimationTestView.pose(r: -ears, y: -lift)
            for index in 1...8 {
                let size = one && index > 4 ? 1 : spines
                held["spine-\(index)"] = AnimationTestView.pose(sx: size, sy: size)
            }
            held["lick"] = AnimationTestView.pose(r: lean, sy: tall)
            held["curl"] = AnimationTestView.pose(r: lean, sy: tall)
            return held
        }
    }

    static let feelings = [
        Feeling(name: "Happy", ears: 12, lift: 2, spines: 1.14, tall: 1.18, lean: 0, one: false),
        Feeling(name: "Surprised", ears: 22, lift: 5, spines: 1.38, tall: 1.4, lean: -14, one: false),
        Feeling(name: "Shy", ears: -30, lift: 0, spines: 0.66, tall: 0.68, lean: 16, one: false),
        Feeling(name: "Sleepy", ears: -18, lift: 0, spines: 0.84, tall: 0.82, lean: 26, one: false),
        Feeling(name: "Curious", ears: 20, lift: 3, spines: 1.24, tall: 1.1, lean: -18, one: true),
    ]

    private func wait(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }

    private func show(_ title: String, _ note: String, together: Bool = false) {
        self.title = title
        self.note = note
        self.together = together
    }

    private func run() async {
        // Hold the random blinks and tilts off, so only what is being shown happens.
        while !Task.isCancelled {
            close = true
            show("Quick eyes", "Now her eyes jump to the new place.\nProposed: one stretched frame, then round again.")
            await wait(1.4)
            for _ in 0..<2 {
                for look in [CGPoint(x: 1, y: 0), CGPoint(x: -1, y: 0), CGPoint(x: 1, y: -1), CGPoint.zero] {
                    now.puggle?.look = look
                    proposed.puggle?.look = look
                    await wait(0.8)
                }
            }
            close = false
            cast = true
            show("Ears, spines and hair", "Today none of these move.\nProposed: each takes a position for the feeling.")
            await wait(1.6)
            for feeling in Self.feelings {
                show(feeling.name, "Ears, spines and hair")
                proposed.each { $0.held = feeling.held }
                await wait(1.7)
                proposed.each { $0.held = [:] }
                await wait(0.9)
            }
            cast = false
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
