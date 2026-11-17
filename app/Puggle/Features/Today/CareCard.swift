import SwiftUI

/// Looking after, on Today: one quiet card listing, for each thing the family has logged or booked, how long
/// since it was last done for each child, or when it is booked. A small mark shows when something has gone a
/// while past its usual gap; it is never called overdue and never red. Tapping a row logs it.
struct CareCard: View {
    @EnvironmentObject private var store: FamilyStore
    let children: [Child]
    var onLog: (CareItem) -> Void
    var onSettings: () -> Void

    /// What has been logged or booked for anyone here, in the usual order.
    private var shown: [CareItem] {
        store.careItems().filter { item in
            children.contains { store.lastCare(item.key, for: $0) != nil || store.booked(item.key, for: $0) != nil }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            let items = shown
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
                    row(item)
                    if item.id != items.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
        }
        .padding(.bottom, 6)
        .foregroundStyle(Palette.ink)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func row(_ item: CareItem) -> some View {
        Button { onLog(item) } label: {
            HStack(alignment: .top, spacing: 12) {
                item.image().frame(width: 26, height: 26).padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).fontWeight(.semibold)
                    ForEach(children.filter { store.lastCare(item.key, for: $0) != nil || store.booked(item.key, for: $0) != nil }) { child in
                        line(item, child)
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
    @ViewBuilder private func line(_ item: CareItem, _ child: Child) -> some View {
        let who = children.count > 1 ? "\(child.displayName) · " : ""
        if let visit = store.booked(item.key, for: child), let at = visit.startedAt {
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
        } else if let last = store.lastCare(item.key, for: child)?.startedAt {
            let gap = store.careGap(item, for: child)
            let pastUsual = CareLine.pastUsual(last: last, gap: gap)
            HStack(spacing: 6) {
                if pastUsual {
                    Circle().fill(Palette.wattle).frame(width: 7, height: 7)
                }
                Text(who + text(item, child, last: last)).font(.subheadline).foregroundStyle(Palette.muted)
                if pastUsual, let gap {
                    Text("· usually \(gap.text.lowercased())").font(.footnote).foregroundStyle(Palette.muted)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// For brushing, today's count ("Twice today"); for the rest, how long since.
    private func text(_ item: CareItem, _ child: Child, last: Date) -> String {
        if item.key == CareItem.brushing.key {
            let today = store.careDone(item.key, for: child).filter { Calendar.current.isDateInToday($0.startedAt ?? .distantPast) }.count
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
