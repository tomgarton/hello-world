import CoreData
import SwiftUI

/// Everything logged, newest first, grouped by day, with a filter by activity.
struct HistoryView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Event.startedAt, order: .reverse)]) private var events: FetchedResults<Event>
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>
    /// Filters stay set until cleared, across launches.
    @AppStorage("historyKind") private var kindFilter = ""
    @AppStorage("historyChild") private var childFilter = ""
    @State private var looking: EditTarget?

    private var isFiltered: Bool { !kindFilter.isEmpty || !childFilter.isEmpty }

    private var filtered: [Event] {
        events.filter { event in
            let kindOK = kindFilter.isEmpty || event.kindRaw == kindFilter
            let childOK = childFilter.isEmpty
                || (event.children ?? []).contains { $0.id?.uuidString == childFilter }
            return kindOK && childOK
        }
    }

    private struct DayGroup: Identifiable {
        let day: Date
        let events: [Event]
        var id: Date { day }
    }

    private var days: [DayGroup] {
        let grouped = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.startedAt ?? .distantPast) }
        return grouped.keys.sorted(by: >).map { DayGroup(day: $0, events: grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                if days.isEmpty {
                    ContentUnavailableView(isFiltered ? "Nothing matches" : "Nothing here yet",
                                           systemImage: "tray",
                                           description: Text(isFiltered
                                                             ? "No entries match the filter."
                                                             : "Entries from everyone in the family show up here."))
                        .listRowBackground(Color.clear)
                    if isFiltered {
                        Button("Clear filters") { kindFilter = ""; childFilter = "" }
                            .listRowBackground(Palette.paper)
                    }
                }
                ForEach(days) { group in
                    Section(header: SquiggleLabel(group.day.formatted(.dateTime.weekday(.wide).day().month(.wide))).textCase(nil)) {
                        ForEach(group.events) { event in
                            Button { looking = EditTarget(event: event) } label: {
                                EventRow(event: event)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Palette.paper)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .alignmentGuide(.listRowSeparatorLeading) { _ in EventRow.iconWell + EventRow.gap }
                            .entrySwipeActions(event)
                            .accessibilityHint("Opens this entry")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .softTopEdge()
            .background(Palette.sand)
            .navigationTitle("History")
            .sheet(item: $looking) { EntryDetailView(event: $0.event) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if children.count > 1 {
                            Picker("Who", selection: $childFilter) {
                                Text("Everyone").tag("")
                                ForEach(children) { child in
                                    Text(child.displayName).tag(child.id?.uuidString ?? "")
                                }
                            }
                        }
                        Picker("What", selection: $kindFilter) {
                            Text("Everything").tag("")
                            ForEach(EventKind.allCases) { kind in
                                Label(kind.title, systemImage: kind.symbol).tag(kind.rawValue)
                            }
                        }
                        if isFiltered {
                            Button("Clear filters") { kindFilter = ""; childFilter = "" }
                        }
                    } label: {
                        Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(isFiltered ? "Filter, on" : "Filter")
                }
            }
        }
    }
}

struct EventRow: View {
    @ObservedObject var event: Event

    /// The same space above and below, everywhere a row is used.
    static let verticalPadding: CGFloat = 13
    static let iconWell: CGFloat = 44
    static let gap: CGFloat = 14

    var body: some View {
        HStack(alignment: .center, spacing: Self.gap) {
            ActivityIcon(event.kind, size: 24, plain: true)
                .frame(width: Self.iconWell, height: Self.iconWell)
                .background(Palette.field, in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(event.summary)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                // Who it was for, then quietly who logged it.
                HStack(alignment: .center, spacing: 8) {
                    ForEach(event.sortedChildren) { ChildChip(child: $0) }
                    if let who = event.loggedBy, !who.isEmpty {
                        Text("by \(who)").font(.footnote).foregroundStyle(Palette.muted).lineLimit(1)
                    }
                }
                if let note = event.note, !note.isEmpty {
                    Text(note).font(.footnote).foregroundStyle(Palette.muted).lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let at = event.startedAt {
                Text(at, style: .time).font(.subheadline).foregroundStyle(Palette.muted).monospacedDigit()
            }
        }
        .padding(.vertical, Self.verticalPadding)
        .contentShape(Rectangle())
    }
}
