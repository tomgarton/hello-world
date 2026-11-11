import SwiftUI

/// What the child form edits, for a new child or an existing one.
struct ChildDraft {
    var name = ""
    var birthDate = Calendar.current.date(byAdding: .month, value: -6, to: .now) ?? .now
    var colour = 0
    var feeding: Feeding?
    var pottyTraining = false

    init() {}

    init(child: Child) {
        name = child.name ?? ""
        birthDate = child.birthDate ?? .now
        colour = Int(child.colourIndex)
        feeding = child.feeding
        pottyTraining = child.pottyTraining
    }

    var ageMonths: Int {
        max(Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0, 0)
    }

    /// Babies are asked how they feed; older children about the potty.
    var asksFeeding: Bool { ageMonths < 24 }
    var asksPotty: Bool { ageMonths >= 18 }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The name, and for a baby an answer to how they feed.
    var isComplete: Bool { !trimmedName.isEmpty && (!asksFeeding || feeding != nil) }

    /// An older child who was never asked about feeding gets "neither", so
    /// their Today shows only what applies to them.
    var feedingToSave: Feeding? { asksFeeding ? feeding : (feeding ?? .neither) }
    var pottyToSave: Bool { asksPotty && pottyTraining }
}

/// Name, birth date, colour, and the two setup questions that build Today.
struct ChildForm: View {
    @Binding var draft: ChildDraft

    private let colourNames = ["Sky", "Shell", "Mint", "Sun"]

    var body: some View {
        Section {
            TextField("Name", text: $draft.name)
                .textContentType(.givenName)
            DatePicker("Birth date", selection: $draft.birthDate, in: ...Date.now, displayedComponents: .date)
        }
        if draft.asksFeeding {
            Section {
                ForEach([Feeding.bottle, .breast, .both]) { option in
                    choiceRow(option.title, isOn: draft.feeding == option) { draft.feeding = option }
                }
            } header: {
                Text("How do they feed?")
            } footer: {
                Text("This decides which tiles show on Today. You can change it any time.")
            }
        }
        if draft.asksPotty {
            Section {
                Toggle("Potty training", isOn: $draft.pottyTraining)
            } footer: {
                Text("Adds a Potty tile. Leave it off if not yet.")
            }
        }
        Section("Colour") {
            HStack(spacing: 14) {
                ForEach(Palette.childColours.indices, id: \.self) { index in
                    Button {
                        draft.colour = index
                    } label: {
                        Circle()
                            .fill(Palette.childColours[index])
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Palette.ink, lineWidth: draft.colour == index ? 3 : 0))
                            .overlay {
                                if draft.colour == index {
                                    Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(Palette.ink)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(colourNames[index])
                    .accessibilityAddTraits(draft.colour == index ? .isSelected : [])
                }
            }
        }
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
            ChildForm(draft: $draft)
            Section {
                Button("Delete \(draft.trimmedName.isEmpty ? "this child" : draft.trimmedName)", role: .destructive) {
                    confirmingDelete = true
                }
                .confirmationDialog("Delete \(child.displayName)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) { confirmingAgain = true }
                    Button("Keep", role: .cancel) {}
                } message: {
                    Text("This removes \(child.displayName) and everything logged for them, for everyone in the family.")
                }
            } footer: {
                Text("Deleting asks twice. It cannot be undone.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle(child.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!draft.isComplete)
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
