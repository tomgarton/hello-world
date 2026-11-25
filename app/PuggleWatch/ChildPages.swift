import SwiftUI

/// Each child as a few short pages turned with the Digital Crown, one idea a page, after Apple's Sleep and
/// Activity apps on the Watch (Tom, 26 November 2026). The single page (`ChildPage` by itself) is kept:
/// launch with "-singlePage 1" to see it.
enum Pages {
    static let on = !UserDefaults.standard.bool(forKey: "singlePage")
    /// For checking: "-previewPage 2" opens on the third page.
    static let first = UserDefaults.standard.integer(forKey: "previewPage")
}

/// What the pages past the first show, read from what the iPhone sent.
struct DayFigures {
    struct Coming: Identifiable {
        let title: String
        let systemImage: String
        let at: Date
        var id: String { title }
    }

    /// Each stretch asleep that touches today. Nil when the iPhone has not sent them (an older Puggle there).
    var sleeps: [WidgetSnapshot.Stretch]?
    /// Hours asleep on each of the last fourteen whole days, oldest first. Nil for a day with nothing logged.
    var days: [Double?]?
    /// What comes next, soonest first, and still to come.
    var coming: [Coming]

    init(child: WidgetSnapshot.Child, now: Date = .now) {
        sleeps = child.sleepsToday
        days = child.sleepDays
        coming = (child.coming ?? []).filter { $0.at > now }.sorted { $0.at < $1.at }.map { next in
            switch next.kind {
            case "sleep": Coming(title: "Next sleep", systemImage: "moon.fill", at: next.at)
            case "nappy": Coming(title: "Next \(Terms.nappyLower)", systemImage: "drop.fill", at: next.at)
            default: Coming(title: "Next feed", systemImage: "waterbottle.fill", at: next.at)
            }
        }
    }

    /// Made up, for "-preview 1": a night to 06:40 and two naps, a fortnight, and a sleep and a feed to come.
    static func fillSample(_ child: inout WidgetSnapshot.Child, now: Date = .now) {
        let midnight = Calendar.current.startOfDay(for: now)
        func at(_ hour: Double) -> Date { midnight.addingTimeInterval(hour * 3600) }
        // The night has a waking in it, so it is two stretches of one sleep.
        let made: [(Double, Double, Int)] = [(-4.9, 2.2, 0), (2.6, 6.67, 0), (9.25, 10.5, 1), (13.1, 14.6, 2)]
        var sleeps = made.filter { at($0.0) < now }.map { WidgetSnapshot.Stretch(start: at($0.0), end: min(at($0.1), now), sleep: $0.2) }
        if let since = child.asleepSince { sleeps.append(WidgetSnapshot.Stretch(start: since, end: nil, sleep: 9)) }
        child.sleepsToday = sleeps
        let milk = child.usesMilk == true
        child.sleepDays = milk ? [13.9, 12.8, 14.2, nil, 13.6, 12.4, 13.1, 14.4, 11.2, 13.8, 14.9, 13.3, 12.9, 13.7]
                               : [11.6, 12.1, 11.2, 11.9, 12.4, 10.8, 11.5, 11.9, 12.2, nil, 11.1, 12.6, 11.8, 11.4]
        child.coming = child.asleepSince != nil ? [] : [WidgetSnapshot.Coming(kind: "sleep", at: now.addingTimeInterval(70 * 60))]
        if milk { child.coming?.append(WidgetSnapshot.Coming(kind: "feed", at: now.addingTimeInterval(125 * 60))) }
    }

    /// Seconds asleep since midnight.
    func asleepToday(now: Date) -> TimeInterval {
        let midnight = Calendar.current.startOfDay(for: now)
        return (sleeps ?? []).reduce(0) { $0 + max(0, ($1.end ?? now).timeIntervalSince(max($1.start, midnight))) }
    }
}

/// One child: Now, Sleep today, Next, and the last fourteen days.
struct PagedChild: View {
    let child: WidgetSnapshot.Child
    @State private var page = Pages.first

    var body: some View {
        let figures = DayFigures(child: child)
        let tint = Tone.child(child.colourIndex)
        NavigationStack {
            TabView(selection: $page) {
                ChildPage(child: child, paged: true)
                    .containerBackground(ground(child.asleepSince != nil ? Tone.night : (child.feedingSince != nil ? Tone.honey : tint.opacity(0.28))), for: .tabView)
                    .navigationTitle(child.name)
                    .tag(0)
                SleepTodayPage(child: child, figures: figures)
                    .containerBackground(ground(Tone.night), for: .tabView)
                    .navigationTitle("Sleep today")
                    .tag(1)
                NextPage(child: child, figures: figures)
                    .containerBackground(ground(Tone.night), for: .tabView)
                    .navigationTitle("Next")
                    .tag(2)
                FortnightPage(child: child, figures: figures)
                    .containerBackground(ground(Tone.night), for: .tabView)
                    .navigationTitle("Last 14 days")
                    .tag(3)
            }
            .tabViewStyle(.verticalPage)
            .toolbar {
                // Whose pages these are, in the corner on every page. Tapping it goes back to Now.
                ToolbarItem(placement: .topBarLeading) {
                    Button { withAnimation { page = 0 } } label: { Badge(child: child, size: 30) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(child.name), now")
                }
            }
        }
        .tint(tint)
        // The page's name under the clock, in the child's colour.
        .toolbarForegroundStyle(tint, for: .navigationBar)
    }

    /// The colour at the top, fading to black at the foot, as Sleep and Activity do.
    private func ground(_ colour: Color) -> LinearGradient {
        LinearGradient(colors: [colour, .black], startPoint: .top, endPoint: .bottom)
    }
}

/// A small coloured label, a large figure and a grey line under it: the foot of each page.
private struct Figure: View {
    let label: String
    let value: String
    var detail: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let detail {
                Text(detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private func hoursAndMinutes(_ seconds: TimeInterval) -> String {
    Elapsed.short(from: Date(timeIntervalSinceReferenceDate: 0), to: Date(timeIntervalSinceReferenceDate: seconds))
}

private func clock(_ date: Date) -> String {
    date.formatted(date: .omitted, time: .shortened)
}

// MARK: Sleep today

/// Today from midnight to midnight as one strip, with a block for each sleep and a line at now.
struct SleepTodayPage: View {
    let child: WidgetSnapshot.Child
    let figures: DayFigures

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let midnight = Calendar.current.startOfDay(for: now)
            VStack(alignment: .leading, spacing: 8) {
                strip(now: now, midnight: midnight)
                    .frame(maxHeight: 64)
                if (figures.sleeps ?? []).isEmpty {
                    Text(figures.sleeps == nil ? "Open Puggle on your iPhone to see today's sleep." : "No sleep logged today.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Figure(label: "Asleep today", value: hoursAndMinutes(figures.asleepToday(now: now)), detail: detail(midnight: midnight), tint: Tone.moon)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
        }
    }

    /// "Up at 06:40 · 2 naps", from the night that ran into today and the sleeps that began today.
    private func detail(midnight: Date) -> String {
        var parts: [String] = []
        let sleeps = figures.sleeps ?? []
        // The night is the sleep that began before midnight; its last stretch says when they got up.
        let night = sleeps.first(where: { $0.start < midnight })?.sleep
        if let up = sleeps.last(where: { $0.sleep == night })?.end, night != nil { parts.append("Up at \(clock(up))") }
        let naps = Set(sleeps.filter { $0.sleep != night }.map(\.sleep)).count
        if naps > 0 { parts.append(naps == 1 ? "1 nap" : "\(naps) naps") }
        return parts.joined(separator: " · ")
    }

    private func strip(now: Date, midnight: Date) -> some View {
        GeometryReader { box in
            let width = box.size.width
            let barHeight = box.size.height - 16
            let x: (Date) -> CGFloat = { width * CGFloat(min(max($0.timeIntervalSince(midnight) / 86400, 0), 1)) }
            ZStack(alignment: .topLeading) {
                // A line and its hour every six hours.
                ForEach([0, 6, 12, 18], id: \.self) { hour in
                    let left = width * CGFloat(hour) / 24
                    Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: box.size.height).offset(x: left)
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .offset(x: left + 3, y: barHeight + 2)
                }
                Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: box.size.height).offset(x: width - 1)
                ForEach(figures.sleeps ?? [], id: \.self) { sleep in
                    let left = x(sleep.start), right = x(sleep.end ?? now)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Tone.moon)
                        .frame(width: max(right - left, 3), height: barHeight - 8)
                        .offset(x: left, y: 4)
                }
                // Now.
                Capsule().fill(.white).frame(width: 2, height: barHeight).offset(x: x(now) - 1)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: Next

/// What comes next, the soonest bright and the one after it dimmer, as Sleep shows bedtime and waking.
struct NextPage: View {
    let child: WidgetSnapshot.Child
    let figures: DayFigures

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 10) {
                if figures.coming.isEmpty {
                    Text(child.asleepSince != nil ? "Asleep now. What's next shows when they wake." : "Nothing to guess from yet. It takes a few days of entries.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(figures.coming.prefix(2).enumerated()), id: \.element.id) { index, coming in
                    VStack(alignment: .leading, spacing: 0) {
                        Label(coming.title, systemImage: coming.systemImage)
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundStyle(index == 0 ? Tone.moon : Color.secondary)
                        Text(clock(coming.at))
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Text("Around then, in \(Elapsed.short(from: context.date, to: coming.at))")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .opacity(index == 0 ? 1 : 0.6)
                    .accessibilityElement(children: .combine)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
        }
    }
}

// MARK: Last 14 days

/// Sleep a day for two weeks, a week each side, with a line across each at its average.
struct FortnightPage: View {
    let child: WidgetSnapshot.Child
    let figures: DayFigures

    var body: some View {
        let days = figures.days ?? Array(repeating: nil, count: 14)
        let weeks = [Array(days.prefix(7)), Array(days.suffix(7))]
        let top = max(days.compactMap { $0 }.max() ?? 1, 1)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(0..<2, id: \.self) { index in
                    let last = Calendar.current.date(byAdding: .day, value: index == 0 ? -7 : 0, to: yesterday) ?? yesterday
                    let first = Calendar.current.date(byAdding: .day, value: -6, to: last) ?? last
                    week(weeks[index], top: top, from: first, to: last)
                }
            }
            if let recent = average(weeks[1]) {
                Figure(label: "Asleep a day", value: hoursAndMinutes(recent * 3600), detail: "Average, last 7 days", tint: Tone.moon)
            } else {
                Text(figures.days == nil ? "Open Puggle on your iPhone to see the last 14 days." : "No sleep logged in the last 7 days.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
    }

    private func average(_ days: [Double?]) -> Double? {
        let known = days.compactMap { $0 }
        return known.isEmpty ? nil : known.reduce(0, +) / Double(known.count)
    }

    private func week(_ days: [Double?], top: Double, from: Date, to: Date) -> some View {
        let mean = average(days)
        return VStack(alignment: .leading, spacing: 2) {
            Text(mean.map { hoursAndMinutes($0 * 3600) } ?? "–")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Tone.moon)
            GeometryReader { box in
                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, hours in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(.white.opacity(hours == nil ? 0 : 0.45))
                                .frame(height: box.size.height * CGFloat((hours ?? 0) / top))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    Rectangle().fill(.white.opacity(0.22)).frame(height: 1)
                    if let mean {
                        Rectangle().fill(Tone.moon).frame(height: 1.5)
                            .offset(y: -box.size.height * CGFloat(mean / top))
                    }
                }
            }
            .frame(height: 44)
            Text(range(from, to))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mean.map { "\(range(from, to)), about \(hoursAndMinutes($0 * 3600)) a day" } ?? range(from, to))
    }

    /// "12 – 18 Nov", or "28 Nov – 4 Dec" across a month's end.
    private func range(_ from: Date, _ to: Date) -> String {
        let day = Date.FormatStyle().day()
        let dayMonth = Date.FormatStyle().day().month(.abbreviated)
        let sameMonth = Calendar.current.isDate(from, equalTo: to, toGranularity: .month)
        return "\(from.formatted(sameMonth ? day : dayMonth)) – \(to.formatted(dayMonth))"
    }
}
