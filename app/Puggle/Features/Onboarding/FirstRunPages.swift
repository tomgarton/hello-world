import SwiftUI

// The pages of first run. Every page shares one skeleton, so nothing jumps between them:
// a field of pattern with a piece of the app on it, then progress, a two-line heading, a line or two of text,
// and the button. Each piece acts out its page's heading once, in a few seconds, then rests.
// Mocked up in docs/tools/make_first_run_mockup.py.

/// The heading face for first run: SF Rounded, heavy. It grows with the reader's text size.
extension Text {
    func firstRunHeading() -> some View {
        font(.system(.title, design: .rounded).weight(.heavy))
            .lineSpacing(-2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Seconds since a page appeared, for its piece to act to. With Reduce Motion it is always "long ago",
/// so every piece shows its finished state and nothing moves.
struct PageClock<Content: View>: View {
    /// How long the piece acts for; the clock stops ticking after that.
    var runs: Double = 7
    @ViewBuilder var content: (Double) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    @State private var done = false

    var body: some View {
        if reduceMotion {
            content(.infinity)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: done)) { timeline in
                content(done ? .infinity : timeline.date.timeIntervalSince(start))
            }
            .onAppear { start = .now; done = false }
            .task {
                try? await Task.sleep(for: .seconds(runs))
                done = true
            }
        }
    }
}

/// Where a finger taps: a circle that arrives, presses, and rings out. Laid over the thing being tapped.
struct TapDot: View {
    let t: Double
    /// When the finger lands.
    let at: Double

    var body: some View {
        let dt = t - at
        var opacity = 0.0, scale = 1.0
        if dt > -0.4, dt < 0 { opacity = min(1, (dt + 0.4) / 0.25); scale = 1.3 - 0.3 * opacity }
        else if dt >= 0, dt < 0.12 { opacity = 1; scale = 0.8 }
        else if dt >= 0.12, dt < 0.5 { let k = (dt - 0.12) / 0.38; opacity = 1 - k; scale = 0.8 + 0.9 * k }
        return Circle()
            .fill(Palette.fixedInk.opacity(0.24))
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .overlay(Circle().stroke(Palette.fixedInk.opacity(0.5), lineWidth: 1.5).padding(-1.5))
            .frame(width: 38, height: 38)
            .scaleEffect(scale)
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private func eased(_ value: Double) -> Double {
    let v = min(max(value, 0), 1)
    return 1 - pow(1 - v, 3)
}

/// The card every piece sits on: one corner, one shadow.
private struct Piece<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 11, y: 6)
    }
}

// MARK: 1. Log the day

/// Four tiles with Feed chosen, and a bottle amount. A tap on plus, a tap on save, then on to the next thing.
/// The plus and minus are real: try them.
struct LogPiece: View {
    let t: Double
    @State private var extra = 0

    var body: some View {
        let nappy = t >= 3.62 && extra == 0
        let saved = t >= 1.82 && t < 3.62 && extra == 0
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                tile("icon-bottle", "Feed", on: !nappy)
                tile("icon-sleep", "Sleep", on: false)
                tile("icon-nappy", Terms.nappy, on: nappy).overlay(TapDot(t: extra == 0 ? t : 99, at: 3.5))
                tile("icon-potty", "Potty", on: false)
            }
            Piece(padding: 12) {
                if nappy {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(["Wet", "Dirty", "Both"], id: \.self) { kind in
                                Text(kind).font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Palette.field, in: Capsule())
                            }
                        }
                        saveButton("Save \(Terms.nappy.lowercased())", done: false)
                    }
                } else {
                    VStack(spacing: 8) {
                        HStack {
                            step("minus", "Less") { extra -= 10 }
                            Spacer()
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(max(10, (t < 0.82 ? 150 : 160) + extra))")
                                    .font(.system(size: 36, weight: .heavy, design: .rounded)).monospacedDigit()
                                    .contentTransition(.numericText())
                                Text("ml").font(.subheadline.weight(.semibold)).foregroundStyle(Palette.muted)
                            }
                            .accessibilityElement(children: .combine)
                            Spacer()
                            step("plus", "More") { extra += 10 }.overlay(TapDot(t: extra == 0 ? t : 99, at: 0.7))
                        }
                        saveButton(saved ? "Saved" : "Save bottle", done: saved).overlay(TapDot(t: extra == 0 ? t : 99, at: 1.7))
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("An example: logging a bottle. Nothing is saved.")
    }

    private func tile(_ icon: String, _ label: String, on: Bool) -> some View {
        VStack(spacing: 2) {
            Image(icon + "-plain").resizable().renderingMode(.template).scaledToFit().frame(width: 24, height: 24)
            Text(label).font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 62)
        .foregroundStyle(on ? Palette.sand : Palette.ink)
        .background(on ? Palette.ink : Palette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 11, y: 6)
        .accessibilityHidden(true)
    }

    private func step(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: symbol).font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(Palette.field, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func saveButton(_ title: String, done: Bool) -> some View {
        Text(title).font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 38)
            .foregroundStyle(done ? .white : Palette.sand)
            .background(done ? Palette.gum : Palette.ink, in: Capsule())
            .accessibilityHidden(true)
    }
}

// MARK: 2. Every child

/// Two children's cards. A tap starts the first one's sleep beside the second's, and both timers run.
struct KidsPiece: View {
    let t: Double

    var body: some View {
        let asleep = t >= 1.12
        VStack(spacing: 10) {
            card("Bea", "2½", initial: "B", colour: 0, asleep: asleep,
                 status: asleep ? "Asleep · \(t < 3 ? 0 : t < 5 ? 1 : 2)m" : "Awake · 2h", tapAt: 1.0)
            card("Ollie", "5mo", initial: "O", colour: 1, asleep: true, status: "Asleep · \(t < 3 ? 42 : t < 5 ? 43 : 44)m", tapAt: nil)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An example: two children, each with their own sleep timer")
    }

    private func card(_ name: String, _ age: String, initial: String, colour: Int, asleep: Bool, status: String, tapAt: Double?) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Palette.childColours[colour].resolvedLight)
                .frame(width: 44, height: 44)
                .overlay(Text(initial).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(Palette.fixedInk))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(name).font(.headline)
                    Text("· \(age)").font(.subheadline).opacity(0.7)
                }
                Text(status).font(.subheadline).monospacedDigit().opacity(0.75).contentTransition(.numericText())
            }
            .lineLimit(1)
            Spacer(minLength: 4)
            Text(asleep ? "Woke up" : "Start sleep").font(.footnote.weight(.semibold))
                .padding(.horizontal, 13).frame(minHeight: 36)
                .foregroundStyle(asleep ? Palette.fixedInk : Palette.ink)
                .background(asleep ? Palette.moon : Palette.field, in: Capsule())
                .overlay { if let tapAt { TapDot(t: t, at: tapAt) } }
        }
        .padding(.vertical, 12).padding(.leading, 14).padding(.trailing, 12)
        .foregroundStyle(asleep ? Palette.fixedPaper : Palette.ink)
        .background(asleep ? Palette.night : Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 11, y: 6)
    }
}

private extension Color {
    /// A child's colour as it is by day, for an initial that is always dark.
    var resolvedLight: Color { Color(UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))) }
}

// MARK: 3. Share the day

/// Three entries by three people, arriving one at a time; the newest last, as if someone else has just logged it.
struct SharePiece: View {
    let t: Double
    private let rows: [(icon: String, what: String, child: String, colour: Int, who: String, when: String, at: Double)] = [
        ("icon-bottle", "Bottle · 180 ml", "Ollie", 1, "Nan", "14:52", 2.0),
        ("icon-sleep", "Slept 1h 59m", "Ollie", 1, "Alex", "12:54", 0.9),
        ("icon-potty", "Potty · Wee", "Bea", 0, "Robin", "11:40", 0.3),
    ]

    var body: some View {
        Piece(padding: 0) {
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index], k = eased((t - row.at) / 0.4)
                    if index > 0 { Divider().padding(.leading, 62).opacity(k) }
                    HStack(spacing: 12) {
                        Image(row.icon + "-plain").resizable().renderingMode(.template).scaledToFit()
                            .frame(width: 20, height: 20)
                            .frame(width: 34, height: 34)
                            .background(Palette.field, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.what).font(.subheadline.weight(.semibold))
                            HStack(spacing: 5) {
                                Text(row.child).font(.caption2.weight(.bold)).foregroundStyle(Palette.fixedInk)
                                    .padding(.horizontal, 8).padding(.vertical, 1)
                                    .background(Palette.childColours[row.colour].resolvedLight, in: Capsule())
                                Text("by \(row.who)").font(.footnote).foregroundStyle(Palette.muted)
                            }
                        }
                        Spacer(minLength: 4)
                        Text(row.when).font(.footnote).monospacedDigit().foregroundStyle(Palette.muted)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    // The newest glows for a moment.
                    .background(Palette.wattle.opacity(index == 0 ? 0.28 * min(max(1 - (t - 2.4) / 1.2, 0), 1) * min(max((t - 2.0) / 0.2, 0), 1) : 0))
                    .opacity(k)
                    .offset(y: (1 - k) * -10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An example: three entries, logged by Nan, Alex and Robin")
    }
}

// MARK: 4. Look back

/// One chart: the bars grow from Monday to Sunday and the total counts up.
struct WeekPiece: View {
    let t: Double
    private let heights: [Double] = [0.84, 0.84, 0.9, 0.88, 0.96, 0.92, 0.6]
    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        Piece {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep this week").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                Text("\(Int((91 * eased((t - 0.3) / 1.6)).rounded()))h")
                    .font(.system(size: 30, weight: .heavy, design: .rounded)).monospacedDigit()
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(heights.indices, id: \.self) { index in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Palette.harbour)
                                .frame(height: max(0, 92 * heights[index] * eased((t - 0.3 - Double(index) * 0.14) / 0.55)))
                                .frame(height: 92, alignment: .bottom)
                            Text(days[index]).font(.caption2).foregroundStyle(Palette.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An example week: 91 hours of sleep")
    }
}

// MARK: 5. Private

/// Two promises, each ticked, and the way to read the rest. The two ticks draw themselves; nothing else moves.
struct PrivatePiece: View {
    let t: Double
    let onMore: () -> Void

    var body: some View {
        Piece(padding: 0) {
            VStack(spacing: 0) {
                promise("No account", "No email or password.", index: 0)
                Divider().padding(.leading, 62)
                promise("No ads", "Nothing is sold or shared.", index: 1)
                Divider().padding(.leading, 16)
                Button(action: onMore) {
                    HStack {
                        Text("See how your data is kept").font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                    }
                    .padding(.horizontal, 16).frame(minHeight: 46)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func promise(_ title: String, _ text: String, index: Int) -> some View {
        let k = eased((t - 0.35 - Double(index) * 0.7) / 0.3)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: 0xCFE5D2))
                TickShape()
                    .trim(from: 0, to: eased((t - 0.5 - Double(index) * 0.7) / 0.4))
                    .stroke(Color(hex: 0x1F6B3C), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 11)
            }
            .frame(width: 30, height: 30)
            .scaleEffect(0.6 + 0.4 * k)
            .opacity(k)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

private struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: The skeleton

/// Progress through a run of pages: full width, one segment each.
struct FirstRunProgress: View {
    let current: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule().fill(index <= current ? Palette.ink : Palette.field).frame(height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

/// One page of first run: a field of pattern, with a piece of the app on it or left as a short band,
/// then progress, the heading, the text, whatever the page asks, and its buttons held at the bottom.
struct FirstRunPage<Piece: View, Content: View, Actions: View>: View {
    let tile: PatternTile
    let colour: PatternColour
    /// A short band with no piece, for the setup pages, so the keyboard has room.
    var band = false
    let progress: (current: Int, count: Int)?
    let heading: String
    let text: String
    @ViewBuilder var piece: (Double) -> Piece
    @ViewBuilder var content: Content
    @ViewBuilder var actions: Actions

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var acting = true

    var body: some View {
        GeometryReader { geometry in
            let large = typeSize.isAccessibilitySize
            let height: CGFloat = band || large ? 76 : min(330, max(250, geometry.size.height * 0.4))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        // The pattern rests while the piece acts, then drifts on.
                        PatternField(tile: tile, colour: colour, resting: acting && !band)
                            .padding(.top, -geometry.safeAreaInsets.top - 400)
                        if !band && !large {
                            PageClock { t in piece(t) }
                                .padding(.horizontal, 20)
                                .padding(.top, 34)
                                .frame(maxWidth: 420)
                        }
                    }
                    .frame(height: height)
                    VStack(alignment: .leading, spacing: 0) {
                        if let progress { FirstRunProgress(current: progress.current, count: progress.count).padding(.bottom, 18) }
                        Text(heading).firstRunHeading()
                        Text(text).font(.body).foregroundStyle(Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                        content.padding(.top, 18)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) { actions }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Palette.sand)
        }
        .task {
            try? await Task.sleep(for: .seconds(4.4))
            acting = false
        }
    }
}
