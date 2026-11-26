import SwiftUI

/// How someone arrives in the scene when Today opens (Tom, 19 November 2026).
enum ArrivalStyle: Equatable {
    /// Up from behind the hill: a crouch, a stretch on the way up, a squash as they land.
    case rise
    /// In along the ground from the edge nearest where they stand, walking.
    case walk
    /// Already there and settled (in bed, at the table): they fade in.
    case fade
    /// Back within a few minutes: already there, no entrance at all.
    case none
}

/// The numbers an arrival moves.
struct ArrivalPose {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var stretch: CGFloat = 1
    var opacity: Double = 1
    /// 1 while an entrance is playing. On the first frame after a new entrance is asked for, SwiftUI draws the
    /// keyframes' end values (everyone in place), and this is 0 then: with Today still marked away, nobody is
    /// drawn, rather than flashing up in place before arriving.
    var live: Double = 0
}

/// Plays an arrival each time `trigger` changes. `edge` is how far sideways the nearest edge of the scene is,
/// signed, for walking in; `delay` staggers one character after another.
struct Arrival: ViewModifier {
    let trigger: Int
    let style: ArrivalStyle
    var edge: CGFloat = 0
    var delay: Double = 0
    /// Told when a walk-in starts and ends, so the legs move.
    var walking: (Bool) -> Void = { _ in }
    /// Today is out of sight: hidden until the next entrance, so the app switcher's picture is the empty scene.
    var away = false

    /// How long a walk-in takes.
    static let walkTime = 0.9
    /// How long after an entrance starts Today stops marking itself away. Every entrance has begun by then, and
    /// each stays marked live until well after.
    static let unhideAfter = 1.0
    static let liveFor = 4.0

    func body(content: Content) -> some View {
        // Out of sight until the first entrance, so nobody is seen standing in place before they arrive.
        content
            .keyframeAnimator(initialValue: ArrivalPose(opacity: trigger == 0 && style != .none ? 0 : 1),
                              trigger: trigger) { view, pose in
                // Squash and stretch keep their volume: taller is narrower.
                view.scaleEffect(x: 1 / pose.stretch, y: pose.stretch, anchor: .bottom)
                    .offset(x: pose.x, y: pose.y)
                    .opacity(pose.opacity)
                    .opacity(away && pose.live < 1 ? 0 : 1)
            } keyframes: { _ in
                // Every style moves the same four numbers, so the tracks are the same and only their values differ.
                let rise = style == .rise, walk = style == .walk
                // A keyframe that takes no time at all divides by nothing: never quite zero.
                let delay = max(delay, 0.001)
                // The squash and stretch: a crouch, a stretch on the way up, a squash on landing (rising); a little
                // settle as they stop (walking).
                let squash: [(CGFloat, Double)] = rise ? [(0.88, 0.08), (1.1, 0.18), (1, 0.12), (0.86, 0.1)]
                    : walk ? [(1, 0.001), (1, 0.001), (1, 0.001), (0.94, 0.1)]
                    : [(1, 0.001), (1, 0.001), (1, 0.001), (1, 0.001)]
                // On from the first moment, and on for longer than any entrance takes. See `Arrival.liveFor`.
                KeyframeTrack(\.live) {
                    LinearKeyframe(1, duration: 0.001)
                    LinearKeyframe(1, duration: Self.liveFor)
                    LinearKeyframe(0, duration: 0.001)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(style == .rise || style == .fade ? 0 : 1, duration: 0.001)
                    LinearKeyframe(style == .rise || style == .fade ? 0 : 1, duration: delay)
                    CubicKeyframe(1, duration: style == .fade ? 0.5 : 0.12)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(rise ? 64 : 0, duration: 0.001)
                    LinearKeyframe(rise ? 64 : 0, duration: delay + 0.08)
                    // Up past where they stand, then down onto it.
                    CubicKeyframe(rise ? -12 : 0, duration: 0.3)
                    CubicKeyframe(0, duration: 0.16)
                }
                KeyframeTrack(\.x) {
                    LinearKeyframe(walk ? edge : 0, duration: 0.001)
                    LinearKeyframe(walk ? edge : 0, duration: delay)
                    CubicKeyframe(0, duration: Self.walkTime)
                }
                KeyframeTrack(\.stretch) {
                    LinearKeyframe(1, duration: 0.001)
                    LinearKeyframe(1, duration: delay + (walk ? Self.walkTime : 0))
                    CubicKeyframe(squash[0].0, duration: squash[0].1)
                    CubicKeyframe(squash[1].0, duration: squash[1].1)
                    CubicKeyframe(squash[2].0, duration: squash[2].1)
                    CubicKeyframe(squash[3].0, duration: squash[3].1)
                    SpringKeyframe(1, duration: 0.4, spring: .init(duration: 0.4, bounce: 0.45))
                }
            }
            .task(id: trigger) {
                guard style == .walk, trigger > 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                walking(true)
                try? await Task.sleep(for: .seconds(Self.walkTime))
                walking(false)
            }
    }
}

extension View {
    func arrival(_ trigger: Int, _ style: ArrivalStyle, edge: CGFloat = 0, delay: Double = 0, away: Bool = false,
                 walking: @escaping (Bool) -> Void = { _ in }) -> some View {
        modifier(Arrival(trigger: trigger, style: style, edge: edge, delay: delay, walking: walking, away: away))
    }
}
