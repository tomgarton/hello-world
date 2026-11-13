import CoreData
import SwiftUI
import UIKit
import UserNotifications

/// A reminder belongs to the person who set it, on their own phone, so it is kept
/// in this phone's settings and never synced. Nobody switches on a reminder for
/// anyone else. Wording states facts and never nags: nothing is "late" or "missed".
struct Reminder: Codable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case feed, medicine, potty
        var id: String { rawValue }

        var title: String {
            switch self {
            case .feed: "Time since a feed"
            case .medicine: "A regular medicine"
            case .potty: "Time to try the potty"
            }
        }
    }

    var id = UUID()
    var kind: Kind
    /// The child's `id`, as a string.
    var childID: String
    var isOn = true
    /// Feed: hours after the last feed. Potty: hours between tries.
    var hours: Double = 3
    /// Medicine.
    var medicine = ""
    var dose = ""
    /// Medicine: times of day, in minutes after midnight.
    var times: [Int] = [8 * 60]
    /// Potty: only between these times, in minutes after midnight.
    var from = 8 * 60
    var until = 18 * 60
}

/// Keeps this phone's reminders, and keeps the notifications in step with them.
@MainActor
final class ReminderStore: ObservableObject {
    static let shared = ReminderStore()
    private static let key = "reminders"
    private static let prefix = "puggle.reminder."

    @Published private(set) var reminders: [Reminder] = []
    /// False when the person has said no to notifications for this app.
    @Published private(set) var allowed = true

    private var pending: Task<Void, Never>?

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = saved
        }
    }

    func save(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
        persist()
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
        reschedule(with: FamilyStore.live)
    }

    /// Asked only when a reminder is first switched on, with the reason shown on screen first.
    func askPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            allowed = true
        case .notDetermined:
            allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            allowed = false
        }
        return allowed
    }

    func checkPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        allowed = status != .denied
    }

    /// Soon after any change, so a run of saves only reschedules once.
    func reschedule(with store: FamilyStore) {
        guard !store.isSample else { return }
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await schedule(with: store)
        }
    }

    private func schedule(with store: FamilyStore) async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard reminders.contains(where: \.isOn) else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "archived != YES")
        request.predicate = store.scoped(request.predicate)
        let children = (try? store.context.fetch(request)) ?? []

        for reminder in reminders where reminder.isOn {
            guard let child = children.first(where: { $0.id?.uuidString == reminder.childID }) else { continue }
            let name = child.displayName
            switch reminder.kind {
            case .feed:
                let feeds = [store.latest(.bottle, for: child), store.latest(.breastfeed, for: child)].compactMap { $0?.startedAt }
                guard let last = feeds.max() else { continue }
                let at = last.addingTimeInterval(reminder.hours * 3600)
                guard at > .now else { continue }
                let hours = reminder.hours.formatted(.number.precision(.fractionLength(0...1)))
                add("\(reminder.id)", title: name, body: "It has been \(hours) hours since \(name)'s last feed.",
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: at.timeIntervalSinceNow, repeats: false))
            case .medicine:
                let what = reminder.medicine.isEmpty ? "Medicine" : reminder.medicine
                let dose = reminder.dose.isEmpty ? "" : ", \(reminder.dose)"
                for (index, minutes) in reminder.times.enumerated() {
                    add("\(reminder.id).\(index)", title: "\(what) for \(name)",
                        body: "Set for \(Self.clock(minutes))\(dose).",
                        trigger: Self.daily(at: minutes))
                }
            case .potty:
                let step = max(Int(reminder.hours * 60), 30)
                var minutes = reminder.from
                var index = 0
                while minutes < reminder.until, index < 24 {
                    add("\(reminder.id).\(index)", title: "Time to try?", body: "A gentle potty reminder for \(name).",
                        trigger: Self.daily(at: minutes))
                    minutes += step
                    index += 1
                }
            }
        }
    }

    private func add(_ id: String, title: String, body: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // Quiet: a banner with no sound, so a reminder never wakes a sleeping baby.
        content.sound = nil
        content.interruptionLevel = .active
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: Self.prefix + id, content: content, trigger: trigger))
    }

    private static func daily(at minutes: Int) -> UNCalendarNotificationTrigger {
        UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minutes / 60, minute: minutes % 60), repeats: true)
    }

    static func clock(_ minutes: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// A regular medicine that is due: from an hour before its time until three hours after,
    /// unless a dose has been logged in that window. It goes quietly once logged.
    func due(for child: Child, in store: FamilyStore, now: Date = .now) -> String? {
        guard let id = child.id?.uuidString else { return nil }
        let start = Calendar.current.startOfDay(for: now)
        for reminder in reminders where reminder.isOn && reminder.kind == .medicine && reminder.childID == id {
            for minutes in reminder.times.sorted() {
                let at = start.addingTimeInterval(Double(minutes) * 60)
                guard now >= at.addingTimeInterval(-3600), now <= at.addingTimeInterval(3 * 3600) else { continue }
                let last = store.lastDose(of: reminder.medicine, for: child)?.startedAt ?? .distantPast
                if last < at.addingTimeInterval(-3600) {
                    let what = reminder.medicine.isEmpty ? "Medicine" : reminder.medicine
                    return "\(what) · \(Self.clock(minutes))"
                }
            }
        }
        return nil
    }
}

// MARK: - Settings

/// Reminders on this phone. Each person sets their own.
struct RemindersView: View {
    @EnvironmentObject private var store: FamilyStore
    @ObservedObject private var reminders = ReminderStore.shared
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.createdAt)],
                  predicate: NSPredicate(format: "archived != YES")) private var allChildren: FetchedResults<Child>
    private var children: [Child] { store.onScreen(allChildren) }
    @State private var editing: Reminder?

    var body: some View {
        List {
            if !reminders.allowed {
                Section {
                    Text("Notifications are off for this app, so reminders can't show.")
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .listRowBackground(Palette.paper)
            }
            Section {
                if reminders.reminders.isEmpty {
                    Text("No reminders yet. They are off until you add one.")
                        .foregroundStyle(Palette.muted)
                }
                ForEach(reminders.reminders) { reminder in
                    Button { editing = reminder } label: { row(reminder) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    offsets.map { reminders.reminders[$0] }.forEach(reminders.delete)
                }
            } footer: {
                Text("Reminders are just for you, on this iPhone. Nobody else in the family gets them.")
            }
            .listRowBackground(Palette.paper)

            if let first = children.first {
                Section {
                    ForEach(Reminder.Kind.allCases) { kind in
                        Button("Add: \(kind.title.lowercased())") {
                            editing = Reminder(kind: kind, childID: first.id?.uuidString ?? "")
                        }
                    }
                }
                .listRowBackground(Palette.paper)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { reminder in
            ReminderEditor(reminder: reminder, children: Array(children))
        }
        .task { await reminders.checkPermission() }
    }

    private func row(_ reminder: Reminder) -> some View {
        let name = children.first { $0.id?.uuidString == reminder.childID }?.displayName ?? "Child"
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(headline(reminder, name: name)).font(.body.weight(.medium))
                Text(detail(reminder)).font(.subheadline).foregroundStyle(Palette.muted)
            }
            Spacer()
            Toggle("On", isOn: Binding(get: { reminder.isOn }, set: { on in
                var changed = reminder
                changed.isOn = on
                Task {
                    if on { _ = await ReminderStore.shared.askPermission() }
                    ReminderStore.shared.save(changed)
                }
            }))
            .labelsHidden()
        }
        .contentShape(Rectangle())
    }

    private func headline(_ reminder: Reminder, name: String) -> String {
        switch reminder.kind {
        case .feed: "\(name): time since a feed"
        case .medicine: "\(name): \(reminder.medicine.isEmpty ? "medicine" : reminder.medicine)"
        case .potty: "\(name): time to try"
        }
    }

    private func detail(_ reminder: Reminder) -> String {
        let hours = reminder.hours.formatted(.number.precision(.fractionLength(0...1)))
        switch reminder.kind {
        case .feed: return "\(hours) hours after the last feed"
        case .medicine: return reminder.times.sorted().map(ReminderStore.clock).joined(separator: " · ")
        case .potty: return "Every \(hours) hours, \(ReminderStore.clock(reminder.from)) to \(ReminderStore.clock(reminder.until))"
        }
    }
}

/// Add or change one reminder. Every number comes from the parent; the app suggests none.
private struct ReminderEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var reminder: Reminder
    let children: [Child]
    @State private var asking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Who", selection: $reminder.childID) {
                        ForEach(children) { child in
                            Text(child.displayName).tag(child.id?.uuidString ?? "")
                        }
                    }
                }
                .listRowBackground(Palette.paper)
                switch reminder.kind {
                case .feed: feedFields
                case .medicine: medicineFields
                case .potty: pottyFields
                }
            }
            .scrollContentBackground(.hidden)
            .listRowBackground(Palette.paper)
            .background(Palette.sand)
            .navigationTitle(reminder.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if reminder.isOn { _ = await ReminderStore.shared.askPermission() }
                            ReminderStore.shared.save(reminder)
                            dismiss()
                        }
                    }
                    .disabled(reminder.kind == .medicine && reminder.medicine.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .foregroundStyle(Palette.ink)
    }

    private var hoursStepper: some View {
        Stepper("Every \(reminder.hours.formatted(.number.precision(.fractionLength(0...1)))) hours",
                value: $reminder.hours, in: 0.5...12, step: 0.5)
    }

    @ViewBuilder private var feedFields: some View {
        Section {
            Stepper("\(reminder.hours.formatted(.number.precision(.fractionLength(0...1)))) hours after a feed",
                    value: $reminder.hours, in: 0.5...12, step: 0.5)
        }
        .listRowBackground(Palette.paper)
        Section {
        } footer: {
            Text("Counted from the last feed anyone logged. You choose the time; the app doesn't suggest one.")
        }
    }

    @ViewBuilder private var medicineFields: some View {
        Section {
            TextField("Which medicine?", text: $reminder.medicine)
            TextField("Dose, as on the label or as prescribed", text: $reminder.dose)
        }
        .listRowBackground(Palette.input)
        Section {
            ForEach(reminder.times.indices, id: \.self) { index in
                DatePicker("Time \(index + 1)", selection: timeBinding(index), displayedComponents: .hourAndMinute)
            }
            .onDelete { reminder.times.remove(atOffsets: $0) }
            Button("Add a time") { reminder.times.append(min((reminder.times.last ?? 480) + 240, 23 * 60)) }
        } footer: {
            Text("Shows as due on Today from an hour before, and goes once a dose is logged.")
        }
    }

    @ViewBuilder private var pottyFields: some View {
        Section {
            hoursStepper
            DatePicker("From", selection: minutes(\.from), displayedComponents: .hourAndMinute)
            DatePicker("Until", selection: minutes(\.until), displayedComponents: .hourAndMinute)
        } footer: {
            Text("A gentle \"Time to try?\" during the day. Never a nag.")
        }
    }

    private func date(_ minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    private func minutesOf(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private func timeBinding(_ index: Int) -> Binding<Date> {
        Binding(get: { date(reminder.times[index]) }, set: { reminder.times[index] = minutesOf($0) })
    }

    private func minutes(_ key: WritableKeyPath<Reminder, Int>) -> Binding<Date> {
        Binding(get: { date(reminder[keyPath: key]) }, set: { reminder[keyPath: key] = minutesOf($0) })
    }
}
