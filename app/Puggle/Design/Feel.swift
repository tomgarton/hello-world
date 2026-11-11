import SwiftUI
import UIKit

/// The app's touch feedback, in one place so it stays consistent and sparing.
/// iOS plays nothing if the person has switched system haptics off.
@MainActor
enum Haptics {
    /// Something was saved or finished: a log, a feed, a sticker.
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }

    /// The app is asking before going on: "Too soon?".
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    /// A choice changed: a child, a chip, a colour.
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }

    /// A light tap for a button that opens or undoes something.
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }

    /// One notch of a stepper.
    static func step() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6) }
}

/// A button that gives a little under the finger. With Reduce Motion on it dims instead of moving.
struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}
