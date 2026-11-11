import SwiftUI

/// Stand-in stickers drawn from system symbols until the Puggle sticker art
/// is added. The raw value is what is saved on the potty entry.
enum Sticker: String, CaseIterable, Identifiable {
    case star, heart, sun, moon, leaf, fish, bird, tortoise, ladybird

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .star: "star.fill"
        case .heart: "heart.fill"
        case .sun: "sun.max.fill"
        case .moon: "moon.stars.fill"
        case .leaf: "leaf.fill"
        case .fish: "fish.fill"
        case .bird: "bird.fill"
        case .tortoise: "tortoise.fill"
        case .ladybird: "ladybug.fill"
        }
    }

    var colour: Color {
        switch self {
        case .star, .sun: Palette.wattle
        case .heart, .ladybird: Palette.waratah
        case .moon, .fish, .bird: Palette.harbour
        case .leaf, .tortoise: Palette.gum
        }
    }

    var name: String { rawValue.capitalized }
}

struct StickerBadge: View {
    let sticker: Sticker
    var size: CGFloat = 44
    /// Every tenth sticker is a shiny one.
    var shiny = false

    var body: some View {
        Circle()
            .fill(Palette.paper)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: sticker.symbol)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(sticker.colour)
            )
            .overlay(Circle().stroke(shiny ? Palette.wattle : Palette.ink.opacity(0.15), lineWidth: shiny ? 3 : 1))
            .accessibilityLabel(shiny ? "Shiny \(sticker.name) sticker" : "\(sticker.name) sticker")
    }
}

/// After a potty success the phone goes to the child. Only the stickers can be
/// tapped; a parent holds the line at the bottom for two seconds to skip.
struct StickerPickerView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    let event: Event

    @State private var chosen: Sticker?

    private var name: String { event.sortedChildren.first?.displayName ?? "" }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(chosen == nil ? "Pick a sticker\(name.isEmpty ? "" : ", \(name)")!" : "On it goes!")
                .font(.display(34))
                .multilineTextAlignment(.center)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(Sticker.allCases) { sticker in
                    Button {
                        pick(sticker)
                    } label: {
                        StickerBadge(sticker: sticker, size: 92)
                            .scaleEffect(chosen == sticker ? 1.15 : 1)
                            .opacity(chosen == nil || chosen == sticker ? 1 : 0.35)
                    }
                    .buttonStyle(.plain)
                    .disabled(chosen != nil)
                }
            }
            Spacer()
            Text("Grown-ups: hold here to skip")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 2) { dismiss() }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Hold for two seconds")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .animation(.spring(duration: 0.3), value: chosen)
        .sensoryFeedback(trigger: chosen) { _, _ in Haptics.isOn ? .success : nil }
    }

    private func pick(_ sticker: Sticker) {
        chosen = sticker
        store.setSticker(sticker.rawValue, on: event)
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            dismiss()
        }
    }
}

/// A week at a glance, and every sticker so far. It only ever adds up: an
/// accident never appears here and never takes anything away.
struct StickerChartView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    let children: [Child]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(children) { child in
                        chart(for: child)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.sand)
            .navigationTitle("Sticker chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .foregroundStyle(Palette.ink)
    }

    private func chart(for child: Child) -> some View {
        let earned = store.stickers(for: child)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days: [Date] = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let toGo = 10 - earned.count % 10
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ChildAvatar(child: child, size: 36)
                Text(child.displayName).font(.title3.weight(.semibold))
            }
            if earned.isEmpty {
                Text("Stickers appear here after a wee, a poo or a try on the potty.")
                    .foregroundStyle(Palette.muted)
            } else {
                HStack(alignment: .top, spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        let todays = earned.filter { calendar.isDate($0.startedAt ?? .distantPast, inSameDayAs: day) }
                        VStack(spacing: 4) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(Palette.muted)
                            ForEach(todays.prefix(4)) { event in
                                if let sticker = Sticker(rawValue: event.sticker ?? "") {
                                    StickerBadge(sticker: sticker, size: 34)
                                }
                            }
                            if todays.count > 4 {
                                Text("+\(todays.count - 4)").font(.caption2).foregroundStyle(Palette.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(todays.count) stickers")
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("\(earned.count) sticker\(earned.count == 1 ? "" : "s") so far")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(Array(earned.enumerated()), id: \.element.objectID) { index, event in
                        if let sticker = Sticker(rawValue: event.sticker ?? "") {
                            StickerBadge(sticker: sticker, size: 44, shiny: (index + 1) % 10 == 0)
                        }
                    }
                }
                Text("Every tenth sticker is a shiny one. \(toGo) to go to the next.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        }
    }
}
