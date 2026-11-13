import CoreData
import SwiftUI

/// A made-up family to look around with: a baby and a toddler, two weeks of
/// entries. It lives in memory only, apart from the real family, and is
/// gone when the app closes or the parent leaves it. Nothing here syncs.
@MainActor
final class SampleFamily: ObservableObject {
    @Published private(set) var store: FamilyStore?
    /// True for the moment it takes to make the sample entries.
    @Published private(set) var loading = false

    var isOn: Bool { store != nil }

    /// `role` shows the family as a helper or a viewer sees it, for checking those screens.
    func start(as role: Role? = nil) {
        guard store == nil, !loading else { return }
        loading = true
        Task {
            // Let the loading screen draw before the entries are made.
            try? await Task.sleep(for: .milliseconds(120))
            let sample = FamilyStore(persistence: Persistence(inMemory: true))
            sample.isSample = true
            SampleData(store: sample).fill()
            sample.authorOverride = nil
            #if DEBUG
            // For checking Patterns with a real history: "-debugImportFile <path> -debugImportBirth 2024-04-29"
            // adds a child to the sample family and imports the file for them. Nothing is saved: the sample is in memory.
            if let path = UserDefaults.standard.string(forKey: "debugImportFile"),
               let birthText = UserDefaults.standard.string(forKey: "debugImportBirth") {
                let format = DateFormatter()
                format.dateFormat = "yyyy-MM-dd"
                if let birth = format.date(from: birthText) {
                    let child = sample.addChild(name: "Ivy", birthDate: birth, colourIndex: 2, feeding: .both)
                    let reading = Importer.read([URL(fileURLWithPath: path)])
                    sample.importDrafts(reading.drafts, children: Dictionary(uniqueKeysWithValues: reading.babies.map { ($0, child) }))
                }
            }
            #endif
            if let role, role != .parent {
                sample.authorOverride = role == .helper ? "Nan" : "Pop"
                sample.roleOverride = role
            }
            sample.refreshRole()
            store = sample
            loading = false
        }
    }

    func leave() {
        store = nil
    }
}

/// Writes the sample entries. The same every time, so screenshots match.
@MainActor
private struct SampleData {
    let store: FamilyStore
    private let calendar = Calendar.current
    private let now = Date.now
    /// First names, so the sample assumes nothing about who is in a family.
    private let people = ["Alex", "Robin", "Nan"]

    /// A steady pseudo-random number in 0..<range for a day and a slot.
    private func wobble(_ day: Int, _ slot: Int, _ range: Int) -> Int {
        guard range > 0 else { return 0 }
        return abs((day &* 7919) &+ (slot &* 104_729) &+ 13) % range
    }

    private func time(_ day: Int, _ hour: Int, _ minute: Int, slot: Int, jitter: Int = 20) -> Date {
        let start = calendar.startOfDay(for: now)
        let base = calendar.date(byAdding: .day, value: -day, to: start) ?? start
        let minutes = hour * 60 + minute + wobble(day, slot, jitter) - jitter / 2
        return base.addingTimeInterval(Double(minutes) * 60)
    }

    private func ago(months: Int = 0, days: Int = 0) -> Date {
        let back = calendar.date(byAdding: .month, value: -months, to: now) ?? now
        return calendar.date(byAdding: .day, value: -days, to: back) ?? back
    }

    /// Logs one entry if it has started. A stretch that spans now is left running.
    @discardableResult
    private func add(_ kind: EventKind, _ child: Child, _ start: Date, end: Date? = nil, ml: Double = 0,
                     detail: String? = nil, dose: String? = nil, value: Double = 0, by: Int = 0) -> Event? {
        guard start <= now else { return nil }
        store.authorOverride = people[by % people.count]
        let stillGoing = (end ?? start) > now
        if stillGoing && kind != .sleep { return nil }
        return store.log(kind, for: [child], at: start, end: stillGoing ? nil : end, amountML: ml,
                         detail: detail, dose: dose, value: value)
    }

    private func feed(_ child: Child, _ start: Date, left: Double, right: Double, by: Int) {
        let end = start.addingTimeInterval((left + right) * 60)
        guard let event = add(.breastfeed, child, start, end: end, detail: "Both", by: by) else { return }
        event.leftSeconds = left * 60
        event.rightSeconds = right * 60
    }

    func fill() {
        let ollie = store.addChild(name: "Ollie", birthDate: ago(months: 5, days: 9), colourIndex: 0, feeding: .both)
        let bea = store.addChild(name: "Bea", birthDate: ago(months: 31, days: 4), colourIndex: 1,
                                 feeding: .neither, pottyTraining: true)
        baby(ollie)
        toddler(bea)
        let family = store.currentFamily()
        let grownUps: [(String, Role, Bool, Bool)] = [("Alex", .parent, true, true), ("Robin", .parent, false, true),
                                                      ("Nan", .helper, false, true), ("Pop", .viewer, false, true),
                                                      ("Jo", .helper, false, false)]
        for (index, (name, role, holds, joined)) in grownUps.enumerated() {
            let person = Person(context: store.context)
            store.place(person, with: family)
            person.id = UUID()
            person.name = name
            person.role = role
            person.holdsFamily = holds
            person.createdAt = ago(days: 40 - index)
            person.invitedAt = ago(days: joined ? 40 - index : 3)
            person.joinedAt = joined ? ago(days: 39 - index) : nil
            person.family = family
        }
        store.persistence.save()
        store.lastSaved = nil
    }

    private func baby(_ child: Child) {
        let foods = ["Pumpkin", "Banana", "Avocado", "Sweet potato", "Pear", "Porridge", "Carrot"]
        for day in stride(from: 13, through: 0, by: -1) {
            add(.sleep, child, time(day + 1, 19, 15, slot: 1), end: time(day, 2, 40, slot: 2))
            feed(child, time(day, 2, 50, slot: 3, jitter: 6), left: Double(7 + wobble(day, 4, 5)), right: Double(5 + wobble(day, 5, 5)), by: 0)
            add(.sleep, child, time(day, 3, 20, slot: 6, jitter: 6), end: time(day, 6, 30, slot: 7))
            add(.bottle, child, time(day, 7, 0, slot: 8), ml: Double(140 + wobble(day, 9, 4) * 10), detail: "Formula", by: 1)
            add(.nappy, child, time(day, 7, 25, slot: 10), detail: "Wet", by: 1)
            add(.sleep, child, time(day, 9, 5, slot: 11), end: time(day, 10, 15, slot: 12))
            feed(child, time(day, 10, 30, slot: 13, jitter: 8), left: Double(8 + wobble(day, 14, 5)), right: Double(6 + wobble(day, 15, 5)), by: 0)
            add(.nappy, child, time(day, 11, 5, slot: 16), detail: wobble(day, 17, 3) == 0 ? "Both" : "Dirty", by: day % 3)
            if day < 10 {
                add(.solids, child, time(day, 12, 0, slot: 18), detail: foods[(13 - day) % foods.count], by: day % 3)
            }
            add(.sleep, child, time(day, 13, 0, slot: 19), end: time(day, 14, 40, slot: 20, jitter: 40))
            add(.bottle, child, time(day, 15, 0, slot: 21), ml: Double(150 + wobble(day, 22, 4) * 10), detail: "Formula", by: 2)
            add(.nappy, child, time(day, 16, 10, slot: 23), detail: "Wet", by: 2)
            feed(child, time(day, 17, 30, slot: 24, jitter: 8), left: Double(6 + wobble(day, 25, 5)), right: Double(6 + wobble(day, 26, 5)), by: 0)
            add(.bottle, child, time(day, 18, 40, slot: 27, jitter: 10), ml: Double(170 + wobble(day, 28, 3) * 10), detail: "Formula", by: 1)
            add(.nappy, child, time(day, 18, 55, slot: 29, jitter: 6), detail: "Wet", by: 1)
        }

        // Weight, from birth.
        let weights: [(months: Int, days: Int, grams: Double)] = [
            (5, 9, 3450), (5, 0, 3610), (4, 9, 4380), (3, 20, 5020), (3, 0, 5650),
            (2, 5, 6240), (1, 10, 6790), (0, 18, 7180), (0, 2, 7420),
        ]
        for weight in weights {
            add(.weight, child, ago(months: weight.months, days: weight.days), value: weight.grams, by: 0)
        }

        // Health: a record, logged plainly.
        add(.vaccination, child, ago(months: 3, days: 26), detail: "6 week vaccinations", by: 0)
        add(.vaccination, child, ago(months: 1, days: 8), detail: "4 month vaccinations", by: 1)
        add(.temperature, child, time(3, 16, 30, slot: 40, jitter: 0), detail: "Ear", value: 37.9, by: 1)
        add(.medicine, child, time(3, 16, 45, slot: 41, jitter: 0), detail: "Paracetamol", dose: "3 ml", by: 1)
        add(.medicine, child, time(3, 22, 50, slot: 42, jitter: 0), detail: "Paracetamol", dose: "3 ml", by: 0)
        add(.temperature, child, time(2, 7, 10, slot: 43, jitter: 0), detail: "Ear", value: 37.1, by: 0)

        add(.milestone, child, ago(months: 3, days: 30), detail: "First smile", by: 0)
        add(.milestone, child, ago(months: 1, days: 20), detail: "First laugh", by: 1)
        add(.milestone, child, ago(months: 1, days: 2), detail: "Rolled over", by: 2)
        add(.milestone, child, ago(days: 10), detail: "First food", by: 0)
    }

    private func toddler(_ child: Child) {
        let breakfasts = ["Porridge", "Toast and egg", "Weet-bix style cereal", "Yoghurt and fruit"]
        let lunches = ["Cheese sandwich", "Pasta", "Rice and vegetables", "Soup and bread"]
        let dinners = ["Fish and peas", "Chicken and rice", "Spaghetti", "Vegetable fritters"]
        let stickers = Stamp.offered.map { $0 }
        var count = 0

        func potty(_ day: Int, _ hour: Int, _ minute: Int, slot: Int) {
            let roll = wobble(day, slot, 10)
            // Further back there are more tries and the odd accident.
            let what: String
            if day > 8 { what = roll < 4 ? "Tried" : (roll < 6 ? "Accident" : "Wee") }
            else { what = roll < 1 ? "Accident" : (roll < 3 ? "Tried" : (roll < 5 ? "Poo" : "Wee")) }
            guard let event = add(.potty, child, time(day, hour, minute, slot: slot), detail: what, by: (day + slot) % 3) else { return }
            if what != "Accident" {
                event.sticker = "\(stickers[count % stickers.count].rawValue):\(Ink.allCases[(count * 3) % Ink.allCases.count].rawValue):"
                    + "\(UInt64.random(in: 1...999_999)):\(String(format: "%.1f", Double.random(in: -4...4))):\(String(format: "%.1f", Double.random(in: -4...4)))"
                count += 1
            }
        }

        for day in stride(from: 13, through: 0, by: -1) {
            add(.sleep, child, time(day + 1, 19, 30, slot: 50), end: time(day, 6, 45, slot: 51))
            potty(day, 7, 0, slot: 52)
            add(.solids, child, time(day, 7, 30, slot: 53), detail: breakfasts[day % breakfasts.count], by: 1)
            potty(day, 10, 0, slot: 54)
            add(.solids, child, time(day, 12, 15, slot: 55), detail: lunches[day % lunches.count], by: day % 3)
            add(.sleep, child, time(day, 12, 50, slot: 56), end: time(day, 14, 20, slot: 57, jitter: 40))
            potty(day, 14, 35, slot: 58)
            add(.solids, child, time(day, 17, 30, slot: 59), detail: dinners[day % dinners.count], by: 0)
            potty(day, 18, 45, slot: 60)
        }

        add(.milestone, child, ago(months: 20), detail: "First word", by: 0)
        add(.milestone, child, ago(months: 18, days: 12), detail: "First steps", by: 1)
        add(.milestone, child, ago(days: 12), detail: "First wee on the potty", by: 2)
    }
}
