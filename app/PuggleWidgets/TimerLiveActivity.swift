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
                .fontDesign(.rounded)
                .activityBackgroundTint(Tone.night)
                .activitySystemActionForegroundColor(Tone.cream)
        } dynamicIsland: { context in
            let state = context.state
            // On the family card the first row's child; otherwise the card's own.
            let lead = context.attributes.lead(state)
            let others = state.others ?? []
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    // Who, beside the camera: the same badge as the closed island, larger.
                    Badge(attributes: lead, size: 40)
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
                                Text(lead.childName)
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
                                ActionButton("Start sleep", action: TimerActions.startSleep, attributes: lead,
                                             spoken: "Start \(lead.childName)'s sleep")
                            case "sleep":
                                ActionButton("Woke up", action: TimerActions.wokeUp, attributes: lead,
                                             spoken: "\(lead.childName) woke up")
                            default:
                                EmptyView()
                            }
                        }
                        if state.mode == "feed" {
                            FeedButtons(attributes: lead, state: state)
                        }
                        // Everyone else, a quiet line each.
                        ForEach(others, id: \.id) { other in
                            OtherLine(other: other)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                    .padding(.bottom, 2)
                }
            } compactLeading: {
                // Everyone on the card, overlapping, the first on top: the number beside is theirs.
                Badges(lead: lead, others: others, size: 22)
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
                // Beside another app's card: the first child's initial.
                Badge(attributes: lead, size: 22)
            }
            .keylineTint(Tone.child(lead.colourIndex))
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
            switch (state.awakeSince, state.nappySince) {
            case let (awake?, nappy?): (Text("Awake ") + Since.text(awake, narrow: true) + Text(" · \(Terms.nappy) ") + Since.text(nappy, narrow: true)).monospacedDigit()
            case let (awake?, nil): (Text("Awake ") + Since.text(awake)).monospacedDigit()
            case let (nil, nappy?): (Text("\(Terms.nappy) ") + Since.text(nappy) + Text(" ago")).monospacedDigit()
            default: Text("Since the last feed")
            }
        case "sleep":
            switch (state.fedSince, state.nappySince) {
            case let (fed?, nappy?): (Text("Fed ") + Since.text(fed, narrow: true) + Text(" · \(Terms.nappy) ") + Since.text(nappy, narrow: true)).monospacedDigit()
            case let (fed?, nil): (Text("Fed ") + Since.text(fed) + Text(" ago")).monospacedDigit()
            case let (nil, nappy?): (Text("\(Terms.nappy) ") + Since.text(nappy) + Text(" ago")).monospacedDigit()
            default: if let since = state.since { Text("Since ") + Text(since, style: .time) } else { Text(state.label) }
            }
        default:
            Text(state.label)
        }
    }
}

/// Whose card it is: their initial on their own colour, as on Today.
private struct Badge: View {
    let name: String
    let colourIndex: Int?
    var size: CGFloat = 22

    init(attributes: TimerAttributes, size: CGFloat = 22) {
        self.init(name: attributes.childName, colourIndex: attributes.colourIndex, size: size)
    }

    init(name: String, colourIndex: Int?, size: CGFloat = 22) {
        self.name = name
        self.colourIndex = colourIndex
        self.size = size
    }

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(Tone.ink)
            .frame(width: size, height: size)
            .background(Tone.child(colourIndex), in: Circle())
            .accessibilityLabel(name)
    }
}

/// The closed island with more than one child: their badges overlapping, the first on top.
private struct Badges: View {
    let lead: TimerAttributes
    let others: [TimerAttributes.ContentState.Other]
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: -size * 0.45) {
            Badge(attributes: lead, size: size).zIndex(3)
            ForEach(Array(others.prefix(2).enumerated()), id: \.element.id) { place, other in
                Badge(name: other.name, colourIndex: other.colourIndex, size: size)
                    .overlay(Circle().stroke(.black, lineWidth: 1.5))
                    .zIndex(Double(2 - place))
            }
        }
    }
}

/// Another child in the open island or on the watch: their badge and one line.
private struct OtherLine: View {
    let other: TimerAttributes.ContentState.Other

    var body: some View {
        HStack(spacing: 6) {
            Badge(name: other.name, colourIndex: other.colourIndex, size: 20)
            Text(other.name).fontWeight(.semibold).foregroundStyle(Tone.cream)
            Group {
                switch other.state.mode {
                case "sleep": if let since = other.state.since { Text("Asleep ") + Since.text(since, narrow: true) }
                case "feed": Text("Feeding")
                default: if let fed = other.state.fedSince { Text("Fed ") + Since.text(fed, narrow: true) + Text(" ago") }
                }
            }
            .foregroundStyle(Tone.moon)
            .monospacedDigit()
            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
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
        let lead = context.attributes.lead(state)
        let others = state.others ?? []
        Group {
            if others.isEmpty {
                alone(lead: lead, state: state)
            } else {
                family(lead: lead, state: state, others: others)
            }
        }
        // Apple's margin for a card on the Lock Screen, so it lines up with notifications.
        .padding(14)
    }

    /// One child: the badge, the name, their three facts and what comes next.
    private func alone(lead: TimerAttributes, state: TimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Badge(attributes: lead, size: 40)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(lead.childName)
                            .font(.headline)
                            .foregroundStyle(Tone.cream)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if state.mode == "sleep" {
                            ActionButton("Woke up", action: TimerActions.wokeUp, attributes: lead,
                                         spoken: "\(lead.childName) woke up")
                        }
                    }
                    .frame(minHeight: 22)
                    if state.mode == "feed" {
                        HStack(spacing: 5) {
                            TimerGlyph(mode: state.mode, size: 15)
                            Text(state.label)
                            Clock(state: state, alignment: .leading)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Tone.moon)
                    } else {
                        // The snapshot, readable without opening anything: the feed, the sleep and the nappy.
                        // Each opens Puggle at the sheet for the next one.
                        Facts(state: state, childID: lead.childID)
                        // What comes next, until its time. After that the card is stale and the line goes.
                        if !context.isStale, let next = state.nextLine() {
                            Text(next)
                                .font(.footnote)
                                .foregroundStyle(Tone.cream.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }
                }
            }
            if state.mode == "feed" {
                FeedButtons(attributes: lead, state: state)
            }
        }
    }

    /// Two or more children: a row each, the busiest first, and only the first with buttons.
    private func family(lead: TimerAttributes, state: TimerAttributes.ContentState, others: [TimerAttributes.ContentState.Other]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FamilyRow(name: lead.childName, colourIndex: lead.colourIndex, childID: lead.childID, state: state) {
                if state.mode == "sleep" {
                    ActionButton("Woke up", action: TimerActions.wokeUp, attributes: lead, spoken: "\(lead.childName) woke up")
                }
            }
            if state.mode == "feed" {
                FeedButtons(attributes: lead, state: state)
            }
            ForEach(others, id: \.id) { other in
                FamilyRow(name: other.name, colourIndex: other.colourIndex, childID: other.id, state: other.state) { EmptyView() }
            }
            if let more = state.more, more > 0 {
                Text("and \(more) more in Puggle")
                    .font(.caption)
                    .foregroundStyle(Tone.cream.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

/// A child's row on the family card: the badge, the name over one quiet line, and the number that matters.
/// Tapping it opens Puggle at that child's sheet: the sleep while asleep, otherwise a feed.
private struct FamilyRow<Trailing: View>: View {
    let name: String
    let colourIndex: Int?
    let childID: String
    let state: TimerAttributes.ContentState
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            // The row is the way in; a button beside it keeps its own tap.
            if state.mode == "feed" {
                face
            } else {
                Link(destination: PuggleLink.log(state.mode == "sleep" ? "asleep" : "fed", child: childID)) { face }
            }
            trailing()
        }
        .frame(minHeight: 34)
    }

    private var face: some View {
        HStack(spacing: 10) {
            Badge(name: name, colourIndex: colourIndex, size: 32)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tone.cream)
                HStack(spacing: 4) {
                    if state.mode == "sleep" { Glyph("sleep", size: 12) }
                    line
                }
                .font(.caption)
                .foregroundStyle(Tone.cream.opacity(0.7))
                .monospacedDigit()
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            Spacer(minLength: 6)
            // A time that counts by itself takes all the width it is given, so it is held to a column and set
            // at its right, where every row's number ends.
            figure
                .font(.headline)
                .foregroundStyle(Tone.moon)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120, alignment: .trailing)
        }
        // The full width, so every row's number ends at the same edge.
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var line: some View {
        switch state.mode {
        case "sleep":
            // The moon beside it says asleep; short, so it fits beside the button.
            if let since = state.since { Text("Since ") + Text(since, style: .time) } else { Text("Asleep") }
        case "feed":
            Text(state.label)
        default:
            if let awake = state.awakeSince { Text("Awake ") + Since.text(awake) }
            else if let nappy = state.nappySince { Text("\(Terms.nappy) ") + Since.text(nappy, narrow: true) + Text(" ago") }
            else { Text("Since the last feed") }
        }
    }

    @ViewBuilder private var figure: some View {
        switch state.mode {
        case "sleep": if let since = state.since { Since.text(since, narrow: true) }
        case "feed": Clock(state: state)
        default: if let fed = state.fedSince { Text("Fed ") + Since.text(fed, narrow: true) }
        }
    }
}

/// Apple Watch's Smart Stack and CarPlay: who, what and the number, with nothing to press.
private struct SmallCard: View {
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        let others = context.state.others ?? []
        if others.isEmpty { alone } else {
            // The family: a line each, the first child's first.
            VStack(alignment: .leading, spacing: 4) {
                OtherLine(other: .init(id: lead.childID, name: lead.childName, colourIndex: lead.colourIndex, state: context.state))
                ForEach(others, id: \.id) { OtherLine(other: $0) }
                if let more = context.state.more, more > 0 {
                    Text("and \(more) more").font(.caption2).foregroundStyle(Tone.cream.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var lead: TimerAttributes { context.attributes.lead(context.state) }

    private var alone: some View {
        let state = context.state
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Badge(attributes: lead, size: 22)
                Text(lead.childName)
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
                    switch (state.awakeSince, state.nappySince) {
                    case let (awake?, nappy?): Text("Awake ") + Since.text(awake, narrow: true) + Text(" · \(Terms.nappy) ") + Since.text(nappy, narrow: true)
                    case let (awake?, nil): Text("Awake ") + Since.text(awake, narrow: true)
                    case let (nil, nappy?): Text("\(Terms.nappy) ") + Since.text(nappy, narrow: true) + Text(" ago")
                    default: EmptyView()
                    }
                case "sleep":
                    if let since = state.since { Text("Asleep ") + Since.text(since, narrow: true) }
                    switch (state.fedSince, state.nappySince) {
                    case let (fed?, nappy?): Text("Fed ") + Since.text(fed, narrow: true) + Text(" · \(Terms.nappy) ") + Since.text(nappy, narrow: true)
                    case let (fed?, nil): Text("Fed ") + Since.text(fed, narrow: true) + Text(" ago")
                    case let (nil, nappy?): Text("\(Terms.nappy) ") + Since.text(nappy, narrow: true) + Text(" ago")
                    default: EmptyView()
                    }
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

/// Up to three facts side by side, each a word over a time: "Fed 1h 29m", "Awake 1h 11m", "Nappy 45m".
/// While asleep the first is "Asleep". Plain facts; nothing is due and nothing turns red.
private struct Facts: View {
    let state: TimerAttributes.ContentState
    let childID: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if state.mode == "sleep", let since = state.since { fact("Asleep", glyph: "sleep", since, link: "asleep") }
            if let fed = state.fedSince { fact("Fed", glyph: "bottle", fed, link: "fed") }
            if state.mode == "glance", let awake = state.awakeSince { fact("Awake", glyph: nil, awake, link: "awake") }
            if let nappy = state.nappySince { fact(Terms.nappy, glyph: "nappy", nappy, link: "nappy") }
        }
    }

    /// A fact is also the way in: it opens Puggle at the sheet for the next one, for this child.
    private func fact(_ title: String, glyph: String?, _ since: Date, link: String) -> some View {
        Link(destination: PuggleLink.log(link, child: childID)) { face(title, glyph: glyph, since) }
    }

    private func face(_ title: String, glyph: String?, _ since: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 3) {
                if let glyph { Glyph(glyph, size: 12) } else { Image(systemName: "sun.max").font(.system(size: 10, weight: .semibold)) }
                Text(title)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Tone.cream.opacity(0.7))
            Since.text(since, narrow: true)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Tone.moon)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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
