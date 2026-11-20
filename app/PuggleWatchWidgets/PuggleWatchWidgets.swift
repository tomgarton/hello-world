import SwiftUI
import WidgetKit

/// Puggle on the watch face (20 November 2026): whoever is asleep or feeding, with the time counting up, or
/// otherwise how long since the first child was fed. A tap opens the Watch app. Reads the summary the Watch
/// app keeps in the shared App Group; with none yet, it is a plain Puggle button.
@main
struct PuggleWatchWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PuggleFace", provider: Provider()) { entry in
            FaceView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Puggle")
        .description("Who is asleep or feeding, or how long since a feed.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let child: WidgetSnapshot.Child?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, child: WidgetSnapshot.preview.children[0]) }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, child: context.isPreview ? WidgetSnapshot.preview.children[0] : Self.lead()))
    }

    /// One entry a minute for the next two hours, so "1h 35m ago" stays right; timers count by themselves.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let child = Self.lead()
        let entries = (0..<120).map { Entry(date: Date.now.addingTimeInterval(Double($0) * 60), child: child) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Whoever has a timer running, else the first child.
    static func lead() -> WidgetSnapshot.Child? {
        let children = WidgetSnapshot.load()?.children ?? []
        return children.first { $0.asleepSince != nil || $0.feedingSince != nil } ?? children.first
    }
}

struct FaceView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    private enum State {
        case asleep(Date), feeding(Date), fed(Date), nothing
    }

    private var state: State {
        guard let child = entry.child else { return .nothing }
        if let since = child.asleepSince { return .asleep(since) }
        if let since = child.feedingSince { return .feeding(since) }
        if let fed = child.lastFeed { return .fed(fed) }
        return .nothing
    }

    private var symbol: String {
        switch state {
        case .asleep: "moon.fill"
        case .feeding: "timer"
        case .fed: "waterbottle.fill"
        case .nothing: "moon.stars.fill"
        }
    }

    /// "1h 35m" or "40 min".
    private func short(_ since: Date) -> String {
        let minutes = max(Int(entry.date.timeIntervalSince(since) / 60), 0)
        return minutes >= 60 ? "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m" : "\(minutes) min"
    }

    @ViewBuilder private var amount: some View {
        switch state {
        case .asleep(let since), .feeding(let since): Text(since, style: .timer).monospacedDigit()
        case .fed(let at): Text(short(at))
        case .nothing: Text("Puggle")
        }
    }

    private var word: String {
        switch state {
        case .asleep: "Asleep"
        case .feeding: "Feeding"
        case .fed: "Fed"
        case .nothing: ""
        }
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                amount.font(.system(size: 12, weight: .semibold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            }
            .widgetAccentable()
        case .accessoryCorner:
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .widgetLabel { amount }
        case .accessoryInline:
            if let child = entry.child, !word.isEmpty {
                Text("\(child.name) · \(word) ") + Text(timerOrAgo)
            } else {
                Text("Puggle")
            }
        default:
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: symbol)
                    Text(entry.child?.name ?? "Puggle").fontWeight(.semibold)
                }
                .widgetAccentable()
                if !word.isEmpty {
                    HStack(spacing: 4) {
                        Text(word).foregroundStyle(.secondary)
                        amount.fontWeight(.semibold)
                        if case .fed = state { Text("ago").foregroundStyle(.secondary) }
                    }
                }
                if let child = entry.child, child.asleepSince == nil, let woke = child.lastWoke {
                    HStack(spacing: 4) {
                        Text("Awake").foregroundStyle(.secondary)
                        Text(short(woke)).fontWeight(.semibold)
                    }
                }
            }
            .font(.system(.footnote, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var timerOrAgo: String {
        switch state {
        case .asleep(let since), .feeding(let since): short(since)
        case .fed(let at): "\(short(at)) ago"
        case .nothing: ""
        }
    }
}
