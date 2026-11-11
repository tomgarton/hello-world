import SwiftUI
import UIKit

/// The app's touch feedback, in one place so it stays consistent and sparing.
/// iOS plays nothing if the person has switched system haptics off.
@MainActor
enum Haptics {
    /// The switch in Settings. On unless the person turns it off.
    static var isOn: Bool { UserDefaults.standard.object(forKey: Setting.haptics) as? Bool ?? true }

    /// Something was saved or finished: a log, a feed, a sticker.
    static func success() { guard isOn else { return }; UINotificationFeedbackGenerator().notificationOccurred(.success) }

    /// The app is asking before going on: "Too soon?".
    static func warning() { guard isOn else { return }; UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    /// A choice changed: a child, a chip, a colour.
    static func selection() { guard isOn else { return }; UISelectionFeedbackGenerator().selectionChanged() }

    /// A light tap for a button that opens or undoes something.
    static func tap() { guard isOn else { return }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }

    /// One notch of a stepper.
    static func step() { guard isOn else { return }; UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6) }
}

/// A button that gives a little under the finger. With Reduce Motion on it dims instead of moving.
struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.2, bounce: 0), value: configuration.isPressed)
    }
}

extension View {
    /// Liquid Glass for a control that is pressed often: on iOS 26 it lifts and
    /// warps under the finger. Earlier versions keep the flat fill.
    /// Only for controls; content such as cards and rows stays solid.
    @ViewBuilder
    func glassControl<S: Shape>(_ shape: S, fallback: Color, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            self.background(tint ?? fallback, in: shape)
        }
    }
}
