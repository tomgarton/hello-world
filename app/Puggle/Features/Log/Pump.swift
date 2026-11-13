import CoreData
import SwiftUI

/// Pumping is the parent's, not a child's: a Pump entry has no children.
/// The total is in `amountML`, the left side in `value` (so right is the rest),
/// and where the milk went in `detail`. A "Count" entry records what is on hand
/// after the parent checks: fridge in `value`, freezer in `amountML`.
enum Pump {
    static let fridge = "Fridge"
    static let freezer = "Freezer"
    static let fed = "Fed"
    static let count = "Count"

    static func placeText(_ detail: String) -> String {
        switch detail {
        case fridge: "fridge"
        case freezer: "freezer"
        case fed: "fed straight away"
        default: detail.lowercased()
        }
    }
}

struct MilkOnHand: Equatable {
    var fridge: Double = 0
    var freezer: Double = 0
    var total: Double { fridge + freezer }
}

extension FamilyStore {
    private func events(of kinds: [EventKind]) -> [Event] {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(format: "kindRaw IN %@", kinds.map(\.rawValue))
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Pump entries, newest first.
    func pumps(limit: Int = 8) -> [Event] {
        Array(events(of: [.pump]).reversed().prefix(limit))
    }

    /// Breast milk in the fridge and freezer: from the last count, add what was
    /// pumped into each, and take each breast-milk bottle from the fridge first.
    func milkOnHand() -> MilkOnHand {
        let all = events(of: [.pump, .bottle])
        var milk = MilkOnHand()
        let start = all.lastIndex { $0.kind == .pump && $0.detail == Pump.count }
        if let start {
            milk.fridge = all[start].value
            milk.freezer = all[start].amountML
        }
        for event in all[(start.map { $0 + 1 } ?? 0)...] {
            switch (event.kind, event.detail) {
            case (.pump, Pump.fridge?): milk.fridge += event.amountML
            case (.pump, Pump.freezer?): milk.freezer += event.amountML
            case (.bottle, "Breast milk"?):
                let fromFridge = min(milk.fridge, event.amountML)
                milk.fridge -= fromFridge
                milk.freezer = max(milk.freezer - (event.amountML - fromFridge), 0)
            default: break
            }
        }
        return milk
    }

    func logPump(left: Double, right: Double, to place: String, at time: Date, note: String?) {
        let event = log(.pump, for: [], at: time, amountML: left + right, detail: place, note: note, value: left)
        lastSaved = LastSaved(events: [event], undo: .delete)
    }

    func setMilkOnHand(_ milk: MilkOnHand) {
        let event = log(.pump, for: [], at: .now, amountML: max(milk.freezer, 0), detail: Pump.count, value: max(milk.fridge, 0))
        lastSaved = LastSaved(events: [event], undo: .delete)
    }
}

/// Log a pump: each side, where it went, and what is on hand now.
struct PumpSheet: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    var editing: Event?

    @State private var left = 60.0
    @State private var right = 60.0
    @State private var place = Pump.fridge
    @State private var time = Date.now
    @State private var note = ""
    @State private var counting = false
    @State private var loaded = false
    @State private var confirmingDelete = false

    private var isCount: Bool { editing?.detail == Pump.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isCount {
                        Text("A count of what was on hand. To change it, add a new count.")
                            .foregroundStyle(Palette.muted)
                    } else {
                        side("Left", value: $left)
                        side("Right", value: $right)
                        Text("Total \(Units.volume(left + right))")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Picker("Where it went", selection: $place) {
                            Text("Fridge").tag(Pump.fridge)
                            Text("Freezer").tag(Pump.freezer)
                            Text("Fed").tag(Pump.fed)
                        }
                        .pickerStyle(.segmented)
                        DatePicker("Time", selection: $time, in: ...Date.now.addingTimeInterval(60))
                            .padding(.horizontal, 14)
                            .frame(minHeight: 52)
                            .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        TextField("Note", text: $note, axis: .vertical)
                            .padding(14)
                            .background(Palette.input, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    if editing == nil {
                        onHand
                    } else {
                        Button("Delete entry", role: .destructive) { confirmingDelete = true }
                            .foregroundStyle(Palette.waratah)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                                Button("Delete", role: .destructive) {
                                    if let editing { store.delete(editing) }
                                    dismiss()
                                }
                                Button("Keep it", role: .cancel) {}
                            }
                    }
                }
                .padding(16)
            }
            .background(Palette.sand)
            .navigationTitle(editing == nil ? "Pump" : "Edit pump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                if !isCount {
                    Button(editing == nil ? "Save pump" : "Save changes", action: save)
                        .buttonStyle(PillButtonStyle())
                        .disabled(left + right <= 0)
                        .opacity(left + right > 0 ? 1 : 0.5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Palette.sand)
                }
            }
            .sheet(isPresented: $counting) { MilkCountSheet(start: store.milkOnHand()) }
        }
        .foregroundStyle(Palette.ink)
        .presentationDetents(editing == nil ? [.medium, .large] : [.large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: load)
    }

    private var onHand: some View {
        let milk = store.milkOnHand()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Milk on hand").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fridge \(Units.volume(milk.fridge))")
                    Text("Freezer \(Units.volume(milk.freezer))")
                }
                .monospacedDigit()
                Spacer()
                Button("Update") { counting = true }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Palette.field, in: Capsule())
                    .buttonStyle(PressStyle())
            }
            Text("Pumps add to it and breast-milk bottles take from it. Update it after throwing some away.")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
        }
        .padding(14)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func side(_ title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.headline)
            Spacer()
            step("minus", label: "Less from the \(title.lowercased())") { value.wrappedValue = max(0, value.wrappedValue - 10) }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", value: value, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad)
                    .displayFont(34)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .fixedSize()
                    .accessibilityLabel("\(title) in millilitres")
                Text("ml").foregroundStyle(Palette.muted)
            }
            .frame(minWidth: 96, alignment: .trailing)
            step("plus", label: "More from the \(title.lowercased())") { value.wrappedValue = min(500, value.wrappedValue + 10) }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func step(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.step()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(Palette.field, in: Circle())
        }
        .foregroundStyle(Palette.ink)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(label)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let event = editing {
            left = event.value
            right = max(event.amountML - event.value, 0)
            place = event.detail ?? Pump.fridge
            time = event.startedAt ?? .now
            note = event.note ?? ""
        } else if let last = store.pumps(limit: 8).first(where: { $0.detail != Pump.count }) {
            // Start from the last pump's amounts and place.
            left = last.value
            right = max(last.amountML - last.value, 0)
            place = last.detail ?? Pump.fridge
        }
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = min(max(left, 0), 1000), r = min(max(right, 0), 1000)
        if let event = editing {
            event.value = l
            event.amountML = l + r
            event.detail = place
            event.startedAt = time
            event.note = trimmed.isEmpty ? nil : trimmed
            store.saveEdit(event)
        } else {
            store.logPump(left: l, right: r, to: place, at: time, note: trimmed.isEmpty ? nil : trimmed)
        }
        Haptics.success()
        dismiss()
    }
}

/// What is actually in the fridge and freezer now, after a look.
struct MilkCountSheet: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    let start: MilkOnHand
    @State private var fridge: Double?
    @State private var freezer: Double?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Fridge") {
                        TextField("ml", value: $fridge, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Freezer") {
                        TextField("ml", value: $freezer, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("In millilitres. The running total starts again from here.")
                }
                .listRowBackground(Palette.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("Milk on hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setMilkOnHand(MilkOnHand(fridge: fridge ?? 0, freezer: freezer ?? 0))
                        dismiss()
                    }
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .presentationDetents([.medium])
        .onAppear {
            fridge = start.fridge
            freezer = start.freezer
        }
    }
}
