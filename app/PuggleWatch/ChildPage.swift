import SwiftUI

/// One child on the Watch. Asleep, the screen is night blue with the sleep counting up; feeding, it is the warm
/// yellow of the sun with the feed counting up; otherwise it shows how they are, with one big button for what
/// is most likely next and two smaller ones below (Tom, 20 November 2026, after Granola's Watch app).
struct ChildPage: View {
    let child: WidgetSnapshot.Child
    @EnvironmentObject private var model: WatchModel
    @State private var choosingNappy = false
    @State private var choosingBottle = false
    @State private var choosingSide = false

    var body: some View {
        Group {
            if let since = child.asleepSince {
                running(label: "Asleep", since: since, fill: Tone.night, ink: Tone.moon) {
                    big("Woke up", systemImage: "sun.max.fill", fill: Tone.moon, ink: Tone.night) { send(.wokeUp) }
                }
            } else if let since = child.feedingSince {
                running(label: child.feedSide.map { "Feeding, \($0.lowercased())" } ?? "Feed paused", since: child.feedSide == nil ? nil : since,
                        fill: Tone.milk, ink: Tone.ink) {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            side("Left", .feedLeft)
                            side("Right", .feedRight)
                        }
                        big("Stop feed", systemImage: "stop.fill", fill: Tone.ink, ink: Tone.milk) { send(.finishFeed) }
                    }
                }
            } else {
                awake
            }
        }
        .sheet(isPresented: $choosingNappy) { NavigationStack { NappyChoice(child: child) } }
        .sheet(isPresented: $choosingBottle) { NavigationStack { BottleChoice(child: child) } }
        .confirmationDialog("Which side?", isPresented: $choosingSide) {
            Button("Start left") { send(.feedLeft) }
            Button("Start right") { send(.feedRight) }
        }
    }

    // MARK: Awake

    private var awake: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Badge(child: child)
                    Text(child.name)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .lineLimit(1)
                }
                facts
                big("Start sleep", systemImage: "moon.fill", fill: Tone.child(child.colourIndex), ink: Tone.ink) { send(.startSleep) }
                HStack(spacing: 6) {
                    if child.breastfeeds == true {
                        small("Start feed", systemImage: "timer") { choosingSide = true }
                    } else if child.usesMilk != false {
                        small("Log bottle", systemImage: "waterbottle.fill") { choosingBottle = true }
                    }
                    if child.pottyTraining != true, child.usesNappies {
                        small("Log \(Terms.nappyLower)", systemImage: "drop.fill") { choosingNappy = true }
                    }
                }
                if child.breastfeeds == true, child.usesMilk != false {
                    small("Log bottle", systemImage: "waterbottle.fill") { choosingBottle = true }
                }
            }
        }
    }

    /// How they are, one fact a line: "Fed 1h 29m ago", "Awake 1h 11m", "Nappy 40m ago".
    private var facts: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 2) {
                if let fed = child.lastFeed { fact("Fed", ago(fed, context.date)) }
                if let woke = child.lastWoke { fact("Awake", Elapsed.short(from: woke, to: context.date)) }
                if child.usesNappies, let nappy = child.lastNappy { fact(Terms.nappy, ago(nappy, context.date)) }
            }
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
    private func running<Buttons: View>(label: String, since: Date?, fill: Color, ink: Color,
                                        @ViewBuilder buttons: () -> Buttons) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Badge(child: child, size: 20)
                Text(child.name)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Group {
                if let since {
                    Text(timerInterval: since...Date.distantFuture, countsDown: false)
                } else {
                    Text("Paused")
                }
            }
            .font(.system(size: 44, weight: .bold, design: .rounded))
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
        .background(fill.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }

    private func side(_ name: String, _ action: WatchLink.Request.Action) -> some View {
        let on = child.feedSide == name
        return Button { send(action) } label: {
            Text(on ? "Pause \(name.lowercased())" : "Start \(name.lowercased())")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 34)
        .background(Tone.ink.opacity(on ? 0.22 : 0.1), in: Capsule())
        .foregroundStyle(Tone.ink)
    }

    // MARK: Buttons

    private func big(_ title: String, systemImage: String, fill: Color, ink: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(fill)
        .foregroundStyle(ink)
    }

    private func small(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                Text(title).font(.system(.caption2, design: .rounded).weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 14))
    }

    private func send(_ action: WatchLink.Request.Action) {
        model.send(WatchLink.Request(action: action, childID: child.id))
    }
}

/// Wet, dirty or both: one tap saves it.
struct NappyChoice: View {
    let child: WidgetSnapshot.Child
    @EnvironmentObject private var model: WatchModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 6) {
            ForEach(["Wet", "Dirty", "Both"], id: \.self) { kind in
                Button {
                    model.send(WatchLink.Request(action: .nappy, childID: child.id, detail: kind))
                    dismiss()
                } label: {
                    Text(kind).font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity)
                }
                .tint(Tone.child(child.colourIndex))
            }
        }
        .navigationTitle(Terms.nappy)
    }
}

/// A bottle: the amount starts at the last one and turns with the Digital Crown, 10 ml a click.
struct BottleChoice: View {
    let child: WidgetSnapshot.Child
    @EnvironmentObject private var model: WatchModel
    @Environment(\.dismiss) private var dismiss
    @State private var ml: Double

    init(child: WidgetSnapshot.Child) {
        self.child = child
        _ml = State(initialValue: Double(child.lastBottleML ?? 120))
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(ml)) ml")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .focusable()
                .digitalCrownRotation($ml, from: 10, through: 400, by: 10, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
                .accessibilityValue("\(Int(ml)) millilitres")
            Text("Turn the crown to change it")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            Button {
                model.send(WatchLink.Request(action: .bottle, childID: child.id, ml: Int(ml)))
                dismiss()
            } label: {
                Text("Save bottle").font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Tone.child(child.colourIndex))
            .foregroundStyle(Tone.ink)
        }
        .navigationTitle("Bottle")
    }
}
