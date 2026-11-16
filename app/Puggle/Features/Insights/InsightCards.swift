import SwiftUI

/// Everything Insights shows for one child and one stretch of time, worked out once when something changes
/// and not each time the screen is drawn.
struct InsightModel {
    var days: [InsightStats.Day] = []
    /// The stretch of the same length just before, to set this one against.
    var before: [InsightStats.Day] = []
    /// The four weeks before the stretch: what "usual" is taken from.
    var earlier: [InsightStats.Day] = []
    var usualDay = InsightStats.UsualDay()
    var changes: [ChildPatterns.Change] = []
    var tin: FormulaDay?
    /// Milestones in the last thirty days, newest first.
    var firsts: [String] = []

    @MainActor
    static func make(child: Child, days count: Int, store: FamilyStore, now: Date = .now) -> InsightModel {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        func back(_ days: Int) -> Date { calendar.date(byAdding: .day, value: -days, to: today) ?? today }
        let from = back(count * 2 + 29)
        let live = (child.events ?? []).filter { $0.isLive && ($0.endedAt ?? $0.startedAt ?? .distantPast) >= from }
        let entries = live.compactMap { InsightStats.Entry($0, now: now) }
        // Whole days only: the stretch ends yesterday. Today is not over, and a part-day beside whole ones
        // reads as a drop; today is on the Today tab.
        let all = InsightStats.days(entries, from: from, to: back(1))
        var model = InsightModel()
        model.days = Array(all.suffix(count))
        model.before = Array(all.dropLast(count).suffix(count))
        model.earlier = Array(all.dropLast(count).suffix(28))
        model.usualDay = InsightStats.usualDay(entries, from: back(14), to: today)
        model.changes = Patterns.make(child: child, now: now).changes
        model.tin = child.birthDate.flatMap { store.formulaGuide()?.table?.formulaDay(birth: $0, now: now) }
        model.firsts = live.filter { $0.kind == .milestone && ($0.startedAt ?? .distantPast) >= back(30) }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
            .map { ($0.detail ?? "").isEmpty ? ($0.note ?? "A first") : $0.detail! }
        return model
    }
}

extension InsightStats.Day {
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

/// How Insights writes amounts.
enum InsightWords {
    /// "9h 20m", "45m".
    static func hours(_ seconds: Double) -> String {
        let minutes = Int((seconds / 60).rounded())
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(String(format: "%02d", m))m"
    }

    static func trim(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...1))) }

    static func amount(_ value: Double, _ metric: InsightMetric) -> String {
        switch metric {
        case .sleep: hours(value * 3600)
        case .bottles: "\(trim(value.rounded())) \(Units.volumeUnit)"
        default: trim(value)
        }
    }

    static func standing(_ standing: InsightStats.Standing, name: String) -> String {
        switch standing {
        case .within: "Within \(name)\u{2019}s usual"
        case .more: "More than \(name)\u{2019}s usual"
        case .less: "Less than \(name)\u{2019}s usual"
        }
    }

    /// "40 min longer than last week", "About the same".
    static func compared(_ change: InsightStats.Compared, as kind: Kind, to before: String) -> (symbol: String, text: String) {
        func size(_ amount: Double) -> String {
            switch kind {
            case .time: Elapsed.short(seconds: amount)
            case .volume: Units.volume(amount)
            case .count: trim(amount)
            }
        }
        switch change {
        case .same: return ("equal", "About the same as \(before)")
        case .more(let amount): return ("arrow.up", "\(size(amount)) \(kind == .time ? "longer" : "more") than \(before)")
        case .less(let amount): return ("arrow.down", "\(size(amount)) \(kind == .time ? "shorter" : (kind == .count ? "fewer" : "less")) than \(before)")
        }
    }

    enum Kind { case time, volume, count }
}

// MARK: The usual-range chart

/// A stretch of days as dots, on a soft band of what is usual for this child. Tap a day to read it.
struct UsualRangeChart: View {
    let name: String
    let title: String
    let model: InsightModel
    let metric: InsightMetric
    @Binding var picked: Date?

    var body: some View {
        let values = model.days.map { $0.value(metric) }
        let usual = InsightStats.usual(model.earlier.map { $0.value(metric) })
        let average = InsightStats.average(values, leavingOutLast: false)
        let chosen = model.days.first { $0.id == picked }
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(chosen.map { $0.id.formatted(.dateTime.weekday(.wide).day().month(.wide)) } ?? title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(InsightWords.amount(chosen.map { $0.value(metric) } ?? average ?? 0, metric))
                        .displayFont(34)
                        .contentTransition(.numericText())
                    if chosen == nil { Text("a day").font(.subheadline.weight(.semibold)).foregroundStyle(Palette.muted) }
                }
                // In words, in the same calm colour whichever way it falls (Tom, 16 November 2026).
                if let usual, let value = chosen.map({ $0.value(metric) }) ?? average, value > 0 {
                    Label(InsightWords.standing(InsightStats.standing(value, in: usual), name: name), systemImage: "circle.fill")
                        .labelStyle(DotLabel())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(metric.colour)
                } else if usual == nil {
                    Text("\(name)\u{2019}s usual shows after a week or so of entries.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
            }
            .accessibilityElement(children: .combine)
            plot(values, usual: usual)
        }
    }

    private func plot(_ values: [Double], usual: ClosedRange<Double>?) -> some View {
        let logged = values.filter { $0 > 0 }
        let low = min(logged.min() ?? 0, usual?.lowerBound ?? .infinity)
        let high = max(logged.max() ?? 1, usual?.upperBound ?? 0)
        let pad = max((high - low) * 0.2, high * 0.05, 0.5)
        let bottom = max(low - pad, 0), top = high + pad
        let wide = model.days.count <= 7
        return HStack(alignment: .top, spacing: 8) {
            GeometryReader { box in
                let step = box.size.width / CGFloat(max(values.count, 1))
                let y: (Double) -> CGFloat = { box.size.height * CGFloat(1 - ($0 - bottom) / (top - bottom)) }
                let x: (Int) -> CGFloat = { step * (CGFloat($0) + 0.5) }
                ZStack(alignment: .topLeading) {
                    if let usual {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(metric.colour.opacity(0.18))
                            .frame(height: max(y(usual.lowerBound) - y(usual.upperBound), 6))
                            .offset(y: y(usual.upperBound))
                        Text("\(name)\u{2019}s usual")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(metric.colour)
                            .offset(x: 6, y: max(y(usual.upperBound) - 16, 0))
                    }
                    // A line through the days that have something; a day with nothing is a gap, not a nought.
                    Path { path in
                        var drawing = false
                        for (index, value) in values.enumerated() {
                            guard value > 0 else { drawing = false; continue }
                            let point = CGPoint(x: x(index), y: y(value))
                            if drawing { path.addLine(to: point) } else { path.move(to: point) }
                            drawing = true
                        }
                    }
                    .stroke(metric.colour.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    ForEach(Array(model.days.enumerated()), id: \.element.id) { index, day in
                        let value = values[index]
                        let today = false
                        let dimmed = picked != nil && picked != day.id
                        if value > 0 {
                            // Today is not over, so its dot is open.
                            Circle()
                                .fill(today ? Palette.paper : metric.colour)
                                .overlay(Circle().stroke(metric.colour, lineWidth: today ? 2.5 : 0))
                                .frame(width: wide ? (today ? 13 : 10) : 5, height: wide ? (today ? 13 : 10) : 5)
                                .opacity(dimmed ? 0.35 : 1)
                                .position(x: x(index), y: y(value))
                        }
                        Color.clear
                            .frame(width: step, height: box.size.height)
                            .contentShape(Rectangle())
                            .position(x: x(index), y: box.size.height / 2)
                            .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { picked = picked == day.id ? nil : day.id } }
                            .accessibilityElement()
                            .accessibilityLabel(day.id.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .accessibilityValue(value > 0 ? InsightWords.amount(value, metric) : "Nothing logged")
                            .accessibilityAddTraits(picked == day.id ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
            .frame(height: 140)
            VStack(alignment: .trailing) {
                Text(axis(top))
                Spacer(minLength: 0)
                Text(axis((top + bottom) / 2))
                Spacer(minLength: 0)
                Text(axis(bottom))
            }
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(Palette.muted)
            .frame(height: 140)
            .accessibilityHidden(true)
        }
        .overlay(alignment: .bottom) {
            // Days along the bottom: each one in a week, one in seven across a month.
            HStack(spacing: 0) {
                ForEach(Array(model.days.enumerated()), id: \.element.id) { index, day in
                    let shown = wide || (model.days.count - 1 - index).isMultiple(of: 7)
                    Text(shown ? (wide ? day.id.formatted(.dateTime.weekday(.abbreviated)) : day.id.formatted(.dateTime.day())) : "")
                        .font(wide ? .footnote : .caption2)
                        .foregroundStyle(picked == day.id ? Palette.ink : Palette.muted)
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.trailing, 44)
            .offset(y: 22)
            .accessibilityHidden(true)
        }
        .padding(.bottom, 22)
    }

    private func axis(_ value: Double) -> String {
        metric == .sleep ? "\(InsightWords.trim(value.rounded()))h" : InsightWords.trim(value >= 10 ? value.rounded() : value)
    }
}

private struct DotLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.system(size: 7))
            configuration.title
        }
    }
}

// MARK: The recap

/// The stretch in cards, after Gentler Streak's monthly recap: each a short sentence, one figure, a note
/// against the stretch before, and a small chart of its own.
struct RecapCards: View {
    let name: String
    let model: InsightModel
    /// "last week" or "the month before".
    let before: String
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let cards = self.cards
        if !cards.isEmpty {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: textSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                ForEach(cards) { $0 }
            }
        }
    }

    private var cards: [RecapCard] {
        var result: [RecapCard] = []
        let days = model.days, earlier = model.before
        func mean(_ list: [InsightStats.Day], _ pick: (InsightStats.Day) -> Double) -> Double? {
            InsightStats.average(list.map(pick), leavingOutLast: false)
        }
        func chip(_ now: Double, _ then: Double?, _ kind: InsightWords.Kind) -> (symbol: String, text: String)? {
            InsightStats.compare(now, with: then).map { InsightWords.compared($0, as: kind, to: before) }
        }

        // Nights: the longest unbroken stretch.
        let nights = days.map(\.longestNight)
        if let longest = nights.max(), longest >= 3600 {
            result.append(RecapCard(id: "nights", label: "Nights", lead: "The longest stretch was", figure: InsightWords.hours(longest), unit: nil,
                                    compared: chip(longest, earlier.map(\.longestNight).max(), .time),
                                    art: AnyView(MiniBars(values: nights, colour: Palette.night))))
        }
        // Day and night.
        if let byDay = mean(days, \.daySleep), let byNight = mean(days, \.nightSleep), byDay + byNight > 0 {
            result.append(RecapCard(id: "daynight", label: "Day and night", lead: "\(name) slept by day for", figure: InsightWords.hours(byDay), unit: "a day",
                                    compared: chip(byDay, mean(earlier, \.daySleep), .time),
                                    art: AnyView(VStack(alignment: .leading, spacing: 6) {
                                        SplitBar(parts: [(byNight, Palette.night), (byDay, InsightColour.sleep)])
                                        Legend(items: [("Night", Palette.night), ("Day", InsightColour.sleep)])
                                    })))
        }
        // Milk, beside the tin.
        if let milk = mean(days, \.bottleML), milk > 0 {
            result.append(RecapCard(id: "milk", label: "Milk", lead: "Bottles came to", figure: Units.volume(milk.rounded()), unit: "a day",
                                    compared: chip(milk, mean(earlier, \.bottleML), .volume),
                                    art: AnyView(VStack(alignment: .leading, spacing: 6) {
                                        MiniBars(values: days.map(\.bottleML), colour: InsightColour.feeds)
                                        if let tin = model.tin {
                                            Text("The tin suggests about \(Units.volume(Double(tin.total)))").font(.caption2).foregroundStyle(Palette.muted)
                                        }
                                    })))
        }
        // Feeds, split by bottle and breast where there are both.
        if let feeds = mean(days, { Double($0.feeds) }), feeds > 0 {
            let bottles = days.reduce(0) { $0 + $1.bottles }, breast = days.reduce(0) { $0 + $1.breastfeeds }
            let art: AnyView = bottles > 0 && breast > 0
                ? AnyView(HStack(spacing: 10) {
                    InsightRing(parts: [(Double(bottles), InsightColour.feeds), (Double(breast), InsightColour.solids)], thickness: 13, gap: 4, corner: 4).frame(width: 64, height: 64)
                    Legend(items: [("Bottle \(bottles)", InsightColour.feeds), ("Breast \(breast)", InsightColour.solids)], stacked: true)
                })
                : AnyView(MiniBars(values: days.map { Double($0.feeds) }, colour: InsightColour.feeds))
            result.append(RecapCard(id: "feeds", label: "Feeds", lead: "\(name) fed", figure: InsightWords.trim(feeds), unit: "times a day",
                                    compared: chip(feeds, mean(earlier, { Double($0.feeds) }), .count), art: art))
        }
        // Nappies and the potty are counted, not averaged.
        let nappies = days.reduce(0) { $0 + $1.nappies }
        if nappies > 0 {
            let wet = days.reduce(0) { $0 + $1.wet }, dirty = days.reduce(0) { $0 + $1.dirty }
            result.append(RecapCard(id: "nappies", label: Terms.nappies, lead: "There were", figure: "\(nappies)", unit: nil,
                                    compared: chip(Double(nappies), Double(earlier.reduce(0) { $0 + $1.nappies }), .count),
                                    art: AnyView(VStack(alignment: .leading, spacing: 6) {
                                        Tally(count: nappies, colour: InsightColour.nappies)
                                        if wet + dirty > 0 { Legend(items: [("Wet \(wet)", InsightColour.nappies), ("Dirty \(dirty)", Palette.muted)]) }
                                    })))
        }
        let potty = days.reduce(0) { $0 + $1.potty }
        if potty > 0 {
            result.append(RecapCard(id: "potty", label: "Potty", lead: "\(name) used the potty", figure: "\(potty)", unit: potty == 1 ? "time" : "times",
                                    compared: chip(Double(potty), Double(earlier.reduce(0) { $0 + $1.potty }), .count),
                                    art: AnyView(Tally(count: potty, colour: InsightColour.potty))))
        }
        if !model.firsts.isEmpty {
            result.append(RecapCard(id: "firsts", label: "Firsts", lead: "New in the last month", figure: "\(model.firsts.count)", unit: nil,
                                    compared: ("sparkle", model.firsts.prefix(2).joined(separator: " · ")),
                                    art: AnyView(EmptyView())))
        }
        return result
    }
}

struct RecapCard: View, Identifiable {
    let id: String
    let label: String
    let lead: String
    let figure: String
    let unit: String?
    let compared: (symbol: String, text: String)?
    let art: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(Palette.muted).kerning(0.4)
            Text(lead).font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true).padding(.top, 2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(figure).displayFont(24).lineLimit(1).minimumScaleFactor(0.7)
                if let unit { Text(unit).font(.caption.weight(.semibold)).foregroundStyle(Palette.muted) }
            }
            if let compared {
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: compared.symbol)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 17, height: 17)
                        .background(Palette.field, in: Circle())
                    Text(compared.text).font(.caption).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 1)
            }
            Spacer(minLength: 8)
            art
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label). \(lead) \(figure)\(unit.map { " \($0)" } ?? ""). \(compared?.text ?? "")")
    }
}

/// A bar for each day; the last is at full strength.
struct MiniBars: View {
    let values: [Double]
    let colour: Color

    var body: some View {
        let top = max(values.max() ?? 1, 0.0001)
        HStack(alignment: .bottom, spacing: values.count > 10 ? 1.5 : 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: values.count > 10 ? 1.5 : 4, style: .continuous)
                    .fill(colour.opacity(index == values.count - 1 ? 1 : 0.5))
                    .frame(height: value > 0 ? max(4, 44 * value / top) : 2)
                    .opacity(value > 0 ? 1 : 0.3)
            }
        }
        .frame(height: 44, alignment: .bottom)
    }
}

/// One bar shared out between two or three things.
struct SplitBar: View {
    let parts: [(value: Double, colour: Color)]

    var body: some View {
        GeometryReader { box in
            let total = max(parts.reduce(0) { $0 + $1.value }, 0.0001)
            HStack(spacing: 3) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(part.colour)
                        .frame(width: max((box.size.width - 3 * CGFloat(parts.count - 1)) * part.value / total, 6))
                }
            }
        }
        .frame(height: 40)
    }
}

/// A small square for each one counted, so a number can be seen as a heap.
struct Tally: View {
    let count: Int
    let colour: Color

    var body: some View {
        let shown = min(count, 66)
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(9), spacing: 3), count: 11), alignment: .leading, spacing: 3) {
            ForEach(0..<shown, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2.5, style: .continuous).fill(colour).frame(width: 9, height: 9)
            }
        }
    }
}

struct Legend: View {
    let items: [(text: String, colour: Color)]
    var stacked = false

    var body: some View {
        let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 3)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Circle().fill(item.colour).frame(width: 8, height: 8)
                    Text(item.text).font(.caption2).foregroundStyle(Palette.muted).lineLimit(1)
                }
            }
        }
    }
}

// MARK: A usual day

/// The child's usual day round a 24-hour clock, midnight at the top: when they are usually asleep, where the
/// feeds usually fall, and a marker for now.
struct UsualDayClock: View {
    let name: String
    let day: InsightStats.UsualDay
    var now: Date = .now

    var body: some View {
        let hour = Double(Calendar.current.component(.hour, from: now)) + Double(Calendar.current.component(.minute, from: now)) / 60
        let asleepNow = day.asleep(atHour: hour)
        VStack(spacing: 10) {
            Canvas { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 34
                func point(_ hour: Double, _ r: CGFloat) -> CGPoint {
                    let angle = (hour / 24) * 2 * .pi - .pi / 2
                    return CGPoint(x: centre.x + r * cos(angle), y: centre.y + r * sin(angle))
                }
                func arc(_ from: Double, _ to: Double) -> Path {
                    Path { path in
                        path.addArc(center: centre, radius: radius, startAngle: .degrees(from * 15 - 90), endAngle: .degrees(to * 15 - 90), clockwise: false)
                    }
                }
                context.stroke(Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)),
                               with: .color(Palette.field), lineWidth: 22)
                for run in day.sleepRuns {
                    // By the clock: asleep in the dark hours is the night, in daylight a nap.
                    let middle = ((run.from + run.to) / 2).truncatingRemainder(dividingBy: 24)
                    let night = middle >= 19 || middle < 7
                    context.stroke(arc(run.from, run.to), with: .color((night ? Palette.night : InsightColour.sleep).opacity(0.55 + 0.45 * run.share)),
                                   style: StrokeStyle(lineWidth: 22, lineCap: .round))
                }
                for time in day.feedTimes {
                    let at = point(time, radius - 24)
                    context.fill(Path(ellipseIn: CGRect(x: at.x - 5, y: at.y - 5, width: 10, height: 10)), with: .color(InsightColour.feeds))
                }
                for (hour, label) in [(0.0, "Midnight"), (6, "6 am"), (12, "Noon"), (18, "6 pm")] {
                    context.draw(Text(label).font(.caption2).foregroundStyle(Palette.muted), at: point(hour, radius + 23))
                }
                let here = point(hour, radius)
                context.fill(Path(ellipseIn: CGRect(x: here.x - 8, y: here.y - 8, width: 16, height: 16)), with: .color(Palette.paper))
                context.stroke(Path(ellipseIn: CGRect(x: here.x - 6.5, y: here.y - 6.5, width: 13, height: 13)), with: .color(Palette.ink), lineWidth: 3)
            }
            .frame(height: 280)
            .overlay {
                VStack(spacing: 0) {
                    Text(asleepNow ? "Asleep" : "Awake").displayFont(24)
                    Text("about now, most days").font(.caption).foregroundStyle(Palette.muted)
                }
            }
            Legend(items: [("Night sleep", Palette.night), ("Naps", InsightColour.sleep), ("Feeds", InsightColour.feeds)])
            Text("From the last two weeks.").font(.caption2).foregroundStyle(Palette.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name)\u{2019}s usual day")
        .accessibilityValue(spoken(asleepNow))
    }

    private func spoken(_ asleepNow: Bool) -> String {
        func clock(_ hour: Double) -> String {
            let minutes = Int((hour.truncatingRemainder(dividingBy: 24)) * 60)
            return Patterns.clock(minute: minutes)
        }
        let sleeps = day.sleepRuns.map { "asleep from \(clock($0.from)) to \(clock($0.to))" }
        let feeds = day.feedTimes.isEmpty ? [] : ["feeds around " + day.feedTimes.map(clock).joined(separator: ", ")]
        return (["Usually \(asleepNow ? "asleep" : "awake") about now"] + sleeps + feeds).joined(separator: "; ")
    }
}

// MARK: What is changing

/// A few sentences on how the child's days have changed, each with an arrow, after Apple Fitness's Trends.
/// The sentences are the ones Patterns already works out.
struct ChangingList: View {
    let changes: [ChildPatterns.Change]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(changes.prefix(4).enumerated()), id: \.offset) { index, change in
                if index > 0 { Divider().padding(.leading, 46) }
                HStack(alignment: .top, spacing: 12) {
                    let way = Self.direction(of: change.text)
                    Image(systemName: way.symbol)
                        .font(.footnote.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(way.colour, in: Circle())
                        .foregroundStyle(Palette.fixedInk)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(change.text).font(.body.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                        if let detail = change.detail {
                            Text(detail).font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// Which way a sentence points, from its own words. Neither way is good or bad: the colours only tell them apart.
    static func direction(of text: String) -> (symbol: String, colour: Color) {
        let words = text.lowercased()
        let up = ["longer", "more", "later", "up from", "bigger"], down = ["shorter", "fewer", "less", "earlier", "down from", "dropped", "smaller"]
        if up.contains(where: words.contains) { return ("arrow.up", Color(hex: 0xCFE5D2)) }
        if down.contains(where: words.contains) { return ("arrow.down", Color(hex: 0xF4E7B0)) }
        return ("arrow.right", Color(hex: 0xEAE2D2))
    }
}
