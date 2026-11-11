import CoreData
import SwiftUI

/// Breastfeed timers: one for each side. Tapping a side starts it and stops
/// the other; tapping it again pauses. The feed keeps running if the sheet
/// is closed, and shows on the child's row on Today.
struct FeedTimerView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss

    let children: [Child]
    /// Called when the parent chooses "Enter a past feed" instead.
    let onPastFeed: () -> Void

    @State private var selected: NSManagedObjectID?
    @State private var confirmingDiscard = false
    @State private var loaded = false

    private var child: Child? { children.first { $0.objectID == selected } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Shown even for one child, so the sheet always says whose feed it is.
                    childPicker
                    if let child {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            timers(for: child, now: context.date)
                        }
                    } else {
                        Text("Choose who is feeding.")
                            .foregroundStyle(Palette.muted)
                    }
                    Button("Enter a past feed") {
                        onPastFeed()
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle(primary: false))
                }
                .padding(18)
            }
            .background(Palette.sand)
            .navigationTitle("Breastfeed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .foregroundStyle(Palette.ink)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: chooseChild)
    }

    /// Opens on a feed that is already running, else the only child, else the
    /// child last fed. For children born on the same day it never guesses.
    private func chooseChild() {
        guard !loaded else { return }
        loaded = true
        if let feeding = children.first(where: { store.activeFeed(for: $0) != nil }) {
            selected = feeding.objectID
        } else if children.count == 1 {
            selected = children.first?.objectID
        } else {
            let days = children.compactMap { $0.birthDate.map { Calendar.current.startOfDay(for: $0) } }
            guard Set(days).count == days.count else { return }
            selected = store.lastChild(for: .breastfeed, among: children)?.objectID
        }
    }

    private var childPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(children) { item in
                    let isOn = item.objectID == selected
                    Button {
                        Haptics.selection()
                        selected = item.objectID
                    } label: {
                        ChildChip(child: item, selected: isOn, ticked: isOn, large: true)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(item.displayName)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder private func timers(for child: Child, now: Date) -> some View {
        let feed = store.activeFeed(for: child)
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                sideButton("Left", child: child, feed: feed, now: now)
                sideButton("Right", child: child, feed: feed, now: now)
            }
            if let feed {
                let total = feed.feedSeconds("Left", now: now) + feed.feedSeconds("Right", now: now)
                Text("Started \((feed.startedAt ?? now).formatted(date: .omitted, time: .shortened)), \(Elapsed.clock(total)) in all")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Finish feed") {
                    Haptics.success()
                    store.finishFeed(for: child)
                    dismiss()
                }
                .buttonStyle(PillButtonStyle())
                Button("Discard this feed", role: .destructive) { confirmingDiscard = true }
                    .foregroundStyle(Palette.waratah)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .confirmationDialog("Discard this feed?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                        Button("Discard", role: .destructive) { store.discardFeed(for: child) }
                        Button("Keep it", role: .cancel) {}
                    }
            } else {
                Text("Tap a side to start. You can close this and the timer keeps going.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func sideButton(_ side: String, child: Child, feed: Event?, now: Date) -> some View {
        let running = feed?.runningSide == side
        let seconds = feed?.feedSeconds(side, now: now) ?? 0
        let state = running ? "Running" : (seconds > 0 ? "Paused" : "Tap to start")
        return Button {
            store.tapFeedSide(side, for: child)
        } label: {
            VStack(spacing: 6) {
                Text(side).font(.title3.weight(.semibold))
                Text(Elapsed.clock(seconds))
                    .displayFont(44)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: Int(seconds))
                HStack(spacing: 4) {
                    if running { Image(systemName: "checkmark").font(.caption.weight(.bold)) }
                    Text(state)
                }
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, minHeight: 170)
            .foregroundStyle(running ? Palette.paper : Palette.ink)
            .background(running ? Palette.ink : Palette.paper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .animation(.easeOut(duration: 0.2), value: running)
        }
        .buttonStyle(PressStyle(scale: 0.97))
        .accessibilityLabel("\(side) side, \(Elapsed.minutes(seconds)), \(state.lowercased())")
        .accessibilityHint(running ? "Pauses this side" : "Starts this side")
        .sensoryFeedback(trigger: running) { _, _ in Haptics.isOn ? .selection : nil }
    }
}
