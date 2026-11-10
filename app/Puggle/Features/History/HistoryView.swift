import CoreData
import SwiftUI

/// Everything logged, newest first, grouped by day, with a filter by activity.
struct HistoryView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Event.startedAt, order: .reverse)]) private var events: FetchedResults<Event>
    @State private var filter: EventKind?

    private var filtered: [Event] {
        guard let filter else { return Array(events) }
        return events.filter { $0.kind == filter }
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
                    ContentUnavailableView("Nothing logged yet",
                                           systemImage: "tray",
                                           description: Text("Entries from everyone in the family show up here."))
                        .listRowBackground(Color.clear)
                }
                ForEach(days) { group in
                    Section(group.day.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                        ForEach(group.events) { event in
                            EventRow(event: event)
                        }
                        .onDelete { offsets in
                            offsets.map { group.events[$0] }.forEach(store.delete)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Show", selection: $filter) {
                            Text("Everything").tag(EventKind?.none)
                            ForEach(EventKind.allCases) { kind in
                                Label(kind.title, systemImage: kind.symbol).tag(EventKind?.some(kind))
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter")
                }
            }
        }
    }
}

struct EventRow: View {
    @ObservedObject var event: Event

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.kind.symbol)
                .frame(width: 36, height: 36)
                .background(Palette.field, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(event.summary).font(.body.weight(.medium))
                HStack(spacing: 6) {
                    ForEach(event.sortedChildren) { ChildChip(child: $0) }
                    if let note = event.note, !note.isEmpty {
                        Text(note).font(.footnote).foregroundStyle(Palette.muted).lineLimit(1)
                    }
                }
            }
            Spacer()
            if let at = event.startedAt {
                Text(at, style: .time).font(.subheadline).foregroundStyle(Palette.muted).monospacedDigit()
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Palette.paper)
    }
}
