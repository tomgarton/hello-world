import SwiftUI

/// The steps of first run, in order. The raw value gives the direction of travel.
enum OnboardingStep: Int, CaseIterable {
    case welcome, joining, found, logging, sharing, name, child, more, invite, amount, done

    /// The steps a new family goes through, for the progress dots.
    static let newFamily: [OnboardingStep] = [.logging, .sharing, .name, .child, .more, .invite, .amount, .done]
    /// The steps for someone joining, or a family coming back from iCloud.
    static let foundPath: [OnboardingStep] = [.found, .name, .done]
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

/// A row of the tiles from Today, as a picture of what logging looks like.
struct OnboardingTiles: View {
    private let kinds: [EventKind] = [.bottle, .sleep, .nappy, .potty]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(kinds) { kind in
                VStack(spacing: 8) {
                    ActivityIcon(kind, size: 36)
                    Text(kind.title)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, minHeight: 92)
                .padding(.horizontal, 4)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tiles for bottle, sleep, \(Terms.nappyLower) and potty")
    }
}

/// A made-up child's row with two entries, as a picture of a shared day.
struct OnboardingSampleDay: View {
    /// Who added each entry. Left off when this build does not share.
    let showsWho: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Palette.childColours[0])
                    .frame(width: 44, height: 44)
                    .overlay(Text("O").font(.system(size: 18, weight: .bold, design: .rounded)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ollie").font(.headline)
                    Text("5 months").font(.subheadline).foregroundStyle(Palette.muted)
                }
            }
            entry(.bottle, text: "Bottle, 150 ml", who: "Robin")
            entry(.sleep, text: "Nap, 1 h 20 min", who: "Nan")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showsWho
            ? "An example day for Ollie: a bottle added by Dad and a nap added by Nan"
            : "An example day for Ollie: a bottle and a nap")
    }

    private func entry(_ kind: EventKind, text: String, who: String) -> some View {
        HStack(spacing: 10) {
            ActivityIcon(kind, size: 28)
            Text(text).font(.body)
            Spacer(minLength: 8)
            if showsWho {
                Text(who)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 26)
                    .background(Palette.field, in: Capsule())
            }
        }
    }
}

/// One of the two large choices on "How much to see". Selection shows as a
/// tick and a border, never colour alone.
struct OnboardingChoice: View {
    let title: String
    let text: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3.weight(.semibold))
                    Text(text)
                        .font(.body)
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                tick
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Palette.ink, lineWidth: isOn ? 2.5 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressStyle(scale: 0.98))
        .foregroundStyle(Palette.ink)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var tick: some View {
        ZStack {
            Circle()
                .fill(isOn ? Palette.ink : Palette.field)
                .frame(width: 28, height: 28)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Palette.paper)
            }
        }
        .accessibilityHidden(true)
    }
}
