import SwiftUI

/// What the child form edits, for a new child or an existing one.
struct ChildDraft {
    var name = ""
    var birthDate = Date.now
    /// False for a new child until the parent has picked the date. It decides
    /// which tiles show, so it is never guessed.
    var birthDateChosen = false
    var colour = 0
    var feeding: Feeding?
    var pottyTraining = false

    init() {}

    init(child: Child) {
        name = child.name ?? ""
        birthDate = child.birthDate ?? .now
        birthDateChosen = true
        colour = Int(child.colourIndex)
        feeding = child.feeding
        pottyTraining = child.pottyTraining
    }

    var ageMonths: Int {
        max(Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0, 0)
    }

    /// Babies are asked how they feed; older children about the potty.
    var asksFeeding: Bool { birthDateChosen && ageMonths < 24 }
    var asksPotty: Bool { birthDateChosen && ageMonths >= 18 }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The name, and for a baby an answer to how they feed.
    var isComplete: Bool { !trimmedName.isEmpty && birthDateChosen && (!asksFeeding || feeding != nil) }

    /// What is still needed before the child can be added, or nil when nothing is.
    var missing: String? {
        if trimmedName.isEmpty { return "Add a name to carry on." }
        if !birthDateChosen { return "Choose a birth date to carry on." }
        if asksFeeding && feeding == nil { return "Choose how they feed to carry on." }
        return nil
    }

    /// An older child who was never asked about feeding gets "neither", so
    /// their Today shows only what applies to them.
    var feedingToSave: Feeding? { asksFeeding ? feeding : (feeding ?? .neither) }
    var pottyToSave: Bool { asksPotty && pottyTraining }
}

/// Name, birth date, colour, and the two setup questions that build Today.
struct ChildForm: View {
    @Binding var draft: ChildDraft
    /// True once "Choose" has been tapped here, so the date wheel is open and ready.
    @State private var picking = false


    var body: some View {
        Section {
            TextField("Name", text: $draft.name)
                .textContentType(.givenName)
            if draft.birthDateChosen && picking {
                // Open at once: no second tap, and nothing to close.
                VStack(alignment: .leading, spacing: 0) {
                    Text("Birth date").foregroundStyle(Palette.ink)
                    DatePicker("Birth date", selection: $draft.birthDate, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            } else if draft.birthDateChosen {
                DatePicker("Birth date", selection: $draft.birthDate, in: ...Date.now, displayedComponents: .date)
            } else {
                Button {
                    Haptics.selection()
                    draft.birthDateChosen = true
                    picking = true
                } label: {
                    HStack {
                        Text("Birth date").foregroundStyle(Palette.ink)
                        Spacer()
                        Text("Choose").fontWeight(.semibold).foregroundStyle(Palette.ink)
                            .padding(.horizontal, 12).frame(minHeight: 34)
                            .background(Palette.field, in: Capsule())
                    }
                }
                .accessibilityHint("Opens the date wheel, starting from today")
            }
        } footer: {
            if !draft.birthDateChosen {
                Text("Their age decides what shows on Today.")
            }
        }
        .listRowBackground(Palette.input)
        if draft.asksFeeding {
            Section {
                ForEach([Feeding.bottle, .breast, .both, .neither]) { option in
                    choiceRow(option.title, isOn: draft.feeding == option) {
                        Haptics.selection()
                        draft.feeding = option
                    }
                }
            } header: {
                Text("How do they feed?")
            } footer: {
                Text("This decides which tiles show on Today. You can change it any time.")
            }
            .listRowBackground(Palette.paper)
        }
        if draft.asksPotty {
            Section {
                Toggle("Potty training", isOn: $draft.pottyTraining)
            } footer: {
                Text("Adds a Potty tile. Leave it off if not yet.")
            }
            .listRowBackground(Palette.paper)
        }
        // Says what is still needed, so a greyed-out button is never a puzzle.
        if let missing = draft.missing {
            Section {
                Label(missing, systemImage: "arrow.up")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Color.clear)
            }
        }
        Section("Colour") {
            // Four a row, each with its name, so two close colours can still be told apart.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(Palette.childColours.indices, id: \.self) { index in
                    Button {
                        Haptics.selection()
                        draft.colour = index
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Palette.childColours[index])
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(Palette.ink, lineWidth: draft.colour == index ? 3 : 0))
                                .overlay {
                                    if draft.colour == index {
                                        Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(Palette.ink)
                                    }
                                }
                            Text(Palette.childColourNames[index])
                                .font(.footnote)
                                .foregroundStyle(draft.colour == index ? Palette.ink : Palette.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Palette.childColourNames[index])
                    .accessibilityAddTraits(draft.colour == index ? .isSelected : [])
                }
            }
        }
        .listRowBackground(Palette.paper)
    }

    private func choiceRow(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(Palette.ink)
                Spacer()
                if isOn { Image(systemName: "checkmark").fontWeight(.semibold).foregroundStyle(Palette.ink) }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Add a child, from Today or the Family tab.
struct AddChildView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: []) private var children: FetchedResults<Child>
    @State private var draft = ChildDraft()

    var body: some View {
        NavigationStack {
            Form { ChildForm(draft: $draft) }
                .scrollContentBackground(.hidden)
                .background(Palette.sand)
                .navigationTitle("Add a child")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            store.addChild(name: draft.trimmedName, birthDate: draft.birthDate, colourIndex: draft.colour,
                                           feeding: draft.feedingToSave, pottyTraining: draft.pottyToSave)
                            dismiss()
                        }
                        .disabled(!draft.isComplete)
                    }
                }
                .onAppear { draft.colour = children.count % Palette.childColours.count }
        }
        .foregroundStyle(Palette.ink)
    }
}

/// A child's page: their details, and removing them.
struct ChildDetailView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var child: Child
    @State private var draft = ChildDraft()
    @State private var loaded = false
    @State private var confirmingDelete = false
    @State private var confirmingAgain = false

    var body: some View {
        Form {
            Section {
                NavigationLink { MilestonesView(child: child) } label: { Label("Milestones", systemImage: "star") }
                NavigationLink { GrowthView(child: child) } label: { Label("Growth", systemImage: "scalemass") }
                NavigationLink { EarnedStickersView(child: child) } label: { Label("Stickers", systemImage: "seal") }
                if store.isParent {
                    NavigationLink { SummaryView(child: child) } label: { Label("Summary for the doctor", systemImage: "doc.text") }
                }
            }
            if store.isParent {
            ChildForm(draft: $draft)
            Section {
                Button(child.archived ? "Show on Today again" : "Hide from Today") {
                    store.setArchived(!child.archived, for: child)
                }
            } footer: {
                Text(child.archived
                     ? "\(child.displayName) is hidden from Today and Insights. Everything logged for them is kept."
                     : "Hides \(child.displayName) from Today and Insights and keeps everything logged for them. You can bring them back any time.")
            }
            Section {
                Button("Delete \(draft.trimmedName.isEmpty ? "this child" : draft.trimmedName)", role: .destructive) {
                    confirmingDelete = true
                }
                .foregroundStyle(Palette.waratah)
                .confirmationDialog("Delete \(child.displayName)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) { confirmingAgain = true }
                    Button("Keep", role: .cancel) {}
                } message: {
                    Text("This removes \(child.displayName) and everything logged for them, for everyone in the family.")
                }
            } footer: {
                Text("Deleting asks twice. It cannot be undone.")
            }
            } else {
                Section {
                    LabeledContent("Born") { Text(child.birthDate?.formatted(date: .abbreviated, time: .omitted) ?? "") }
                } footer: {
                    Text("\(store.whoToAsk.prefix(1).uppercased() + store.whoToAsk.dropFirst()) can change \(child.displayName)'s details.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle(child.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if store.isParent {
                    Button("Save") { save() }.disabled(!draft.isComplete)
                }
            }
        }
        .alert("Are you sure?", isPresented: $confirmingAgain) {
            Button("Delete \(child.displayName) and their entries", role: .destructive) {
                dismiss()
                store.delete(child)
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("\(child.displayName)'s entries will be gone from every phone in the family.")
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            draft = ChildDraft(child: child)
        }
    }

    private func save() {
        child.name = draft.trimmedName
        child.birthDate = draft.birthDate
        child.colourIndex = Int16(draft.colour)
        child.feeding = draft.feedingToSave
        child.pottyTraining = draft.pottyToSave
        store.saveChild()
        dismiss()
    }
}
