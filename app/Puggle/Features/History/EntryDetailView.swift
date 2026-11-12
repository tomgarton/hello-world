import CoreData
import SwiftUI

extension FamilyStore {
    /// Whether "Again" makes sense: the same simple thing, logged now. Not for
    /// medicines (they have their own checks), sleeps, timers or one-offs.
    func canLogAgain(_ event: Event) -> Bool {
        switch event.kind {
        case .bottle, .nappy, .potty, .solids: true
        case .pump: event.detail != Pump.count
        default: false
        }
    }

    /// Logs the same entry again, for the same children, now. Undo is on Today.
    @discardableResult
    func logAgain(_ event: Event) -> [Event] {
        guard canLogAgain(event) else { return [] }
        if event.kind == .pump {
            logPump(left: event.value, right: max(event.amountML - event.value, 0),
                    to: event.detail ?? Pump.fridge, at: .now, note: nil)
            return lastSaved?.events ?? []
        }
        return logEach(event.kind, for: event.sortedChildren, at: .now, amountML: event.amountML,
                       detail: event.detail, dose: event.dose, value: event.value)
    }
}

/// One entry, to read. Changing it is a deliberate step: Edit, top right.
struct EntryDetailView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)]) private var children: FetchedResults<Child>
    @ObservedObject var event: Event
    @State private var editing = false
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ActivityIcon(event.kind, size: 28, plain: true)
                            .frame(width: 52, height: 52)
                            .background(Palette.field, in: Circle())
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.summary)
                                .font(.title3.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                ForEach(event.sortedChildren) { ChildChip(child: $0) }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Palette.paper)

                Section {
                    if let start = event.startedAt {
                        LabeledContent(event.endedAt == nil ? "Time" : "Started") {
                            Text(start.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    if let start = event.startedAt, let end = event.endedAt, event.kind == .sleep || event.kind == .breastfeed {
                        LabeledContent(event.kind == .sleep ? "Woke" : "Finished") {
                            Text(end.formatted(date: .omitted, time: .shortened))
                        }
                        LabeledContent("Length") { Text(Elapsed.short(from: start, to: end)) }
                    }
                    if let who = event.loggedBy, !who.isEmpty {
                        LabeledContent("Logged by") { Text(who) }
                    }
                    if let note = event.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note").font(.footnote).foregroundStyle(Palette.muted)
                            Text(note)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listRowBackground(Palette.paper)

                if store.canLogAgain(event) {
                    Section {
                        Button {
                            Haptics.success()
                            store.logAgain(event)
                            dismiss()
                        } label: {
                            Label("Log this again now", systemImage: "arrow.clockwise")
                        }
                    } footer: {
                        Text("Same details, for the same child, at the time now.")
                    }
                    .listRowBackground(Palette.paper)
                }

                Section {
                    Button("Delete entry", role: .destructive) { confirmingDelete = true }
                        .foregroundStyle(Palette.waratah)
                }
                .listRowBackground(Palette.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .navigationTitle(event.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Edit") { editing = true } }
            }
            .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Haptics.tap()
                    dismiss()
                    store.delete(event)
                }
                Button("Keep it", role: .cancel) {}
            }
            .sheet(isPresented: $editing) {
                if event.kind == .pump {
                    PumpSheet(editing: event)
                } else {
                    LogSheet(kind: event.kind, children: Array(children), editing: event)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Swipe left to delete, after a check; swipe right to log the same thing again.
struct EntrySwipeActions: ViewModifier {
    @EnvironmentObject private var store: FamilyStore
    let event: Event
    @State private var confirmingDelete = false

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    confirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(Palette.waratah)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if store.canLogAgain(event) {
                    Button {
                        Haptics.success()
                        store.logAgain(event)
                    } label: {
                        Label("Again", systemImage: "arrow.clockwise")
                    }
                    .tint(Palette.moonDeep)
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Haptics.tap()
                    store.delete(event)
                }
                Button("Keep it", role: .cancel) {}
            } message: {
                Text(event.summary)
            }
    }
}

extension Palette {
    /// A calm blue for a positive swipe action.
    static let moonDeep = Color(light: 0x4A6FA5, dark: 0x6E93C9, night: 0x56739C)
}

extension View {
    func entrySwipeActions(_ event: Event) -> some View { modifier(EntrySwipeActions(event: event)) }
}

/// A soft blur under the status bar, so content scrolling up behind it fades
/// out instead of running into the clock.
struct TopScrim: View {
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.safeAreaInsets.top + 22
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Palette.sand.opacity(0.55)
            }
            .mask(LinearGradient(stops: [.init(color: .black, location: 0),
                                         .init(color: .black, location: 0.55),
                                         .init(color: .clear, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(height: height)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// The system's soft edge where there is one (iOS 26); otherwise our own scrim.
    @ViewBuilder func softTopEdge() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self.overlay(alignment: .top) { TopScrim() }
        }
    }
}
