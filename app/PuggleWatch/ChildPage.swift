import SwiftUI
import WatchKit

/// One child on the Watch. Asleep, the screen is night blue with the sleep counting up; feeding, it is a deep
/// honey with the feed counting up; otherwise it shows how they are, with one big button for what
/// is most likely next and two smaller ones below (Tom, 20 November 2026, after Granola's Watch app).
struct ChildPage: View {
    let child: WidgetSnapshot.Child
    /// The first of a child's pages in the paged trial (`PagedChild`): their name is in the title and their
    /// badge in the corner, so the page starts with the facts, each large.
    var paged = false
    /// Counts up each time the page should go back to its top: the badge tapped, or the page left.
    var toTop = 0
    @EnvironmentObject private var model: WatchModel
    // For checking: "-previewSheet nappy" or "bottle" opens one on the first child.
    @State private var choosingNappy = false
    @State private var choosingBottle = false
    @State private var choosingSide = false

    var body: some View {
        Group {
            if let since = child.asleepSince {
                running(label: "Asleep", fill: Tone.night, ink: Tone.moon, moon: true) {
                    // A sleep reads as on the iPhone's Lock Screen, "1h 2m"; only a feed, short and watched,
                    // ticks in seconds (Tom, 20 November 2026). Its first minute is "Just now", as elsewhere.
                    TimelineView(.periodic(from: since, by: 60)) { context in
                        if context.date.timeIntervalSince(since) < 60 {
                            Text("Just now")
                        } else {
                            Text(.dateRange(startingAt: since), format: .components(style: .narrow, fields: [.hour, .minute]))
                        }
                    }
                } buttons: {
                    big("Woke up", systemImage: "sun.max.fill", fill: Tone.moon, ink: Tone.night) { send(.wokeUp) }
                }
            } else if let since = child.feedingSince {
                // The time fed, without the pauses, when the iPhone sends it; from the start otherwise.
                let paused = child.feedSide == nil
                let label = child.feedSide.map { "Feeding, \($0.lowercased())" } ?? (child.feedBanked == nil ? "Feed" : "Feed paused")
                running(label: label, fill: Tone.honey, ink: Tone.cream, moon: false) {
                    if paused {
                        Text(child.feedBanked.map { Duration.seconds($0).formatted(.time(pattern: .minuteSecond)) } ?? "Paused")
                    } else {
                        let from = child.feedBanked.flatMap { banked in child.feedSideSince?.addingTimeInterval(-banked) } ?? since
                        Text(timerInterval: from...Date.distantFuture, countsDown: false)
                    }
                } buttons: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            side("Left", .feedLeft)
                            side("Right", .feedRight)
                        }
                        big("Stop feed", systemImage: "stop.fill", fill: Tone.milk, ink: Tone.ink) { send(.finishFeed) }
                    }
                }
            } else {
                awake.modifier(Arriving())
            }
        }
        // The closing cross is white: on its own dark circle, not the child's pale colour.
        .sheet(isPresented: $choosingNappy) { NavigationStack { NappyChoice(child: child) }.tint(Tone.closeButton) }
        .sheet(isPresented: $choosingBottle) { NavigationStack { BottleChoice(child: child, ounces: model.snapshot?.ounces == true) }.tint(Tone.closeButton) }
        // A sheet, not a dialog: the dialog stayed up over the feed it had started.
        .sheet(isPresented: $choosingSide) {
            NavigationStack {
                SideChoice(child: child) { side in
                    choosingSide = false
                    send(side)
                }
            }
            .tint(Tone.closeButton)
        }
        .onAppear {
            guard child.id == WatchModel.shared.snapshot?.children.first?.id else { return }
            switch UserDefaults.standard.string(forKey: "previewSheet") {
            case "nappy": choosingNappy = true
            case "bottle": choosingBottle = true
            case "side": choosingSide = true
            default: break
            }
        }
    }

    // MARK: Awake

    private var awake: some View {
        ScrollViewReader { scroller in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Color.clear.frame(height: 0).id("top")
                    if paged {
                        // What "Start sleep" answers comes first, with the button in view under it.
                        largeFacts(first: true)
                    } else {
                        HStack(spacing: 8) {
                            Badge(child: child)
                            Text(child.name)
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .lineLimit(1)
                        }
                        facts
                    }
                    // One column, every button the full width, so their edges line up.
                    VStack(spacing: 6) {
                        big("Start sleep", systemImage: "moon.fill", fill: Tone.child(child.colourIndex), ink: Tone.ink) { send(.startSleep) }
                        if paged { largeFacts(first: false).padding(.vertical, 4) }
                        if child.breastfeeds == true {
                            row("Start feed", systemImage: "timer") { Haptic.tap(); choosingSide = true }
                        }
                        // A summary from an older Puggle does not say, so it goes by milk as before.
                        if child.usesBottle ?? (child.usesMilk != false) {
                            row("Log bottle", systemImage: "waterbottle.fill") { Haptic.tap(); choosingBottle = true }
                        }
                        if child.pottyTraining != true, child.usesNappies {
                            row("Log \(Terms.nappyLower)", systemImage: "drop.fill") { Haptic.tap(); choosingNappy = true }
                        }
                    }
                    .id("end")
                }
                .padding(.horizontal, 4)
                // Clear of the page dots at the foot of the screen.
                .padding(.bottom, 14)
            }
            .onAppear {
                // For checking: "-previewScroll 1" opens at the foot of the page.
                if UserDefaults.standard.bool(forKey: "previewScroll") { scroller.scrollTo("end", anchor: .bottom) }
            }
            .onChange(of: toTop) { withAnimation { scroller.scrollTo("top", anchor: .top) } }
        }
    }

    /// How they are, one fact a line: "Fed 1h 29m ago", "Awake 1h 11m", "Nappy 40m ago".
    private var facts: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 2) {
                // As on Today: Fed for a child on milk, Ate for one past it; Potty while potty training.
                if child.usesMilk != false, let fed = child.lastFeed { fact("Fed", ago(fed, context.date)) }
                if child.usesMilk == false, let ate = child.lastSolids { fact("Ate", ago(ate, context.date)) }
                if let woke = child.lastWoke { fact("Awake", context.date.timeIntervalSince(woke) < 60 ? "just now" : Elapsed.short(from: woke, to: context.date)) }
                if child.pottyTraining == true {
                    if let potty = child.lastPotty { fact("Potty", ago(potty, context.date)) }
                } else if child.usesNappies, let nappy = child.lastNappy {
                    fact(Terms.nappy, ago(nappy, context.date))
                }
            }
        }
    }

    /// The same facts for the paged trial, as Activity lists steps and distance: a grey word, a large figure
    /// and a line between. Awake comes first, as it is what "Start sleep" under it answers.
    private func largeFacts(first: Bool) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let all: [(word: String, value: String)] = [
                child.lastWoke.map { ("Awake", context.date.timeIntervalSince($0) < 60 ? "just now" : Elapsed.short(from: $0, to: context.date)) },
                child.usesMilk != false ? child.lastFeed.map { ("Fed", ago($0, context.date)) } : child.lastSolids.map { ("Ate", ago($0, context.date)) },
                child.pottyTraining == true ? child.lastPotty.map { ("Potty", ago($0, context.date)) }
                    : (child.usesNappies ? child.lastNappy.map { (Terms.nappy, ago($0, context.date)) } : nil),
            ].compactMap { $0 }
            let rows = first ? Array(all.prefix(1)) : Array(all.dropFirst())
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 { Rectangle().fill(.white.opacity(0.2)).frame(height: 1) }
                    VStack(alignment: .leading, spacing: -2) {
                        Text(row.word)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(row.value)
                            .rounded(first ? 34 : 26)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.default, value: row.value)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fact(_ word: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(word).foregroundStyle(.secondary)
            Text(value).fontWeight(.semibold)
        }
        .font(.system(.footnote, design: .rounded))
        .accessibilityElement(children: .combine)
    }

    private func ago(_ date: Date, _ now: Date) -> String {
        now.timeIntervalSince(date) < 60 ? "just now" : "\(Elapsed.short(from: date, to: now)) ago"
    }

    // MARK: Running

    /// The whole screen in one colour, who it is, the time counting up large, and what to do about it.
    private func running<Counter: View, Buttons: View>(label: String, fill: Color, ink: Color, moon: Bool,
                                                       @ViewBuilder counter: () -> Counter,
                                                       @ViewBuilder buttons: () -> Buttons) -> some View {
        VStack(spacing: 2) {
            if !paged {
                HStack(spacing: 6) {
                    Badge(child: child, size: 20)
                    Text(child.name)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            // The moon comes up as they fall asleep.
            if paged, moon { Rising(systemName: "moon.stars.fill") }
            counter()
            .rounded(44, .bold)
            .monospacedDigit()
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            Text(label)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .opacity(0.8)
            Spacer(minLength: 0)
            buttons()
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 6)
        .background(paged ? Color.clear.ignoresSafeArea() : fill.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        // Falling asleep, feeding and waking change the scene over a moment, not at a cut: each screen
        // fades in as it arrives, while the colour behind crosses over (`PagedChild`).
        .modifier(Arriving())
    }

    private func side(_ name: String, _ action: WatchLink.Request.Action) -> some View {
        let on = child.feedSide == name
        return Button { send(action) } label: {
            Text(on ? "Pause \(name.lowercased())" : "Start \(name.lowercased())")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 40)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .background(Tone.cream.opacity(on ? 0.3 : 0.14), in: Capsule())
        .contentShape(Capsule())
        .foregroundStyle(Tone.cream)
    }

    // MARK: Buttons

    /// The main button: a filled capsule, the full width.
    private func big(_ title: String, systemImage: String, fill: Color, ink: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(fill, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// The others: a quieter capsule, the same width, its icon and words at the left like a list row.
    private func row(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(Tone.child(child.colourIndex))
                    .frame(width: 22)
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.white.opacity(0.14), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func send(_ action: WatchLink.Request.Action) {
        model.send(WatchLink.Request(action: action, childID: child.id))
    }
}

/// Fades a screen in as it arrives. Still at once with Reduce Motion.
struct Arriving: ViewModifier {
    @State private var here = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(here ? 1 : 0)
            .onAppear {
                if reduceMotion { here = true } else { withAnimation(.easeOut(duration: 0.55)) { here = true } }
            }
    }
}

/// A small picture that rises into place as its screen arrives: the moon, when a sleep starts.
struct Rising: View {
    let systemName: String
    @State private var up = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 22, weight: .semibold))
            .offset(y: up ? 0 : 26)
            .opacity(up ? 1 : 0)
            .onAppear {
                if reduceMotion { up = true } else { withAnimation(.spring(duration: 0.9, bounce: 0.3).delay(0.15)) { up = true } }
            }
            .accessibilityHidden(true)
    }
}

/// Wet, dirty or both: one tap saves it.
struct NappyChoice: View {
    let child: WidgetSnapshot.Child
    @EnvironmentObject private var model: WatchModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(["Wet", "Dirty", "Both"], id: \.self) { kind in
                    Button {
                        model.send(WatchLink.Request(action: .nappy, childID: child.id, detail: kind))
                        dismiss()
                    } label: {
                        Text(kind)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Tone.ink)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Tone.child(child.colourIndex), in: Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(Terms.nappy)
    }
}

/// Left or right, to start a feed: one tap starts it.
struct SideChoice: View {
    let child: WidgetSnapshot.Child
    let choose: (WatchLink.Request.Action) -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach([("Left", WatchLink.Request.Action.feedLeft), ("Right", .feedRight)], id: \.0) { name, action in
                Button { choose(action) } label: {
                    Text(name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Tone.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Tone.child(child.colourIndex), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(name.lowercased())")
            }
        }
        .padding(.horizontal, 4)
        .navigationTitle("Which side?")
    }
}

/// A bottle: the amount starts at the last one and turns with the Digital Crown, 10 ml (or half an ounce) a click.
struct BottleChoice: View {
    let child: WidgetSnapshot.Child
    let ounces: Bool
    @EnvironmentObject private var model: WatchModel
    @Environment(\.dismiss) private var dismiss
    /// Millilitres, or ounces when the iPhone is set to them.
    @State private var amount: Double

    init(child: WidgetSnapshot.Child, ounces: Bool = false) {
        self.child = child
        self.ounces = ounces
        let ml = Double(child.lastBottleML ?? 120)
        _amount = State(initialValue: ounces ? max((ml / WidgetSnapshot.mlPerOz * 2).rounded() / 2, 0.5) : ml)
    }

    private var ml: Int { Int((ounces ? amount * WidgetSnapshot.mlPerOz : amount).rounded()) }

    var body: some View {
        VStack(spacing: 8) {
            Text(ounces ? "\(amount.formatted(.number.precision(.fractionLength(0...1)))) oz" : "\(Int(amount)) ml")
                .contentTransition(.numericText(value: amount))
                .animation(.snappy(duration: 0.2), value: amount)
                .rounded(36, .bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .focusable()
                .digitalCrownRotation($amount, from: ounces ? 0.5 : 10, through: ounces ? 14 : 400, by: ounces ? 0.5 : 10,
                                      sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
                .accessibilityValue(ounces ? "\(amount.formatted()) ounces" : "\(Int(amount)) millilitres")
            CrownHint()
            Button {
                model.send(WatchLink.Request(action: .bottle, childID: child.id, ml: ml))
                dismiss()
            } label: {
                Text("Save bottle")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Tone.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Tone.child(child.colourIndex), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .navigationTitle("Bottle")
    }
}

/// "Turn the crown", with the crown drawn beside it: short enough for the small Watch.
struct CrownHint: View {
    var body: some View {
        Label("Turn the crown", systemImage: "digitalcrown.horizontal.arrow.clockwise.fill")
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// A light tick for a tap that opens something. Taps that save play their own (`WatchModel.send`).
enum Haptic {
    static func tap() { WKInterfaceDevice.current().play(.click) }
}

/// A figure's size, which grows with the text size set on the Watch as the labels do.
private struct Scaled: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(_ size: CGFloat, _ weight: Font.Weight, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: .rounded))
    }
}

extension View {
    func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> some View {
        modifier(Scaled(size, weight, relativeTo: size < 16 ? .caption2 : .title2))
    }
}
