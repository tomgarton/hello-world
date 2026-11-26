import SwiftUI

/// What the family looks after and how often: each item's gap (learned, or set by a parent), the family's own
/// items, and reminders on this phone.
struct CareSettingsView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    let children: [Child]
    @State private var newName = ""
    @State private var newIcon = CareItem.ownIcons[0]
    @State private var changes = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.careItems()) { item in
                        NavigationLink {
                            CareItemView(item: item, children: children)
                        } label: {
                            HStack(spacing: 12) {
                                item.image().frame(width: 24, height: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                    Text(gapLine(item)).font(.footnote).foregroundStyle(Palette.muted)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        let items = store.careItems()
                        for index in offsets where items[index].own { store.removeCareItem(items[index]) }
                        changes += 1
                    }
                } footer: {
                    Text("How often is learned from what's logged. A parent can set it instead. Swipe to remove one of your own.")
                }
                .listRowBackground(Palette.paper)

                if store.isParent {
                    Section("Add your own") {
                        TextField("Name, like swimming lessons", text: $newName)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CareItem.ownIcons, id: \.self) { icon in
                                    Button {
                                        Haptics.selection()
                                        newIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .frame(width: 44, height: 44)
                                            .background(newIcon == icon ? Palette.wattle.opacity(0.45) : Palette.field, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(icon.replacingOccurrences(of: ".", with: " "))
                                    .accessibilityAddTraits(newIcon == icon ? .isSelected : [])
                                }
                            }
                        }
                        Button("Add") {
                            if store.addCareItem(name: newName, icon: newIcon) != nil {
                                Haptics.success()
                                newName = ""
                                changes += 1
                            }
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .listRowBackground(Palette.paper)
                }
            }
            .id(changes)
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("Looking after")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .foregroundStyle(Palette.ink)
    }

    /// "Every 9 days, learned", or for several children with different gaps, the first child's that is learned.
    private func gapLine(_ item: CareItem) -> String {
        let gaps = children.compactMap { store.careGap(item, for: $0) }
        guard let gap = gaps.first(where: { $0.source != .starting }) ?? gaps.first else {
            return item.appointment ? "Book a visit from Today" : "Not logged yet"
        }
        switch gap.source {
        case .set: return "\(gap.text), set"
        case .learned: return "\(gap.text), learned"
        case .starting: return "\(gap.text) to start with"
        }
    }
}

/// One item: how often, and a reminder for each child on this phone.
private struct CareItemView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var reminders = ReminderStore.shared
    let item: CareItem
    let children: [Child]
    @State private var days = 7.0
    @State private var isSet = false
    @State private var loaded = false

    var body: some View {
        List {
            if !item.appointment || children.contains(where: { store.careGap(item, for: $0) != nil }) {
                Section {
                    ForEach(children) { child in
                        HStack {
                            Text(child.displayName)
                            Spacer()
                            Text(learned(child)).foregroundStyle(Palette.muted)
                        }
                    }
                } header: {
                    Text("Learned so far")
                }
                .listRowBackground(Palette.paper)
            }
            if store.isParent {
                Section {
                    Toggle("Set it myself", isOn: $isSet)
                        .onChange(of: isSet) { _, on in store.setCareGap(item, days: on ? days : nil) }
                    if isSet {
                        Stepper(CareGap(days: days, source: .set).text, value: $days, in: 0.5...365, step: days < 14 ? 1 : 7)
                            .onChange(of: days) { _, now in store.setCareGap(item, days: now) }
                    }
                } footer: {
                    Text("For the whole family. Off, it's learned from what's logged.")
                }
                .listRowBackground(Palette.paper)
            }
            Section {
                ForEach(children) { child in
                    Toggle(child.displayName, isOn: reminderBinding(child))
                }
            } header: {
                Text("Remind me")
            } footer: {
                Text(item.appointment
                     ? "The evening before a booked visit, on this iPhone only."
                     : "Once it's been the usual time since the last one, at 6 pm, on this iPhone only.")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            if let gap = children.first.flatMap({ store.careGap(item, for: $0) }) {
                days = gap.days
                isSet = gap.source == .set
            }
        }
    }

    private func learned(_ child: Child) -> String {
        guard let gap = store.careGap(item, for: child) else { return "Not yet" }
        return gap.source == .learned ? gap.text : "Not yet, \(gap.text.lowercased()) to start with"
    }

    private func reminder(for child: Child) -> Reminder? {
        reminders.reminders.first { $0.kind == .care && $0.careKey == item.key && $0.childID == child.id?.uuidString }
    }

    private func reminderBinding(_ child: Child) -> Binding<Bool> {
        Binding(get: { reminder(for: child)?.isOn == true }, set: { on in
            Task {
                if on { _ = await ReminderStore.shared.askPermission() }
                if var existing = reminder(for: child) {
                    existing.isOn = on
                    ReminderStore.shared.save(existing)
                } else if on {
                    var new = Reminder(kind: .care, childID: child.id?.uuidString ?? "")
                    new.careKey = item.key
                    new.times = [18 * 60]
                    ReminderStore.shared.save(new)
                }
            }
        })
    }
}
