import CoreData
import SwiftUI

/// Looking after, on Today: one quiet card listing, for each thing the family has logged or booked, how long
/// since it was last done for each child, or when it is booked. A small mark shows when something has gone a
/// while past its usual gap; it is never called overdue and never red. Tapping a row logs it.
struct CareCard: View {
    @EnvironmentObject private var store: FamilyStore
    let children: [Child]
    var onLog: (CareItem) -> Void
    var onSettings: () -> Void

    /// Each child's care entries by item, worked out once per drawing of the card.
    private typealias Index = [NSManagedObjectID: [String: (done: [Event], booked: Event?)]]

    private func has(_ item: CareItem, _ child: Child, in index: Index) -> Bool {
        guard let entry = index[child.objectID]?[item.key] else { return false }
        return !entry.done.isEmpty || entry.booked != nil
    }

    var body: some View {
        let index: Index = Dictionary(uniqueKeysWithValues: children.map { ($0.objectID, store.careIndex(for: $0)) })
        // What has been logged or booked for anyone here, in the usual order.
        let items = store.careItems().filter { item in children.contains { has(item, $0, in: index) } }
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Looking after").font(.headline)
                Spacer()
                Button("Edit", action: onSettings)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Change what's looked after and how often")
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            if items.isEmpty {
                Button { onLog(.bath) } label: {
                    HStack(spacing: 12) {
                        CareItem.bath.image().frame(width: 26, height: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bath, teeth, nails, haircuts").fontWeight(.semibold)
                            Text("And the dentist and the doctor. Log one to see it here.")
                                .font(.footnote).foregroundStyle(Palette.muted)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "plus").font(.footnote.weight(.bold)).foregroundStyle(Palette.muted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle())
                .disabled(!store.canLog)
            } else {
                ForEach(items) { item in
                    row(item, index)
                    if item.id != items.last?.id {
                        // From the words to the same margin on the right, so no line runs into the card's edge.
                        Divider().padding(.leading, 54).padding(.trailing, 16)
                    }
                }
            }
        }
        .padding(.bottom, 6)
        .foregroundStyle(Palette.ink)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func row(_ item: CareItem, _ index: Index) -> some View {
        Button { onLog(item) } label: {
            HStack(alignment: .top, spacing: 12) {
                item.image().frame(width: 26, height: 26).padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).fontWeight(.semibold)
                    ForEach(children.filter { has(item, $0, in: index) }) { child in
                        line(item, child, index[child.objectID]?[item.key] ?? ([], nil))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .disabled(!store.canLog)
        .accessibilityHint("Logs \(item.name.lowercased())")
    }

    /// One child's line: "Bea · 9 days ago", with the soft mark if it has been a while, or the booking.
    @ViewBuilder private func line(_ item: CareItem, _ child: Child, _ entry: (done: [Event], booked: Event?)) -> some View {
        let who = children.count > 1 ? "\(child.displayName) · " : ""
        if let visit = entry.booked, let at = visit.startedAt {
            HStack(spacing: 8) {
                Text(who + CareLine.booked(at)).font(.subheadline).foregroundStyle(Palette.muted)
                if store.canLog {
                    Button("Done") {
                        Haptics.success()
                        store.markDone(visit)
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 30)
                    .background(Palette.field, in: Capsule())
                    .accessibilityLabel("Mark \(item.name.lowercased()) for \(child.displayName) as done")
                }
            }
            // The button is taller than the words; it reaches past the line rather than pushing it down,
            // so a booked line sits as close to the name as any other.
            .padding(.vertical, -5)
        } else if let last = entry.done.last?.startedAt {
            let gap = store.careGap(item, for: child, done: entry.done)
            let pastUsual = CareLine.pastUsual(last: last, gap: gap)
            HStack(spacing: 6) {
                if pastUsual {
                    Circle().fill(Palette.wattle).frame(width: 7, height: 7)
                }
                // One run of words, so the smaller "usually" part sits on the same baseline as the rest.
                (Text(who + text(item, entry.done, last: last)).font(.subheadline)
                    + Text(pastUsual && gap != nil ? " · usually \(gap?.text.lowercased() ?? "")" : "").font(.footnote))
                    .foregroundStyle(Palette.muted)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// For brushing, today's count ("Twice today"); for the rest, how long since.
    private func text(_ item: CareItem, _ done: [Event], last: Date) -> String {
        if item.key == CareItem.brushing.key {
            let today = done.filter { Calendar.current.isDateInToday($0.startedAt ?? .distantPast) }.count
            switch today {
            case 0: break
            case 1: return "Once today"
            case 2: return "Twice today"
            default: return "\(today) times today"
            }
        }
        return CareLine.since(last)
    }
}
