import SwiftUI

/// A switch with clear contrast in every look. Off: a dark track with an outline
/// and a light knob. On: an ink track with a paper knob and a tick.
/// VoiceOver still sees an ordinary switch.
struct PuggleToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? Palette.ink : Palette.toggleOff)
                        .overlay(Capsule().strokeBorder(Palette.muted, lineWidth: configuration.isOn ? 0 : 1.5))
                    Circle()
                        .fill(configuration.isOn ? Palette.paper : Palette.muted)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if configuration.isOn {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                        .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                        .padding(4)
                }
                .frame(width: 54, height: 32)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

extension Palette {
    /// The track of a switch that is off: darker than the row it sits on.
    static let toggleOff = Color(light: 0xD9CFBC, dark: 0x16120F, night: 0x0C0A08)
}
