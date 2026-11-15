import PhotosUI
import SwiftUI

/// Photos of a box, bottle or tin (the front, then the directions in one part or several), read on this phone, then each row checked against the photo
/// before anything is saved. What is saved is shared with the family.
struct BoxReaderView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss

    let kind: GuideKind
    /// The box or tin being edited or read again.
    var existing: Guide?
    /// Start from what `existing` holds, rather than from new photos.
    var editing = false
    var startName = ""
    var onSaved: (Guide) -> Void = { _ in }

    private enum Side: Identifiable { case front, directions, more; var id: Self { self } }

    @State private var name = ""
    @State private var strength = ""
    @State private var gapText = ""
    @State private var limitText = ""
    @State private var table: BoxTable?
    @State private var unsure = Set<BoxReader.Cell>()
    @State private var ticked = Set<UUID>()
    @State private var frontRead = false
    /// The photos of the directions: one for a flat box, two or three for a table that wraps round a bottle.
    @State private var shots: [UIImage] = []
    @State private var zoomed = 0
    private var directions: UIImage? { shots.first }
    @State private var keepPhoto = true
    @State private var busy: Side?
    @State private var choosing: Side?
    @State private var camera: Side?
    /// Which photo the library is open for.
    @State private var pickingFor: Side = .directions
    @State private var showLibrary = false
    @State private var picked: PhotosPickerItem?
    @State private var zooming = false
    @State private var loaded = false

    private var allTicked: Bool { (table?.rows ?? []).allSatisfy { ticked.contains($0.id) } }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && allTicked && (table != nil || directions != nil || editing)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !editing { photos }
                Section {
                    TextField("Name", text: $name)
                    TextField(kind == .medicine ? "Strength, such as 120 mg in 5 ml" : "Stage, if the tin has one", text: $strength)
                } header: {
                    Text("Name")
                } footer: {
                    Text(frontRead ? "Read from the front. Change it if it's wrong." : "Type it, or take a photo of the front.")
                }
                .listRowBackground(Palette.paper)
                if table != nil || directions != nil { check }
                if kind == .medicine && (table != nil || directions != nil || editing) { rules }
                if directions != nil {
                    Section {
                        Toggle(shots.count > 1 ? "Keep these photos" : "Keep this photo", isOn: $keepPhoto)
                    } footer: {
                        Text(keepPhoto ? "Kept with the family's copy, so anyone can check the table against the \(kind.thing)."
                                       : "Only the typed-up table is kept.")
                    }
                    .listRowBackground(Palette.paper)
                }
                Section {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                } footer: {
                    if !allTicked {
                        Text("Tick every row once it matches the photo.")
                    } else {
                        Text("The app never chooses \(kind == .medicine ? "a dose" : "an amount"). It shows the \(kind.thing)'s table as you checked it.")
                    }
                }
                .listRowBackground(Palette.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle(editing ? "Edit" : kind.readTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .confirmationDialog("Photo", isPresented: Binding(get: { choosing != nil }, set: { if !$0 { choosing = nil } }),
                                presenting: choosing) { side in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take a photo") { camera = side }
                }
                Button("Choose a photo") { pickingFor = side; showLibrary = true }
            }
            .photosPicker(isPresented: $showLibrary, selection: $picked, matching: .images)
            .onChange(of: picked) { _, item in
                guard let item else { return }
                let side = pickingFor
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        await read(image, side)
                    }
                    picked = nil
                }
            }
            .fullScreenCover(item: $camera) { side in
                CameraPicker { image in Task { await read(image, side) } }
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $zooming) {
                if let image = shots[safe: zoomed] ?? shots.first { PhotoViewer(image: image) }
            }
            .onAppear(perform: load)
        }
        .foregroundStyle(Palette.ink)
    }

    // MARK: Photos

    private var photos: some View {
        Section {
            photoRow(.front, title: "1. The front", detail: "For the name\(kind == .medicine ? " and strength" : "")", done: frontRead)
            photoRow(.directions, title: "2. The directions",
                     detail: kind == .medicine ? "The table of ages and doses" : "The table of ages, water and scoops",
                     done: directions != nil)
            if directions != nil {
                photoRow(.more, title: "Add another photo",
                         detail: shots.count > 1 ? "\(shots.count) photos of the directions so far" : "For a table that wraps round a bottle",
                         done: false)
            }
        } header: {
            Text("Photos")
        } footer: {
            Text("Read on this iPhone. Lay the \(kind.thing) flat, in good light, close up. On a bottle, take the table in two or three parts, each overlapping the last, and they are joined.")
        }
        .listRowBackground(Palette.paper)
    }

    private func photoRow(_ side: Side, title: String, detail: String, done: Bool) -> some View {
        Button { choosing = side } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(Palette.muted)
                }
                Spacer()
                if busy == side {
                    ProgressView()
                } else if done {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.gum)
                        .accessibilityLabel("Done. Tap to take it again.")
                } else {
                    Image(systemName: "camera").foregroundStyle(Palette.muted)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Checking

    @ViewBuilder private var check: some View {
        Section {
            if !shots.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(shots.enumerated()), id: \.offset) { index, shot in
                            Button { zoomed = index; zooming = true } label: {
                                Image(uiImage: shot)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(alignment: .bottomTrailing) {
                                        Label("Zoom", systemImage: "arrow.up.left.and.arrow.down.right")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(.thinMaterial, in: Capsule())
                                            .padding(8)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(shots.count > 1 ? "Photo \(index + 1) of the directions. Opens it larger." : "The photo of the directions. Opens it larger.")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            if table == nil || (table?.rows.isEmpty ?? true) {
                Text("No table could be read. Add the rows yourself, or save the photo on its own.")
                    .foregroundStyle(Palette.muted)
            }
        } header: {
            Text("Check it")
        } footer: {
            if !(table?.rows.isEmpty ?? true) {
                Text("Check each row against the photo, then tick it. Tap anything to correct it.\(unsure.isEmpty ? "" : " The reader wasn't sure about the highlighted ones.")")
            }
        }
        .listRowBackground(Palette.paper)

        if table != nil {
            Section {
                headings
                ForEach(Array((table?.rows ?? []).enumerated()), id: \.element.id) { index, row in
                    rowEditor(index, row)
                }
                .onDelete { offsets in
                    table?.rows.remove(atOffsets: offsets)
                }
                Button {
                    let width = table?.columns.count ?? 1
                    let row = BoxTable.Row(age: "", from: nil, values: Array(repeating: "", count: width))
                    table?.rows.append(row)
                } label: {
                    Label("Add a row", systemImage: "plus")
                }
            } header: {
                Text("From the \(kind.thing)")
            }
            .listRowBackground(Palette.paper)
        } else {
            Section {
                Button {
                    let columns = kind.defaultColumns
                    table = BoxTable(columns: columns, rows: [BoxTable.Row(age: "", from: nil, values: Array(repeating: "", count: columns.count))])
                } label: {
                    Label("Type the table", systemImage: "tablecells")
                }
            }
            .listRowBackground(Palette.paper)
        }
    }

    /// Side by side suits a tin (an age, water and scoops). A table with more columns, or with words in
    /// its cells, would not fit across the screen, so each row is laid out down the page instead.
    private var stacked: Bool {
        guard let table else { return false }
        return table.columns.count > 2 || table.rows.contains { $0.values.contains { $0.count > 9 } }
    }

    @ViewBuilder private var headings: some View {
        if stacked {
            DisclosureGroup("Headings") {
                ForEach(Array((table?.columns ?? []).enumerated()), id: \.offset) { index, _ in
                    HStack {
                        TextField("Heading", text: Binding(get: { table?.columns[safe: index] ?? "" }, set: { table?.columns[index] = $0 }))
                        if (table?.columns.count ?? 0) > 1 {
                            Button(role: .destructive) { removeColumn(index) } label: { Image(systemName: "minus.circle") }
                                .buttonStyle(.plain)
                                .foregroundStyle(Palette.waratah)
                                .accessibilityLabel("Remove this column")
                        }
                    }
                }
                Button { addColumn() } label: { Label("Add a column", systemImage: "plus") }
            }
            .font(.subheadline)
        } else {
            HStack(spacing: 8) {
                Text("Age").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array((table?.columns ?? []).enumerated()), id: \.offset) { index, _ in
                    TextField("Heading", text: Binding(get: { table?.columns[safe: index] ?? "" },
                                                       set: { table?.columns[index] = $0 }))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 76)
                }
                Spacer().frame(width: 36)
            }
        }
    }

    private func removeColumn(_ index: Int) {
        guard var changed = table, changed.columns.indices.contains(index) else { return }
        changed.columns.remove(at: index)
        for row in changed.rows.indices where changed.rows[row].values.indices.contains(index) {
            // A row that had something in the column needs checking again.
            if !changed.rows[row].values[index].isEmpty { ticked.remove(changed.rows[row].id) }
            changed.rows[row].values.remove(at: index)
        }
        table = changed
    }

    private func addColumn() {
        guard var changed = table else { return }
        changed.columns.append("Column \(changed.columns.count + 1)")
        for row in changed.rows.indices { changed.rows[row].values.append("") }
        table = changed
    }

    private func tick(_ row: BoxTable.Row) -> some View {
        let isTicked = ticked.contains(row.id)
        return Button {
            if isTicked { ticked.remove(row.id) } else { ticked.insert(row.id); Haptics.tap() }
        } label: {
            Image(systemName: isTicked ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isTicked ? Palette.gum : Palette.muted)
                .frame(width: 36, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isTicked ? "Checked" : "Check this row")
    }

    private func rowEditor(_ index: Int, _ row: BoxTable.Row) -> some View {
        let age = Binding(get: { table?.rows[safe: index]?.age ?? "" }, set: { edit(index) { $0.age = $1 }($0) })
        func value(_ column: Int) -> Binding<String> {
            Binding(get: { table?.rows[safe: index]?.values[safe: column] ?? "" }, set: { edit(index) { $0.values[column] = $1 }($0) })
        }
        return VStack(alignment: .leading, spacing: 6) {
            if stacked {
                HStack(alignment: .center, spacing: 8) {
                    cellField("Age", text: age, cell: .init(row: row.id, column: -1))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    tick(row)
                }
                ForEach(Array(row.values.enumerated()), id: \.offset) { column, _ in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(table?.columns[safe: column] ?? "").font(.footnote).foregroundStyle(Palette.muted)
                            .frame(width: 88, alignment: .leading)
                        cellField("–", text: value(column), cell: .init(row: row.id, column: column), wraps: true)
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    cellField("Age", text: age, cell: .init(row: row.id, column: -1))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Array(row.values.enumerated()), id: \.offset) { column, _ in
                        cellField("–", text: value(column), cell: .init(row: row.id, column: column))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 76)
                    }
                    tick(row)
                }
            }
            startsAt(index, row)
        }
        .padding(.vertical, 2)
    }

    /// The age the row starts at, as a number, so the app knows when a child reaches it.
    private func startsAt(_ index: Int, _ row: BoxTable.Row) -> some View {
        HStack(spacing: 6) {
            Text("Starts at").font(.footnote).foregroundStyle(Palette.muted)
            TextField("–", text: Binding(
                get: { row.from.map { String($0.count) } ?? "" },
                set: { text in edit(index) { row, value in
                    if let count = Int(value) { row.from = AgeMark(count: count, unit: row.from?.unit ?? .months) } else { row.from = nil }
                }(text) }))
                .keyboardType(.numberPad)
                .font(.footnote.monospacedDigit())
                .frame(width: 34)
                .padding(.vertical, 2).padding(.horizontal, 4)
                .background(Palette.input, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Picker("Unit", selection: Binding(
                get: { row.from?.unit ?? .months },
                set: { unit in edit(index) { row, _ in row.from = AgeMark(count: row.from?.count ?? 0, unit: unit) }("") })) {
                ForEach(AgeMark.Unit.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu)
            .font(.footnote)
            .labelsHidden()
            if row.from == nil {
                Text("Not by age").font(.footnote).foregroundStyle(Palette.muted)
            }
        }
    }

    private func cellField(_ prompt: String, text: Binding<String>, cell: BoxReader.Cell, wraps: Bool = false) -> some View {
        TextField(prompt, text: text, axis: wraps ? .vertical : .horizontal)
            .font(.body.monospacedDigit())
            .padding(.vertical, 4).padding(.horizontal, 6)
            .background(unsure.contains(cell) ? Palette.wattle.opacity(0.35) : Palette.input,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityHint(unsure.contains(cell) ? "The reader wasn't sure about this one." : "")
    }

    /// Changing a row after it was ticked asks for it to be checked again.
    private func edit(_ index: Int, _ change: @escaping (inout BoxTable.Row, String) -> Void) -> (String) -> Void {
        { value in
            guard var row = table?.rows[safe: index] else { return }
            change(&row, value)
            guard row != table?.rows[index] else { return }
            table?.rows[index] = row
            ticked.remove(row.id)
        }
    }

    private var rules: some View {
        Section {
            LabeledContent("Smallest gap, hours") {
                TextField("–", text: $gapText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 56)
            }
            LabeledContent("Most doses in 24 hours") {
                TextField("–", text: $limitText).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 56)
            }
        } footer: {
            Text("From the box. The app asks before a dose that goes past them.")
        }
        .listRowBackground(Palette.paper)
    }

    // MARK: Reading and saving

    private func load() {
        guard !loaded else { return }
        loaded = true
        name = existing?.name ?? startName
        if let existing, editing {
            strength = existing.strength ?? ""
            table = existing.table
            ticked = Set((table?.rows ?? []).map(\.id))
            shots = existing.photo.flatMap(UIImage.init(data:)).map { [$0] } ?? []
            keepPhoto = existing.photo != nil
        }
        if kind == .medicine {
            let gap = existing.map(\.gapHours) ?? MedicineRules.gap(for: name) ?? 0
            let limit = existing.map { Int($0.doseLimit) } ?? MedicineRules.limit(for: name) ?? 0
            gapText = gap > 0 ? gap.formatted(.number.precision(.fractionLength(0...1))) : ""
            limitText = limit > 0 ? String(limit) : ""
        }
    }

    private func read(_ image: UIImage, _ side: Side) async {
        busy = side
        let lines = await BoxReader.lines(in: image)
        let label = LabelReading.parse(lines: lines.map { (text: $0.text, height: $0.box.height) })
        switch side {
        case .front:
            if !label.name.isEmpty { name = label.name }
            if let found = label.strength { strength = found }
            frontRead = true
        case .more:
            // Another part of the same table: what it adds is joined on, and nothing already read is replaced.
            shots.append(image)
            let found = BoxReader.table(from: lines, kind: kind)
            let before = table
            let joined = BoxReader.merged(table ?? BoxTable(columns: kind.defaultColumns, rows: []), with: found.table,
                                          loose: BoxReader.looseRows(from: lines), kind: kind)
            table = joined.rows.isEmpty ? nil : joined
            unsure.formUnion(found.unsure)
            // A row this photo changed, or added, needs checking.
            let same = Set((before?.rows ?? []).filter { row in joined.rows.contains(row) }.map(\.id))
            ticked.formIntersection(same)
        case .directions:
            shots = [image]
            let found = BoxReader.table(from: lines, kind: kind)
            table = found.table.rows.isEmpty ? nil : found.table
            unsure = found.unsure
            ticked = []
            if kind == .medicine {
                if let gap = label.gap { gapText = gap.formatted(.number.precision(.fractionLength(0...1))) }
                if let limit = label.limit { limitText = String(limit) }
            }
            if name.isEmpty, !label.name.isEmpty { name = label.name }
        }
        busy = nil
    }

    private func save() {
        var kept = table
        kept?.rows.removeAll { $0.age.trimmingCharacters(in: .whitespaces).isEmpty && $0.values.allSatisfy(\.isEmpty) }
        let photo: Data? = keepPhoto ? (editing ? existing?.photo : BoxReader.sideBySide(shots).flatMap(BoxReader.keepable)) : nil
        guard let guide = store.saveGuide(
            replacing: existing, kind: kind, name: name, strength: strength, table: kept, photo: photo,
            gap: Double(gapText.replacingOccurrences(of: ",", with: ".")), limit: Int(limitText)) else { return }
        Haptics.success()
        onSaved(guide)
        dismiss()
    }
}

// MARK: The kept table

/// A saved box or tin: the table in the app's own type, the children's ages beside it, the photo behind a link.
struct GuideView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var guide: Guide
    var children: [Child] = []

    @State private var editing = false
    @State private var readingAgain = false
    @State private var zooming = false
    @State private var removing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(guide.name ?? "").displayFont(28)
                        if let strength = guide.strength { Text(strength).foregroundStyle(Palette.muted) }
                        ForEach(children) { child in
                            if let line = child.ageLine() { Text(line).font(.headline) }
                        }
                    }
                    if let table = guide.table, !table.rows.isEmpty {
                        TableCard(table: table, heading: "From the \(guide.kind.thing)")
                    }
                    if guide.kind == .medicine, guide.gapHours > 0 || guide.doseLimit > 0 {
                        VStack(spacing: 0) {
                            if guide.gapHours > 0 {
                                LabeledContent("Smallest gap", value: "\(guide.gapHours.formatted(.number.precision(.fractionLength(0...1)))) hours")
                                    .padding(14)
                            }
                            if guide.doseLimit > 0 {
                                LabeledContent("Most doses in 24 hours", value: "\(guide.doseLimit)").padding(14)
                            }
                        }
                        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    if guide.photo != nil {
                        Button { zooming = true } label: {
                            HStack {
                                Label("See the photo of the \(guide.kind.thing)", systemImage: "photo")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
                            }
                            .padding(14)
                            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Typed up from a photo\(guide.readAt.map { " on \($0.formatted(.dateTime.day().month(.wide)))" } ?? ""). The app never chooses \(guide.kind == .medicine ? "a dose" : "an amount"); check it against the \(guide.kind.thing) itself.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if store.isParent {
                        Button("Read a new \(guide.kind.thing)") { readingAgain = true }
                            .buttonStyle(PillButtonStyle(primary: false))
                        Button("Remove this \(guide.kind.thing)", role: .destructive) { removing = true }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Palette.waratah)
                    }
                }
                .padding(20)
            }
            .background(Palette.sand.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                if store.isParent {
                    ToolbarItem(placement: .primaryAction) { Button("Edit") { editing = true } }
                }
            }
            .sheet(isPresented: $editing) { BoxReaderView(kind: guide.kind, existing: guide, editing: true) }
            .sheet(isPresented: $readingAgain) { BoxReaderView(kind: guide.kind, existing: guide) }
            .fullScreenCover(isPresented: $zooming) {
                if let image = guide.photo.flatMap(UIImage.init(data:)) { PhotoViewer(image: image) }
            }
            .confirmationDialog("Remove \(guide.name ?? "this")?", isPresented: $removing, titleVisibility: .visible) {
                Button("Remove for everyone", role: .destructive) {
                    store.deleteGuide(guide)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The table and photo go from every phone in the family. Entries already logged stay.")
            }
        }
        .foregroundStyle(Palette.ink)
    }
}

/// A table from a box or tin, in the app's own type. No row is picked out.
struct TableCard: View {
    let table: BoxTable
    var heading: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let heading { Text(heading).font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted) }
            if table.columns.count > 2 || table.rows.contains(where: { $0.values.contains { $0.count > 9 } }) {
                // Too wide to sit across the card: each row goes down the page, as in the reader.
                ForEach(table.rows) { row in
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.age).font(.subheadline.weight(.semibold))
                        ForEach(Array(row.values.enumerated()), id: \.offset) { column, value in
                            if !value.isEmpty {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(table.columns[safe: column] ?? "").font(.footnote).foregroundStyle(Palette.muted)
                                        .frame(width: 88, alignment: .leading)
                                    Text(value).monospacedDigit().fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            } else {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("Age")
                    ForEach(Array(table.columns.enumerated()), id: \.offset) { Text($0.element).gridColumnAlignment(.trailing) }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.muted)
                ForEach(table.rows) { row in
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        Text(row.age).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(Array(row.values.enumerated()), id: \.offset) { Text($0.element).monospacedDigit() }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A photo to pinch, drag and double-tap.
struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale * pinch)
                .offset(x: offset.width + drag.width, y: offset.height + drag.height)
                .gesture(MagnifyGesture()
                    .updating($pinch) { value, state, _ in state = value.magnification }
                    .onEnded { value in scale = min(max(scale * value.magnification, 1), 6); if scale == 1 { offset = .zero } })
                .simultaneousGesture(DragGesture()
                    .updating($drag) { value, state, _ in if scale > 1 { state = value.translation } }
                    .onEnded { value in if scale > 1 { offset.width += value.translation.width; offset.height += value.translation.height } })
                .onTapGesture(count: 2) {
                    withAnimation(.snappy) {
                        if scale > 1 { scale = 1; offset = .zero } else { scale = 2.5 }
                    }
                }
                .accessibilityLabel("Photo of the directions")
            Button("Close") { dismiss() }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16).frame(minHeight: 44)
                .background(.black.opacity(0.5), in: Capsule())
                .padding(16)
        }
    }
}

// MARK: Moving up a row

enum RowNotices {
    static let seenKey = "rowNoticesSeen"

    static func key(guide: Guide, child: Child, from: AgeMark) -> String {
        "\(guide.id?.uuidString ?? "").\(child.id?.uuidString ?? "").\(from.count)\(from.unit.rawValue)"
    }

    static func seen(_ key: String) -> Bool { (UserDefaults.standard.stringArray(forKey: seenKey) ?? []).contains(key) }

    static func markSeen(_ key: String) {
        var list = UserDefaults.standard.stringArray(forKey: seenKey) ?? []
        guard !list.contains(key) else { return }
        list.append(key)
        UserDefaults.standard.set(Array(list.suffix(200)), forKey: seenKey)
    }

    /// "today", "tomorrow" or the weekday.
    static func day(_ date: Date, now: Date = .now) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return "today" }
        if let next = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: next) { return "tomorrow" }
        return "on " + date.formatted(.dateTime.weekday(.wide))
    }
}

/// On the bottle sheet, two days before a child reaches a new row on the tin. It names the change
/// and shows the rows either side. It never says how much to give.
struct RowNoticeCard: View {
    let guide: Guide
    let child: Child
    @State private var dismissed = false

    var body: some View {
        if !dismissed, let birth = child.birthDate, let table = guide.table,
           let change = table.change(birth: birth),
           !RowNotices.seen(RowNotices.key(guide: guide, child: child, from: change.from)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(child.displayName) is \(change.from.words) \(RowNotices.day(change.on))")
                    .font(.headline)
                Text("The \(guide.kind.thing) has a different row from \(change.from.words).")
                    .foregroundStyle(Palette.muted)
                TableCard(table: BoxTable(columns: table.columns, rows: [change.before, change.after].compactMap { $0 }))
                Text("From your photo of the \(guide.kind.thing). Check it against the \(guide.kind.thing) itself.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                Button("Got it") {
                    RowNotices.markSeen(RowNotices.key(guide: guide, child: child, from: change.from))
                    withAnimation { dismissed = true }
                }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.wattle.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

#if DEBUG
/// A bottle's table, as read, opened for checking: "-debugBox 1" with the sample family.
struct BoxReaderDebug: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var guide: Guide?

    var body: some View {
        Group {
            if let guide { BoxReaderView(kind: .medicine, existing: guide, editing: true) } else { Color.clear }
        }
        .onAppear {
            guard guide == nil else { return }
            func row(_ age: String, _ count: Int, _ unit: AgeMark.Unit, _ values: [String]) -> BoxTable.Row {
                BoxTable.Row(age: age, from: AgeMark(count: count, unit: unit), values: values)
            }
            let table = BoxTable(columns: ["How much", "How often"], rows: [
                row("2-3 months", 2, .months, ["2.5 ml - If necessary, after 4-6 hours", "a second dose"]),
                row("3-6 months", 3, .months, ["2.5 ml", "Up to 4 times a day"]),
                row("6-24 months", 6, .months, ["5 ml", "Up to 4 times a day"]),
                row("2-4 years", 2, .years, ["7.5 ml (5 ml + 2.5 ml)", "Up to 4 times a day"]),
            ])
            guide = store.saveGuide(replacing: nil, kind: .medicine, name: "Paracetamol", strength: "120 mg in 5 ml",
                                    table: table, photo: nil, gap: 4, limit: 4)
        }
    }
}
#endif
