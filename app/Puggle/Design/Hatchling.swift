import SwiftUI

/// Puggle as a baby, in her egg: the logo mark, drawn and moved by the same rig as Puggle
/// (Resources/Rigs/hatchling.rig.json, written by tools/make_hatchling_rig.py).
/// At rest she is the mark. `hatch()` plays her out of the egg once.
@MainActor
final class HatchlingController: ObservableObject {
    let rig: RigRuntime? = Rig.load("hatchling").map(RigRuntime.init)

    /// The egg rocks, cracks and opens. With Reduce Motion on she is simply there.
    func hatch() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        rig?.play("hatch")
    }
}

struct HatchlingView: View {
    @ObservedObject var controller: HatchlingController
    /// Still, for a picture of the mark.
    var frozen = false

    var body: some View {
        if let runtime = controller.rig {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: frozen)) { context in
                RigFrame(rig: runtime.rig, states: runtime.advance(to: context.date), face: runtime.face)
            }
            .aspectRatio(runtime.rig.size[0] / runtime.rig.size[1], contentMode: .fit)
            .accessibilityElement()
            .accessibilityLabel("A baby platypus looking out of a broken eggshell")
        }
    }
}
