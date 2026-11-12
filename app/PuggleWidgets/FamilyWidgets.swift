import AppIntents
import SwiftUI
import WidgetKit

/// Warm, fixed colours: widgets follow the Home Screen's light or dark look.
private enum WTone {
    static let paper = Color(light: 0xFBF6E9, dark: 0x2A2420)
    static let field = Color(light: 0xEAE2D2, dark: 0x3B332D)
    static let ink = Color(light: 0x3A2A20, dark: 0xEBDDC4)
    static let muted = Color(light: 0x6B5E52, dark: 0xB3A590)
    static let night = Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x40 / 255)
    static let moon = Color(red: 0xF3 / 255, green: 0xE0 / 255, blue: 0xB8 / 255)
    static let childColours: [Color] = [Color(light: 0xBFD9F5, dark: 0x2E4A6E), Color(light: 0xF3D5C9, dark: 0x6A4236),
                                        Color(light: 0xCFE5D2, dark: 0x34523B), Color(light: 0xF6E2A8, dark: 0x5E4E22),
                                        Color(light: 0xE2D4F1, dark: 0x4B3D63), Color(light: 0xF6CFDC, dark: 0x6A3A4B)]
    static func child(_ index: Int) -> Color { childColours[((index % childColours.count) + childColours.count) % childColours.count] }
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self = Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

// MARK: Timeline

struct FamilyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    var chosenID: String?

    var chosen: WidgetSnapshot.Child? {
        guard let children = snapshot?.children, !children.isEmpty else { return nil }
        return children.first { $0.id == chosenID } ?? children.first
    }
}

/// "1 hr 35 min" or "12 min": updated each time the timeline refreshes.
private func since(_ date: Date, now: Date) -> String {
    let minutes = max(Int(now.timeIntervalSince(date) / 60), 0)
    if minutes < 1 { return "just now" }
    let h = minutes / 60, m = minutes % 60
    return h > 0 ? "\(h) hr \(m) min" : "\(m) min"
}

/// Refreshes every 15 minutes so "ago" stays right; the app also refreshes it on every change.
private func familyTimeline(_ snapshot: WidgetSnapshot?, chosen: String? = nil) -> Timeline<FamilyEntry> {
    let now = Date.now
    let entries = (0..<8).map { FamilyEntry(date: now.addingTimeInterval(Double($0) * 15 * 60), snapshot: snapshot, chosenID: chosen) }
    return Timeline(entries: entries, policy: .after(now.addingTimeInterval(2 * 3600)))
}

// MARK: One child (small)

struct ChildWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Child"
    static var description = IntentDescription("Choose whose day to show.")
    @Parameter(title: "Child") var child: WidgetChild?
}

struct ChildProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> FamilyEntry { FamilyEntry(date: .now, snapshot: .preview) }
    func snapshot(for configuration: ChildWidgetIntent, in context: Context) async -> FamilyEntry {
        FamilyEntry(date: .now, snapshot: context.isPreview ? .preview : (WidgetSnapshot.load() ?? .preview), chosenID: configuration.child?.id)
    }
    func timeline(for configuration: ChildWidgetIntent, in context: Context) async -> Timeline<FamilyEntry> {
        familyTimeline(WidgetSnapshot.load(), chosen: configuration.child?.id)
    }
}

struct ChildWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "puggle.child", intent: ChildWidgetIntent.self, provider: ChildProvider()) { entry in
            ChildWidgetView(entry: entry)
        }
        .configurationDisplayName("One child")
        .description("Since the last feed, and whether they're asleep.")
        .supportedFamilies([.systemSmall])
    }
}

private struct ChildWidgetView: View {
    let entry: FamilyEntry

    var body: some View {
        Group {
            if let child = entry.chosen {
                let asleep = child.asleepSince != nil
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(String(child.name.prefix(1)))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(width: 30, height: 30)
                            .background(WTone.child(child.colourIndex), in: Circle())
                        Text(child.name).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                    if let start = child.asleepSince {
                        Label("Asleep", systemImage: "moon.fill").font(.caption.weight(.semibold))
                        Text(start, style: .timer).font(.title2.weight(.semibold)).monospacedDigit()
                    } else if let fed = child.lastFeed {
                        Text("Since a feed").font(.caption.weight(.semibold)).foregroundStyle(WTone.muted)
                        Text(since(fed, now: entry.date)).font(.title3.weight(.semibold)).monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.7)
                        if let text = child.lastFeedText {
                            Text(text).font(.caption).foregroundStyle(WTone.muted).lineLimit(1)
                        }
                    } else {
                        Text("Nothing logged yet").font(.subheadline).foregroundStyle(WTone.muted)
                    }
                }
                .foregroundStyle(asleep ? WTone.moon : WTone.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .containerBackground(for: .widget) { asleep ? WTone.night : WTone.paper }
            } else {
                EmptyWidget()
            }
        }
    }
}

// MARK: The family (medium)

struct FamilyProvider: TimelineProvider {
    func placeholder(in context: Context) -> FamilyEntry { FamilyEntry(date: .now, snapshot: .preview) }
    func getSnapshot(in context: Context, completion: @escaping (FamilyEntry) -> Void) {
        completion(FamilyEntry(date: .now, snapshot: context.isPreview ? .preview : (WidgetSnapshot.load() ?? .preview)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FamilyEntry>) -> Void) {
        completion(familyTimeline(WidgetSnapshot.load()))
    }
}

struct FamilyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "puggle.family", provider: FamilyProvider()) { entry in
            FamilyWidgetView(entry: entry)
        }
        .configurationDisplayName("The family")
        .description("Every child, with buttons for a sleep and \(Terms.aNappy).")
        .supportedFamilies([.systemMedium])
    }
}

private struct FamilyWidgetView: View {
    let entry: FamilyEntry

    var body: some View {
        Group {
            if let children = entry.snapshot?.children, !children.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(children.prefix(3))) { child in
                        row(child, compact: children.count > 2)
                    }
                    Spacer(minLength: 0)
                }
                .containerBackground(for: .widget) { WTone.paper }
            } else {
                EmptyWidget()
            }
        }
    }

    private func row(_ child: WidgetSnapshot.Child, compact: Bool) -> some View {
        HStack(spacing: 10) {
            Text(String(child.name.prefix(1)))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(width: 30, height: 30)
                .background(WTone.child(child.colourIndex), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(child.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Group {
                    if let start = child.asleepSince {
                        Text("Asleep · ") + Text(start, style: .timer)
                    } else if let fed = child.lastFeed {
                        Text("Fed \(since(fed, now: entry.date)) ago")
                    } else {
                        Text("Nothing yet today")
                    }
                }
                .font(.caption)
                .foregroundStyle(WTone.muted)
                .monospacedDigit()
                .lineLimit(1)
            }
            Spacer(minLength: 4)
            if child.usesNappies && !compact {
                button(Terms.nappy, symbol: "drop", action: TimerActions.nappyWet, child: child, filled: false)
            }
            if child.asleepSince != nil {
                button("Woke", symbol: "sun.max", action: TimerActions.wokeUp, child: child, filled: true)
            } else {
                button("Sleep", symbol: "moon", action: TimerActions.startSleep, child: child, filled: true)
            }
        }
        .foregroundStyle(WTone.ink)
    }

    private func button(_ title: String, symbol: String, action: String, child: WidgetSnapshot.Child, filled: Bool) -> some View {
        Button(intent: TimerActionIntent(action, childID: child.id)) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 10)
                .frame(minHeight: 30)
                .foregroundStyle(filled ? WTone.paper : WTone.ink)
                .background(filled ? WTone.ink : WTone.field, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action == TimerActions.nappyWet ? "Log a wet \(Terms.nappyLower) for \(child.name)"
                            : action == TimerActions.wokeUp ? "\(child.name) woke up" : "Start \(child.name)'s sleep")
    }
}

/// Before the app has been opened (or in the free test build): a gentle prompt.
private struct EmptyWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "moon.stars").font(.title2)
            Text("Open the app to add your little ones.").font(.subheadline)
        }
        .foregroundStyle(WTone.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { WTone.paper }
    }
}

// MARK: Control Centre

@available(iOS 18.0, *)
struct StartSleepControlIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Start sleep"
    static var description = IntentDescription("Starts a child's sleep timer.")
    @Parameter(title: "Child") var child: WidgetChild?
}

@available(iOS 18.0, *)
struct StartSleepControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "puggle.startSleep", intent: StartSleepControlIntent.self) { configuration in
            let child = configuration.child ?? WidgetSnapshot.load()?.children.first.map { WidgetChild(id: $0.id, name: $0.name) }
            ControlWidgetButton(action: TimerActionIntent(TimerActions.startSleep, childID: child?.id ?? "")) {
                Label(child.map { "Sleep: \($0.name)" } ?? "Start sleep", systemImage: "moon.fill")
            }
        }
        .displayName("Start sleep")
        .description("Starts a sleep timer for the child you choose.")
    }
}
