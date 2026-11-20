import AppIntents
import SwiftUI
import WidgetKit

/// Warm, fixed colours: widgets follow the Home Screen's light or dark look.
private enum WTone {
    static let paper = Color(light: 0xFBF6E9, dark: 0x2A2420)
    static let field = Color(light: 0xEAE2D2, dark: 0x3B332D)
    static let ink = Color(light: 0x3A2A20, dark: 0xEBDDC4)
    static let muted = Color(light: 0x6B5E52, dark: 0xB3A590)
    static let night = Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x40 / 255)
    static let moon = Color(red: 0xF3 / 255, green: 0xE0 / 255, blue: 0xB8 / 255)
    static let badgeInk = Color(light: 0x3A2A20, dark: 0xEBDDC4)
    /// The same order as the app's child colours, so a child is the same colour in both.
    static let childColours: [Color] = [Color(light: 0xBFD9F5, dark: 0x2E4A6E), Color(light: 0xF3D5C9, dark: 0x6A4236),
                                        Color(light: 0xCFE5D2, dark: 0x34523B), Color(light: 0xF6E2A8, dark: 0x5E4E22),
                                        Color(light: 0xE2D4F1, dark: 0x4B3D63), Color(light: 0xF6CFDC, dark: 0x6A3A4B),
                                        Color(light: 0xC4E6E4, dark: 0x2C514F), Color(light: 0xDDD8D0, dark: 0x4A4540)]
    static func child(_ index: Int) -> Color { childColours[((index % childColours.count) + childColours.count) % childColours.count] }
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self = Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

// MARK: Timeline

struct FamilyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    var chosenID: String?

    var chosen: WidgetSnapshot.Child? {
        guard let children = snapshot?.children, !children.isEmpty else { return nil }
        return children.first { $0.id == chosenID } ?? children.first
    }
}

/// "1h 29m", updating by itself from iOS 18; before that, the time as it was when the widget last refreshed.
private func sinceText(_ date: Date, now: Date) -> Text {
    if #available(iOS 18.0, *) {
        return Text(.dateRange(startingAt: date), format: .components(style: .narrow, fields: [.hour, .minute]))
    }
    let minutes = max(Int(now.timeIntervalSince(date) / 60), 0)
    return Text(minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m")
}

/// A time that counts by itself, taking only the room its words need. Such a time asks for all the width
/// there is, which pushes whatever is beside it about. Here a still copy of the words sets the size (the
/// longer of how it reads now and how it will read by the next refresh), and the counting one is drawn over it.
private struct SinceValue: View {
    let since: Date
    let now: Date

    private func words(at date: Date) -> String {
        let minutes = max(Int(date.timeIntervalSince(since) / 60), 0)
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }

    var body: some View {
        let (first, later) = (words(at: now), words(at: now.addingTimeInterval(15 * 60)))
        Text(later.count > first.count ? later : first)
            .lineLimit(1)
            .fixedSize()
            .hidden()
            .overlay(alignment: .leading) { sinceText(since, now: now).lineLimit(1).fixedSize() }
    }
}

/// One thing worth knowing about a child, as on the Lock Screen card: a word, and how long since.
private struct Fact: Identifiable {
    let title: String
    /// One of Puggle's glyphs, or nil for the sun (awake has no glyph of ours).
    let glyph: String?
    let since: Date
    /// Which of Today's facts it is, for the link that opens its sheet.
    let link: String
    var id: String { title }
}

private extension WidgetSnapshot.Child {
    /// The snapshot: the sleep (running, or how long awake), the last feed and the last nappy.
    /// Only what is recent: a feed from yesterday is not news.
    func facts(now: Date) -> [Fact] {
        let recent = { (date: Date?) -> Date? in date.flatMap { now.timeIntervalSince($0) < 12 * 3600 && $0 <= now.addingTimeInterval(60) ? $0 : nil } }
        var all: [Fact] = []
        if let asleep = asleepSince { all.append(Fact(title: "Asleep", glyph: "sleep", since: asleep, link: "asleep")) }
        if let fed = recent(lastFeed) { all.append(Fact(title: "Fed", glyph: "bottle", since: fed, link: "fed")) }
        if asleepSince == nil, let woke = recent(lastWoke) { all.append(Fact(title: "Awake", glyph: nil, since: woke, link: "awake")) }
        if usesNappies, let nappy = recent(lastNappy) { all.append(Fact(title: Terms.nappy, glyph: "nappy", since: nappy, link: "nappy")) }
        return all
    }
}

/// A word over a time, or beside it. The same on every widget.
private struct FactView: View {
    let fact: Fact
    let now: Date
    var beside = false
    var large = false

    var body: some View {
        let label = HStack(spacing: 3) {
            if let glyph = fact.glyph { Glyph(glyph, size: large ? 14 : 12) } else { Image(systemName: "sun.max").font(.system(size: large ? 12 : 10, weight: .semibold)) }
            Text(fact.title)
        }
        .font((large ? Font.footnote : .caption2).weight(.medium))
        .foregroundStyle(.secondary)
        let value = SinceValue(since: fact.since, now: now)
            .font((large ? Font.title3 : .subheadline).weight(.semibold))
            .monospacedDigit()
        Group {
            if beside {
                HStack(spacing: 6) { label; Spacer(minLength: 4); value }
            } else {
                // Its own size, so the facts in a row sit the same distance apart whatever their times read.
                VStack(alignment: .leading, spacing: 0) { label; value }
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A fact is also the way in: a tap opens Puggle at the sheet for the next one, for that child. It never
/// logs by itself (Tom, 15 November 2026).
private struct FactLink<Face: View>: View {
    let fact: Fact
    let child: WidgetSnapshot.Child
    @ViewBuilder let face: () -> Face

    var body: some View {
        Link(destination: PuggleLink.log(fact.link, child: child.id)) { face() }
    }
}

private struct ChildBadge: View {
    let child: WidgetSnapshot.Child
    var size: CGFloat = 30

    var body: some View {
        Text(String(child.name.prefix(1)))
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(WTone.badgeInk)
            .frame(width: size, height: size)
            .background(WTone.child(child.colourIndex), in: Circle())
    }
}

/// How long after a nappy the widget's button offers Undo.
private let undoWindow: TimeInterval = 60

/// Refreshes every 15 minutes so "ago" stays right; the app also refreshes it on every change.
private func familyTimeline(_ snapshot: WidgetSnapshot?, chosen: String? = nil) -> Timeline<FamilyEntry> {
    let now = Date.now
    var times = (0..<8).map { now.addingTimeInterval(Double($0) * 15 * 60) }
    // Straight after a nappy the button offers Undo; add a moment when it goes back.
    for nappy in (snapshot?.children ?? []).compactMap(\.lastNappy) {
        let over = nappy.addingTimeInterval(undoWindow + 1)
        if over > now { times.append(over) }
    }
    // When a "next" line's time passes, the widget is drawn again without it.
    for next in (snapshot?.children ?? []).compactMap(\.nextAt) where next > now { times.append(next.addingTimeInterval(1)) }
    let entries = times.sorted().map { FamilyEntry(date: $0, snapshot: snapshot, chosenID: chosen) }
    return Timeline(entries: entries, policy: .after(now.addingTimeInterval(2 * 3600)))
}

// MARK: One child (small)

struct ChildWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Child"
    static var description = IntentDescription("Choose whose day to show.")
    @Parameter(title: "Child") var child: WidgetChild?
}

struct ChildProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> FamilyEntry { FamilyEntry(date: .now, snapshot: .preview) }
    func snapshot(for configuration: ChildWidgetIntent, in context: Context) async -> FamilyEntry {
        FamilyEntry(date: .now, snapshot: context.isPreview ? .preview : (WidgetSnapshot.load() ?? .preview), chosenID: configuration.child?.id)
    }
    func timeline(for configuration: ChildWidgetIntent, in context: Context) async -> Timeline<FamilyEntry> {
        familyTimeline(WidgetSnapshot.load(), chosen: configuration.child?.id)
    }
}

struct ChildWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "puggle.child", intent: ChildWidgetIntent.self, provider: ChildProvider()) { entry in
            ChildWidgetView(entry: entry).fontDesign(.rounded)
        }
        .configurationDisplayName("One child")
        // As plain text: WidgetKit stops the whole extension, Live Activity included, on a description with a
        // value put into it.
        .description(Text(verbatim: "Last feed, sleep and \(Terms.nappyLower) for one child. Also on the Lock Screen."))
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

private struct ChildWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FamilyEntry

    var body: some View {
        if let child = entry.chosen {
            let facts = child.facts(now: entry.date)
            switch family {
            case .accessoryInline:
                // One line beside the date: the name and the first fact.
                Group {
                    if let first = facts.first { Text("\(child.name): \(first.title) ") + sinceText(first.since, now: entry.date) } else { Text(child.name) }
                }
                .containerBackground(for: .widget) { Color.clear }
            case .accessoryRectangular:
                // Under the clock on the Lock Screen: the name, then up to two facts.
                VStack(alignment: .leading, spacing: 1) {
                    Text(child.name).font(.headline).lineLimit(1)
                    ForEach(facts.prefix(2)) { fact in
                        (Text(fact.title + " ") + sinceText(fact.since, now: entry.date)).font(.subheadline).monospacedDigit().lineLimit(1)
                    }
                    if facts.isEmpty { Text("Nothing logged yet").font(.subheadline) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerBackground(for: .widget) { Color.clear }
            default:
                let asleep = child.asleepSince != nil
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        ChildBadge(child: child, size: 28)
                        Text(child.name).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                    if facts.isEmpty {
                        Text("Nothing logged yet").font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(facts.prefix(3)) { FactView(fact: $0, now: entry.date, beside: true) }
                    }
                }
                .foregroundStyle(asleep ? WTone.moon : WTone.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .containerBackground(for: .widget) { asleep ? WTone.night : WTone.paper }
            }
        } else {
            EmptyWidget()
        }
    }
}

// MARK: The family at a glance (medium and large)

struct SnapshotWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "puggle.snapshot", provider: FamilyProvider()) { entry in
            SnapshotWidgetView(entry: entry).fontDesign(.rounded)
        }
        .configurationDisplayName("Family snapshot")
        .description("Every child's last feed, sleep and change, side by side.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct SnapshotWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FamilyEntry

    var body: some View {
        Group {
            if let children = entry.snapshot?.children, !children.isEmpty {
                // As many rows as fit: three on a medium widget, six on a large one. The rest are counted.
                let room = family == .systemLarge ? 6 : 3
                let shown = Array(children.prefix(room))
                VStack(alignment: .leading, spacing: 0) {
                    if family == .systemLarge, children.count <= 4 {
                        // The large widget has the room for the day so far and what comes next (Tom, 15 November 2026).
                        ForEach(children) { child in
                            block(child, roomy: children.count <= 3).frame(maxHeight: .infinity)
                            if child.id != children.last?.id { Divider().opacity(0.5) }
                        }
                    } else if children.count == 1, let only = children.first {
                        alone(only)
                    } else {
                        ForEach(shown) { child in
                            row(child).frame(maxHeight: .infinity)
                            if child.id != shown.last?.id { Divider().opacity(0.5) }
                        }
                        if children.count > shown.count {
                            Text("and \(children.count - shown.count) more in Puggle").font(.caption2).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .foregroundStyle(WTone.ink)
                .containerBackground(for: .widget) { WTone.paper }
            } else {
                EmptyWidget()
            }
        }
    }

    /// One child has the widget to themselves: the facts get the room.
    private func alone(_ child: WidgetSnapshot.Child) -> some View {
        let facts = child.facts(now: entry.date)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ChildBadge(child: child, size: 34)
                Text(child.name).font(.title3.weight(.semibold)).lineLimit(1)
            }
            Spacer(minLength: 0)
            if facts.isEmpty {
                Text("Nothing logged yet today").font(.subheadline).foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 20) { ForEach(facts) { fact in FactLink(fact: fact, child: child) { FactView(fact: fact, now: entry.date, large: true) } } }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// A child on the large widget: their name, the three facts, the day so far and what comes next.
    private func block(_ child: WidgetSnapshot.Child, roomy: Bool) -> some View {
        let facts = child.facts(now: entry.date)
        let next: String? = child.nextAt.flatMap { $0 > entry.date ? child.nextText : nil }
        return VStack(alignment: .leading, spacing: roomy ? 6 : 3) {
            HStack(spacing: 8) {
                ChildBadge(child: child, size: roomy ? 30 : 24)
                Text(child.name).font((roomy ? Font.headline : .subheadline).weight(.semibold)).lineLimit(1)
                Spacer(minLength: 8)
                if let next {
                    Text(next).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            if facts.isEmpty {
                Text("Nothing logged yet today").font(.subheadline).foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: roomy ? 20 : 16) {
                    ForEach(facts.prefix(3)) { fact in FactLink(fact: fact, child: child) { FactView(fact: fact, now: entry.date, large: roomy) } }
                }
            }
            if let today = child.today {
                Text("Today · " + today)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(roomy ? 2 : 1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ child: WidgetSnapshot.Child) -> some View {
        let facts = child.facts(now: entry.date)
        return HStack(spacing: 10) {
            ChildBadge(child: child, size: 28)
            Text(child.name).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75)
                .frame(width: 64, alignment: .leading)
            if facts.isEmpty {
                Text("Nothing logged yet today").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // The same gap between each fact, from the left, in line with "Nothing logged yet today".
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) { ForEach(facts.prefix(3)) { fact in FactLink(fact: fact, child: child) { FactView(fact: fact, now: entry.date) } } }
                    HStack(alignment: .top, spacing: 10) { ForEach(facts.prefix(3)) { fact in FactLink(fact: fact, child: child) { FactView(fact: fact, now: entry.date) } } }
                    HStack(alignment: .top, spacing: 10) { ForEach(facts.prefix(2)) { fact in FactLink(fact: fact, child: child) { FactView(fact: fact, now: entry.date) } } }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: The family (medium)

struct FamilyProvider: TimelineProvider {
    func placeholder(in context: Context) -> FamilyEntry { FamilyEntry(date: .now, snapshot: .preview) }
    func getSnapshot(in context: Context, completion: @escaping (FamilyEntry) -> Void) {
        completion(FamilyEntry(date: .now, snapshot: context.isPreview ? .preview : (WidgetSnapshot.load() ?? .preview)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FamilyEntry>) -> Void) {
        completion(familyTimeline(WidgetSnapshot.load()))
    }
}

struct FamilyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "puggle.family", provider: FamilyProvider()) { entry in
            FamilyWidgetView(entry: entry).fontDesign(.rounded)
        }
        .configurationDisplayName("Quick log")
        // Fixed text: WidgetKit stops the widget if this is built from a value that changes.
        .description("Start a sleep or log a change for any child, without opening the app.")
        .supportedFamilies([.systemMedium])
    }
}

private struct FamilyWidgetView: View {
    let entry: FamilyEntry

    var body: some View {
        Group {
            if let children = entry.snapshot?.children, !children.isEmpty {
                // The rows share the height, so two children do not leave the bottom half empty.
                VStack(spacing: 0) {
                    ForEach(Array(children.prefix(3))) { child in
                        row(child, compact: children.count > 2).frame(maxHeight: .infinity)
                    }
                }
                .containerBackground(for: .widget) { WTone.paper }
            } else {
                EmptyWidget()
            }
        }
    }

    private func row(_ child: WidgetSnapshot.Child, compact: Bool) -> some View {
        HStack(spacing: 10) {
            ChildBadge(child: child, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(child.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                // Short, so it is never cut off beside the buttons: the first fact, or nothing.
                Group {
                    if let first = child.facts(now: entry.date).first {
                        Text(first.title + " ") + sinceText(first.since, now: entry.date)
                    } else {
                        Text("Nothing yet")
                    }
                }
                .font(.caption)
                .foregroundStyle(WTone.muted)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            // The words take what the buttons leave. A time that counts by itself asks for all the width there
            // is, and with first call on it, it squeezed the buttons down to their icons (Tom, 15 November 2026).
            .frame(maxWidth: .infinity, alignment: .leading)
            if child.usesNappies && !compact {
                // For a minute after a nappy, the button takes it back: a stray tap is easy on the Home Screen.
                if let nappy = child.lastNappy, entry.date.timeIntervalSince(nappy) < undoWindow, entry.date >= nappy.addingTimeInterval(-5) {
                    button("Undo", symbol: "arrow.uturn.backward", action: TimerActions.undoNappy, child: child, filled: false)
                } else {
                    button(Terms.nappy, symbol: "glyph-nappy", action: TimerActions.nappyWet, child: child, filled: false)
                }
            }
            if child.asleepSince != nil {
                button("Woke", symbol: "sun.max", action: TimerActions.wokeUp, child: child, filled: true)
            } else {
                button("Sleep", symbol: "glyph-sleep", action: TimerActions.startSleep, child: child, filled: true)
            }
        }
        .foregroundStyle(WTone.ink)
    }

    private func button(_ title: String, symbol: String, action: String, child: WidgetSnapshot.Child, filled: Bool) -> some View {
        Button(intent: TimerActionIntent(action, childID: child.id)) {
            // "glyph-…" is one of Puggle's own icons; anything else is one of Apple's symbols.
            Label {
                Text(title)
            } icon: {
                if symbol.hasPrefix("glyph-") {
                    Glyph(String(symbol.dropFirst(6)), size: 15)
                } else {
                    Image(systemName: symbol)
                }
            }
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 30)
                // Always its own size, whatever is beside it.
                .fixedSize()
                .foregroundStyle(filled ? WTone.paper : WTone.ink)
                .background(filled ? WTone.ink : WTone.field, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action == TimerActions.undoNappy ? "Undo the \(Terms.nappyLower) just logged for \(child.name)"
                            : action == TimerActions.nappyWet ? "Log a wet \(Terms.nappyLower) for \(child.name)"
                            : action == TimerActions.wokeUp ? "\(child.name) woke up" : "Start \(child.name)'s sleep")
    }
}

/// Before the app has been opened (or in the free test build): a gentle prompt.
private struct EmptyWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Glyph("sleep", size: 28)
            Text("No children to show. Open the app to add one.").font(.subheadline)
        }
        .foregroundStyle(WTone.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { WTone.paper }
    }
}

// MARK: Tiles for one child (medium)

/// Log for one child (built 16 November 2026, drawn as "Log for one child, tiles" in
/// `docs/previews/widgets/family.png`). Four tiles, each the fact and the way in: it opens that sheet in
/// Puggle. The shape is from Huckleberry; one ink and Puggle's icons, not a colour for every activity.
struct TilesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "puggle.tiles", intent: ChildWidgetIntent.self, provider: ChildProvider()) { entry in
            TilesWidgetView(entry: entry).fontDesign(.rounded)
        }
        .configurationDisplayName("Log for one child")
        // Fixed text: WidgetKit stops the extension on a description with a value put into it.
        .description("Their sleep, last feed and more as tiles. Tap one to log the next.")
        .supportedFamilies([.systemMedium])
    }
}

/// One tile: what it is, how long since, and where a tap goes.
private struct Tile: Identifiable {
    let title: String
    let glyph: String?
    let since: Date?
    let link: String
    var asleep = false
    var id: String { link }
}

private extension WidgetSnapshot.Child {
    /// Up to four tiles: the sleep, the feed, the nappy or the potty, and solids. Only what the child uses.
    func tiles(now: Date) -> [Tile] {
        let recent = { (date: Date?) -> Date? in date.flatMap { now.timeIntervalSince($0) < 24 * 3600 && $0 <= now.addingTimeInterval(60) ? $0 : nil } }
        var all: [Tile] = []
        if let asleep = asleepSince {
            all.append(Tile(title: "Asleep", glyph: "sleep", since: asleep, link: "asleep", asleep: true))
        } else {
            all.append(Tile(title: "Awake", glyph: "sleep", since: recent(lastWoke), link: "awake"))
        }
        if usesMilk ?? (lastFeed != nil) { all.append(Tile(title: "Fed", glyph: "bottle", since: recent(lastFeed), link: "fed")) }
        if pottyTraining == true {
            all.append(Tile(title: "Potty", glyph: "potty", since: recent(lastPotty), link: "potty"))
        } else if usesNappies {
            all.append(Tile(title: Terms.nappy, glyph: "nappy", since: recent(lastNappy), link: "nappy"))
        }
        if usesSolids == true { all.append(Tile(title: "Solids", glyph: "solids", since: recent(lastSolids), link: "ate")) }
        return Array(all.prefix(4))
    }
}

private struct TilesWidgetView: View {
    let entry: FamilyEntry

    var body: some View {
        if let child = entry.chosen {
            let tiles = child.tiles(now: entry.date)
            VStack(alignment: .leading, spacing: 8) {
                // Whose tiles they are, small, since the widget may be one of several.
                HStack(spacing: 6) {
                    ChildBadge(child: child, size: 18)
                    Text(child.name).font(.caption.weight(.semibold)).lineLimit(1)
                }
                let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(tiles) { tile in
                        Link(destination: PuggleLink.log(tile.link, child: child.id)) { face(tile) }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .foregroundStyle(WTone.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) { WTone.paper }
        } else {
            EmptyWidget()
        }
    }

    private func face(_ tile: Tile) -> some View {
        HStack(spacing: 8) {
            if let glyph = tile.glyph { Glyph(glyph, size: 20) }
            VStack(alignment: .leading, spacing: 0) {
                Text(tile.title).font(.caption2.weight(.medium)).opacity(0.75)
                Group {
                    if let since = tile.since { SinceValue(since: since, now: entry.date) } else { Text("–") }
                }
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            }
            Spacer(minLength: 2)
            Image(systemName: "plus").font(.caption.weight(.semibold)).opacity(0.6)
        }
        .lineLimit(1)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .foregroundStyle(tile.asleep ? WTone.moon : WTone.ink)
        .background(tile.asleep ? WTone.night : WTone.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Puggle to log it")
    }
}

// MARK: Control Centre

@available(iOS 18.0, *)
struct StartSleepControlIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Start sleep"
    static var description = IntentDescription("Starts a child's sleep timer.")
    @Parameter(title: "Child") var child: WidgetChild?
}

@available(iOS 18.0, *)
struct StartSleepControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "puggle.startSleep", intent: StartSleepControlIntent.self) { configuration in
            let child = configuration.child ?? WidgetSnapshot.load()?.children.first.map { WidgetChild(id: $0.id, name: $0.name) }
            ControlWidgetButton(action: TimerActionIntent(TimerActions.startSleep, childID: child?.id ?? "")) {
                Label(child.map { "Sleep: \($0.name)" } ?? "Start sleep", systemImage: "moon.fill")
            }
        }
        .displayName("Start sleep")
        .description("Starts a sleep timer for the child you choose.")
    }
}
