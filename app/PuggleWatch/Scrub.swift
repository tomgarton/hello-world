import SwiftUI
import WatchKit

/// The day as one strip: a line every six hours, a block for each stretch asleep, a row of dots for feeds
/// and meals, a row of squares for nappies and the potty, and a marker.
/// On "Sleep today" the marker is now. Opened up (`DayScrub`) it is wherever the crown has been turned to.
struct DayStrip: View {
    let sleeps: [WidgetSnapshot.Stretch]
    var marks: [WidgetSnapshot.Mark] = []
    let now: Date
    /// How much of the blocks is drawn, from the left: 0 to 1. They fill in when the page arrives.
    var drawn: CGFloat = 1
    /// Where the crown is. Nil on the page, where the marker is now.
    var marker: Date?
    /// The sleep under the marker, which stays bright while the rest dim.
    var bright: Int?
    /// The mark the marker is on, drawn larger.
    var near: WidgetSnapshot.Mark?

    /// Feeds and meals are dots in the yellow of milk; nappies and the potty are squares in sea green.
    static func isFood(_ mark: WidgetSnapshot.Mark) -> Bool { mark.kind == "feed" || mark.kind == "meal" }

    var body: some View {
        let midnight = Calendar.current.startOfDay(for: now)
        GeometryReader { box in
            let width = box.size.width
            // Under the blocks: two rows of marks when there are any, then the hours.
            let rows: CGFloat = marks.isEmpty ? 0 : 16
            let barHeight = box.size.height - 16 - rows
            let x: (Date) -> CGFloat = { width * CGFloat(min(max($0.timeIntervalSince(midnight) / 86400, 0), 1)) }
            ZStack(alignment: .topLeading) {
                // A line and its hour every six hours.
                ForEach([0, 6, 12, 18], id: \.self) { hour in
                    let left = width * CGFloat(hour) / 24
                    Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: box.size.height).offset(x: left)
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .offset(x: left + 3, y: barHeight + rows + 2)
                }
                Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: box.size.height).offset(x: width - 1)
                ZStack(alignment: .topLeading) {
                    ForEach(sleeps, id: \.self) { sleep in
                        let left = x(sleep.start), right = x(sleep.end ?? now)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Tone.moon)
                            .opacity(marker == nil || bright == sleep.sleep ? 1 : 0.45)
                            .frame(width: max(right - left, 3), height: barHeight - 8)
                            .offset(x: left, y: 4)
                    }
                    ForEach(marks, id: \.self) { mark in
                        let food = Self.isFood(mark)
                        let size: CGFloat = near == mark ? 8 : 5
                        Group {
                            if food { Circle().fill(Tone.milk) } else { RoundedRectangle(cornerRadius: 1.5, style: .continuous).fill(Tone.sea) }
                        }
                        .frame(width: size, height: size)
                        .opacity(marker == nil || near == mark ? 1 : 0.6)
                        .offset(x: x(mark.at) - size / 2, y: barHeight + (food ? 4 : 12) - size / 2)
                    }
                }
                .frame(width: width, height: barHeight + rows, alignment: .topLeading)
                .mask(alignment: .leading) { Rectangle().frame(width: width * drawn + 4).offset(x: -4) }
                // Now: the marker on the page, a faint line once the crown has its own.
                Capsule().fill(.white.opacity(marker == nil ? 1 : 0.35)).frame(width: 2, height: barHeight).offset(x: x(now) - 1)
                if let marker {
                    Capsule().fill(.white).frame(width: 2, height: barHeight + rows).offset(x: x(marker) - 1)
                    Circle().fill(Tone.night).stroke(.white, lineWidth: 2).frame(width: 9, height: 9)
                        .offset(x: x(marker) - 4.5, y: barHeight / 2 - 4.5)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// What the dots and squares under the strip are, with how many: "● 4 feeds  ■ 3 nappies".
struct MarkKey: View {
    let marks: [WidgetSnapshot.Mark]

    var body: some View {
        let count: (String) -> Int = { kind in marks.filter { $0.kind == kind }.count }
        let some: (Int, String, String) -> String? = { n, one, many in n == 0 ? nil : (n == 1 ? "1 \(one)" : "\(n) \(many)") }
        let food = [some(count("feed"), "feed", "feeds"), some(count("meal"), "meal", "meals")].compactMap { $0 }.joined(separator: ", ")
        let changes = [some(count("nappy"), Terms.nappyLower, Terms.nappiesLower), some(count("potty"), "potty trip", "potty trips")].compactMap { $0 }.joined(separator: ", ")
        if !marks.isEmpty {
            HStack(spacing: 10) {
                if !food.isEmpty {
                    HStack(spacing: 4) { Circle().fill(Tone.milk).frame(width: 6, height: 6); Text(food) }
                }
                if !changes.isEmpty {
                    HStack(spacing: 4) { RoundedRectangle(cornerRadius: 1.5, style: .continuous).fill(Tone.sea).frame(width: 6, height: 6); Text(changes) }
                }
            }
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityElement(children: .combine)
        }
    }
}

/// "Sleep today", opened: turning the Digital Crown moves along the day, and the words under the strip say
/// what was happening then. A tick on the wrist at each falling asleep and each waking. After a tides app
/// Tom showed (26 November 2026).
struct DayScrub: View {
    let child: WidgetSnapshot.Child
    let sleeps: [WidgetSnapshot.Stretch]
    let marks: [WidgetSnapshot.Mark]
    private let now: Date
    private let midnight: Date
    /// Minutes after midnight. For checking: "-previewScrub 600" opens at 10:00.
    @State private var minute: Double

    init(child: WidgetSnapshot.Child, sleeps: [WidgetSnapshot.Stretch], marks: [WidgetSnapshot.Mark] = [], now: Date = .now) {
        self.child = child
        self.sleeps = sleeps
        self.marks = marks
        self.now = now
        midnight = Calendar.current.startOfDay(for: now)
        let upTo = now.timeIntervalSince(Calendar.current.startOfDay(for: now)) / 60
        let asked = UserDefaults.standard.double(forKey: "previewScrub")
        _minute = State(initialValue: asked > 0 ? min(asked, upTo) : upTo)
    }

    /// What the marker is on.
    private struct Moment: Equatable {
        var label: String
        var from: Date
        var to: Date?
        /// The sleep it is in, to keep bright. Nil when awake.
        var sleep: Int?
        /// Seconds to show large.
        var length: TimeInterval
    }

    private var time: Date { midnight.addingTimeInterval(minute * 60) }

    private func moment(at time: Date) -> Moment {
        let nightIndex = sleeps.first(where: { $0.start < midnight })?.sleep
        if let under = sleeps.first(where: { $0.start <= time && time < ($0.end ?? now.addingTimeInterval(1)) }) {
            let whole = sleeps.filter { $0.sleep == under.sleep }
            let from = whole.first?.start ?? under.start
            let to = whole.last?.end
            let asleep = whole.reduce(0) { $0 + ($1.end ?? now).timeIntervalSince($1.start) }
            return Moment(label: under.sleep == nightIndex ? "Night" : "Nap", from: from, to: to, sleep: under.sleep, length: asleep)
        }
        let before = sleeps.last(where: { ($0.end ?? .distantFuture) <= time })
        let after = sleeps.first(where: { $0.start > time })
        let from = before?.end ?? midnight
        let to = after?.start
        // Between two stretches of one sleep: a waking in it.
        let waking = before != nil && before?.sleep == after?.sleep
        return Moment(label: waking ? "Awake in the \(before?.sleep == nightIndex ? "night" : "nap")" : "Awake",
                      from: from, to: to, sleep: waking ? before?.sleep : nil, length: (to ?? now).timeIntervalSince(from))
    }

    /// The feed, meal, nappy or potty trip within eight minutes of the marker, the nearest first.
    private func mark(near time: Date) -> WidgetSnapshot.Mark? {
        marks.filter { abs($0.at.timeIntervalSince(time)) <= 8 * 60 }
            .min { abs($0.at.timeIntervalSince(time)) < abs($1.at.timeIntervalSince(time)) }
    }

    private func words(_ mark: WidgetSnapshot.Mark) -> String {
        let what = switch mark.kind {
        case "feed": "Fed"
        case "meal": "Ate"
        case "potty": "Potty"
        default: Terms.nappy
        }
        return "\(what) at \(clock(mark.at))"
    }

    var body: some View {
        let moment = moment(at: time)
        let near = mark(near: time)
        let tint = Tone.child(child.colourIndex)
        // At now the Watch's own clock already says the time, so the title says "Now".
        let atNow = abs(time.timeIntervalSince(now)) < 90
        VStack(alignment: .leading, spacing: 8) {
            DayStrip(sleeps: sleeps, marks: marks, now: now, marker: time, bright: moment.sleep, near: near)
                // A fixed height: on a small Watch a flexible one was squeezed until the blocks were lines.
                .frame(height: 68)
            VStack(alignment: .leading, spacing: 0) {
                Text(moment.label)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(Tone.moon)
                Text(Elapsed.short(from: moment.from, to: moment.from.addingTimeInterval(moment.length)))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                // On a feed or a nappy the line under says so; otherwise when this stretch began and ended.
                if let near {
                    Text(words(near))
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(DayStrip.isFood(near) ? Tone.milk : Tone.sea)
                } else {
                    Text(moment.to.map { "\(clock(moment.from)) – \(clock($0))" } ?? "Since \(clock(moment.from))")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .animation(.snappy(duration: 0.25), value: moment)
            .animation(.snappy(duration: 0.2), value: near)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .containerBackground(LinearGradient(colors: [Tone.night, .black], startPoint: .top, endPoint: .bottom), for: .navigation)
        .navigationTitle { Text(atNow ? "Now" : clock(time)).foregroundStyle(tint).monospacedDigit() }
        .focusable()
        .digitalCrownRotation($minute, from: 0, through: max(now.timeIntervalSince(midnight) / 60, 1), by: 1,
                              sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: false)
        // A tick at each falling asleep and each waking, and none in between.
        .onChange(of: moment.from) { WKInterfaceDevice.current().play(.click) }
        // And a lighter one on reaching a feed or a nappy.
        .onChange(of: near) { _, mark in if mark != nil { WKInterfaceDevice.current().play(.directionUp) } }
        .accessibilityLabel("Today, \(clock(time))")
    }

    private func clock(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
}

/// "Last 14 days", opened: the crown moves from day to day, a click each, and the day it is on is bright.
struct FortnightScrub: View {
    let child: WidgetSnapshot.Child
    let days: [Double?]
    /// Which day, 0 the oldest. Starts on yesterday. For checking: "-previewScrubDay 5".
    @State private var day: Double = {
        let asked = UserDefaults.standard.string(forKey: "previewScrubDay").flatMap(Double.init)
        return min(max(asked ?? 13, 0), 13)
    }()

    var body: some View {
        let index = min(max(Int(day.rounded()), 0), days.count - 1)
        let top = max(days.compactMap { $0 }.max() ?? 1, 1)
        let known = days.compactMap { $0 }
        let mean = known.isEmpty ? nil : known.reduce(0, +) / Double(known.count)
        let today = Calendar.current.startOfDay(for: .now)
        let date = Calendar.current.date(byAdding: .day, value: index - days.count, to: today) ?? today
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { box in
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(days.enumerated()), id: \.offset) { offset, hours in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(offset == index ? Tone.moon : Color.white.opacity(0.35))
                            .frame(height: max(box.size.height * CGFloat((hours ?? 0) / top), 2))
                            .opacity(hours == nil && offset != index ? 0.35 : 1)
                            .frame(maxWidth: .infinity)
                            // A little air between the two weeks.
                            .padding(.leading, offset == 7 ? 6 : 0)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .animation(.snappy(duration: 0.2), value: index)
            }
            .frame(height: 60)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(Tone.moon)
                    .contentTransition(.numericText())
                Text(days[index].map { Elapsed.short(from: Date(timeIntervalSinceReferenceDate: 0), to: Date(timeIntervalSinceReferenceDate: $0 * 3600)) } ?? "–")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(days[index] == nil ? "No sleep logged" : (mean.map { "Average \(Elapsed.short(from: Date(timeIntervalSinceReferenceDate: 0), to: Date(timeIntervalSinceReferenceDate: $0 * 3600))) a day" } ?? "Asleep"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .animation(.snappy(duration: 0.25), value: index)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .containerBackground(LinearGradient(colors: [Tone.night, .black], startPoint: .top, endPoint: .bottom), for: .navigation)
        .navigationTitle { Text("Day by day").foregroundStyle(Tone.child(child.colourIndex)) }
        .focusable()
        .digitalCrownRotation($day, from: 0, through: Double(days.count - 1), by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
    }
}
