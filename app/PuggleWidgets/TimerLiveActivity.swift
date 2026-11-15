import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// A child's card on the Lock Screen and in the Dynamic Island: a running feed, a running sleep, or how
/// long since the last feed and since they woke.
///
/// Whose card it is comes first everywhere: the child's initial on their own colour. Then the one number
/// that matters, kept short so it never runs out of room. Apple Watch and CarPlay get a layout of their own
/// (from iOS 18), with no buttons, because CarPlay switches buttons off.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration { TimerCard.configuration { LockScreenCard(context: $0) } }
}

@available(iOS 18.0, *)
struct TimerLiveActivityWithSmall: Widget {
    var body: some WidgetConfiguration {
        TimerCard.configuration { FamilyCard(context: $0) }
            .supplementalActivityFamilies([.small])
    }
}

/// The Lock Screen card, or the small one where the system asks for it (Apple Watch's Smart Stack, CarPlay).
@available(iOS 18.0, *)
private struct FamilyCard: View {
    @Environment(\.activityFamily) private var family
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        if family == .small { SmallCard(context: context) } else { LockScreenCard(context: context) }
    }
}

private enum TimerCard {
    @MainActor static func configuration<Card: View>(@ViewBuilder card: @escaping (ActivityViewContext<TimerAttributes>) -> Card) -> ActivityConfiguration<TimerAttributes> {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            card(context)
                .activityBackgroundTint(Tone.night)
                .activitySystemActionForegroundColor(Tone.cream)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    // Who, beside the camera: the same badge as the closed island, larger.
                    Badge(attributes: context.attributes, size: 40)
                        .padding(.leading, 6)
                        .padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // What, and the number that matters, large, as on the system timer.
                    VStack(alignment: .trailing, spacing: -2) {
                        HStack(spacing: 4) {
                            if state.mode != "glance" { TimerGlyph(mode: state.mode, size: 13) }
                            Text(state.heading)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Tone.cream.opacity(0.7))
                        Figure(state: state)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Tone.moon)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150, alignment: .trailing)
                    .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(context.attributes.childName)
                                    .font(.headline)
                                    .foregroundStyle(Tone.cream)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Detail(state: state)
                                    .font(.subheadline)
                                    .foregroundStyle(Tone.cream.opacity(0.7))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            Spacer(minLength: 8)
                            switch state.mode {
                            case "glance":
                                ActionButton("Start sleep", action: TimerActions.startSleep, attributes: context.attributes,
                                             spoken: "Start \(context.attributes.childName)'s sleep")
                            case "sleep":
                                ActionButton("Woke up", action: TimerActions.wokeUp, attributes: context.attributes,
                                             spoken: "\(context.attributes.childName) woke up")
                            default:
                                EmptyView()
                            }
                        }
                        if state.mode == "feed" {
                            FeedButtons(attributes: context.attributes, state: state)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                    .padding(.bottom, 2)
                }
            } compactLeading: {
                Badge(attributes: context.attributes, size: 22)
            } compactTrailing: {
                // Short units ("25m", "1h 29m"), snug to the camera, never cut off.
                // A self-updating text asks for all the width there is, which would stretch the island across
                // the status bar. So it gets a fixed, small width, with its digits at the outer end.
                HStack(spacing: 3) {
                    if state.mode != "glance" { TimerGlyph(mode: state.mode, size: 12) }
                    Figure(state: state, narrow: true)
                        .multilineTextAlignment(.trailing)
                        .frame(width: state.mode == "feed" ? 26 : 40, alignment: .trailing)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Tone.moon)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            } minimal: {
                // With two children there are two of these side by side: the initial tells them apart.
                Badge(attributes: context.attributes, size: 22)
            }
            .keylineTint(Tone.child(context.attributes.colourIndex))
        }
    }
}

private extension TimerAttributes.ContentState {
    /// The word over the number: what the number is counting.
    var heading: String {
        switch mode {
        case "sleep": "Asleep"
        case "feed": runningSide.map { "\($0) side" } ?? "Paused"
        default: "Fed"
        }
    }
}

/// The number: how long asleep, how long on this side, or how long since a feed.
private struct Figure: View {
    let state: TimerAttributes.ContentState
    var narrow = false

    var body: some View {
        switch state.mode {
        case "glance":
            if let fed = state.fedSince { Since.text(fed, narrow: true).monospacedDigit() }
        case "sleep":
            if let since = state.since { Since.text(since, narrow: true).monospacedDigit() }
        default:
            // A feed is short and watched, so its clock ticks. In the closed island it is minutes, to stay narrow.
            if narrow, let since = state.since { Since.text(since, narrow: true).monospacedDigit() }
            else { Clock(state: state) }
        }
    }
}

/// The line under the name in the open island.
private struct Detail: View {
    let state: TimerAttributes.ContentState

    var body: some View {
        switch state.mode {
        case "glance":
            if let awake = state.awakeSince { (Text("Awake ") + Since.text(awake)).monospacedDigit() } else { Text("Since the last feed") }
        case "sleep":
            if let since = state.since { Text("Since ") + Text(since, style: .time) } else { Text(state.label) }
        default:
            Text(state.label)
        }
    }
}

/// Whose card it is: their initial on their own colour, as on Today.
private struct Badge: View {
    let attributes: TimerAttributes
    var size: CGFloat = 22

    var body: some View {
        Text(String(attributes.childName.prefix(1)).uppercased())
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(Tone.ink)
            .frame(width: size, height: size)
            .background(Tone.child(attributes.colourIndex), in: Circle())
            .accessibilityLabel(attributes.childName)
    }
}

/// Puggle's own moon for a sleep and bottle for a feed. A glance at the day has no icon of ours, so it keeps Apple's clock.
private struct TimerGlyph: View {
    let mode: String
    var size: CGFloat = 20

    var body: some View {
        switch mode {
        case "sleep": Glyph("sleep", size: size)
        case "feed": Glyph("bottle", size: size)
        default: Image(systemName: "clock")
        }
    }
}

/// Fixed colours: the Lock Screen view is always the night look.
private enum Tone {
    static let night = Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x40 / 255)
    static let moon = Color(red: 0xF3 / 255, green: 0xE0 / 255, blue: 0xB8 / 255)
    static let cream = Color(red: 0xFB / 255, green: 0xF6 / 255, blue: 0xE9 / 255)
    static let ink = Color(red: 0x3A / 255, green: 0x2A / 255, blue: 0x20 / 255)

    /// The children's colours, as in the app (Sky, Shell, Mint, Sun, Lilac, Rose, Sea, Stone).
    private static let children: [UInt32] = [0xBFD9F5, 0xF3D9C9, 0xCFE5D2, 0xF4E7B0, 0xE2D4F1, 0xF6CFDC, 0xC4E6E4, 0xDDD8D0]

    static func child(_ index: Int?) -> Color {
        guard let index else { return moon }
        let hex = children[((index % children.count) + children.count) % children.count]
        return Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

private struct LockScreenCard: View {
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        let state = context.state
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Badge(attributes: context.attributes, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.childName)
                        .font(.headline)
                        .foregroundStyle(Tone.cream)
                        .lineLimit(1)
                    if state.mode == "glance" {
                        GlanceLines(state: state)
                    } else {
                        HStack(spacing: 5) {
                            TimerGlyph(mode: state.mode, size: 15)
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
        // Apple's margin for a card on the Lock Screen, so it lines up with notifications.
        .padding(14)
    }
}

/// Apple Watch's Smart Stack and CarPlay: who, what and the number, with nothing to press.
private struct SmallCard: View {
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        let state = context.state
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Badge(attributes: context.attributes, size: 22)
                Text(context.attributes.childName)
                    .font(.headline)
                    .foregroundStyle(Tone.cream)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if state.mode != "glance" { TimerGlyph(mode: state.mode, size: 16).foregroundStyle(Tone.moon) }
            }
            Group {
                switch state.mode {
                case "glance":
                    if let fed = state.fedSince { Text("Fed ") + Since.text(fed, narrow: true) + Text(" ago") }
                    if let awake = state.awakeSince { Text("Awake ") + Since.text(awake, narrow: true) }
                case "sleep":
                    if let since = state.since { Text("Asleep ") + Since.text(since, narrow: true) }
                default:
                    HStack(spacing: 5) {
                        Text(state.label)
                        Clock(state: state, alignment: .leading)
                    }
                }
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Tone.moon)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// "Fed 1 hr, 29 min ago" and "Awake 1 hr, 11 min". Plain facts; nothing is due and nothing turns red.
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

/// How long since a moment, updating by itself, with no seconds ticking: "1 hr, 29 min", or "1h 29m" where room is short.
private enum Since {
    static func text(_ date: Date, narrow: Bool = false) -> Text {
        if #available(iOS 18.0, *) {
            return Text(.dateRange(startingAt: date), format: .components(style: narrow ? .narrow : .abbreviated, fields: [.hour, .minute]))
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
