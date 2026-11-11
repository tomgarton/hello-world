import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The Lock Screen and Dynamic Island view of a child's card: a running
/// feed, a running sleep, or how long since the last feed and since they woke.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            LockScreenCard(context: context)
                .activityBackgroundTint(Tone.night)
                .activitySystemActionForegroundColor(Tone.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.childName, systemImage: symbol(context.state))
                        .font(.headline)
                        .foregroundStyle(Tone.cream)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // The number that matters, large, as on the system timer.
                    VStack(alignment: .trailing, spacing: 0) {
                        if context.state.mode == "glance" {
                            if let fed = context.state.fedSince {
                                Since(date: fed).font(.title2.weight(.semibold))
                                Text("since a feed").font(.caption2).foregroundStyle(Tone.cream.opacity(0.7))
                            }
                        } else {
                            Clock(state: context.state).font(.title.weight(.semibold))
                            Text(context.state.label).font(.caption2).foregroundStyle(Tone.cream.opacity(0.7))
                        }
                    }
                    .foregroundStyle(Tone.moon)
                    .frame(maxWidth: 150, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    switch context.state.mode {
                    case "glance":
                        HStack {
                            if let awake = context.state.awakeSince {
                                (Text("Awake ") + Since.text(awake))
                                    .font(.subheadline)
                                    .foregroundStyle(Tone.cream.opacity(0.8))
                            }
                            Spacer()
                            ActionButton("Start sleep", action: TimerActions.startSleep, attributes: context.attributes,
                                         spoken: "Start \(context.attributes.childName)'s sleep")
                        }
                    case "feed":
                        FeedButtons(attributes: context.attributes, state: context.state)
                    default:
                        HStack {
                            Spacer()
                            ActionButton("Woke up", action: TimerActions.wokeUp, attributes: context.attributes,
                                         spoken: "\(context.attributes.childName) woke up")
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: symbol(context.state)).foregroundStyle(Tone.moon)
            } compactTrailing: {
                Group {
                    if context.state.mode == "glance", let fed = context.state.fedSince {
                        Since(date: fed, short: true)
                    } else {
                        Clock(state: context.state)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Tone.moon)
                .frame(maxWidth: 64)
            } minimal: {
                Image(systemName: symbol(context.state)).foregroundStyle(Tone.moon)
            }
            .keylineTint(Tone.moon)
        }
    }

    private func symbol(_ state: TimerAttributes.ContentState) -> String {
        switch state.mode {
        case "sleep": "moon.fill"
        case "feed": "heart.fill"
        default: "clock"
        }
    }
}

/// Fixed colours: the Lock Screen view is always the night look.
private enum Tone {
    static let night = Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x40 / 255)
    static let moon = Color(red: 0xF3 / 255, green: 0xE0 / 255, blue: 0xB8 / 255)
    static let cream = Color(red: 0xFB / 255, green: 0xF6 / 255, blue: 0xE9 / 255)
    static let ink = Color(red: 0x3A / 255, green: 0x2A / 255, blue: 0x20 / 255)
}

private struct LockScreenCard: View {
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        let state = context.state
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: state.mode == "sleep" ? "moon.fill" : (state.mode == "feed" ? "heart.fill" : "clock"))
                    .font(.title2)
                    .foregroundStyle(Tone.moon)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.childName)
                        .font(.headline)
                        .foregroundStyle(Tone.cream)
                        .lineLimit(1)
                    if state.mode == "glance" {
                        GlanceLines(state: state)
                    } else {
                        HStack(spacing: 6) {
                            Text(state.label)
                            Clock(state: state, alignment: .leading)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Tone.moon)
                    }
                }
                Spacer(minLength: 0)
                if state.mode == "sleep" {
                    ActionButton("Woke up", action: TimerActions.wokeUp, attributes: context.attributes,
                                 spoken: "\(context.attributes.childName) woke up")
                } else if state.mode == "glance" {
                    ActionButton("Start sleep", action: TimerActions.startSleep, attributes: context.attributes,
                                 spoken: "Start \(context.attributes.childName)'s sleep")
                }
            }
            if state.mode == "feed" {
                FeedButtons(attributes: context.attributes, state: state)
            }
        }
        .padding(16)
    }
}

/// "Fed 2 hr, 10 min ago" and "Awake 1 hr, 40 min". Plain facts; nothing is due and nothing turns red.
private struct GlanceLines: View {
    let state: TimerAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // One line each: the text shrinks a little before it would wrap.
            if let fed = state.fedSince {
                (Text("Fed ") + Since.text(fed) + Text(" ago"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            if let awake = state.awakeSince {
                (Text("Awake ") + Since.text(awake))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .font(.subheadline)
        .foregroundStyle(Tone.moon)
        .monospacedDigit()
    }
}

/// "23 min" or "1 hr, 3 min", updating by itself, with no seconds ticking.
private struct Since: View {
    let date: Date
    var short = false

    var body: some View {
        Since.text(date, short: short).monospacedDigit()
    }

    static func text(_ date: Date, short: Bool = false) -> Text {
        if #available(iOS 18.0, *) {
            return Text(.currentDate, format: .offset(to: date, allowedFields: [.hour, .minute],
                                                      maxFieldCount: short ? 1 : 2, sign: .never))
        }
        return Text(date, style: .relative)
    }
}

/// Counts up by itself; the app does not need to be running.
private struct Clock: View {
    let state: TimerAttributes.ContentState
    var alignment: TextAlignment = .trailing

    var body: some View {
        if let since = state.since ?? state.fedSince ?? state.awakeSince {
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

/// Left, Right and Finish, so a feed can be run from the Lock Screen.
private struct FeedButtons: View {
    let attributes: TimerAttributes
    let state: TimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            side("Left", action: TimerActions.feedLeft)
            side("Right", action: TimerActions.feedRight)
            Spacer(minLength: 0)
            ActionButton("Finish", action: TimerActions.finishFeed, attributes: attributes,
                         spoken: "Finish \(attributes.childName)'s feed")
        }
    }

    private func side(_ name: String, action: String) -> some View {
        let running = state.runningSide == name
        return ActionButton(name, action: action, attributes: attributes, filled: running, ticked: running,
                            spoken: running ? "Pause the \(name.lowercased()) side" : "Start the \(name.lowercased()) side")
    }
}

private struct ActionButton: View {
    let title: String
    let action: String
    let attributes: TimerAttributes
    var filled = true
    var ticked = false
    let spoken: String

    init(_ title: String, action: String, attributes: TimerAttributes, filled: Bool = true, ticked: Bool = false, spoken: String) {
        self.title = title
        self.action = action
        self.attributes = attributes
        self.filled = filled
        self.ticked = ticked
        self.spoken = spoken
    }

    var body: some View {
        Button(intent: TimerActionIntent(action, childID: attributes.childID)) {
            HStack(spacing: 4) {
                if ticked { Image(systemName: "checkmark").font(.caption2.weight(.bold)) }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(filled ? Tone.ink : Tone.moon)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(filled ? Tone.moon : Tone.moon.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spoken)
    }
}
