import CoreData
import SwiftUI

/// One sheet for every activity. Pick the child (or several), set the few
/// details that matter, save. Nappy and potty save in one tap.
struct LogSheet: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss

    let kind: EventKind
    let children: [Child]

    @State private var selected: Set<NSManagedObjectIDWrapper> = []
    @State private var time = Date.now
    @State private var endTime = Date.now
    @State private var amount = 150.0
    @State private var milk = "Formula"
    @State private var side = "Left"
    @State private var minutes = 10.0
    @State private var food = ""
    @State private var note = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    childPicker
                    details
                    TextField("Note", text: $note, axis: .vertical)
                        .padding(14)
                        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(18)
            }
            .background(Palette.sand)
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                if needsSaveButton {
                    Button("Save \(kind.title.lowercased())") { save() }
                        .buttonStyle(PillButtonStyle())
                        .disabled(chosenChildren.isEmpty)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 8)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
        .onAppear(perform: chooseDefaultChild)
    }

    // MARK: Children

    private var chosenChildren: [Child] {
        children.filter { selected.contains(NSManagedObjectIDWrapper($0)) }
    }

    private var childPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(children) { child in
                    let key = NSManagedObjectIDWrapper(child)
                    Button {
                        if selected.contains(key) { selected.remove(key) } else { selected.insert(key) }
                    } label: {
                        ChildChip(child: child, selected: selected.contains(key))
                            .scaleEffect(1.15)
                            .padding(.horizontal, 4)
                    }
                    .accessibilityAddTraits(selected.contains(key) ? .isSelected : [])
                }
                if children.count > 1 {
                    Button("Everyone") { selected = Set(children.map(NSManagedObjectIDWrapper.init)) }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(Palette.field, in: Capsule())
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Default to the youngest child for feeds and nappies, the eldest for potty.
    private func chooseDefaultChild() {
        guard selected.isEmpty else { return }
        let byAge = children.sorted { ($0.birthDate ?? .distantPast) > ($1.birthDate ?? .distantPast) }
        let pick = (kind == .potty ? byAge.last : byAge.first) ?? children.first
        if let pick { selected = [NSManagedObjectIDWrapper(pick)] }
    }

    // MARK: Details

    private var needsSaveButton: Bool { !(kind == .nappy || kind == .potty) }

    @ViewBuilder private var details: some View {
        switch kind {
        case .bottle:
            VStack(spacing: 16) {
                HStack {
                    stepButton("minus") { amount = max(10, amount - 10) }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(amount))").font(.display(64)).monospacedDigit()
                        Text("ml").foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    stepButton("plus") { amount = min(400, amount + 10) }
                }
                Picker("Milk", selection: $milk) {
                    ForEach(["Formula", "Breast milk", "Mixed"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                timeRow("Time", $time)
            }
        case .breastfeed:
            VStack(spacing: 16) {
                Picker("Side", selection: $side) {
                    ForEach(["Left", "Right", "Both"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                Stepper("\(Int(minutes)) minutes", value: $minutes, in: 1...90)
                    .padding(14)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                timeRow("Started", $time)
            }
        case .solids:
            VStack(spacing: 16) {
                TextField("What did they try?", text: $food)
                    .padding(14)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                timeRow("Time", $time)
            }
        case .sleep:
            VStack(spacing: 16) {
                timeRow("Fell asleep", $time)
                timeRow("Woke up", $endTime)
                Text("For a nap happening now, use Asleep on the Today screen.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        case .nappy:
            quickChoices(["Wet", "Dirty", "Both", "Dry"])
        case .potty:
            quickChoices(["Wee", "Poo", "Accident", "Sat, nothing"])
        case .note:
            EmptyView()
        }
    }

    private func quickChoices(_ options: [String]) -> some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(option) { save(detail: option) }
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .foregroundStyle(Palette.ink)
                        .disabled(chosenChildren.isEmpty)
                }
            }
            timeRow("Time", $time)
            Text("One tap saves it.").font(.footnote).foregroundStyle(Palette.muted)
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(Palette.field, in: Circle())
        }
        .foregroundStyle(Palette.ink)
        .buttonRepeatBehavior(.enabled)
    }

    private func timeRow(_ label: String, _ date: Binding<Date>) -> some View {
        DatePicker(label, selection: date, in: ...Date.now.addingTimeInterval(60))
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Save

    private func save(detail: String? = nil) {
        let who = chosenChildren
        guard !who.isEmpty else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote
        switch kind {
        case .bottle:
            store.log(.bottle, for: who, at: time, amountML: amount, detail: milk, note: noteValue)
        case .breastfeed:
            store.log(.breastfeed, for: who, at: time, end: time.addingTimeInterval(minutes * 60), detail: side, note: noteValue)
        case .solids:
            store.log(.solids, for: who, at: time, detail: food, note: noteValue)
        case .sleep:
            store.log(.sleep, for: who, at: min(time, endTime), end: max(time, endTime), note: noteValue)
        case .nappy, .potty:
            store.log(kind, for: who, at: time, detail: detail, note: noteValue)
        case .note:
            store.log(.note, for: who, at: time, note: noteValue)
        }
        saved.toggle()
        dismiss()
    }
}

/// Lets a Set hold Core Data objects by identity.
struct NSManagedObjectIDWrapper: Hashable {
    let id: NSManagedObjectID
    init(_ object: NSManagedObject) { id = object.objectID }
}
