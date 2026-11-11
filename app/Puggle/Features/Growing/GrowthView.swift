import Charts
import SwiftUI

/// A child's weights over time. Shown, never scored: no bands, no colour,
/// and the same line about the nurse or GP whatever the numbers are.
struct GrowthView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject var child: Child

    @State private var adding = false
    @State private var editing: EditTarget?

    var body: some View {
        let weights = store.weights(for: child)
        List {
            if weights.count >= 2 {
                Section {
                    chart(weights)
                        .frame(height: 220)
                        .padding(.vertical, 8)
                        .listRowBackground(Palette.paper)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(spoken(weights))
                }
            }
            Section {
                if weights.isEmpty {
                    Text("Weights logged for \(child.displayName) show up here.")
                        .foregroundStyle(Palette.muted)
                        .listRowBackground(Palette.paper)
                }
                ForEach(weights.reversed()) { event in
                    Button { editing = EditTarget(event: event) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text((event.startedAt ?? .now).formatted(.dateTime.day().month(.wide).year()))
                                Text(child.ageText(at: event.startedAt ?? .now))
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Text("\(Int(event.value).formatted()) g")
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Palette.paper)
                    .accessibilityHint("Opens this weight to change it")
                }
                Button("Add a weight") { adding = true }
                    .listRowBackground(Palette.paper)
            } footer: {
                Text("These are the numbers you entered. For what they mean for \(child.displayName), your child health nurse or GP is the one to ask.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .foregroundStyle(Palette.ink)
        .navigationTitle("\(child.displayName)'s growth")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $adding) {
            LogSheet(kind: .weight, children: [child])
        }
        .sheet(item: $editing) { target in
            LogSheet(kind: .weight, children: [child], editing: target.event)
        }
    }

    private func chart(_ weights: [Event]) -> some View {
        let values = weights.map { $0.value / 1000 }
        let low = (values.min() ?? 0) - 0.5, high = (values.max() ?? 1) + 0.5
        return Chart(weights) { event in
            LineMark(x: .value("Date", event.startedAt ?? .now), y: .value("Kilograms", event.value / 1000))
                .foregroundStyle(Palette.ink)
            PointMark(x: .value("Date", event.startedAt ?? .now), y: .value("Kilograms", event.value / 1000))
                .foregroundStyle(Palette.ink)
        }
        .chartYScale(domain: max(low, 0)...high)
        .chartYAxisLabel("kg")
    }

    private func spoken(_ weights: [Event]) -> String {
        guard let first = weights.first, let last = weights.last else { return "" }
        let from = (first.startedAt ?? .now).formatted(.dateTime.day().month(.wide))
        let to = (last.startedAt ?? .now).formatted(.dateTime.day().month(.wide))
        return "Chart of \(weights.count) weights, from \(Int(first.value).formatted()) grams on \(from) to \(Int(last.value).formatted()) grams on \(to)."
    }
}
