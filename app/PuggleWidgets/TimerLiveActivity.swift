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
                // Open, it grows out of the closed island and looks like the Lock Screen card (Apple asks for both):
                // the badge and the name where the badge was, the button at the right, then the facts in columns.
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        if !others.isEmpty {
                            // The family: everyone's badges, then a row each below, as on the Lock Screen.
                            Badges(lead: lead, others: others, size: 28)
                        } else {
                            Badge(attributes: lead, size: 28)
                        }
                        Text(others.isEmpty ? lead.childName : "Family")
                            .font(.headline)
                            .foregroundStyle(Tone.cream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.leading, 6)
                    .padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Group {
                        switch others.isEmpty ? state.mode : "family" {
                        case "family":
                            // Each row has its own button.
                            EmptyView()
                        case "glance":
                            ActionButton("Start sleep", action: TimerActions.startSleep, attributes: lead,
                                         spoken: "Start \(lead.childName)'s sleep")
                        case "sleep":
                            ActionButton("Woke up", action: TimerActions.wokeUp, attributes: lead,
                                         spoken: "\(lead.childName) woke up")
                        default:
                            Text(state.heading)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Tone.cream.opacity(0.8))
                        }
                    }
                    .padding(.trailing, 6)
                    .padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Group {
                        if !others.isEmpty {
                            FamilyRows(lead: lead, state: state, others: others)
                        } else if state.mode == "feed" {
                            FeedNow(attributes: lead, state: state)
                        } else {
                            Facts(state: state, childID: lead.childID, size: 24)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, others.isEmpty ? 2 : 8)
                }
            } compactLeading: {
                CompactLeading(lead: lead, others: others, mode: state.mode)
            } compactTrailing: {
                CompactTrailing(state: state)
            } minimal: {
                // Beside another app's activity: Puggle's face, awake, asleep or feeding, as the child is (P2).
                PuggleMark(mode: state.mode, size: 24)
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
            // The first fact, as on the card: the feed for a child on milk, the last meal for a toddler.
            if let first = state.milk == false ? (state.ateSince ?? state.awakeSince) : state.fedSince { Since.text(first, narrow: true).monospacedDigit() }
        case "sleep":
            if let since = state.since { Since.text(since, narrow: true).monospacedDigit() }
        default:
            // A feed is short and watched, so its clock ticks. In the closed island it is minutes, to stay narrow.
            if narrow, let since = state.since { Since.text(since, narrow: true).monospacedDigit() }
            else { Clock(state: state) }
        }
    }
}

/// Puggle's face as the Live Activity's mark (Tom, 20 November 2026; P2 and P3 of
/// docs/previews/live-card/all-presentations.html): awake, asleep, or with a bottle while feeding. Apple allows
/// a logo mark with no container around it, never the whole app icon.
private struct PuggleMark: View {
    let mode: String
    var size: CGFloat = 24

    var body: some View {
        Image(mode == "sleep" ? "glyph-puggle-asleep" : mode == "feed" ? "glyph-puggle-feeding" : "glyph-puggle-awake")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel(mode == "sleep" ? "Asleep" : mode == "feed" ? "Feeding" : "Puggle")
    }
}

/// The closed island's left side: everyone's badges, or in landscape, where each side is a 28-point circle,
/// Puggle's face alone (Apple's limited-width guidance, 13 October 2026; iOS 27 and later).
private struct CompactLeading: View {
    let lead: TimerAttributes
    let others: [TimerAttributes.ContentState.Other]
    let mode: String

    var body: some View {
        if #available(iOS 27.0, *) { Limited { $0 ? AnyView(PuggleMark(mode: mode, size: 26)) : AnyView(badges) } } else { badges }
    }

    private var badges: some View { Badges(lead: lead, others: others, size: 22) }
}

/// The closed island's right side: the number that matters, in short units, snug to the camera. Empty in
/// landscape, where the system then hides it and the left side stands alone.
private struct CompactTrailing: View {
    let state: TimerAttributes.ContentState

    var body: some View {
        if #available(iOS 27.0, *) { Limited { $0 ? AnyView(EmptyView()) : AnyView(figure) } } else { figure }
    }

    /// A self-updating text asks for all the width there is, which would stretch the island across the status
    /// bar. So it gets a fixed, small width, with its digits at the outer end.
    private var figure: some View {
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
    }
}

/// Whether the island is limited to a 28-point circle each side, as in landscape.
@available(iOS 27.0, *)
private struct Limited: View {
    @Environment(\.isDynamicIslandLimitedInWidth) private var limited
    let content: (Bool) -> AnyView
    init(@ViewBuilder _ content: @escaping (Bool) -> AnyView) { self.content = content }
    var body: some View { content(limited) }
}

/// A feed running: its time large, as large as the facts, and the buttons beside it: the other side and Finish.
/// Paused, both sides to start again.
private struct FeedNow: View {
    let attributes: TimerAttributes
    let state: TimerAttributes.ContentState
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 8) {
            Clock(state: state, alignment: .leading)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Tone.moon)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
            FeedButtons(attributes: attributes, state: state)
        }
    }
}

/// Another child on the family card or in the open island: badge and name, then their facts in the same columns,
/// smaller. Tapping it opens Puggle at their sheet.
private struct ChildColumns: View {
    let name: String
    let colourIndex: Int?
    let childID: String
    let state: TimerAttributes.ContentState
    /// The first child's button, in the place of their third column (or beside the feed).
    var button: AnyView?

    var body: some View {
        HStack(spacing: 8) {
            Badge(name: name, colourIndex: colourIndex, size: 24)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tone.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 52, alignment: .leading)
            if state.mode == "feed" {
                HStack(spacing: 4) {
                    Glyph("bottle", size: 12)
                    Text(state.label)
                    Clock(state: state, alignment: .leading)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Tone.moon)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                button
            } else if let button {
                Facts(state: state, childID: childID, size: 17, rules: false, limit: 2, slots: 2, extra: button)
            } else {
                Facts(state: state, childID: childID, size: 17, rules: false, slots: 3)
            }
        }
    }
}

/// StandBy (P3): the phone charging on its side, the card filling the screen and, at night, tinted red by iOS.
/// Puggle's face large, as the child is, beside what matters most: while asleep or feeding the time it has run,
/// large; otherwise the three facts.
private struct StandByCard: View {
    let lead: TimerAttributes
    let state: TimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 18) {
            PuggleMark(mode: state.mode, size: 72)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.mode == "sleep" ? "\(lead.childName), asleep" : state.mode == "feed" ? "\(lead.childName), \(state.label.lowercased())" : lead.childName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tone.cream.opacity(0.8))
                    .lineLimit(1)
                switch state.mode {
                case "sleep":
                    if let since = state.since {
                        Since.text(since, narrow: true)
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Tone.moon)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    if let next = state.nextLine() {
                        Text(next).font(.caption.weight(.medium)).foregroundStyle(Tone.cream.opacity(0.75))
                    }
                case "feed":
                    Clock(state: state, alignment: .leading)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Tone.moon)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                default:
                    Facts(state: state, childID: lead.childID, size: 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .font(.subheadline.weight(.medium))
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
    /// StandBy: the phone on its side, charging, the card filling the screen.
    @Environment(\.isActivityFullscreen) private var fullscreen

    var body: some View {
        let state = context.state
        let lead = context.attributes.lead(state)
        let others = state.others ?? []
        Group {
            if fullscreen {
                StandByCard(lead: lead, state: state)
            } else if others.isEmpty {
                alone(lead: lead, state: state)
            } else {
                family(lead: lead, state: state, others: others)
            }
        }
        // Apple's margin for a card on the Lock Screen, so it lines up with notifications.
        .padding(14)
    }

    /// One child: a small line with the badge, the name and what comes next, then their three facts in columns,
    /// each time large over its word (Tom and his wife, 20 November 2026: option E of
    /// docs/previews/live-card/bigger-facts.html). Feeding, the running feed and its buttons in place of the facts.
    private func alone(lead: TimerAttributes, state: TimerAttributes.ContentState) -> some View {
        // What comes next, until its time. After that the card is stale and the line goes.
        let next = context.isStale || state.mode == "feed" ? nil : state.nextLine()
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Badge(attributes: lead, size: 24)
                Text(lead.childName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tone.cream)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                if state.mode == "sleep" {
                    ActionButton("Woke up", action: TimerActions.wokeUp, attributes: lead,
                                 spoken: "\(lead.childName) woke up")
                } else if state.mode == "feed" {
                    // Which side, where what comes next usually is.
                    HStack(spacing: 4) {
                        Glyph("bottle", size: 12)
                        Text(state.heading)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Tone.cream.opacity(0.8))
                } else if let next {
                    Text(next)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Tone.cream.opacity(0.8))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            if state.mode == "feed" {
                // The feed's time as large as the facts, with the other side and Finish beside it.
                FeedNow(attributes: lead, state: state)
            } else {
                // The snapshot, readable at a glance: the feed, the sleep and the nappy, each opening Puggle at the
                // sheet for the next one.
                Facts(state: state, childID: lead.childID)
                // While asleep the button has the top right, so what comes next goes under the facts.
                if state.mode == "sleep", let next {
                    Text(next)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Tone.cream.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// How far in the name starts: the badge and the gap after it.
    private static let underName: CGFloat = 24 + 8

    /// Two or more children: a row each (see `FamilyRows`).
    private func family(lead: TimerAttributes, state: TimerAttributes.ContentState, others: [TimerAttributes.ContentState.Other]) -> some View {
        FamilyRows(lead: lead, state: state, others: others)
    }
}

/// Two or more children (proposed 20 November 2026): a row each, the same three facts in columns as the one-child
/// card, smaller. The rows run in Today's order, so each child keeps their place; whoever is feeding has the feed's
/// buttons in their row, and anyone asleep a Woke up button (Tom, 20 November 2026). The Lock Screen and the open
/// island both show this.
private struct FamilyRows: View {
    let lead: TimerAttributes
    let state: TimerAttributes.ContentState
    let others: [TimerAttributes.ContentState.Other]

    private var rows: [TimerAttributes.ContentState.Other] {
        var rows = others
        let first = TimerAttributes.ContentState.Other(id: lead.childID, name: lead.childName, colourIndex: lead.colourIndex, state: state)
        rows.insert(first, at: min(max(state.leadPlace ?? 0, 0), rows.count))
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Rectangle().fill(Tone.cream.opacity(0.12)).frame(height: 1) }
                ChildColumns(name: row.name, colourIndex: row.colourIndex, childID: row.id, state: row.state, button: button(for: row))
            }
            if let more = state.more, more > 0 {
                Text("and \(more) more in the app")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Tone.cream.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func button(for row: TimerAttributes.ContentState.Other) -> AnyView? {
        let who = TimerAttributes(childID: row.id, childName: row.name, colourIndex: row.colourIndex)
        switch row.state.mode {
        case "sleep":
            return AnyView(ActionButton("Woke up", action: TimerActions.wokeUp, attributes: who, small: true, spoken: "\(row.name) woke up"))
        case "feed" where row.id == lead.childID:
            return AnyView(FeedButtons(attributes: who, state: row.state))
        default:
            return nil
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
                // In Today's order, as on the Lock Screen.
                ForEach(rows, id: \.id) { OtherLine(other: $0) }
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

    private var rows: [TimerAttributes.ContentState.Other] {
        var rows = context.state.others ?? []
        let first = TimerAttributes.ContentState.Other(id: lead.childID, name: lead.childName, colourIndex: lead.colourIndex, state: context.state)
        rows.insert(first, at: min(max(context.state.leadPlace ?? 0, 0), rows.count))
        return rows
    }

    /// One child on the Watch or in CarPlay: a small name line, then the same three facts in columns as the Lock
    /// Screen card, sized to fit 194 × 80 points; feeding, the feed's time large. No buttons: CarPlay turns them off.
    private var alone: some View {
        let state = context.state
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Badge(attributes: lead, size: 16)
                Text(lead.childName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Tone.cream)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if state.mode == "feed" {
                    Text(state.heading).font(.caption2.weight(.semibold)).foregroundStyle(Tone.cream.opacity(0.8))
                }
            }
            if state.mode == "feed" {
                Clock(state: state, alignment: .leading)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Tone.moon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Facts(state: state, childID: lead.childID, size: 15, rules: false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

/// Up to three facts in columns, each a time large over its word: "1h 46m" over "Fed", "2h 56m" over "Awake",
/// "1h 14m" over "Nappy", with a thin line between them. While asleep the first is "Asleep". Plain facts;
/// nothing is due and nothing turns red. The times count up by themselves, so each is one run of text and its
/// "h" and "m" are the size of the numbers.
private struct Facts: View {
    @Environment(\.isLuminanceReduced) private var dimmed
    let state: TimerAttributes.ContentState
    let childID: String
    /// The times' size: 26 on the Lock Screen, smaller for a second child's row, the Watch and CarPlay.
    var size: CGFloat = 26
    /// Thin lines between the columns; left out where the columns are small.
    var rules = true
    /// At most this many facts.
    var limit = 3
    /// Columns to keep even when there are fewer facts, so rows on the family card line up. Nil: as many as there are.
    var slots: Int?
    /// Something in the last column, as wide as a fact: the first child's button on the family card.
    var extra: AnyView?

    private typealias Fact = (title: String, glyph: String?, since: Date, link: String)

    /// Each fact in its own place, as on the child's card on Today, at every age: food (Fed on milk, Ate past
    /// it), then sleep (Awake or Asleep), then the nappy or the potty. Nil where nothing is logged.
    private var placed: [Fact?] {
        let onMilk = state.milk != false
        var food: Fact?, sleep: Fact?, toilet: Fact?
        if onMilk, let fed = state.fedSince { food = ("Fed", "bottle", fed, "fed") }
        if !onMilk, let ate = state.ateSince { food = ("Ate", "solids", ate, "ate") }
        if state.mode == "sleep", let since = state.since { sleep = ("Asleep", "sleep", since, "asleep") }
        if state.mode == "glance", let awake = state.awakeSince { sleep = ("Awake", nil, awake, "awake") }
        if state.potty == true {
            if let potty = state.pottySince { toilet = ("Potty", "potty", potty, "potty") }
        } else if let nappy = state.nappySince {
            toilet = (Terms.nappy, "nappy", nappy, "nappy")
        }
        return [food, sleep, toilet]
    }

    var body: some View {
        // In rows that line up (the family card), every fact keeps its column, so a second child's Asleep sits
        // under the first child's Asleep even when nothing has been fed (Tom, 20 November 2026). Alone, the
        // facts there are share the width.
        let cells: [Fact?] = slots != nil ? Array(placed.prefix(limit)) : Array(placed.compactMap { $0 }.prefix(limit))
        let columns = max(cells.count, slots ?? 0)
        HStack(spacing: 0) {
            ForEach(0..<columns, id: \.self) { index in
                if index > 0, rules {
                    Rectangle().fill(Tone.cream.opacity(0.16)).frame(width: 1, height: size + 18)
                }
                if index < cells.count, let fact = cells[index] {
                    Link(destination: PuggleLink.log(fact.link, child: childID)) { face(fact.title, glyph: fact.glyph, fact.since) }
                } else {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                }
            }
            if let extra { extra.frame(maxWidth: .infinity) }
        }
    }

    private func face(_ title: String, glyph: String?, _ since: Date) -> some View {
        VStack(spacing: 1) {
            // A time that counts up takes all the width it is given, so it is centred in it, as its word is under it.
            Since.text(since, narrow: true)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Tone.moon)
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 3) {
                if let glyph { Glyph(glyph, size: size < 20 ? 10 : 12) } else { Image(systemName: "sun.max").font(.system(size: size < 20 ? 9 : 10, weight: .semibold)) }
                Text(title)
            }
            .font(.system(size: size < 20 ? 11 : 12, weight: .medium))
            // Brighter when the screen is dimmed for Always On, so the words stay readable.
            .foregroundStyle(Tone.cream.opacity(dimmed ? 0.9 : 0.75))
            .lineLimit(1)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
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

    /// While one side runs: the other side, and Finish. Paused: both sides, and Finish. Apple prefers few buttons
    /// on a Live Activity; pausing is in the app.
    var body: some View {
        HStack(spacing: 8) {
            if state.runningSide != "Left" { side("Left", action: TimerActions.feedLeft) }
            if state.runningSide != "Right" { side("Right", action: TimerActions.feedRight) }
            ActionButton("Finish", action: TimerActions.finishFeed, attributes: attributes,
                         spoken: "Finish \(attributes.childName)'s feed")
        }
    }

    private func side(_ name: String, action: String) -> some View {
        ActionButton(name, action: action, attributes: attributes, filled: false,
                     spoken: "Switch to the \(name.lowercased()) side")
    }
}

private struct ActionButton: View {
    @Environment(\.isLuminanceReduced) private var dimmed
    let title: String
    let action: String
    let attributes: TimerAttributes
    var filled = true
    var ticked = false
    let spoken: String
    /// Smaller, to fit a column of the family card.
    var small = false

    init(_ title: String, action: String, attributes: TimerAttributes, filled: Bool = true, ticked: Bool = false, small: Bool = false, spoken: String) {
        self.small = small
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
                    .lineLimit(1)
                    .fixedSize()
            }
            .font(small ? .footnote.weight(.semibold) : .subheadline.weight(.semibold))
            // Always On, a filled button is a bright block on a dimmed screen: it is drawn as an outline instead,
            // as Apple asks (Tom, 20 November 2026).
            .foregroundStyle(filled && !dimmed ? Tone.ink : Tone.moon)
            .padding(.horizontal, small ? 10 : 12)
            .frame(minHeight: small ? 32 : 36)
            .background(filled && !dimmed ? Tone.moon : Tone.moon.opacity(dimmed ? 0 : 0.16), in: Capsule())
            .overlay { if dimmed { Capsule().stroke(Tone.moon.opacity(0.8), lineWidth: 1.5) } }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spoken)
    }
}
