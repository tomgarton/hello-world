import CoreData
import SwiftUI

/// Today: every child at once, then a card per activity showing the latest
/// entry for each child. Tapping + opens the log sheet for that activity.
struct TodayView: View {
    @EnvironmentObject private var store: FamilyStore
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>
    /// Watching events keeps the cards and status lines fresh when anyone logs.
    @FetchRequest(sortDescriptors: [SortDescriptor(\Event.createdAt)]) private var events: FetchedResults<Event>

    @State private var logging: EventKind?
    @State private var addingChild = false

    private let cardKinds: [EventKind] = [.bottle, .sleep, .nappy, .potty, .solids, .breastfeed]

    var body: some View {
        let _ = events.count
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if children.isEmpty {
                        emptyState
                    } else {
                        ForEach(children) { child in
                            ChildStatusRow(child: child)
                        }
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(cardKinds) { kind in
                                ActivityCard(kind: kind, children: Array(children)) { logging = kind }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Palette.sand)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $logging) { kind in
            LogSheet(kind: kind, children: Array(children))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $addingChild) {
            AddChildView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
            Text(children.isEmpty ? "Today" : ListFormatter.localizedString(byJoining: children.map(\.displayName)))
                .font(.display(32))
                .foregroundStyle(Palette.ink)
        }
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your little ones")
                .font(.title3.weight(.semibold))
            Text("Twins, siblings, as many as you have. Everyone in the family sees the same day.")
                .foregroundStyle(Palette.muted)
            Button("Add a child") { addingChild = true }
                .buttonStyle(PillButtonStyle())
        }
        .padding(18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// One line per child: who is asleep, when they last fed.
struct ChildStatusRow: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child

    var body: some View {
        HStack(spacing: 14) {
            ChildAvatar(child: child, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(child.displayName).font(.headline)
                    Text(child.ageText).foregroundStyle(Palette.muted)
                }
                status
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
            }
            Spacer()
            sleepButton
        }
        .padding(14)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder private var status: some View {
        if let sleep = store.activeSleep(for: child), let start = sleep.startedAt {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text("Asleep \(Elapsed.short(from: start, to: context.date))")
            }
        } else if let feed = store.latest(.bottle, for: child) ?? store.latest(.breastfeed, for: child), let at = feed.startedAt {
            Text("\(feed.summary), \(at.formatted(.relative(presentation: .named)))")
        } else if let event = store.latest(for: child), let at = event.startedAt {
            Text("\(event.summary), \(at.formatted(.relative(presentation: .named)))")
        } else {
            Text("Nothing logged yet")
        }
    }

    private var sleepButton: some View {
        let asleep = store.activeSleep(for: child) != nil
        return Button(asleep ? "Woke up" : "Asleep") {
            asleep ? store.endSleep(for: child) : store.startSleep(for: child)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .frame(minHeight: 40)
        .background(Palette.field, in: Capsule())
        .foregroundStyle(Palette.ink)
        .sensoryFeedback(.success, trigger: asleep)
    }
}

/// A card per activity, listing the latest entry for each child.
struct ActivityCard: View {
    @EnvironmentObject private var store: FamilyStore
    let kind: EventKind
    let children: [Child]
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                        .background(Palette.paper, in: Circle())
                }
                .foregroundStyle(Palette.ink)
                .accessibilityLabel("Log \(kind.title.lowercased())")
            }
            Text(kind.title).font(.title3.weight(.semibold))
            ForEach(children) { child in
                if let event = store.latest(kind, for: child), let at = event.startedAt {
                    HStack(spacing: 6) {
                        ChildChip(child: child)
                        Text(at, style: .time).font(.footnote).foregroundStyle(Palette.muted)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
