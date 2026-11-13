import SwiftUI

/// How a child's days have changed with age: charts by month of age, the changes
/// as plain sentences, and pages to read on the NHS website.
struct PatternsView: View {
    @ObservedObject var child: Child
    /// Other children in the family, for comparing at the same age if the parent chooses to.
    var others: [Child] = []
    @AppStorage("compareAtSameAge") private var compare = false

    var body: some View {
        let p = Patterns.make(child: child)
        VStack(alignment: .leading, spacing: 16) {
            if p.months.isEmpty {
                Text(child.birthDate == nil
                     ? "Patterns need \(child.displayName)'s birth date, on the Family tab."
                     : "Patterns appear once there are a few weeks of entries for \(child.displayName). They show how bedtime, sleep, naps and bottles have changed with age.")
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                if let prompt = p.prompt {
                    card {
                        Text(prompt).font(.body.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                        reading(Reading.sleep(ageMonths: p.ageMonths))
                    }
                }
                bedtimeCard(p.months)
                barsCard("Longest stretch at night", p.months.compactMap { m in m.longestNight.map { (m.id, $0 / 3600) } },
                         headline: { "About \(Elapsed.short(seconds: (($0 * 3600) / 900).rounded() * 900))" },
                         value: { Elapsed.short(seconds: ($0 * 3600 / 300).rounded() * 300) }, colour: InsightColour.sleep)
                barsCard("Naps a day", p.months.compactMap { m in m.napsPerDay.map { (m.id, $0) } },
                         headline: { "\($0.formatted(.number.precision(.fractionLength(0...1)))) a day" },
                         value: { $0.formatted(.number.precision(.fractionLength(1))) }, colour: InsightColour.sleep)
                barsCard("Bottles a day", p.months.compactMap { m in m.bottlesPerDay.map { (m.id, $0) } },
                         headline: { count in
                             let ml = p.months.last { $0.bottlesPerDay != nil }?.mlPerBottle
                             return "\(count.formatted(.number.precision(.fractionLength(0...1)))) a day" + (ml.map { ", about \(Units.volume(Patterns.round10($0))) each" } ?? "")
                         },
                         value: { $0.formatted(.number.precision(.fractionLength(1))) }, colour: InsightColour.feeds)

                if !p.changes.isEmpty {
                    Text("What changed").font(.headline).accessibilityAddTraits(.isHeader)
                    card {
                        ForEach(Array(p.changes.enumerated()), id: \.offset) { index, change in
                            if index > 0 { Divider() }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(change.text).fixedSize(horizontal: false, vertical: true)
                                if let detail = change.detail {
                                    Text(detail).font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                let readings = Reading.forAge(months: p.ageMonths, days: p.ageDays)
                if !readings.isEmpty {
                    Text("To read").font(.headline).accessibilityAddTraits(.isHeader)
                    ForEach(readings) { one in card { reading(one) } }
                }

                Text("Worked out from what was logged, by month of age. Days with nothing logged are left out. The app doesn't say what is usual for a child.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if !others.isEmpty { comparison(p) }
            }
        }
    }

    // MARK: Cards

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func title(_ text: String) -> some View {
        Text(text).font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
    }

    @ViewBuilder private func bedtimeCard(_ months: [ChildPatterns.Month]) -> some View {
        let shown = months.filter { $0.bedtime != nil }
        if let latest = shown.last, let middle = latest.bedtime {
            card {
                VStack(alignment: .leading, spacing: 2) {
                    title("Bedtime")
                    Text("Around \(Patterns.clock(afterNoon: Patterns.round5(middle)))").displayFont(28)
                    if let early = latest.bedtimeEarly, let late = latest.bedtimeLate {
                        Text("Most nights between \(Patterns.clock(afterNoon: Patterns.round5(early))) and \(Patterns.clock(afterNoon: Patterns.round5(late))), at \(Patterns.ageWords(latest.id))")
                            .font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
                BedtimeChart(months: shown)
                Text("By month of age. The dot is the usual bedtime, the bar where most of them fell.")
                    .font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private func barsCard(_ name: String, _ values: [(Int, Double)], headline: (Double) -> String,
                                       value: @escaping (Double) -> String, colour: Color) -> some View {
        if let latest = values.last {
            card {
                VStack(alignment: .leading, spacing: 2) {
                    title(name)
                    Text(headline(latest.1)).displayFont(28)
                    Text("At \(Patterns.ageWords(latest.0))").font(.subheadline).foregroundStyle(Palette.muted)
                }
                .accessibilityElement(children: .combine)
                MonthBars(values: values, colour: colour, label: value)
            }
        }
    }

    private func reading(_ one: Reading) -> some View {
        Link(destination: one.url) {
            VStack(alignment: .leading, spacing: 3) {
                Text(one.line).font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                HStack(alignment: .firstTextBaseline) {
                    Text(one.title).font(.headline).foregroundStyle(Palette.ink).multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                }
                Text("Information from the NHS website").font(.footnote).foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityHint("Opens the NHS website")
    }

    // MARK: At the same age

    @ViewBuilder private func comparison(_ mine: ChildPatterns) -> some View {
        let names = ListFormatter.localizedString(byJoining: others.map(\.displayName))
        Toggle("Show \(names) at the same age", isOn: $compare)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        if compare, let age = mine.months.last?.id {
            card {
                title("At \(Patterns.ageWords(age))")
                row("", [child] + others) { $0.displayName }
                let all = [child] + others
                let months: [ChildPatterns.Month?] = all.map { one in Patterns.make(child: one).months.first { $0.id == age } }
                row("Usual bedtime", all) { one in months[all.firstIndex(of: one) ?? 0]?.bedtime.map { Patterns.clock(afterNoon: Patterns.round5($0)) } ?? "–" }
                row("Longest stretch at night", all) { one in months[all.firstIndex(of: one) ?? 0]?.longestNight.map { Elapsed.short(seconds: ($0 / 300).rounded() * 300) } ?? "–" }
                row("Naps a day", all) { one in months[all.firstIndex(of: one) ?? 0]?.napsPerDay.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "–" }
                row("Bottles a day", all) { one in months[all.firstIndex(of: one) ?? 0]?.bottlesPerDay.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "–" }
                Text("Every child is different, and neither is ahead. A dash means too little was logged at that age.")
                    .font(.footnote).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func row(_ label: String, _ children: [Child], _ text: @escaping (Child) -> String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty { Text(label).font(.footnote).foregroundStyle(Palette.muted) }
            HStack {
                ForEach(children) { one in
                    Text(text(one))
                        .font(label.isEmpty ? .subheadline.weight(.bold) : .body.weight(.semibold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: Charts

/// One bar per month of age, labelled every few months.
struct MonthBars: View {
    let values: [(Int, Double)]
    let colour: Color
    let label: (Double) -> String

    var body: some View {
        let top = max(values.map(\.1).max() ?? 1, 0.0001)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(values, id: \.0) { month, value in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(colour)
                        .frame(height: max(4, 80 * value / top))
                    Text(showsLabel(month) ? "\(month)" : " ")
                        .font(.footnote).foregroundStyle(Palette.muted).fixedSize()
                }
                .frame(maxWidth: 30)
                .accessibilityElement()
                .accessibilityLabel(Patterns.ageWords(month))
                .accessibilityValue(label(value))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .bottomLeading)
    }

    private func showsLabel(_ month: Int) -> Bool {
        values.count <= 8 || month % 3 == 0 || month == values.last?.0
    }
}

/// Bedtime by month of age: a dot for the usual time and a bar for where most fell.
struct BedtimeChart: View {
    let months: [ChildPatterns.Month]

    var body: some View {
        let early = months.compactMap { $0.bedtimeEarly ?? $0.bedtime }.min() ?? 0
        let late = months.compactMap { $0.bedtimeLate ?? $0.bedtime }.max() ?? 1
        let low = Double(early - 15), span = Double(max(late - early + 30, 60))
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(months) { month in
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        let h = geometry.size.height
                        let y = { (v: Int) -> CGFloat in CGFloat((Double(v) - low) / span) * h }
                        let top = y(month.bedtimeEarly ?? month.bedtime ?? 0), bottom = y(month.bedtimeLate ?? month.bedtime ?? 0)
                        ZStack(alignment: .top) {
                            Capsule().fill(InsightColour.sleep.opacity(0.35))
                                .frame(width: 12, height: max(bottom - top, 12))
                                .offset(y: top - 2)
                            Circle().fill(Palette.ink).frame(width: 7, height: 7)
                                .offset(y: y(month.bedtime ?? 0) - 3.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 90)
                    Text(showsLabel(month.id) ? "\(month.id)" : " ").font(.footnote).foregroundStyle(Palette.muted).fixedSize()
                }
                .frame(maxWidth: 30)
                .accessibilityElement()
                .accessibilityLabel(Patterns.ageWords(month.id))
                .accessibilityValue(month.bedtime.map { "Usually \(Patterns.clock(afterNoon: Patterns.round5($0)))" } ?? "")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func showsLabel(_ month: Int) -> Bool {
        months.count <= 8 || month % 3 == 0 || month == months.last?.id
    }
}

// MARK: Reading

/// A page on the NHS website, with the app's own short line above it. The app links;
/// it doesn't quote or reword. Listed for review in docs/for-review-tips-and-links.md.
struct Reading: Identifiable {
    let id: String
    let line: String
    let title: String
    let url: URL

    static func sleep(ageMonths: Int) -> Reading {
        ageMonths < 12
            ? Reading(id: "sleep-baby", line: "About sleep at this age", title: "Helping your baby to sleep",
                      url: URL(string: "https://www.nhs.uk/baby/caring-for-a-newborn/helping-your-baby-to-sleep/")!)
            : Reading(id: "sleep-young", line: "About sleep at this age", title: "Sleep and young children",
                      url: URL(string: "https://www.nhs.uk/baby/health/sleep-and-young-children/")!)
    }

    static func forAge(months: Int, days: Int) -> [Reading] {
        var list: [Reading] = []
        // From 5 months 2 weeks to 9 months: weaning comes in around 6 months.
        if days >= 167, months < 9 {
            list.append(Reading(id: "weaning", line: "Around 6 months, solid foods come in", title: "Weaning",
                                url: URL(string: "https://www.nhs.uk/start-for-life/baby/weaning/")!))
        }
        list.append(sleep(ageMonths: months))
        return list
    }
}
