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
    /// Called with the new entries after a save (not after an edit).
    var onSaved: ([Event]) -> Void = { _ in }

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
    @State private var medicine = ""
    @State private var doseText = ""
    @State private var gapText = ""
    @State private var limitText = ""
    @State private var readingLabel = false
    @State private var readingTin = false
    @State private var openGuide: Guide?
    @State private var temperature: Double?
    @State private var place = ""
    @State private var vaccine = ""
    @State private var grams: Double?
    @State private var milestone = ""
    /// Each child's own amount when a bottle is logged for several at once.
    @State private var amounts: [NSManagedObjectIDWrapper: Double] = [:]
    @State private var loadedFeed: (side: String, minutes: Double)?
    @State private var tooSoon: String?
    @State private var twice: String?
    @State private var confirmedTwice = false
    /// Solids: how it went. Nappy: the colour. Both optional.
    @State private var extra = ""
    @State private var confirmedTooSoon = false
    @State private var saved = false
    @State private var confirmingDelete = false
    @State private var loaded = false
    @FocusState private var amountFocused: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    childPicker
                    details
                    TextField("Note", text: $note, axis: .vertical)
                        .padding(14)
                        .background(Palette.input, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if let editing, store.canChange(editing) {
                        Button("Delete entry", role: .destructive) { confirmingDelete = true }
                    .foregroundStyle(Palette.waratah)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .alert("Delete this entry?", isPresented: $confirmingDelete) {
                                Button("Delete", role: .destructive) { deleteEntry() }
                                Button("Keep it", role: .cancel) {}
                            }
                    }
                }
                .padding(16)
            }
            .background(Palette.sand)
            .navigationTitle(isEditing ? "Edit \(kind.title.lowercased())" : kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        amountFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if needsSaveButton {
                    // Solid on purpose: as glass, the main action let the form show through
                    // and all but vanished when disabled.
                    Button(isEditing ? "Save changes" : "Save \(kind.title.lowercased())") { save() }
                        .buttonStyle(PillButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Palette.sand)
                }
            }
            .alert("Too soon?", isPresented: Binding(get: { tooSoon != nil }, set: { if !$0 { tooSoon = nil } })) {
                Button("Log anyway") {
                    confirmedTooSoon = true
                    save()
                }
                Button("Don't log", role: .cancel) {}
            } message: {
                Text(tooSoon ?? "")
            }
            .alert("Logged twice?", isPresented: Binding(get: { twice != nil }, set: { if !$0 { twice = nil } })) {
                Button("Save anyway") {
                    confirmedTwice = true
                    save()
                }
                Button("Don't save", role: .cancel) {}
            } message: {
                Text(twice ?? "")
            }
        }
        .foregroundStyle(Palette.ink)
        // Full height at the largest text sizes, where half a screen is not enough room.
        .presentationDetents(isEditing || textSize.isAccessibilitySize ? [.large] : [.medium, .large])
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
                let timed = event.feedSeconds("Left") + event.feedSeconds("Right")
                if timed > 0 {
                    minutes = min(max(1, (timed / 60).rounded()), 90)
                } else if let end = event.endedAt {
                    minutes = min(max(1, (end.timeIntervalSince(time) / 60).rounded()), 90)
                }
                loadedFeed = (side, minutes)
            case .solids:
                food = event.detail ?? ""
                extra = event.dose ?? ""
            case .nappy, .potty:
                choice = event.detail
                extra = event.dose ?? ""
            case .medicine:
                medicine = event.detail ?? ""
                doseText = event.dose ?? ""
                gapText = Self.savedGap(for: medicine)
                limitText = Self.savedLimit(for: medicine)
            case .temperature:
                temperature = event.value > 0 ? event.value : nil
                place = event.detail ?? ""
            case .vaccination:
                vaccine = event.detail ?? ""
            case .weight:
                grams = event.value > 0 ? event.value : nil
            case .milestone:
                milestone = event.detail ?? ""
            case .sleep, .note, .pump:
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
                        Haptics.selection()
                        if isEditing {
                            selected = [key]
                        } else if isOn {
                            selected.remove(key)
                        } else {
                            selected.insert(key)
                        }
                    } label: {
                        ChildChip(child: child, selected: isOn, ticked: isOn, large: true)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(child.displayName)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
                if children.count > 1, !isEditing {
                    Button("Everyone") {
                        Haptics.selection()
                        selected = Set(children.map(NSManagedObjectIDWrapper.init))
                    }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 40)
                        .background(Palette.field, in: Capsule())
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: Details

    /// A new nappy or potty entry saves from its choice buttons.
    private var needsSaveButton: Bool { isEditing || !(kind == .nappy || kind == .potty) }

    private var canSave: Bool {
        guard !chosenChildren.isEmpty else { return false }
        switch kind {
        case .medicine: return !medicine.trimmingCharacters(in: .whitespaces).isEmpty
        case .temperature: return (temperature ?? 0) > 0
        case .vaccination: return !vaccine.trimmingCharacters(in: .whitespaces).isEmpty
        case .weight: return (grams ?? 0) > 0
        case .milestone: return !milestone.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    // MARK: Medicine gaps

    /// The smallest gap the parent set for each medicine, in hours, by name.
    /// The app only ever checks against this; it never suggests one.
    private static func savedGap(for name: String) -> String {
        MedicineRules.gap(for: name).map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? ""
    }

    private static func savedLimit(for name: String) -> String {
        MedicineRules.limit(for: name).map(String.init) ?? ""
    }

    private var limitCount: Int? { Int(limitText).flatMap { $0 > 0 ? $0 : nil } }

    private var gapHours: Double? {
        Double(gapText.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil }
    }

    private func rememberGap() {
        // A helper logs against the family's rules and doesn't change them.
        guard store.isParent else { return }
        MedicineRules.set(gap: gapHours, limit: limitCount, for: medicine)
    }

    private func tooSoonWarning(for who: [Child]) -> String? {
        let name = medicine.trimmingCharacters(in: .whitespaces)
        // The most doses in 24 hours, as the parent set it from the box.
        if let limit = limitCount {
            for child in who {
                let recent = store.doses(of: name, for: child).compactMap(\.startedAt)
                    .filter { $0 <= time && $0 > time.addingTimeInterval(-24 * 3600) }
                if recent.count >= limit {
                    let next = store.nextDose(of: name, for: child, now: time).map { " The next fits from \($0.formatted(date: .omitted, time: .shortened))." } ?? ""
                    return "\(child.displayName) has had \(recent.count) doses of \(name) in the last 24 hours. The most you set is \(limit).\(next)"
                }
            }
        }
        guard let gap = gapHours else { return nil }
        for child in who {
            guard let last = store.lastDose(of: name, for: child), let at = last.startedAt else { continue }
            let since = time.timeIntervalSince(at)
            if since >= 0 && since < gap * 3600 {
                let hours = gap.formatted(.number.precision(.fractionLength(0...1)))
                return "\(child.displayName) had \(name) \(Elapsed.short(from: at, to: time)) ago. The gap you set is \(hours) hours."
            }
        }
        return nil
    }

    /// A second bottle for the same child within five minutes is probably the
    /// same feed logged twice (two parents, or a double tap).
    private func loggedTwiceWarning(for who: [Child]) -> String? {
        for child in who {
            guard let last = store.latest(.bottle, for: child), let at = last.startedAt,
                  abs(time.timeIntervalSince(at)) < 5 * 60 else { continue }
            let by = (last.loggedBy ?? "").isEmpty ? "" : " by \(last.loggedBy!)"
            return "\(child.displayName) already has a bottle at \(at.formatted(date: .omitted, time: .shortened))\(by). Save another one?"
        }
        return nil
    }

    /// Medicines this family has logged, newest first, with the last dose written.
    private var pastMedicines: [(name: String, dose: String)] {
        var all: [Event] = []
        for child in children {
            all += (child.events ?? []).filter { $0.kind == .medicine }
        }
        all.sort { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
        var seen = Set<String>()
        var result: [(name: String, dose: String)] = []
        // Regular medicines set up as reminders come first, so the name always matches.
        let ids = Set(children.compactMap { $0.id?.uuidString })
        for reminder in ReminderStore.shared.reminders where reminder.kind == .medicine && ids.contains(reminder.childID) {
            let name = reminder.medicine.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty, seen.insert(name.lowercased()).inserted { result.append((name, reminder.dose)) }
        }
        for event in all {
            let name = (event.detail ?? "").trimmingCharacters(in: .whitespaces)
            if !name.isEmpty, seen.insert(name.lowercased()).inserted {
                result.append((name, event.dose ?? ""))
            }
            if result.count == 6 { break }
        }
        return result
    }

    /// A labelled number, so the label stays once something is typed.
    private func ruleField(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("Optional", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
        .padding(14)
        .background(Palette.input, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func field(_ prompt: String, text: Binding<String>) -> some View {
        TextField(prompt, text: text)
            .padding(14)
            .background(Palette.input, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func chip(_ title: String, isOn: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 4) {
                if isOn { Image(systemName: "checkmark").font(.caption2.weight(.bold)) }
                Text(title)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Palette.field, in: Capsule())
            .overlay(Capsule().stroke(Palette.ink, lineWidth: isOn ? 1.5 : 0))
            .animation(.easeOut(duration: 0.15), value: isOn)
        }
        .buttonStyle(PressStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func bigNumber(_ prompt: String, value: Binding<Double?>, digits: Int, unit: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Spacer()
            TextField(prompt, value: value, format: .number.precision(.fractionLength(digits)))
                .keyboardType(digits == 0 ? .numberPad : .decimalPad)
                .displayFont(56)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .fixedSize()
                .accessibilityLabel(label)
            Text(unit).foregroundStyle(Palette.muted)
            Spacer()
        }
    }

    /// Under the milk: the family's saved tin, with any row change coming up, or a way to read one.
    @ViewBuilder private var tinRow: some View {
        if let tin = store.formulaGuide() {
            VStack(spacing: 10) {
                ForEach(chosenChildren) { child in RowNoticeCard(guide: tin, child: child) }
                Button { openGuide = tin } label: {
                    HStack {
                        Label(tin.name ?? "Formula", systemImage: "tablecells")
                        Spacer()
                        Text("See the table").foregroundStyle(Palette.muted)
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.muted)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).frame(minHeight: 48)
                    .background(Palette.input, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .sheet(item: $openGuide) { GuideView(guide: $0, children: chosenChildren) }
            }
        } else if store.isParent {
            Button { readingTin = true } label: {
                Label("Read the tin", systemImage: "camera.viewfinder")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
            }
            .foregroundStyle(Palette.ink)
            .accessibilityHint("Types up the table of ages, water and scoops from a photo, for the family.")
            .sheet(isPresented: $readingTin) { BoxReaderView(kind: .formula) }
        }
    }

    @ViewBuilder private var details: some View {
        switch kind {
        case .bottle:
            VStack(spacing: 16) {
                if ownAmounts {
                    ForEach(chosenChildren) { child in ownAmountRow(child) }
                } else {
                    HStack {
                        stepButton("minus", label: "Less") { amount = max(Units.volumeFloor, amount - Units.volumeStep(from: amount, down: true)) }
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            // Shown and typed in the parent's units; stored in millilitres.
                            TextField("0", value: Binding(get: { Units.volumeValue(amount) },
                                                          set: { amount = Units.volumeFromValue($0) }),
                                      format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(Units.ounces ? .decimalPad : .numberPad)
                                .focused($amountFocused)
                                .displayFont(64)
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .fixedSize()
                                .accessibilityLabel(Units.ounces ? "Amount in ounces" : "Amount in millilitres")
                            Text(Units.volumeUnit).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        stepButton("plus", label: "More") { amount = min(400, amount + Units.volumeStep(from: amount, down: false)) }
                    }
                }
                Picker("Milk", selection: $milk) {
                    ForEach(["Formula", "Breast milk", "Mixed"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                if milk != "Breast milk", !isEditing { tinRow }
                if milk == "Breast milk", !isEditing {
                    let onHand = store.milkOnHand()
                    if onHand.total > 0 {
                        Text("On hand: \(Units.volume(onHand.fridge)) in the fridge, \(Units.volume(onHand.freezer)) in the freezer.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
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
                    .background(Palette.input, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                Text("How it went (optional)").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                HStack(spacing: 8) {
                    ForEach(["Loved it", "Some", "Not today"], id: \.self) { option in
                        chip(option, isOn: extra == option) { extra = (extra == option ? "" : option) }
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
            VStack(alignment: .leading, spacing: 12) {
                // Optional, and picked before the one-tap choice.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Colour").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                        ForEach(["Yellow", "Mustard", "Green", "Brown", "Black", "Pale"], id: \.self) { option in
                            chip(option, isOn: extra == option) { extra = (extra == option ? "" : option) }
                        }
                    }
                }
                .accessibilityLabel("Colour, optional")
                quickChoices(["Wet", "Dirty", "Both", "Dry"])
            }
        case .potty:
            quickChoices(["Wee", "Poo", "Tried", "Accident"])
        case .note:
            timeRow("Time", $time)
        case .medicine:
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    field("Which medicine?", text: $medicine)
                    if store.isParent {
                        Button { readingLabel = true } label: {
                            Image(systemName: "camera.viewfinder")
                                .font(.title3)
                                .frame(width: 50, height: 50)
                                .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .foregroundStyle(Palette.ink)
                        .accessibilityLabel("Read the box")
                        .sheet(isPresented: $readingLabel) {
                            BoxReaderView(kind: .medicine, existing: store.medicineBox(named: medicine), startName: medicine) { guide in
                                medicine = guide.name ?? medicine
                                gapText = guide.gapHours > 0 ? guide.gapHours.formatted(.number.precision(.fractionLength(0...1))) : ""
                                limitText = guide.doseLimit > 0 ? String(guide.doseLimit) : ""
                            }
                        }
                    }
                }
                if let box = store.medicineBox(named: medicine) {
                    Button { openGuide = box } label: {
                        Label("See the \(box.name ?? "medicine") box", systemImage: "tablecells")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Palette.ink)
                    .frame(minHeight: 44)
                    .sheet(item: $openGuide) { GuideView(guide: $0, children: chosenChildren) }
                }
                if chosenChildren.count == 1, let child = chosenChildren.first, !isEditing,
                   let summary = store.doseSummary(of: medicine, for: child) {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                        .monospacedDigit()
                }
                if !pastMedicines.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(pastMedicines, id: \.name) { item in
                                chip(item.dose.isEmpty ? item.name : "\(item.name), \(item.dose)") {
                                    medicine = item.name
                                    doseText = item.dose
                                    gapText = Self.savedGap(for: item.name)
                                    limitText = Self.savedLimit(for: item.name)
                                }
                            }
                        }
                    }
                }
                field("Dose, as on the label or as prescribed", text: $doseText)
                Group {
                    ruleField("Smallest gap, in hours", text: $gapText, keyboard: .decimalPad)
                    ruleField("Most doses in 24 hours", text: $limitText, keyboard: .numberPad)
                }
                .disabled(!store.isParent)
                Text(store.isParent ? "Shared with your family, so every phone makes the same check."
                                    : "Set by \(store.whoToAsk), and the same on every phone in the family.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("From the box or prescription. The app asks before a dose that goes past them, and never suggests one.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                timeRow("Time", $time)
                timeShortcuts
            }
        case .temperature:
            VStack(alignment: .leading, spacing: 16) {
                bigNumber("0.0", value: Binding(get: { temperature.map(Units.temperatureValue) }, set: { temperature = $0.map(Units.temperatureFromValue) }),
                          digits: 1, unit: Units.temperatureUnit, label: Units.fahrenheit ? "Temperature in degrees Fahrenheit" : "Temperature in degrees Celsius")
                HStack(spacing: 8) {
                    ForEach(["Ear", "Forehead", "Underarm", "Mouth"], id: \.self) { option in
                        chip(option, isOn: place == option) { place = (place == option ? "" : option) }
                    }
                }
                timeRow("Time", $time)
                timeShortcuts
            }
        case .vaccination:
            VStack(alignment: .leading, spacing: 16) {
                field("Which vaccination?", text: $vaccine)
                timeRow("Time", $time)
                timeShortcuts
            }
        case .weight:
            VStack(alignment: .leading, spacing: 16) {
                weightInput
                if let change = weightChange {
                    Text(change).foregroundStyle(Palette.muted)
                }
                timeRow("Time", $time)
                timeShortcuts
            }
        case .milestone:
            VStack(alignment: .leading, spacing: 16) {
                field("What happened?", text: $milestone)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.firsts, id: \.self) { item in
                            chip(item, isOn: milestone == item) { milestone = item }
                        }
                    }
                }
                timeRow("When", $time)
            }
        case .pump:
            EmptyView()
        }
    }

    /// Firsts to pick from. No ages are attached: they happen when they happen.
    private static let firsts = ["First smile", "First laugh", "Rolled over", "Sat up", "First tooth",
                                 "First food", "Crawled", "First word", "First steps", "Slept through"]

    // MARK: Own amounts

    /// Several children on one bottle sheet get a row each.
    private var ownAmounts: Bool { !isEditing && chosenChildren.count > 1 }

    /// A child's amount: what was typed here, else their last bottle, else the sheet's amount.
    private func ownAmount(_ child: Child) -> Double {
        if let typed = amounts[NSManagedObjectIDWrapper(child)] { return typed }
        if let last = store.latest(.bottle, for: child), last.amountML > 0 { return last.amountML }
        return amount
    }

    private func ownAmountRow(_ child: Child) -> some View {
        let key = NSManagedObjectIDWrapper(child)
        let value = Binding<Double>(get: { ownAmount(child) }, set: { amounts[key] = $0 })
        return HStack(spacing: 10) {
            ChildChip(child: child)
            Spacer(minLength: 0)
            smallStep("minus", label: "Less for \(child.displayName)") { amounts[key] = max(10, ownAmount(child) - Units.volumeStep) }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", value: Binding(get: { Units.volumeValue(value.wrappedValue) },
                                              set: { value.wrappedValue = Units.volumeFromValue($0) }),
                          format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(Units.ounces ? .decimalPad : .numberPad)
                    .displayFont(34)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .fixedSize()
                    .accessibilityLabel("\(child.displayName)'s amount in \(Units.ounces ? "ounces" : "millilitres")")
                Text(Units.volumeUnit).foregroundStyle(Palette.muted)
            }
            .frame(minWidth: 96, alignment: .trailing)
            smallStep("plus", label: "More for \(child.displayName)") { amounts[key] = min(400, ownAmount(child) + Units.volumeStep) }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func smallStep(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
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

    /// Grams, or pounds and ounces side by side; stored in grams either way.
    @ViewBuilder private var weightInput: some View {
        if Units.pounds {
            let totalOunces = (grams ?? 0) / Units.gramsPerOunce
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Spacer()
                TextField("0", value: Binding(get: { grams == nil ? nil : Double(Int(totalOunces.rounded()) / 16) },
                                              set: { lb in
                                                  let oz = Double(Int(totalOunces.rounded()) % 16)
                                                  grams = ((lb ?? 0) * 16 + oz) * Units.gramsPerOunce
                                              }),
                          format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad).displayFont(56).monospacedDigit()
                    .multilineTextAlignment(.trailing).fixedSize()
                    .accessibilityLabel("Weight, pounds")
                Text("lb").foregroundStyle(Palette.muted)
                TextField("0", value: Binding(get: { grams == nil ? nil : Double(Int(totalOunces.rounded()) % 16) },
                                              set: { oz in
                                                  let lb = Double(Int(totalOunces.rounded()) / 16)
                                                  grams = (lb * 16 + min(max(oz ?? 0, 0), 15)) * Units.gramsPerOunce
                                              }),
                          format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad).displayFont(56).monospacedDigit()
                    .multilineTextAlignment(.trailing).fixedSize()
                    .accessibilityLabel("and ounces")
                Text("oz").foregroundStyle(Palette.muted)
                Spacer()
            }
        } else {
            bigNumber("0", value: $grams, digits: 0, unit: "g", label: "Weight in grams")
        }
    }

    /// The change from the first weight logged, as a plain number. The app
    /// does not say whether it is fine.
    private var weightChange: String? {
        guard chosenChildren.count == 1, let child = chosenChildren.first,
              let first = store.firstWeight(for: child), first != editing,
              let now = grams, now > 0 else { return nil }
        return "Change since the first weight logged: \(Units.weightChange(now - first.value))"
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
                    .buttonStyle(PressStyle())
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
            Haptics.step()
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
        Button(title) {
            Haptics.selection()
            action()
        }
        .buttonStyle(PressStyle())
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
        let medicineName = medicine.trimmingCharacters(in: .whitespacesAndNewlines)
        let doseValue = doseText.trimmingCharacters(in: .whitespacesAndNewlines)
        let vaccineName = vaccine.trimmingCharacters(in: .whitespacesAndNewlines)
        let milestoneName = milestone.trimmingCharacters(in: .whitespacesAndNewlines)

        if kind == .bottle, !isEditing, !confirmedTwice, let warning = loggedTwiceWarning(for: who) {
            twice = warning
            Haptics.warning()
            return
        }

        if kind == .medicine {
            if !isEditing, !confirmedTooSoon, let warning = tooSoonWarning(for: who) {
                tooSoon = warning
                Haptics.warning()
                return
            }
            rememberGap()
        }

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
                // Changing the side or the length replaces what the timers recorded.
                if loadedFeed?.side != side || loadedFeed?.minutes != minutes || event.runningSide != nil {
                    event.leftSeconds = 0
                    event.rightSeconds = 0
                }
                event.runningSide = nil
                event.sideStartedAt = nil
            case .solids:
                event.startedAt = time
                event.detail = trimmedFood
                event.dose = extra.isEmpty ? nil : extra
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
                if kind == .nappy { event.dose = extra.isEmpty ? nil : extra }
            case .note:
                event.startedAt = time
            case .medicine:
                event.startedAt = time
                event.detail = medicineName
                event.dose = doseValue.isEmpty ? nil : doseValue
            case .temperature:
                event.startedAt = time
                event.value = temperature ?? 0
                event.detail = place.isEmpty ? nil : place
            case .vaccination:
                event.startedAt = time
                event.detail = vaccineName
            case .weight:
                event.startedAt = time
                event.value = grams ?? 0
            case .milestone:
                event.startedAt = time
                event.detail = milestoneName
            case .pump:
                break
            }
            store.saveEdit(event)
        } else {
            let events: [Event]
            switch kind {
            case .bottle:
                if ownAmounts {
                    let each = who.map { (child: $0, ml: min(max(ownAmount($0), 0), 1000)) }
                    events = store.logBottles(each, at: time, detail: milk, note: noteValue)
                } else {
                    events = store.logEach(.bottle, for: who, at: time, amountML: ml, detail: milk, note: noteValue)
                }
            case .breastfeed:
                events = store.logEach(.breastfeed, for: who, at: time, end: time.addingTimeInterval(minutes * 60), detail: side, note: noteValue)
            case .solids:
                events = store.logEach(.solids, for: who, at: time, detail: trimmedFood, note: noteValue,
                                       dose: extra.isEmpty ? nil : extra)
            case .sleep:
                events = store.logEach(.sleep, for: who, at: min(time, endTime), end: max(time, endTime), note: noteValue)
            case .nappy, .potty:
                events = store.logEach(kind, for: who, at: time, detail: detail, note: noteValue,
                                       dose: kind == .nappy && !extra.isEmpty ? extra : nil)
            case .note:
                events = store.logEach(.note, for: who, at: time, note: noteValue)
            case .medicine:
                events = store.logEach(.medicine, for: who, at: time, detail: medicineName, note: noteValue,
                                       dose: doseValue.isEmpty ? nil : doseValue)
            case .temperature:
                events = store.logEach(.temperature, for: who, at: time, detail: place.isEmpty ? nil : place,
                                       note: noteValue, value: temperature ?? 0)
            case .vaccination:
                events = store.logEach(.vaccination, for: who, at: time, detail: vaccineName, note: noteValue)
            case .weight:
                events = store.logEach(.weight, for: who, at: time, note: noteValue, value: grams ?? 0)
            case .milestone:
                events = store.logEach(.milestone, for: who, at: time, detail: milestoneName, note: noteValue)
            case .pump:
                events = []
            }
            onSaved(events)
        }
        // Played here, not from a view modifier: the sheet is already on its way out.
        Haptics.success()
        dismiss()
    }

    private func deleteEntry() {
        guard let event = editing else { return }
        Haptics.tap()
        dismiss()
        store.delete(event)
    }
}

/// Lets a Set hold Core Data objects by identity.
struct NSManagedObjectIDWrapper: Hashable {
    let id: NSManagedObjectID
    init(_ object: NSManagedObject) { id = object.objectID }
}
