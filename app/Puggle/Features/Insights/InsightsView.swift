import SwiftUI

/// Look back without scores: last night per child, and the week as plain
/// bars with a value on each. No averages, no comparisons between children.
struct InsightsView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)],
                  predicate: NSPredicate(format: "archived != YES")) private var children: FetchedResults<Child>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if children.isEmpty {
                        Text("Insights appear once a child has been added.")
                            .foregroundStyle(Palette.muted)
                    }
                    ForEach(children) { child in
                        ChildInsights(child: child)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.sand)
            .navigationTitle("Insights")
        }
    }
}

struct ChildInsights: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child

    private var events: [Event] { Array(child.events ?? []) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ChildAvatar(child: child, size: 36)
                Text(child.displayName).font(.title3.weight(.semibold))
            }
            let logged = daysLogged
            if logged < 3 {
                Text(logged == 0
                     ? "Nothing logged for \(child.displayName) yet."
                     : "\(logged) day\(logged == 1 ? "" : "s") logged so far. Here is what there is.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }
            if logged > 0 {
                lastNight
                week
            }
        }
        .foregroundStyle(Palette.ink)
    }

    private var daysLogged: Int {
        Set(events.compactMap { $0.startedAt.map { Calendar.current.startOfDay(for: $0) } }).count
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

    private var lastNight: some View {
        let pieces = nightPieces
        return VStack(alignment: .leading, spacing: 4) {
            Text("Last night").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            if let first = pieces.first, let last = pieces.last {
                let total = pieces.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
                let longest = pieces.map { $0.end.timeIntervalSince($0.start) }.max() ?? 0
                Text("Slept \(duration(total))").font(.title2.weight(.semibold))
                Text(last.open
                     ? "From \(first.start.formatted(date: .omitted, time: .shortened)), still asleep"
                     : "Between \(first.start.formatted(date: .omitted, time: .shortened)) and \(last.end.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(Palette.muted)
                if pieces.count > 1 {
                    Text("Longest stretch \(duration(longest))").foregroundStyle(Palette.muted)
                }
            } else {
                Text("No sleep logged for last night.").foregroundStyle(Palette.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: This week

    private struct Day: Identifiable {
        let id: Date
        let label: String
        let spoken: String
        var sleep = 0.0
        var bottleML = 0.0
        var feeds = 0
        var nappies = 0
    }

    private var days: [Day] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var result: [Day] = []
        for offset in (0..<7).reversed() {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            var day = Day(id: start,
                          label: start.formatted(.dateTime.weekday(.narrow)),
                          spoken: start.formatted(.dateTime.weekday(.wide)))
            for event in events {
                guard let at = event.startedAt else { continue }
                if event.kind == .sleep {
                    day.sleep += event.asleepSeconds(from: max(at, start), to: min(event.endedAt ?? .now, end))
                } else if at >= start && at < end {
                    switch event.kind {
                    case .bottle: day.bottleML += event.amountML; day.feeds += 1
                    case .breastfeed: day.feeds += 1
                    case .nappy: day.nappies += 1
                    default: break
                    }
                }
            }
            result.append(day)
        }
        return result
    }

    @ViewBuilder private var week: some View {
        let days = days
        VStack(alignment: .leading, spacing: 16) {
            Text("The last seven days").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            if days.contains(where: { $0.sleep >= 60 }) {
                WeekBars(title: "Sleep", unit: "hours",
                         bars: days.map { .init(label: $0.label, spoken: $0.spoken, value: $0.sleep / 3600,
                                                text: $0.sleep >= 60 ? String(format: "%.1f", $0.sleep / 3600) : "–") })
            }
            if days.contains(where: { $0.feeds > 0 }) {
                WeekBars(title: "Feeds", unit: "feeds",
                         bars: days.map { .init(label: $0.label, spoken: $0.spoken, value: Double($0.feeds),
                                                text: $0.feeds > 0 ? "\($0.feeds)" : "–") })
            }
            if days.contains(where: { $0.bottleML > 0 }) {
                WeekBars(title: "Bottles", unit: "millilitres",
                         bars: days.map { .init(label: $0.label, spoken: $0.spoken, value: $0.bottleML,
                                                text: $0.bottleML > 0 ? "\(Int($0.bottleML))" : "–") })
            }
            if days.contains(where: { $0.nappies > 0 }) {
                WeekBars(title: "Nappies", unit: "nappies",
                         bars: days.map { .init(label: $0.label, spoken: $0.spoken, value: Double($0.nappies),
                                                text: $0.nappies > 0 ? "\($0.nappies)" : "–") })
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func duration(_ seconds: Double) -> String {
        Elapsed.short(from: Date.now.addingTimeInterval(-seconds), to: .now)
    }
}

/// Seven outlined bars with a value on each, and a spoken description.
struct WeekBars: View {
    struct Bar {
        let label: String
        let spoken: String
        let value: Double
        let text: String
    }

    let title: String
    let unit: String
    let bars: [Bar]

    var body: some View {
        let top = max(bars.map(\.value).max() ?? 0, 0.0001)
        VStack(alignment: .leading, spacing: 8) {
            Text(unit == title.lowercased() ? title : "\(title), \(unit)").font(.subheadline.weight(.semibold))
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(bars.indices, id: \.self) { index in
                    let bar = bars[index]
                    VStack(spacing: 4) {
                        Text(bar.text).font(.caption2).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Palette.field)
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Palette.ink, lineWidth: 1.5))
                            .frame(height: max(3, 72 * bar.value / top))
                        Text(bar.label).font(.caption2).foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) in \(unit), last seven days")
        .accessibilityValue(bars.map { "\($0.spoken) \($0.text == "–" ? "none" : $0.text)" }.joined(separator: ", "))
    }
}
