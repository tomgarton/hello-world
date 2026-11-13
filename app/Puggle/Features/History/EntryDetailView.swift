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
                .tint(Palette.waratahFill)
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
    static let moonDeep = Color(light: 0x4A6FA5, dark: 0x5A7FB8, night: 0x56739C)
}

extension View {
    func entrySwipeActions(_ event: Event) -> some View { modifier(EntrySwipeActions(event: event)) }
}

/// A soft blur under the status bar, so content scrolling up behind it fades
/// out instead of running into the clock.
struct TopScrim: View {
    /// 0 hides it (nothing under the clock yet), 1 shows it fully.
    var strength: Double = 1

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.safeAreaInsets.top + 64
            // Several soft steps rather than one edge, so there is no line where it ends.
            let fade = Gradient(stops: [.init(color: .black, location: 0),
                                        .init(color: .black.opacity(0.92), location: 0.3),
                                        .init(color: .black.opacity(0.6), location: 0.55),
                                        .init(color: .black.opacity(0.25), location: 0.78),
                                        .init(color: .clear, location: 1)])
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(colors: [Palette.sand.opacity(0.85), Palette.sand.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
            }
            .mask(LinearGradient(gradient: fade, startPoint: .top, endPoint: .bottom))
            .frame(height: height)
            .ignoresSafeArea(edges: .top)
            .opacity(strength)
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

/// History's swipes, for rows outside a system list (Today so far): drag left
/// for Delete, which asks first; drag right for Again. Vertical scrolling is
/// left alone, and a swipe only opens once it is clearly sideways.
struct SwipeableEntryRow<Content: View>: View {
    @EnvironmentObject private var store: FamilyStore
    let event: Event
    @ViewBuilder var content: Content

    @State private var offset: CGFloat = 0
    @State private var start: CGFloat = 0
    @State private var pulling = false
    @State private var confirmingDelete = false

    private let reveal: CGFloat = 84

    var body: some View {
        let canAgain = store.canLogAgain(event)
        ZStack {
            HStack(spacing: 0) {
                if canAgain {
                    action("Again", symbol: "arrow.clockwise", tint: Palette.moonDeep) {
                        Haptics.success()
                        close()
                        store.logAgain(event)
                    }
                    .opacity(offset > 12 ? 1 : 0)
                }
                Spacer(minLength: 0)
                action("Delete", symbol: "trash", tint: Palette.waratahFill) {
                    confirmingDelete = true
                }
                .opacity(offset < -12 ? 1 : 0)
            }
            content
                .background(Palette.paper)
                // While the row is being pulled, or sits open, a touch must not open the entry.
                .allowsHitTesting(offset == 0 && !pulling)
                .overlay {
                    // Open: a tap anywhere on the row closes it again.
                    if offset != 0 {
                        Color.clear.contentShape(Rectangle()).onTapGesture { close() }
                    }
                }
                .offset(x: offset)
        }
        .clipped()
        .modifier(SidewaysPull(
            onChanged: { across in
                if !pulling {
                    pulling = true
                    start = offset
                }
                offset = min(canAgain ? reveal * 1.2 : 0, max(-reveal * 1.2, start + across))
            },
            onEnded: {
                pulling = false
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                    if offset < -reveal / 2 { offset = -reveal }
                    else if offset > reveal / 2, canAgain { offset = reveal }
                    else { offset = 0 }
                }
            }))
        .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Haptics.tap()
                close()
                store.delete(event)
            }
            Button("Keep it", role: .cancel) { close() }
        } message: {
            Text(event.summary)
        }
        .accessibilityAction(named: "Delete") { confirmingDelete = true }
        .accessibilityAction(named: "Log again") {
            guard canAgain else { return }
            store.logAgain(event)
        }
    }

    private func close() {
        withAnimation(.spring(duration: 0.3, bounce: 0.1)) { offset = 0 }
    }

    private func action(_ title: String, symbol: String, tint: Color, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(tint, in: Circle())
                Text(title).font(.caption).foregroundStyle(Palette.muted)
            }
            .frame(width: reveal)
        }
        .buttonStyle(PressStyle())
        .accessibilityHidden(true)
    }
}

/// A sideways pull on a row inside a scrolling page.
///
/// The page's own scrolling must never be held up by it. So the pull is a
/// UIKit recogniser that only starts when the finger sets off sideways; a
/// finger moving up or down is refused at once and the page scrolls as usual.
/// Once a pull has started, the touch is taken from the row, so letting go
/// doesn't also press it.
private struct SidewaysPull: ViewModifier {
    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(SidewaysPan(onChanged: onChanged, onEnded: onEnded))
        } else {
            content.simultaneousGesture(Fallback(onChanged: onChanged, onEnded: onEnded).gesture)
        }
    }

    /// Before iOS 18 there is no way to put a UIKit recogniser on a SwiftUI view, so a drag stands in.
    private struct Fallback {
        let onChanged: (CGFloat) -> Void
        let onEnded: () -> Void
        var gesture: some Gesture {
            DragGesture(minimumDistance: 18)
                .onChanged { value in
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.6 else { return }
                    onChanged(value.translation.width)
                }
                .onEnded { _ in onEnded() }
        }
    }
}

@available(iOS 18.0, *)
private struct SidewaysPan: UIGestureRecognizerRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed:
            onChanged(recognizer.translation(in: recognizer.view).x)
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Only a finger setting off sideways starts the pull.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let speed = pan.velocity(in: pan.view)
            return abs(speed.x) > abs(speed.y) * 1.3
        }

        /// The page waits to hear whether this is a sideways pull. It hears at once, so scrolling is not slowed.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            other.view is UIScrollView
        }
    }
}
