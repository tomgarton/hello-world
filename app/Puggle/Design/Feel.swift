import CoreHaptics
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

    private static var engine: CHHapticEngine?

    /// The milestone: three rising ticks while she winds up, then one full beat as she lets go.
    /// The only composed pattern in the app. Falls back to the plain success tap.
    static func celebrate() {
        guard isOn else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return success() }
        func tick(_ time: TimeInterval, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
            CHHapticEvent(eventType: .hapticTransient,
                          parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                       CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)],
                          relativeTime: time)
        }
        let glow = CHHapticEvent(eventType: .hapticContinuous,
                                 parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
                                              CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)],
                                 relativeTime: 0.30, duration: 0.22)
        let events = [tick(0, 0.3, 0.4), tick(0.10, 0.45, 0.5), tick(0.20, 0.6, 0.6), tick(0.29, 1.0, 0.7), glow]
        do {
            if engine == nil { engine = try CHHapticEngine() }
            try engine?.start()
            let player = try engine?.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            success()
        }
    }

    /// A stamp landing on paper: one heavy hit.
    static func thud() { guard isOn else { return }; UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1) }

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
    func glassControl<S: Shape>(_ shape: S, fallback: Color, tint: Color? = nil, quiet: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            // "Quiet" is the clear glass: it takes the colour of what is under it, so a
            // row of them does not outshine the content. It still lifts when pressed.
            self.glassEffect((quiet ? Glass.clear : Glass.regular).tint(tint).interactive(), in: shape)
        } else {
            self.background(tint ?? fallback, in: shape)
        }
    }
}
