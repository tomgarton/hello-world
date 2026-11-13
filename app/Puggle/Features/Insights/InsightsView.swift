import SwiftUI

/// Look back without scores. One child and one stretch of time at a once:
/// a chart of one thing by day, last night, and a ring of what was logged.
/// Week and Month are totals and counts. Patterns shows how a child's own days
/// have changed with age. Never targets, normal ranges or comparing with other
/// people's children; comparing siblings only when a parent switches it on.
/// (Decided 13 November 2026: averages are allowed for a child's own history.)
struct InsightsView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)],
                  predicate: NSPredicate(format: "archived != YES")) private var children: FetchedResults<Child>
    @State private var chosen: Child?
    @State private var period = InsightPeriod.week

    private var child: Child? { chosen.flatMap { picked in children.first { $0 == picked } } ?? children.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if children.count > 1 { childPicker }
                    if let child {
                        ChildInsights(child: child, period: $period, others: children.filter { $0 != child })
                            .id(child.objectID)
                    } else {
                        Text("Insights appear once a child has been added.")
                            .foregroundStyle(Palette.muted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.sand)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var childPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(children) { one in
                    let on = one == child
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { chosen = one }
                    } label: {
                        HStack(spacing: 8) {
                            ChildAvatar(child: one, size: 28)
                            Text(one.displayName).font(.subheadline.weight(.semibold))
                        }
                        .padding(.leading, 6)
                        .padding(.trailing, 14)
                        .frame(minHeight: 44)
                        .foregroundStyle(on ? Palette.paper : Palette.ink)
                        .background(on ? Palette.ink : Palette.paper, in: Capsule())
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }
}

enum InsightPeriod: String, CaseIterable, Identifiable {
    case week, month, patterns
    var id: String { rawValue }
    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .patterns: "Patterns"
        }
    }
    var days: Int { self == .month ? 30 : 7 }
    var words: String { self == .week ? "the last seven days" : "the last thirty days" }
}

/// What the chart can show.
enum InsightMetric: String, CaseIterable, Identifiable {
    case sleep, feeds, bottles, nappies, potty
    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: "Sleep"
        case .feeds: "Feeds"
        case .bottles: "Bottles"
        case .nappies: Terms.nappies
        case .potty: "Potty"
        }
    }

    var colour: Color {
        switch self {
        case .sleep: InsightColour.sleep
        case .feeds, .bottles: InsightColour.feeds
        case .nappies: InsightColour.nappies
        case .potty: InsightColour.potty
        }
    }
}

/// One colour for each kind of thing, the same in the chart, the ring and the list.
/// Mid-tones, so they sit on the paper by day and after dark.
enum InsightColour {
    static let sleep = Color(light: 0x5A7FB8, dark: 0x7C9FD6, night: 0x6D86B0)
    static let feeds = Color(light: 0xD9A441, dark: 0xE5B556, night: 0xB8924A)
    static let solids = Color(light: 0xE5855F, dark: 0xEE9674, night: 0xBD7A60)
    static let nappies = Color(light: 0x4E9A8C, dark: 0x69B3A5, night: 0x5C9488)
    static let potty = Color(light: 0x9483D4, dark: 0xA999E4, night: 0x8C80BA)
    static let other = Color(light: 0x8E9A5B, dark: 0xA5B170, night: 0x8A9363)
}

struct ChildInsights: View {
    @ObservedObject var child: Child
    @Binding var period: InsightPeriod
    var others: [Child] = []
    @State private var metric = InsightMetric.sleep
    /// A bar that has been tapped, to read its day.
    @State private var picked: Date?

    private var events: [Event] { Array(child.events ?? []).filter(\.isLive) }

    struct Day: Identifiable {
        let id: Date
        var sleep = 0.0
        var sleeps = 0
        var bottleML = 0.0
        var feeds = 0
        var solids = 0
        var nappies = 0
        var potty = 0
        var other = 0

        func value(_ metric: InsightMetric) -> Double {
            switch metric {
            case .sleep: sleep / 3600
            case .feeds: Double(feeds)
            case .bottles: Units.volumeValue(bottleML)
            case .nappies: Double(nappies)
            case .potty: Double(potty)
            }
        }
    }

    private var days: [Day] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var result: [Day] = []
        for offset in (0..<period.days).reversed() {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            var day = Day(id: start)
            for event in events {
                guard let at = event.startedAt else { continue }
                if event.kind == .sleep {
                    day.sleep += event.asleepSeconds(from: max(at, start), to: min(event.endedAt ?? .now, end))
                    if at >= start && at < end { day.sleeps += 1 }
                } else if at >= start && at < end {
                    switch event.kind {
                    case .bottle: day.bottleML += event.amountML; day.feeds += 1
                    case .breastfeed: day.feeds += 1
                    case .solids: day.solids += 1
                    case .nappy: day.nappies += 1
                    case .potty: day.potty += 1
                    default: day.other += 1
                    }
                }
            }
            result.append(day)
        }
        return result
    }

    var body: some View {
        if period == .patterns {
            VStack(alignment: .leading, spacing: 16) {
                periodPicker
                PatternsView(child: child, others: others)
            }
            .foregroundStyle(Palette.ink)
        } else {
            periodBody
        }
    }

    /// Week, Month or Patterns: a pill in the app's own colours.
    private var periodPicker: some View {
            HStack(spacing: 4) {
                ForEach(InsightPeriod.allCases) { one in
                    let on = one == period
                    Button(one.title) {
                        withAnimation(.easeInOut(duration: 0.2)) { period = one; picked = nil }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(on ? Palette.ink : Palette.muted)
                    .background(on ? Palette.field : Color.clear, in: Capsule())
                    .contentShape(Capsule())
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Palette.paper, in: Capsule())
    }

    private var periodBody: some View {
        let days = days
        let metrics = InsightMetric.allCases.filter { metric in days.contains { $0.value(metric) > 0 } }
        let showing = metrics.contains(metric) ? metric : (metrics.first ?? .sleep)
        return VStack(alignment: .leading, spacing: 16) {
            periodPicker

            if let first = days.first?.id, let last = days.last?.id {
                Text(rangeTitle(first, last))
                    .displayFont(30)
                    .accessibilityAddTraits(.isHeader)
            }

            if metrics.isEmpty {
                Text("Nothing logged for \(child.displayName) in \(period.words).")
                    .foregroundStyle(Palette.muted)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                chart(days, metrics: metrics, showing: showing)
                lastNight
                logged(days)
            }
        }
        .foregroundStyle(Palette.ink)
    }

    /// "7 to 13 Nov", or "28 Oct to 3 Nov" across a month's end.
    private func rangeTitle(_ first: Date, _ last: Date) -> String {
        let sameMonth = Calendar.current.isDate(first, equalTo: last, toGranularity: .month)
        let start = first.formatted(sameMonth ? .dateTime.day() : .dateTime.day().month(.abbreviated))
        return "\(start) to \(last.formatted(.dateTime.day().month(.abbreviated)))"
    }

    // MARK: The chart

    private func chart(_ days: [Day], metrics: [InsightMetric], showing: InsightMetric) -> some View {
        let values = days.map { $0.value(showing) }
        let top = niceTop(values.max() ?? 0)
        let chosen = days.first { $0.id == picked }
        return VStack(alignment: .leading, spacing: 14) {
            // The thing being shown, then its total, or one day's when a bar is tapped.
            VStack(alignment: .leading, spacing: 2) {
                Text(chosen.map { $0.id.formatted(.dateTime.weekday(.wide).day().month(.wide)) } ?? "\(showing.title), \(period.words)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                Text(amount(chosen.map { $0.value(showing) } ?? values.reduce(0, +), showing))
                    .displayFont(34)
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)

            HStack(alignment: .top, spacing: 8) {
                GeometryReader { geometry in
                    let height = geometry.size.height
                    ZStack(alignment: .bottom) {
                        // Three faint lines to read the bars against.
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { line in
                                Rectangle().fill(Palette.ink.opacity(0.1)).frame(height: 1)
                                if line < 2 { Spacer(minLength: 0) }
                            }
                        }
                        HStack(alignment: .bottom, spacing: period == .week ? 10 : 3) {
                            ForEach(days) { day in
                                let value = day.value(showing)
                                let dimmed = picked != nil && picked != day.id
                                RoundedRectangle(cornerRadius: period == .week ? 8 : 3, style: .continuous)
                                    .fill(showing.colour.opacity(dimmed ? 0.35 : 1))
                                    .frame(height: value > 0 ? max(4, height * value / top) : 0)
                                    .frame(maxWidth: period == .week ? 34 : .infinity, maxHeight: .infinity, alignment: .bottom)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeOut(duration: 0.15)) { picked = picked == day.id ? nil : day.id }
                                    }
                                    // Each bar is read as its day and its amount, and can be chosen like a button.
                                    .accessibilityElement()
                                    .accessibilityLabel(day.id.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                    .accessibilityValue(value > 0 ? axis(value, showing) : "Nothing logged")
                                    .accessibilityAddTraits(picked == day.id ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                    }
                }
                .frame(height: 150)
                // What the lines stand for, down the right-hand side.
                VStack(alignment: .leading) {
                    Text(axis(top, showing))
                    Spacer(minLength: 0)
                    Text(axis(top / 2, showing))
                    Spacer(minLength: 0)
                    Text(axis(0, showing))
                }
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.muted)
                .frame(height: 150)
                .offset(y: -6)
                .accessibilityHidden(true)
            }
            // Days along the bottom: each one in a week, one in seven across a month.
            HStack(spacing: period == .week ? 10 : 3) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    let shown = period == .week || (days.count - 1 - index).isMultiple(of: 7)
                    Text(shown ? (period == .week ? day.id.formatted(.dateTime.weekday(.abbreviated)) : day.id.formatted(.dateTime.day())) : "")
                        .font(period == .week ? .footnote : .caption2)
                        .foregroundStyle(picked == day.id ? Palette.ink : Palette.muted)
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.trailing, 36)
            .accessibilityHidden(true)

            if metrics.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(metrics) { one in
                            let on = one == showing
                            Button(one.title) {
                                withAnimation(.easeInOut(duration: 0.2)) { metric = one; picked = nil }
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .foregroundStyle(on ? Palette.paper : Palette.ink)
                            .background(on ? Palette.ink : Palette.field, in: Capsule())
                            .buttonStyle(PressStyle())
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(showing.title), \(period.words)")
        .accessibilityValue(days.map { "\($0.id.formatted(.dateTime.weekday(.wide).day())) \(amount($0.value(showing), showing))" }.joined(separator: ", "))
    }

    /// A round number a little above the tallest bar.
    private func niceTop(_ value: Double) -> Double {
        guard value > 0 else { return 1 }
        for step in [2.0, 4, 6, 8, 10, 12, 16, 20, 24, 30, 40, 50, 60, 80, 100, 150, 200, 300, 400, 500, 600, 800, 1000, 1500, 2000, 3000] where value <= step {
            return step
        }
        return (value / 1000).rounded(.up) * 1000
    }

    private func amount(_ value: Double, _ metric: InsightMetric) -> String {
        switch metric {
        case .sleep: hours(value * 3600)
        case .bottles: "\(trim(value)) \(Units.volumeUnit)"
        default: "\(Int(value))"
        }
    }

    private func axis(_ value: Double, _ metric: InsightMetric) -> String {
        metric == .sleep ? "\(trim(value)) h" : trim(value)
    }

    private func trim(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...1))) }

    /// "9h 20m", "45m", "71h".
    private func hours(_ seconds: Double) -> String {
        let minutes = Int((seconds / 60).rounded())
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 || h >= 24 ? "\(h)h" : "\(h)h \(m)m"
    }

    // MARK: Last night

    /// The pieces of sleep that fall between 6 pm yesterday and noon today.
    private var nightPieces: [(start: Date, end: Date, open: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let from = calendar.date(byAdding: .hour, value: -6, to: today),
              let noon = calendar.date(byAdding: .hour, value: 12, to: today) else { return [] }
        let to = min(noon, .now)
        var pieces: [(start: Date, end: Date, open: Bool)] = []
        for sleep in events where sleep.kind == .sleep {
            // Night wakings show as gaps.
            let parts = sleep.asleepPieces(from: from, to: to)
            for (index, piece) in parts.enumerated() where piece.duration >= 60 {
                pieces.append((piece.start, piece.end, sleep.endedAt == nil && index == parts.count - 1))
            }
        }
        return pieces.sorted { $0.start < $1.start }
    }

    @ViewBuilder private var lastNight: some View {
        let pieces = nightPieces
        if let first = pieces.first, let last = pieces.last {
            let total = pieces.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
            let longest = pieces.map { $0.end.timeIntervalSince($0.start) }.max() ?? 0
            HStack(alignment: .top, spacing: 12) {
                tile("Last night", hours(total),
                     last.open ? "From \(first.start.formatted(date: .omitted, time: .shortened)), still asleep"
                               : "\(first.start.formatted(date: .omitted, time: .shortened)) to \(last.end.formatted(date: .omitted, time: .shortened))")
                tile("Longest stretch", hours(longest),
                     pieces.count > 1 ? "\(pieces.count - 1) waking\(pieces.count == 2 ? "" : "s")" : "Slept through")
            }
        }
    }

    private func tile(_ title: String, _ value: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            Text(value).displayFont(26)
            Text(note).font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: What was logged

    private struct Slice: Identifiable {
        let id: String
        let title: String
        let kind: EventKind
        let colour: Color
        let count: Int
        let note: String
    }

    private func logged(_ days: [Day]) -> some View {
        let bottle = days.reduce(0.0) { $0 + $1.bottleML }
        let all: [Slice] = [
            Slice(id: "sleep", title: "Sleep", kind: .sleep, colour: InsightColour.sleep,
                  count: days.reduce(0) { $0 + $1.sleeps }, note: hours(days.reduce(0.0) { $0 + $1.sleep })),
            Slice(id: "feeds", title: "Feeds", kind: .bottle, colour: InsightColour.feeds,
                  count: days.reduce(0) { $0 + $1.feeds }, note: bottle > 0 ? "\(Units.volume(bottle)) by bottle" : ""),
            Slice(id: "solids", title: "Solids", kind: .solids, colour: InsightColour.solids,
                  count: days.reduce(0) { $0 + $1.solids }, note: ""),
            Slice(id: "nappies", title: Terms.nappies, kind: .nappy, colour: InsightColour.nappies,
                  count: days.reduce(0) { $0 + $1.nappies }, note: ""),
            Slice(id: "potty", title: "Potty", kind: .potty, colour: InsightColour.potty,
                  count: days.reduce(0) { $0 + $1.potty }, note: ""),
            Slice(id: "other", title: "Everything else", kind: .note, colour: InsightColour.other,
                  count: days.reduce(0) { $0 + $1.other }, note: ""),
        ]
        // Largest first, so the ring reads from its biggest block round to its smallest.
        let slices = all.filter { $0.count > 0 }.sorted { $0.count > $1.count }
        let total = slices.reduce(0) { $0 + $1.count }
        return VStack(alignment: .leading, spacing: 18) {
            Text("What was logged").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            ZStack {
                InsightRing(parts: slices.map { (Double($0.count), $0.colour) })
                VStack(spacing: 0) {
                    Text("\(total)").displayFont(40)
                    Text("Logged this \(period.title.lowercased())").font(.footnote).foregroundStyle(Palette.muted)
                }
            }
            .frame(width: 236, height: 236)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(total) entries in \(period.words)")

            VStack(spacing: 0) {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    if index > 0 { Divider().padding(.leading, 56) }
                    HStack(spacing: 12) {
                        ActivityIcon(slice.kind, size: 24, plain: true)
                            .frame(width: 44, height: 44)
                            .background(slice.colour.opacity(0.32), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(slice.title).font(.body.weight(.semibold))
                            if !slice.note.isEmpty {
                                Text(slice.note).font(.footnote).foregroundStyle(Palette.muted)
                            }
                        }
                        Spacer(minLength: 8)
                        Text("\(slice.count)").font(.body.weight(.semibold)).monospacedDigit()
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// A thick ring in separate blocks with softly rounded corners, one for each
/// kind of thing: the largest first from the top, going round clockwise. A
/// small share shows as a rounded square, never a dot.
struct InsightRing: View {
    let parts: [(value: Double, colour: Color)]
    var thickness: CGFloat = 38
    /// The space between two blocks, in points.
    var gap: CGFloat = 7
    var corner: CGFloat = 9

    var body: some View {
        GeometryReader { geometry in
            let outer = min(geometry.size.width, geometry.size.height) / 2
            let pieces = shares(middle: outer - thickness / 2)
            ZStack {
                ForEach(pieces.indices, id: \.self) { index in
                    let block = RingBlock(from: pieces[index].start, to: pieces[index].start + pieces[index].share,
                                          thickness: thickness, gap: parts.count > 1 ? gap : 0, corner: corner)
                    // Filling and then outlining the block in its own colour rounds its corners.
                    block.fill(parts[index].colour)
                    block.stroke(parts[index].colour, style: StrokeStyle(lineWidth: corner * 2, lineJoin: .round))
                }
            }
        }
    }

    /// Each part's share of the ring. A small one is given enough to be a square.
    private func shares(middle: CGFloat) -> [(start: Double, share: Double)] {
        let total = max(parts.reduce(0) { $0 + $1.value }, 0.0001)
        let least = Double((thickness + gap) / (2 * .pi * max(middle, 1)))
        var raw = parts.map { max($0.value / total, least) }
        let sum = raw.reduce(0, +)
        raw = raw.map { $0 / sum }
        var start = 0.0
        return raw.map { share in
            defer { start += share }
            return (start, share)
        }
    }
}

/// One block of the ring, drawn smaller by its corner all round so that an outline of that width brings it back to size.
struct RingBlock: Shape {
    /// Where it starts and ends, as fractions of the way round from the top.
    let from: Double
    let to: Double
    let thickness: CGFloat
    let gap: CGFloat
    let corner: CGFloat

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let middle = outer - thickness / 2
        // Pull each end in by half the gap and by the corner.
        let pull = Double((gap / 2 + corner) / max(middle, 1))
        var start = from * 2 * .pi - .pi / 2 + pull
        var end = to * 2 * .pi - .pi / 2 - pull
        if end < start {
            let mid = (start + end) / 2
            start = mid - 0.001
            end = mid + 0.001
        }
        var path = Path()
        path.addArc(center: centre, radius: outer - corner, startAngle: .radians(start), endAngle: .radians(end), clockwise: false)
        path.addArc(center: centre, radius: outer - thickness + corner, startAngle: .radians(end), endAngle: .radians(start), clockwise: true)
        path.closeSubpath()
        return path
    }
}
