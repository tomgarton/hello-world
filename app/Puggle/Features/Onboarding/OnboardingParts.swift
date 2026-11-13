import SwiftUI

/// The steps of first run, in order. The raw value gives the direction of travel.
enum OnboardingStep: Int, CaseIterable {
    case welcome, joining, found, logging, together, lookingBack, you, child, more, invite, family

    /// Three pages about the app, each with a dot.
    static let pages: [OnboardingStep] = [.logging, .together, .lookingBack]
    /// The setup screens, each with a dot. Adding another child returns to the second.
    static var setup: [OnboardingStep] { Persistence.cloudSyncEnabled ? [.you, .child, .more, .invite] : [.you, .child, .more] }

    /// The dots this step shows, if any.
    var dots: (current: Int, count: Int)? {
        if let index = Self.pages.firstIndex(of: self) { return (index, Self.pages.count) }
        if let index = Self.setup.firstIndex(of: self) { return (index, Self.setup.count) }
        if self == .child, !Self.setup.contains(.child) { return nil }
        return nil
    }
}

/// One first-run page: content that scrolls if the text is large, with the
/// buttons held at the bottom.
struct OnboardingPage<Content: View, Actions: View>: View {
    private let content: Content
    private let actions: Actions

    init(@ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                actions
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Palette.sand)
        }
    }
}

/// Where you are in setup: one dot per step after the welcome.
struct OnboardingDots: View {
    let current: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.ink : Palette.field)
                    .frame(width: index == current ? 18 : 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

/// The bottle stepper from the log sheet, to try. Nothing is saved.
struct OnboardingTryBottle: View {
    @State private var amount = 160
    @State private var milk = "Formula"

    var body: some View {
        VStack(spacing: 12) {
            Text("Try it").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                step("minus", "Less") { amount = max(10, amount - 10) }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(amount)").displayFont(44).monospacedDigit().contentTransition(.numericText())
                    Text("ml").foregroundStyle(Palette.muted)
                }
                .accessibilityElement(children: .combine)
                Spacer()
                step("plus", "More") { amount = min(400, amount + 10) }
            }
            Picker("Milk", selection: $milk) {
                ForEach(["Formula", "Breast milk", "Mixed"], id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Try the bottle stepper. Nothing is saved.")
    }

    private func step(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(Palette.field, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Three people at the three levels, as in the Family tab.
struct OnboardingLevels: View {
    private let rows: [(String, String, Int)] = [("You", "Parent", 3), ("Nan", "Helper", 1), ("Pop", "Viewer", 6)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 { Divider().padding(.leading, 62) }
                HStack(spacing: 12) {
                    Circle()
                        .fill(Palette.childColours[row.2])
                        .frame(width: 36, height: 36)
                        .overlay(Text(String(row.0.prefix(1))).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Palette.fixedInk))
                    Text(row.0).font(.headline)
                    Spacer()
                    Text(row.1)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 10)
                        .frame(minHeight: 26)
                        .background(Palette.field, in: Capsule())
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 56)
            }
        }
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An example family: you as a parent, Nan as a helper, Pop as a viewer")
    }
}

/// A made-up week of bottles, drawn like the chart in Insights.
struct OnboardingWeek: View {
    private let counts = [6, 5, 7, 6, 6, 5, 7]
    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bottles this week").font(.headline)
                Spacer()
                Text("42 · 6 a day").font(.subheadline).foregroundStyle(Palette.muted).monospacedDigit()
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(counts.indices, id: \.self) { index in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Palette.childColours[0])
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Palette.ink.opacity(0.25), lineWidth: 1))
                            .frame(height: CGFloat(counts[index]) * 11)
                        Text(days[index]).font(.footnote).foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An example week: 42 bottles, about 6 a day")
    }
}
