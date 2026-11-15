import SwiftUI

/// How much milk a child has had from bottles today, beside what the family's tin suggests for their age.
/// The tin's figure is a guide to see a day against, not an amount to reach: every baby is different, and
/// the tin says so itself (Clara's ask, 15 November 2026).
struct MilkDay: Equatable {
    /// Millilitres from bottles since midnight.
    let drunk: Double
    let bottles: Int
    let guide: FormulaDay?

    @MainActor
    init?(child: Child, store: FamilyStore, now: Date = .now) {
        let bottles = store.events(for: child, since: Calendar.current.startOfDay(for: now)).filter { $0.kind == .bottle && $0.isLive }
        let guide = child.birthDate.flatMap { birth in store.formulaGuide()?.table?.formulaDay(birth: birth, now: now) }
        // Nothing to say for a child with no bottles today and no tin to go by.
        guard !bottles.isEmpty || (guide != nil && child.uses(.bottle)) else { return nil }
        self.init(drunk: bottles.reduce(0) { $0 + Double($1.amountML) }, bottles: bottles.count, guide: guide)
    }

    init(drunk: Double, bottles: Int, guide: FormulaDay?) {
        self.drunk = drunk
        self.bottles = bottles
        self.guide = guide
    }

    /// "630 ml today · Tin suggests about 840 ml", for a child's card on Today.
    var line: String? {
        guard drunk > 0 else { return nil }
        let today = "\(Units.volume(drunk)) today"
        return guide.map { "\(today) · Tin suggests about \(Units.volume(Double($0.total)))" } ?? today
    }

    /// "630 ml in 3 bottles".
    var summary: String {
        guard bottles > 0 else { return "No bottles yet today" }
        guard drunk > 0 else { return bottles == 1 ? "1 bottle" : "\(bottles) bottles" }
        return "\(Units.volume(drunk)) in \(bottles == 1 ? "1 bottle" : "\(bottles) bottles")"
    }

    /// "The tin suggests about 840 ml a day at 6 months: 4 feeds of 210 ml, 28 scoops."
    var guideLine: String? {
        guard let guide else { return nil }
        let scoops = guide.totalScoops.map { ", \($0) scoops" } ?? ""
        return "The tin suggests about \(Units.volume(Double(guide.total))) a day at \(guide.age): "
            + "\(guide.feeds) feeds of \(Units.volume(Double(guide.water)))\(scoops)."
    }

    /// How far through the tin's day, from 0 to 1. Past it is still 1: there is nothing to go over.
    var share: Double? { guide.map { min(drunk / Double(max($0.total, 1)), 1) } }
}

/// The card in a child's day: the total, a quiet bar against the tin, and the tin's own figures.
struct MilkTodayCard: View {
    let day: MilkDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Milk today").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            Text(day.summary).font(.title3.weight(.semibold)).monospacedDigit()
            if let share = day.share {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.field)
                        Capsule().fill(Palette.iconYellow).frame(width: max(geometry.size.width * share, share > 0 ? 8 : 0))
                    }
                }
                .frame(height: 8)
                .accessibilityHidden(true)
            }
            if let guide = day.guideLine {
                Text(guide + " Every baby is different.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
