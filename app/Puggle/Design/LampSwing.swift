import SwiftUI

/// The lamp over the tea table swings when it is tapped or dragged (Tom, 19 November 2026).
///
/// A pendulum hanging from the middle of the ceiling: drag the lamp and it follows the finger on its cord;
/// let go and it swings back and forth, slowing until it hangs still. A tap gives it a push away from the
/// finger. Gentle by design: it never swings far, it settles in a few seconds, and nothing flashes.
/// With Reduce Motion it only leans and comes back, with no swing.
///
/// The room is drawn many times a second, so the swing is worked out when it is drawn (`angle(at:length:)`),
/// from the time since the last frame. One lamp, so one shared swing.
final class LampSwing {
    static let shared = LampSwing()

    /// The furthest it swings either way, in radians (about 34°).
    static let reach = 0.6

    /// Radians from hanging straight down; positive is to the right.
    private(set) var angle = 0.0
    /// Radians a second.
    private var speed = 0.0
    /// Where the finger holds it, while it is held.
    private var held: Double?
    private var last: Date?
    /// Leans and comes back with no swing.
    var calm = false

    /// Its angle now, moved on from the last frame. `length` is the cord, in points, so a longer cord
    /// (Today pulled down) swings a little slower, as a real one would.
    func angle(at date: Date, length: CGFloat) -> Double {
        let dt = min(max(date.timeIntervalSince(last ?? date), 0), 1.0 / 20)
        last = date
        if let held {
            // Follows the finger closely, but not stiffly.
            angle += (held - angle) * min(1, dt * 24)
            speed = 0
            return angle
        }
        guard angle != 0 || speed != 0 else { return 0 }
        // Gravity over the cord's length, made a touch quicker than real so it reads at this size.
        let pull = 1500 / Double(max(length, 60))
        if calm {
            // Critically damped: back to straight down without passing it.
            let damping = 2 * pull.squareRoot()
            speed += (-pull * angle - damping * speed) * dt
        } else {
            speed += (-pull * sin(angle) - 0.9 * speed) * dt
        }
        angle = min(max(angle + speed * dt, -Self.reach), Self.reach)
        if abs(angle) < 0.002, abs(speed) < 0.01 { angle = 0; speed = 0 }
        return angle
    }

    /// Held by a finger at this angle.
    func hold(_ to: Double) {
        held = min(max(to, -Self.reach), Self.reach)
    }

    /// Let go, moving at this many radians a second.
    func release(speed: Double) {
        held = nil
        self.speed = calm ? 0 : min(max(speed, -4), 4)
    }

    /// A tap: a push this way, in radians a second.
    func push(_ by: Double) {
        held = nil
        if calm {
            angle = min(max(angle + by * 0.12, -Self.reach), Self.reach)
        } else {
            speed = min(max(speed + by, -4), 4)
        }
    }
}

/// Where the tea lamp can be touched on Today: a patch over the lamp as it hangs, which turns a drag into a
/// swing and a tap into a push. Anywhere else on the scene, a drag still pulls Today down.
struct LampHandle: View {
    /// How far Today is pulled down: the cord is that much longer.
    let pull: CGFloat
    let width: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: CGPoint?

    /// The top of the cord, in this patch's own space.
    private var anchor: CGPoint { CGPoint(x: width / 2, y: 0) }

    var body: some View {
        Color.clear
            .frame(width: width, height: pull + 110)
            .contentShape(Rectangle().path(in: CGRect(x: width / 2 - 60, y: pull + 30, width: 120, height: 80)))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        LampSwing.shared.calm = reduceMotion
                        if start == nil { start = value.startLocation }
                        // A drag of more than a few points: the lamp follows the finger on its cord.
                        if hypot(value.translation.width, value.translation.height) > 6 {
                            LampSwing.shared.hold(swing(at: value.location))
                        }
                    }
                    .onEnded { value in
                        defer { start = nil }
                        if hypot(value.translation.width, value.translation.height) <= 6 {
                            // A tap: a push away from the side it was tapped on.
                            LampSwing.shared.push(value.location.x < width / 2 ? 1.6 : -1.6)
                        } else {
                            // Let go: it carries on at the speed the finger was moving.
                            let now = swing(at: value.location), then = swing(at: value.predictedEndLocation)
                            LampSwing.shared.release(speed: (then - now) * 4)
                        }
                        Haptics.tap()
                    }
            )
            .accessibilityHidden(true)
    }

    /// The lamp's angle for a finger here: the cord pointing from the ceiling to the finger.
    private func swing(at point: CGPoint) -> Double {
        let dx = Double(point.x - anchor.x), dy = Double(max(point.y - anchor.y, 20))
        return atan2(dx, dy)
    }
}
