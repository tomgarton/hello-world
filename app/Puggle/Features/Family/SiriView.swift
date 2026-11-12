import AppIntents
import CoreData
import SwiftUI

/// Siri works as soon as the app is installed: nothing to switch on or record.
/// This page shows the exact words, with the family's own names in them, and
/// where to put a shortcut on the Action button.
struct SiriView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)],
                  predicate: NSPredicate(format: "archived != YES")) private var children: FetchedResults<Child>

    private var name: String { children.first?.displayName ?? "Ollie" }

    private var phrases: [(symbol: String, words: String, does: String)] {
        [("moon", "Start sleep for \(name) in Puggle", "Starts the sleep timer"),
         ("sun.max", "\(name) woke up in Puggle", "Ends it"),
         ("drop", "Log a nappy for \(name) in Puggle", "Saves a wet nappy. Change it in the app if not"),
         ("waterbottle", "Log a bottle for \(name) in Puggle", "Asks how much"),
         ("clock", "When was \(name) last fed in Puggle", "Tells you, out loud")]
    }

    var body: some View {
        List {
            Section {
                ForEach(phrases, id: \.words) { phrase in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: phrase.symbol)
                            .font(.body.weight(.semibold))
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\u{201C}\(phrase.words)\u{201D}").font(.body.weight(.medium))
                            Text(phrase.does).font(.footnote).foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("Say to Siri")
            } footer: {
                Text("Nothing to set up. Say \u{201C}Hey Siri\u{201D} or hold the side button first. Any child's name works.")
            }
            .listRowBackground(Palette.paper)

            Section {
                ShortcutsLink()
                    .shortcutsLinkStyle(.automaticOutline)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } footer: {
                Text("Also in the Shortcuts app, to add to the Home Screen.")
            }

            Section {
                step(1, "Open the Settings app, then Action Button.")
                step(2, "Swipe to Shortcut, then tap Choose a Shortcut.")
                step(3, "Pick Puggle, then Start sleep.")
            } header: {
                Text("On the Action button")
            } footer: {
                Text("One press starts a sleep, without unlocking the phone.")
            }
            .listRowBackground(Palette.paper)

            Section {
                step(1, "Open the Settings app, then Focus, then Sleep.")
                step(2, "Under Focus Filters, tap Add Filter, then Puggle.")
                step(3, "Switch on Dark while this Focus is on.")
            } header: {
                Text("A dark look at bedtime")
            } footer: {
                Text("The app goes dark at bedtime; the rest of the phone doesn't change.")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Siri and shortcuts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { PuggleShortcuts.updateAppShortcutParameters() }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .frame(width: 24, height: 24)
                .background(Palette.field, in: Circle())
            Text(text)
        }
        .padding(.vertical, 2)
    }
}
