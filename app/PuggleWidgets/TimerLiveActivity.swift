import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The Lock Screen and Dynamic Island view of a running sleep or feed.
/// One activity per timer, so twins get a line each.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            LockScreenTimer(context: context)
                .activityBackgroundTint(Tone.night)
                .activitySystemActionForegroundColor(Tone.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.childName, systemImage: symbol(context))
                        .font(.headline)
                        .foregroundStyle(Tone.cream)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Clock(state: context.state)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Tone.moon)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.label)
                            .font(.subheadline)
                            .foregroundStyle(Tone.cream.opacity(0.8))
                        Spacer()
                        StopButton(attributes: context.attributes)
                    }
                }
            } compactLeading: {
                Image(systemName: symbol(context)).foregroundStyle(Tone.moon)
            } compactTrailing: {
                Clock(state: context.state)
                    .foregroundStyle(Tone.moon)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: symbol(context)).foregroundStyle(Tone.moon)
            }
            .keylineTint(Tone.moon)
        }
    }

    private func symbol(_ context: ActivityViewContext<TimerAttributes>) -> String {
        context.attributes.kind == "sleep" ? "moon.fill" : "heart.fill"
    }
}

/// Fixed colours: the Lock Screen view is always the night look.
private enum Tone {
    static let night = Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x40 / 255)
    static let moon = Color(red: 0xF3 / 255, green: 0xE0 / 255, blue: 0xB8 / 255)
    static let cream = Color(red: 0xFB / 255, green: 0xF6 / 255, blue: 0xE9 / 255)
    static let ink = Color(red: 0x3A / 255, green: 0x2A / 255, blue: 0x20 / 255)
}

private struct LockScreenTimer: View {
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: context.attributes.kind == "sleep" ? "moon.fill" : "heart.fill")
                .font(.title2)
                .foregroundStyle(Tone.moon)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.childName)
                    .font(.headline)
                    .foregroundStyle(Tone.cream)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(context.state.label)
                    Clock(state: context.state, alignment: .leading)
                }
                .font(.subheadline)
                .foregroundStyle(Tone.moon)
            }
            Spacer(minLength: 0)
            StopButton(attributes: context.attributes)
        }
        .padding(16)
    }
}

/// Counts up by itself; the app does not need to be running.
private struct Clock: View {
    let state: TimerAttributes.ContentState
    var alignment: TextAlignment = .trailing

    var body: some View {
        if let since = state.since {
            // A timer text takes all the width it can; the alignment decides which end the digits sit at.
            Text(since, style: .timer)
                .monospacedDigit()
                .multilineTextAlignment(alignment)
        } else {
            Text(state.pausedText ?? "")
                .monospacedDigit()
        }
    }
}

private struct StopButton: View {
    let attributes: TimerAttributes

    var body: some View {
        let sleep = attributes.kind == "sleep"
        Button(intent: TimerActionIntent(kind: attributes.kind, childID: attributes.childID)) {
            Text(sleep ? "Woke up" : "Finish")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tone.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(Tone.moon, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sleep ? "\(attributes.childName) woke up" : "Finish \(attributes.childName)'s feed")
    }
}
