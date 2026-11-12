import CoreData
import SwiftUI

/// One thing that can be logged from Today: an activity, or the Health group.
struct Tile: Identifiable, Hashable {
    let id: String

    static let health = Tile(id: "health")
    /// The order tiles are offered in. Sleep is not here: it starts from each child's row.
    static let all: [Tile] = [EventKind.bottle, .breastfeed, .nappy, .potty, .solids, .weight, .pump].map { Tile(id: $0.rawValue) } + [health]

    var kind: EventKind? { EventKind(rawValue: id) }
    var title: String { kind?.title ?? "Health" }
    var iconName: String { (kind ?? .medicine).iconName }
}

/// Which tiles are large, which are chips and which are hidden. Until the
/// parent changes it, it is suggested from what the children use.
struct TileLayout {
    static let mainLimit = 3

    var main: [Tile]
    var chips: [Tile]
    var hidden: [Tile]

    /// The first three everyday things the children use are large; the rest are chips.
    static func suggested(from available: [Tile]) -> TileLayout {
        let main = Array(available.filter { $0 != .health && $0.kind != .weight && $0.kind != .pump }.prefix(mainLimit))
        return TileLayout(main: main, chips: available.filter { !main.contains($0) }, hidden: [])
    }

    /// The parent's own choice, kept to tiles that still apply.
    static func custom(main: String, hidden: String, available: [Tile]) -> TileLayout {
        let mainIDs = main.split(separator: ",").map(String.init)
        let hiddenIDs = Set(hidden.split(separator: ",").map(String.init))
        let chosen = Array(mainIDs.compactMap { id in available.first { $0.id == id } }.prefix(mainLimit))
        let hiddenTiles = available.filter { hiddenIDs.contains($0.id) && !chosen.contains($0) }
        return TileLayout(main: chosen,
                          chips: available.filter { !chosen.contains($0) && !hiddenTiles.contains($0) },
                          hidden: hiddenTiles)
    }
}

/// The most recent entry in the last 24 hours, for a tile: "Bea 20:55".
/// Named whenever the tile is for more than one child.
@MainActor
func latestLine(_ entries: [(child: Child, event: Event)], named: Bool) -> String {
    let cutoff = Date.now.addingTimeInterval(-24 * 3600)
    guard let last = entries
        .filter({ ($0.event.startedAt ?? .distantPast) > cutoff })
        .max(by: { ($0.event.startedAt ?? .distantPast) < ($1.event.startedAt ?? .distantPast) }) else { return "" }
    let time = (last.event.startedAt ?? .now).formatted(date: .omitted, time: .shortened)
    return named ? "\(last.child.displayName) \(time)" : time
}

/// A tile on Today, large or as a chip. Tapping logs; touching and holding
/// offers each child's latest entry to change. Health asks which of its three first.
struct TileButton: View {
    @EnvironmentObject private var store: FamilyStore
    let tile: Tile
    let children: [Child]
    var large = true
    let onAdd: (EventKind) -> Void
    let onEdit: (Event) -> Void

    private var entries: [(child: Child, event: Event)] {
        children.compactMap { child in
            let latest: Event?
            if let kind = tile.kind {
                latest = store.latest(kind, for: child)
            } else {
                latest = (child.events ?? [])
                    .filter { $0.kind.isHealth }
                    .max { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
            }
            return latest.map { (child, $0) }
        }
    }

    var body: some View {
        let entries = self.entries
        let latest = latestLine(entries, named: children.count > 1)
        Group {
            if let kind = tile.kind {
                Button {
                    Haptics.tap()
                    onAdd(kind)
                } label: {
                    face(latest)
                }
                .buttonStyle(PressStyle(scale: 0.96))
                .contextMenu { editItems(entries) }
            } else {
                Menu {
                    ForEach(EventKind.health) { kind in
                        Button { onAdd(kind) } label: { Label(kind.title, systemImage: kind.symbol) }
                    }
                    if !entries.isEmpty {
                        Divider()
                        editItems(entries)
                    }
                } label: {
                    face(latest)
                }
            }
        }
        .accessibilityLabel("Log \(tile.title.lowercased())")
        .accessibilityValue(latest)
    }

    @ViewBuilder private func editItems(_ entries: [(child: Child, event: Event)]) -> some View {
        ForEach(entries, id: \.event.objectID) { entry in
            Button {
                onEdit(entry.event)
            } label: {
                Label("Change \(entry.child.displayName)'s last: \(entry.event.summary)", systemImage: "pencil")
            }
        }
    }

    @ViewBuilder private func face(_ latest: String) -> some View {
        if large {
            VStack(spacing: 4) {
                ActivityIcon(named: tile.iconName, size: 40)
                Text(tile.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                // Always there, so every tile is the same height.
                Text(latest.isEmpty ? " " : latest)
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Palette.ink)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            HStack(spacing: 6) {
                ActivityIcon(named: tile.iconName, size: 24)
                Text(tile.title).font(.subheadline.weight(.semibold))
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .frame(minHeight: 44)
            .foregroundStyle(Palette.ink)
            .background(Palette.field, in: Capsule())
            .contentShape(Capsule())
        }
    }
}

/// Lays chips out in rows, wrapping when a row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews, width: bounds.width)
        for (index, point) in rows.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (points: [CGPoint], width: CGFloat, height: CGFloat) {
        var points: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return (points, widest, y + rowHeight)
    }
}

/// "Tiles on Today": each one is a main tile, a chip, or hidden.
struct TileChooserView: View {
    @Environment(\.dismiss) private var dismiss
    let available: [Tile]
    @AppStorage(Setting.tilesCustom) private var custom = false
    @AppStorage(Setting.tilesMain) private var mainStored = ""
    @AppStorage(Setting.tilesHidden) private var hiddenStored = ""

    private enum Place: String, CaseIterable, Identifiable {
        case main = "Main tile", chip = "Chip", hidden = "Hidden"
        var id: String { rawValue }
    }

    private var layout: TileLayout {
        custom ? .custom(main: mainStored, hidden: hiddenStored, available: available) : .suggested(from: available)
    }

    private func place(of tile: Tile) -> Place {
        let layout = self.layout
        if layout.main.contains(tile) { return .main }
        return layout.hidden.contains(tile) ? .hidden : .chip
    }

    private func set(_ tile: Tile, to place: Place) {
        let layout = self.layout
        var main = layout.main.filter { $0 != tile }
        var hidden = layout.hidden.filter { $0 != tile }
        switch place {
        case .main:
            // A fourth main tile turns the oldest one into a chip.
            if main.count >= TileLayout.mainLimit { main.removeFirst() }
            main.append(tile)
        case .hidden:
            hidden.append(tile)
        case .chip:
            break
        }
        // Keep main tiles in the usual order, so they do not jump about.
        main = available.filter { main.contains($0) }
        mainStored = main.map(\.id).joined(separator: ",")
        hiddenStored = hidden.map(\.id).joined(separator: ",")
        custom = true
        Haptics.selection()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(available) { tile in
                        HStack(spacing: 12) {
                            ActivityIcon(named: tile.iconName, size: 28)
                            Text(tile.title)
                            Spacer()
                            Picker(tile.title, selection: Binding(get: { place(of: tile) }, set: { set(tile, to: $0) })) {
                                ForEach(Place.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .labelsHidden()
                        }
                        .listRowBackground(Palette.paper)
                    }
                } footer: {
                    Text("Up to three main tiles; the rest sit beneath as chips. Sleep starts from each child's row. Hiding a tile keeps everything already logged.")
                }
                if custom {
                    Section {
                        Button("Use the suggested tiles") {
                            custom = false
                            Haptics.selection()
                        }
                        .listRowBackground(Palette.paper)
                    } footer: {
                        Text("Suggested from the children's ages and how they feed.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.sand)
            .navigationTitle("Tiles on Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .foregroundStyle(Palette.ink)
    }
}

/// The top of Today: the date, with Puggle beside it.
///
/// Tapping her is just for fun: a small hop. While a child sleeps she sways
/// instead, quietly. She hops once on the first open of each day. When the
/// animated character exists, the same tap plays her real wave.
struct PuggleHeader: View {
    /// True while any child is asleep.
    let quiet: Bool

    @StateObject private var controller = PuggleController()
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var nod: CGFloat = 0
    @AppStorage("puggleGreetedOn") private var greetedOn = ""
    @State private var lift: CGFloat = 0
    @State private var tilt: Double = 0

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                Text(Date.now, format: .dateTime.day().month(.wide))
                    .displayFont(28)
                    .foregroundStyle(Palette.ink)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button(action: react) {
                PuggleView(controller: controller)
                    .frame(height: 78)
                    .scaleEffect(x: 1, y: 1 - nod * 0.06, anchor: .bottom)
                    .offset(y: lift + nod * 3)
                    .rotationEffect(.degrees(tilt), anchor: .bottom)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(quiet ? "Puggle, being quiet" : "Puggle")
            .accessibilityHint("Says hello")
        }
        .padding(.top, 8)
        .onAppear { controller.asleep = quiet }
        .onChange(of: quiet) { _, now in controller.asleep = now }
        // A small nod each time something is saved. No sound or tap: the save has its own.
        .onChange(of: store.lastSaved?.id) { _, id in
            guard id != nil, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.14)) { nod = quiet ? 0.5 : 1 }
            withAnimation(.spring(duration: 0.35, bounce: 0.3).delay(0.14)) { nod = 0 }
        }
        .task {
            // Once a day, after the splash has gone.
            let today = Date.now.formatted(.iso8601.year().month().day())
            guard greetedOn != today, !quiet else { return }
            try? await Task.sleep(for: .seconds(1.8))
            greetedOn = today
            react()
        }
    }

    private func react() {
        controller.greet()
        guard !controller.isAnimated, !reduceMotion else {
            if !quiet { Haptics.tap() }
            return
        }
        if quiet {
            // Quiet at night: a slow sway, no hop and no tap to feel.
            withAnimation(.easeInOut(duration: 0.5)) { tilt = 4 }
            withAnimation(.easeInOut(duration: 0.6).delay(0.5)) { tilt = 0 }
        } else {
            Haptics.tap()
            withAnimation(.spring(duration: 0.18, bounce: 0)) { lift = -12 }
            withAnimation(.spring(duration: 0.4, bounce: 0.45).delay(0.18)) { lift = 0 }
        }
    }
}
