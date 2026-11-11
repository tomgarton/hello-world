import CoreData
import SwiftUI

/// What an edit sheet is opened on. `endingSleep` is for "Set wake time" on a
/// timer that was left running.
struct EditTarget: Identifiable {
    let event: Event
    var endingSleep = false
    var id: NSManagedObjectID { event.objectID }
}

/// One sheet for every activity, for a new entry or to change an existing one.
/// Pick the child (or several), set the few details that matter, save.
/// A new nappy or potty entry saves in one tap.
struct LogSheet: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss

    let kind: EventKind
    let children: [Child]
    var editing: Event?
    var endingSleep = false

    @State private var selected: Set<NSManagedObjectIDWrapper> = []
    @State private var time = Date.now
    @State private var endTime = Date.now
    @State private var stillAsleep = false
    @State private var amount = 150.0
    @State private var amountTouched = false
    @State private var milk = "Formula"
    @State private var side = "Left"
    @State private var minutes = 10.0
    @State private var food = ""
    @State private var choice: String?
    @State private var note = ""
    @State private var saved = false
    @State private var confirmingDelete = false
    @State private var loaded = false
    @FocusState private var amountFocused: Bool

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    childPicker
                    details
                    TextField("Note", text: $note, axis: .vertical)
                        .padding(14)
                        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if isEditing {
                        Button("Delete entry", role: .destructive) { confirmingDelete = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                                Button("Delete", role: .destructive) { deleteEntry() }
                                Button("Keep it", role: .cancel) {}
                            }
                    }
                }
                .padding(18)
            }
            .background(Palette.sand)
            .navigationTitle(isEditing ? "Edit \(kind.title.lowercased())" : kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if needsSaveButton {
                    Button(isEditing ? "Save changes" : "Save \(kind.title.lowercased())") { save() }
                        .buttonStyle(PillButtonStyle())
                        .disabled(chosenChildren.isEmpty)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Palette.sand)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
        .presentationDetents(isEditing ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: load)
        .onChange(of: selected) { _, _ in rememberLastBottle() }
    }

    // MARK: Setup

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let event = editing {
            selected = Set(event.sortedChildren.map(NSManagedObjectIDWrapper.init))
            time = event.startedAt ?? .now
            endTime = event.endedAt ?? .now
            stillAsleep = kind == .sleep && event.endedAt == nil && !endingSleep
            note = event.note ?? ""
            switch kind {
            case .bottle:
                if event.amountML > 0 { amount = event.amountML }
                milk = event.detail ?? milk
                amountTouched = true
            case .breastfeed:
                side = event.detail ?? side
                if let end = event.endedAt { minutes = max(1, end.timeIntervalSince(time) / 60) }
            case .solids:
                food = event.detail ?? ""
            case .nappy, .potty:
                choice = event.detail
            case .sleep, .note:
                break
            }
        } else {
            chooseDefaultChild()
            rememberLastBottle()
        }
    }

    /// Open on the child last logged for this activity. For children born on the
    /// same day never guess: the parent picks one, or several.
    private func chooseDefaultChild() {
        guard selected.isEmpty else { return }
        if children.count == 1, let only = children.first {
            selected = [NSManagedObjectIDWrapper(only)]
            return
        }
        let days = children.compactMap { $0.birthDate.map { Calendar.current.startOfDay(for: $0) } }
        guard Set(days).count == days.count else { return }
        let byAge = children.sorted { ($0.birthDate ?? .distantPast) > ($1.birthDate ?? .distantPast) }
        let pick = store.lastChild(for: kind, among: children)
            ?? (kind == .potty ? byAge.last : byAge.first)
        if let pick { selected = [NSManagedObjectIDWrapper(pick)] }
    }

    /// A new bottle starts from that child's last amount and milk.
    private func rememberLastBottle() {
        guard kind == .bottle, !isEditing, !amountTouched,
              chosenChildren.count == 1, let child = chosenChildren.first,
              let last = store.latest(.bottle, for: child) else { return }
        if last.amountML > 0 { amount = last.amountML }
        if let what = last.detail, !what.isEmpty { milk = what }
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
                    let isOn = selected.contains(key)
                    Button {
                        if isEditing {
                            selected = [key]
                        } else if isOn {
                            selected.remove(key)
                        } else {
                            selected.insert(key)
                        }
                    } label: {
                        ChildChip(child: child, selected: isOn, ticked: isOn)
                            .scaleEffect(1.15)
                            .padding(.horizontal, 6)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(child.displayName)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
                if children.count > 1, !isEditing {
                    Button("Everyone") { selected = Set(children.map(NSManagedObjectIDWrapper.init)) }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(Palette.field, in: Capsule())
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: Details

    /// A new nappy or potty entry saves from its choice buttons.
    private var needsSaveButton: Bool { isEditing || !(kind == .nappy || kind == .potty) }

    @ViewBuilder private var details: some View {
        switch kind {
        case .bottle:
            VStack(spacing: 16) {
                HStack {
                    stepButton("minus", label: "Less") { amount = max(10, amount - 10) }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("0", value: $amount, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .focused($amountFocused)
                            .font(.display(64))
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                            .accessibilityLabel("Amount in millilitres")
                        Text("ml").foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    stepButton("plus", label: "More") { amount = min(400, amount + 10) }
                }
                Picker("Milk", selection: $milk) {
                    ForEach(["Formula", "Breast milk", "Mixed"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                timeRow("Time", $time)
                timeShortcuts
            }
            .onChange(of: amountFocused) { _, focused in if focused { amountTouched = true } }
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
                timeShortcuts
            }
        case .solids:
            VStack(alignment: .leading, spacing: 16) {
                TextField("What did they try?", text: $food)
                    .padding(14)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                if !pastFoods.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(pastFoods, id: \.self) { item in
                                Button(item) { food = item }
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 44)
                                    .background(Palette.field, in: Capsule())
                            }
                        }
                    }
                }
                timeRow("Time", $time)
                timeShortcuts
            }
        case .sleep:
            VStack(spacing: 16) {
                timeRow("Fell asleep", $time)
                if isEditing, editing?.endedAt == nil {
                    Toggle("Still asleep", isOn: $stillAsleep)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                if !stillAsleep {
                    timeRow("Woke up", $endTime)
                }
                if !isEditing {
                    Text("For a nap happening now, use Start sleep on the Today screen.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
            }
        case .nappy:
            quickChoices(["Wet", "Dirty", "Both", "Dry"])
        case .potty:
            quickChoices(["Wee", "Poo", "Accident", "Sat, nothing"])
        case .note:
            timeRow("Time", $time)
        }
    }

    /// Foods this family has logged before, newest first.
    private var pastFoods: [String] {
        var solids: [Event] = []
        for child in children {
            solids += (child.events ?? []).filter { $0.kind == .solids }
        }
        solids.sort { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
        var seen = Set<String>()
        var foods: [String] = []
        for event in solids {
            let name = (event.detail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty, seen.insert(name.lowercased()).inserted { foods.append(name) }
            if foods.count == 8 { break }
        }
        return foods
    }

    private func quickChoices(_ options: [String]) -> some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options, id: \.self) { option in
                    let isOn = isEditing && choice == option
                    Button {
                        if isEditing { choice = option } else { save(detail: option) }
                    } label: {
                        HStack(spacing: 6) {
                            if isOn { Image(systemName: "checkmark").font(.subheadline.weight(.bold)) }
                            Text(option)
                        }
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Palette.ink, lineWidth: isOn ? 2 : 0))
                    }
                    .foregroundStyle(Palette.ink)
                    .disabled(chosenChildren.isEmpty)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            timeRow("Time", $time)
            timeShortcuts
            if !isEditing {
                Text(chosenChildren.isEmpty ? "Choose who it's for first." : "One tap saves it.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        }
    }

    private func stepButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            amountTouched = true
            action()
        } label: {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(Palette.field, in: Circle())
        }
        .foregroundStyle(Palette.ink)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(label)
    }

    private func timeRow(_ label: String, _ date: Binding<Date>) -> some View {
        DatePicker(label, selection: date, in: ...Date.now.addingTimeInterval(60))
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// One tap for the common "I forgot to log it" cases.
    private var timeShortcuts: some View {
        HStack(spacing: 8) {
            shortcut("Now") { time = .now }
            shortcut("Earlier today") {
                let today = Calendar.current.startOfDay(for: .now)
                let base = Calendar.current.isDateInToday(time) ? time : Date.now
                time = max(today, base.addingTimeInterval(-3600))
            }
            shortcut("Yesterday") {
                if let moved = Calendar.current.date(byAdding: .day, value: -1, to: .now) { time = moved }
            }
            Spacer(minLength: 0)
        }
    }

    private func shortcut(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Palette.field, in: Capsule())
    }

    // MARK: Save

    private func save(detail: String? = nil) {
        let who = chosenChildren
        guard !who.isEmpty else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote
        let ml = min(max(amount, 0), 1000)
        let trimmedFood = food.trimmingCharacters(in: .whitespacesAndNewlines)

        if let event = editing {
            event.children = Set(who)
            event.note = noteValue
            switch kind {
            case .bottle:
                event.startedAt = time
                event.amountML = ml
                event.detail = milk
            case .breastfeed:
                event.startedAt = time
                event.endedAt = time.addingTimeInterval(minutes * 60)
                event.detail = side
            case .solids:
                event.startedAt = time
                event.detail = trimmedFood
            case .sleep:
                if stillAsleep {
                    event.startedAt = time
                    event.endedAt = nil
                } else {
                    event.startedAt = min(time, endTime)
                    event.endedAt = max(time, endTime)
                }
            case .nappy, .potty:
                event.startedAt = time
                event.detail = choice
            case .note:
                event.startedAt = time
            }
            store.saveEdit(event)
        } else {
            switch kind {
            case .bottle:
                store.logEach(.bottle, for: who, at: time, amountML: ml, detail: milk, note: noteValue)
            case .breastfeed:
                store.logEach(.breastfeed, for: who, at: time, end: time.addingTimeInterval(minutes * 60), detail: side, note: noteValue)
            case .solids:
                store.logEach(.solids, for: who, at: time, detail: trimmedFood, note: noteValue)
            case .sleep:
                store.logEach(.sleep, for: who, at: min(time, endTime), end: max(time, endTime), note: noteValue)
            case .nappy, .potty:
                store.logEach(kind, for: who, at: time, detail: detail, note: noteValue)
            case .note:
                store.logEach(.note, for: who, at: time, note: noteValue)
            }
        }
        saved.toggle()
        dismiss()
    }

    private func deleteEntry() {
        guard let event = editing else { return }
        dismiss()
        store.delete(event)
    }
}

/// Lets a Set hold Core Data objects by identity.
struct NSManagedObjectIDWrapper: Hashable {
    let id: NSManagedObjectID
    init(_ object: NSManagedObject) { id = object.objectID }
}
