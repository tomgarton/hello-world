import SwiftUI

/// A child's milestones in order, with their age worked out for each.
struct MilestonesView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var child: Child

    @State private var adding = false
    @State private var editing: EditTarget?
    @State private var celebrating: String?

    var body: some View {
        let milestones = store.milestones(for: child)
        List {
            if milestones.isEmpty {
                Text("The moments worth keeping go here: a first smile, first steps, or anything you want to remember.")
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Palette.paper)
            }
            ForEach(milestones) { event in
                Button { editing = EditTarget(event: event) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "star")
                            .frame(width: 36, height: 36)
                            .background(Palette.field, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.summary).font(.body.weight(.medium))
                            if let at = event.startedAt {
                                Text(when(at)).font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Palette.paper)
                .accessibilityHint("Opens this milestone to change it")
            }
            Button("Add a milestone") { adding = true }
                .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .navigationTitle("\(child.displayName)'s milestones")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $adding, onDismiss: {
            // The hooray waits for the sheet to go, so the two never overlap.
            if let title = pendingTitle {
                pendingTitle = nil
                withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) { celebrating = title }
            }
        }) {
            LogSheet(kind: .milestone, children: [child]) { events in
                pendingTitle = events.first?.detail
            }
        }
        .sheet(item: $editing) { target in
            LogSheet(kind: .milestone, children: [child], editing: target.event)
        }
        .overlay {
            if let title = celebrating {
                Hooray(name: child.displayName, title: title) {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { celebrating = nil }
                }
                .transition(.opacity)
            }
        }
    }

    @State private var pendingTitle: String?

    /// "12 August 2026, at 3 months".
    private func when(_ date: Date) -> String {
        let day = date.formatted(.dateTime.day().month(.wide).year())
        let age = child.ageText(at: date)
        return age.isEmpty ? day : "\(day), at \(age)"
    }
}

/// The one big reaction in the app. Tap anywhere, or wait, and it goes.
private struct Hooray: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let name: String
    let title: String
    let onDone: () -> Void

    @State private var burst = false

    var body: some View {
        ZStack {
            Palette.wattle.ignoresSafeArea()
            // Stars stand in for the quatrefoils and the shiny sticker.
            ForEach(0..<10, id: \.self) { index in
                let angle = Double(index) / 10 * 2 * .pi
                Image(systemName: "star.fill")
                    .font(.system(size: index.isMultiple(of: 2) ? 30 : 20))
                    .foregroundStyle(Palette.paper)
                    .offset(x: cos(angle) * (burst ? 150 : 40), y: sin(angle) * (burst ? 210 : 60))
                    .opacity(burst ? 1 : 0)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 10) {
                Text("Hooray!").font(.display(54))
                Text("\(name): \(title)")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Palette.ink)
            .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Closes")
        .sensoryFeedback(.success, trigger: burst)
        .task {
            if reduceMotion {
                burst = true
            } else {
                withAnimation(.spring(duration: 0.7, bounce: 0.4)) { burst = true }
            }
            try? await Task.sleep(for: .seconds(3))
            onDone()
        }
    }
}
