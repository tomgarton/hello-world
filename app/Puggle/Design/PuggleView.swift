import SwiftUI
#if canImport(RiveRuntime)
import RiveRuntime
#endif

/// The names agreed in `design/rive/README.md`. Change them there first.
enum PuggleRive {
    static let file = "puggle"
    static let artboard = "Puggle"
    static let stateMachine = "Mood"

    enum Input {
        static let greet = "greet"          // trigger
        static let celebrate = "celebrate"  // trigger
        static let nod = "nod"              // trigger
        static let proud = "proud"          // trigger
        static let wake = "wake"            // trigger
        static let asleep = "asleep"        // boolean
        static let walking = "walking"      // boolean
        static let energy = "energy"        // number, 0...1
        static let lookX = "lookX"          // number, -1...1
        static let lookY = "lookY"          // number, -1...1
    }
}

/// Drives Puggle's mood. Create one, hand it to `PuggleView`, then call
/// `greet()`, `nod()`, `proud()` or `celebrate()`, or set `asleep` and `walking`.
///
/// Without the Rive runtime or the `.riv` file, every call is a no-op and
/// the view shows the still image, so the app works either way.
@MainActor
final class PuggleController: ObservableObject {
    @Published var asleep = false { didSet { push() } }
    @Published var walking = false { didSet { push() } }

    #if canImport(RiveRuntime)
    let rive: RiveViewModel?

    init() {
        if Bundle.main.url(forResource: PuggleRive.file, withExtension: "riv") != nil {
            rive = RiveViewModel(fileName: PuggleRive.file,
                                 stateMachineName: PuggleRive.stateMachine,
                                 artboardName: PuggleRive.artboard)
        } else {
            rive = nil
        }
    }
    #else
    init() {}
    #endif

    /// True when the animated character can be shown.
    var isAnimated: Bool {
        #if canImport(RiveRuntime)
        return rive != nil
        #else
        return false
        #endif
    }

    /// Hello: on launch and on the splash screen.
    func greet() { fire(PuggleRive.Input.greet) }

    /// A milestone. The only big reaction; keep it rare.
    func celebrate() { fire(PuggleRive.Input.celebrate) }

    /// An everyday log was saved. Never wait for this before saving.
    func nod() { fire(PuggleRive.Input.nod) }

    /// A potty success.
    func proud() { fire(PuggleRive.Input.proud) }

    /// A sleep ended.
    func wake() { asleep = false; fire(PuggleRive.Input.wake) }

    /// 1 by day, 0.5 at night: scales how big and fast she moves.
    func setEnergy(_ value: Double) {
        #if canImport(RiveRuntime)
        rive?.setInput(PuggleRive.Input.energy, value: value)
        #endif
    }

    /// Where a finger is, from -1 to 1 on each axis; (0, 0) when lifted.
    func look(x: Double, y: Double) {
        #if canImport(RiveRuntime)
        rive?.setInput(PuggleRive.Input.lookX, value: x)
        rive?.setInput(PuggleRive.Input.lookY, value: y)
        #endif
    }

    private func fire(_ name: String) {
        #if canImport(RiveRuntime)
        rive?.triggerInput(name)
        #endif
    }

    private func push() {
        #if canImport(RiveRuntime)
        rive?.setInput(PuggleRive.Input.asleep, value: asleep)
        rive?.setInput(PuggleRive.Input.walking, value: walking)
        #endif
    }
}

/// Puggle, animated when possible and still otherwise.
struct PuggleView: View {
    @ObservedObject var controller: PuggleController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.puggleNight) private var night

    var body: some View {
        Group {
            if controller.isAnimated && !reduceMotion {
                animated
            } else {
                still
            }
        }
        .aspectRatio(240.0 / 300.0, contentMode: .fit)
        // Dimmed with the night look, so she is not the brightest thing on the screen.
        .brightness(night ? -0.18 : 0)
        .saturation(night ? 0.8 : 1)
        .accessibilityElement()
        .accessibilityLabel(controller.asleep ? "Puggle, asleep" : "Puggle")
    }

    @ViewBuilder private var animated: some View {
        #if canImport(RiveRuntime)
        if let rive = controller.rive {
            rive.view()
        } else {
            still
        }
        #else
        still
        #endif
    }

    /// `PuggleStill` in the asset catalogue. Until it exists, a soft placeholder.
    @ViewBuilder private var still: some View {
        if UIImage(named: "PuggleStill") != nil {
            Image("PuggleStill").resizable().scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Palette.field)
                .overlay(Image(systemName: "pawprint").font(.largeTitle).foregroundStyle(Palette.muted))
        }
    }
}
