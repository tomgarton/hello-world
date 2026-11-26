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
    /// What comes next, soonest first.
    var coming: [Coming]
    /// Whether the iPhone sent any guesses at all (an older Puggle there sends none).
    var guessed: Bool
    /// Today's feeds, meals, nappies and potty trips.
    var marks: [WidgetSnapshot.Mark]

    init(child: WidgetSnapshot.Child, now: Date = .now) {
        let midnight = Calendar.current.startOfDay(for: now)
        // Only what touches today: after midnight a summary from yesterday still has yesterday's naps in it.
        sleeps = child.sleepsToday.map { $0.filter { ($0.end ?? now) > midnight } }
        days = child.sleepDays(now: now)
        marks = (child.marksToday ?? []).filter { $0.at >= midnight && $0.at <= now }
        guessed = child.coming != nil
        // Those gone by are left out where they are shown, minute by minute (`NextPage`).
        coming = (child.coming ?? []).sorted { $0.at < $1.at }.map { next in
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
        // Only those already over, so none is cut short at now and read as "awake for 0 min".
        var sleeps = made.filter { at($0.1) <= now }.map { WidgetSnapshot.Stretch(start: at($0.0), end: at($0.1), sleep: $0.2) }
        if let since = child.asleepSince { sleeps.append(WidgetSnapshot.Stretch(start: since, end: nil, sleep: 9)) }
        child.sleepsToday = sleeps
        let milk = child.usesMilk == true
        child.sleepDays = milk ? [13.9, 12.8, 14.2, nil, 13.6, 12.4, 13.1, 14.4, 11.2, 13.8, 14.9, 13.3, 12.9, 13.7]
                               : [11.6, 12.1, 11.2, 11.9, 12.4, 10.8, 11.5, 11.9, 12.2, nil, 11.1, 12.6, 11.8, 11.4]
        child.coming = child.asleepSince != nil ? [] : [WidgetSnapshot.Coming(kind: "sleep", at: now.addingTimeInterval(70 * 60))]
        if milk { child.coming?.append(WidgetSnapshot.Coming(kind: "feed", at: now.addingTimeInterval(125 * 60))) }
        let made2: [(String, Double)] = milk
            ? [("feed", 2.3), ("nappy", 2.4), ("feed", 6.8), ("nappy", 7.0), ("meal", 8.2), ("feed", 8.7), ("nappy", 9.1), ("feed", 12.0), ("nappy", 12.6), ("feed", 15.2), ("nappy", 16.0)]
            : [("meal", 7.3), ("potty", 7.6), ("meal", 10.0), ("potty", 10.4), ("meal", 12.2), ("potty", 13.0), ("meal", 15.3), ("potty", 16.1)]
        child.marksToday = made2.filter { at($0.1) <= now }.map { WidgetSnapshot.Mark(kind: $0.0, at: at($0.1)) }
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
    /// Whether this is the child showing. Swiping away puts their pages back to Now, so swiping to a child
    /// always arrives on the page with their name.
    var selected = true
    @State private var page = Pages.first
    @State private var toTop = 0
    /// The day it is, so the pages are drawn again when it changes: at midnight with the app open, or on
    /// coming back to it in a new day. The fourteen days then move on by one (`sleepDays(now:)`).
    @State private var today = Calendar.current.startOfDay(for: .now)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let _ = today
        let figures = DayFigures(child: child)
        let tint = Tone.child(child.colourIndex)
        NavigationStack {
            TabView(selection: $page) {
                ChildPage(child: child, paged: true, toTop: toTop, showing: page == 0)
                    // The three colours lie one on another and cross over, so falling asleep goes to night
                    // over a moment and waking comes back.
                    .containerBackground(for: .tabView) {
                        ZStack {
                            ground(tint.opacity(0.28))
                            ground(Tone.honey).opacity(child.feedingSince != nil ? 1 : 0)
                            ground(Tone.night).opacity(child.asleepSince != nil ? 1 : 0)
                        }
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: child.asleepSince != nil)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: child.feedingSince != nil)
                    }
                    .navigationTitle { Text(child.name).foregroundStyle(tint) }
                    .tag(0)
                SleepTodayPage(child: child, figures: figures, current: page == 1)
                    .containerBackground(ground(Tone.night), for: .tabView)
                    .navigationTitle { Text("Sleep today").foregroundStyle(tint) }
                    .tag(1)
                NextPage(child: child, figures: figures)
                    .containerBackground(ground(Tone.night), for: .tabView)
                    .navigationTitle { Text("Next").foregroundStyle(tint) }
                    .tag(2)
                FortnightPage(child: child, figures: figures, current: page == 3)
                    .containerBackground(ground(Tone.night), for: .tabView)
                    .navigationTitle { Text("Last 14 days").foregroundStyle(tint) }
                    .tag(3)
            }
            .tabViewStyle(.verticalPage)
            .toolbar {
                // Whose pages these are, in the corner on every page. Tapping it goes back to Now.
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptic.tap()
                        toTop += 1
                        withAnimation { page = 0 }
                    } label: { Badge(child: child, size: 30) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(child.name), now")
                }
            }
        }
        .tint(tint)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            today = Calendar.current.startOfDay(for: .now)
        }
        // Swiping to another child puts these pages back to Now. Swiping back up to Now from the page under it
        // arrives at Now's top: `ChildPage` goes back there once it is out of sight (`showing`).
        .onChange(of: selected) { _, showing in
            if !showing { page = 0; toTop += 1 }
        }
        .task {
            // For checking without a swipe: "-previewTurn 1" with "-previewScroll 1" turns from the foot of
            // Now to Sleep today and back, as a swipe down and up would.
            guard UserDefaults.standard.bool(forKey: "previewTurn") else { return }
            try? await Task.sleep(for: .seconds(4))
            withAnimation { page = 1 }
            try? await Task.sleep(for: .seconds(4))
            withAnimation { page = 0 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = Calendar.current.startOfDay(for: .now) }
        }
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
    /// Whether tapping it opens a closer look: an arrow at its right says so.
    var opens = false

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            words
            if opens {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .rounded(34, .semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                // A figure rolls to its new value.
                .contentTransition(.numericText())
                .animation(.default, value: value)
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

/// A page as it is when it fits the screen, so one swipe turns it; scrolling only when it does not, on the
/// small Watch or with larger text. A page that always scrolled took two swipes to leave.
private struct Fitting<Content: View>: View {
    /// Whether this is the page showing. Left, it goes back to its top.
    var current = true
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            // With room left for the dots at the foot of the screen, or it counts as not fitting.
            content.padding(.bottom, 14).frame(maxHeight: .infinity, alignment: .top)
            ScrollViewReader { scroller in
                ScrollView {
                    content
                        .padding(.bottom, 16)
                        .id("top")
                }
                .onChange(of: current) { _, showing in
                    if !showing { scroller.scrollTo("top", anchor: .top) }
                }
            }
        }
        // Measured against the whole screen below the title. The Watch keeps a deep margin free above the
        // dots, and a page only a few points into it would scroll by those few points.
        .ignoresSafeArea(.container, edges: .bottom)
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
    /// Whether this is the page showing, so the strip can fill in as it arrives.
    var current = true
    @State private var drawn: CGFloat = 0
    @State private var scrubbing = UserDefaults.standard.string(forKey: "previewSheet") == "day"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let midnight = Calendar.current.startOfDay(for: now)
            let sleeps = figures.sleeps ?? []
            Fitting(current: current) {
                VStack(alignment: .leading, spacing: 5) {
                    // Tap it to look along the day with the crown.
                    Button {
                        Haptic.tap()
                        scrubbing = true
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            DayStrip(sleeps: sleeps, marks: figures.marks, now: now, drawn: drawn)
                                .frame(height: 64)
                            if !sleeps.isEmpty {
                                Figure(label: "Asleep today", value: hoursAndMinutes(figures.asleepToday(now: now)),
                                       detail: detail(midnight: midnight), tint: Tone.moon, opens: true)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(sleeps.isEmpty && figures.marks.isEmpty)
                    .accessibilityHint("Opens the day to look along")
                    if sleeps.isEmpty {
                        Text(figures.sleeps == nil ? "Open Puggle on your iPhone to see today's sleep." : "No sleep logged today.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    MarkKey(marks: figures.marks)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
            }
        }
        .onAppear { draw(current) }
        .onChange(of: current) { _, showing in draw(showing) }
        .sheet(isPresented: $scrubbing) {
            NavigationStack { DayScrub(child: child, sleeps: figures.sleeps ?? [], marks: figures.marks) }
                .tint(Tone.closeButton)
        }
    }

    /// The blocks fill in from the left as the page arrives, and are whole at once with Reduce Motion.
    private func draw(_ showing: Bool) {
        guard showing else { drawn = 0; return }
        if reduceMotion { drawn = 1 } else { withAnimation(.easeOut(duration: 0.7)) { drawn = 1 } }
    }

    /// "Up at 06:40 · 2 naps", and "2 naps · Bed at 19:30" once they are down for the night. A sleep that
    /// starts from 17:00 to 05:00 is the night and is not counted as a nap (`WidgetSnapshot.isNight`).
    private func detail(midnight: Date) -> String {
        let sleeps = figures.sleeps ?? []
        // Each sleep by its first stretch.
        let starts = Dictionary(sleeps.map { ($0.sleep, $0.start) }, uniquingKeysWith: min)
        let nights = starts.filter { WidgetSnapshot.isNight($0.value) }
        let morning = nights.filter { $0.value < midnight.addingTimeInterval(5 * 3600) }.max { $0.value < $1.value }?.key
        let evening = nights.filter { $0.value >= midnight.addingTimeInterval(17 * 3600) }.min { $0.value < $1.value }?.value
        var parts: [String] = []
        if let morning, let up = sleeps.last(where: { $0.sleep == morning })?.end, evening == nil { parts.append("Up at \(clock(up))") }
        let naps = starts.count - nights.count
        if naps > 0 { parts.append(naps == 1 ? "1 nap" : "\(naps) naps") }
        if let evening { parts.append("Bed at \(clock(evening))") }
        return parts.joined(separator: " · ")
    }
}

// MARK: Next

/// What comes next, the soonest bright and the one after it dimmer, as Sleep shows bedtime and waking.
struct NextPage: View {
    let child: WidgetSnapshot.Child
    let figures: DayFigures

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            // A guess is only shown ahead of time, as on the iPhone: once it has gone by it goes.
            let coming = figures.coming.filter { $0.at > context.date }
            Fitting {
                VStack(alignment: .leading, spacing: 10) {
                    if coming.isEmpty {
                        Text(child.asleepSince != nil ? "Asleep now. What's next shows when they wake."
                             : !figures.guessed ? "Open Puggle on your iPhone to see what's next."
                             : "No guess just now. They come from the last week of entries on your iPhone.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(coming.prefix(2).enumerated()), id: \.element.id) { index, coming in
                        let soon = coming.at.timeIntervalSince(context.date) < 60
                        VStack(alignment: .leading, spacing: 0) {
                            Label(coming.title, systemImage: coming.systemImage)
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundStyle(index == 0 ? Tone.moon : Tone.moon.opacity(0.75))
                            Text(clock(coming.at))
                                .rounded(34, .semibold)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                // The one after is quieter, and still clear enough to read.
                                .foregroundStyle(.white.opacity(index == 0 ? 1 : 0.8))
                            Text(soon ? "Around now" : "Around then, in \(Elapsed.short(from: context.date, to: coming.at))")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
            }
        }
    }
}

// MARK: Last 14 days

/// Sleep a day for two weeks, a week each side, with a line across each at its average.
struct FortnightPage: View {
    let child: WidgetSnapshot.Child
    let figures: DayFigures
    /// Whether this is the page showing, so the bars can rise as it arrives.
    var current = true
    @State private var drawn = false
    @State private var scrubbing = UserDefaults.standard.string(forKey: "previewSheet") == "days"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let days = figures.days ?? Array(repeating: nil, count: 14)
        let weeks = [Array(days.prefix(7)), Array(days.suffix(7))]
        let top = max(days.compactMap { $0 }.max() ?? 1, 1)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        Fitting(current: current) {
        VStack(alignment: .leading, spacing: 8) {
            // Tap them to go day by day with the crown.
            Button {
                Haptic.tap()
                scrubbing = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(0..<2, id: \.self) { index in
                        let last = Calendar.current.date(byAdding: .day, value: index == 0 ? -7 : 0, to: yesterday) ?? yesterday
                        let first = Calendar.current.date(byAdding: .day, value: -6, to: last) ?? last
                        week(weeks[index], top: top, from: first, to: last, order: index * 7)
                    }
                }
                if let recent = average(weeks[1]) {
                    Figure(label: "Asleep a day", value: hoursAndMinutes(recent * 3600), detail: "Average, last 7 days", tint: Tone.moon, opens: true)
                }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(figures.days == nil)
            .accessibilityHint("Opens the days one by one")
            if average(weeks[1]) == nil {
                Text(figures.days == nil ? "Open Puggle on your iPhone to see the last 14 days." : "No sleep logged in the last 7 days.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
        }
        .onAppear { drawn = current }
        .onChange(of: current) { _, showing in drawn = showing }
        .sheet(isPresented: $scrubbing) {
            NavigationStack { FortnightScrub(child: child, days: days) }
                .tint(Tone.closeButton)
        }
    }

    private func average(_ days: [Double?]) -> Double? {
        let known = days.compactMap { $0 }
        return known.isEmpty ? nil : known.reduce(0, +) / Double(known.count)
    }

    private func week(_ days: [Double?], top: Double, from: Date, to: Date, order: Int) -> some View {
        let mean = average(days)
        return VStack(alignment: .leading, spacing: 2) {
            Text(mean.map { hoursAndMinutes($0 * 3600) } ?? "–")
                .rounded(12, .semibold)
                .foregroundStyle(Tone.moon)
            GeometryReader { box in
                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(days.enumerated()), id: \.offset) { offset, hours in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(.white.opacity(hours == nil ? 0 : 0.45))
                                .frame(height: box.size.height * CGFloat((hours ?? 0) / top))
                                .frame(maxWidth: .infinity)
                                // Each bar rises from the baseline, one after the other.
                                .scaleEffect(y: drawn ? 1 : 0.02, anchor: .bottom)
                                .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2).delay(Double(order + offset) * 0.03), value: drawn)
                        }
                    }
                    Rectangle().fill(.white.opacity(0.22)).frame(height: 1)
                    if let mean {
                        Rectangle().fill(Tone.moon).frame(height: 1.5)
                            .offset(y: -box.size.height * CGFloat(mean / top))
                            .opacity(drawn ? 1 : 0)
                            .animation(reduceMotion ? nil : .easeIn(duration: 0.3).delay(0.45), value: drawn)
                    }
                }
            }
            .frame(height: 44)
            Text(range(from, to))
                .rounded(10, .medium)
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
