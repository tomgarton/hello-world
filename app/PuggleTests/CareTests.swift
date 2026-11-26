import CoreData
import XCTest
@testable import Puggle

/// Looking after: baths, brushing, nails, haircuts, the dentist and the doctor, and a family's own.
@MainActor
final class CareTests: XCTestCase {
    private var store: FamilyStore!
    private var bea: Child!

    override func setUp() async throws {
        store = FamilyStore(persistence: Persistence(inMemory: true))
        store.isSample = true
        bea = store.addChild(name: "Bea", birthDate: Date.now.addingTimeInterval(-900 * 86_400), colourIndex: 1, feeding: .neither)
    }

    private func daysAgo(_ days: Double) -> Date { Date.now.addingTimeInterval(-days * 86_400) }

    // MARK: How often

    func testNothingIsLearnedFromFewerThanThreeEntries() {
        XCTAssertNil(FamilyStore.learnedGap([daysAgo(14), daysAgo(7)]))
    }

    func testTheLearnedGapIsTheMiddleOfTheRecentGaps() {
        // Gaps of 6, 7 and 30 days: the middle is 7, so one long gap doesn't pull it.
        let dates = [daysAgo(43), daysAgo(37), daysAgo(30), daysAgo(0)]
        XCTAssertEqual(FamilyStore.learnedGap(dates)!, 7, accuracy: 0.01)
    }

    func testAGapStartsAsAGuessThenIsLearnedThenCanBeSet() {
        XCTAssertEqual(store.careGap(.nails, for: bea)?.source, .starting)
        for days in [30.0, 21, 12, 3] { store.logEach(.care, for: [bea], at: daysAgo(days), detail: CareItem.nails.key) }
        let learned = store.careGap(.nails, for: bea)
        XCTAssertEqual(learned?.source, .learned)
        XCTAssertEqual(learned!.days, 9, accuracy: 0.01)
        store.setCareGap(.nails, days: 14)
        XCTAssertEqual(store.careGap(.nails, for: bea), CareGap(days: 14, source: .set))
        store.setCareGap(.nails, days: nil)
        XCTAssertEqual(store.careGap(.nails, for: bea)?.source, .learned)
    }

    func testGapsReadPlainly() {
        XCTAssertEqual(CareGap(days: 0.5, source: .starting).text, "Twice a day")
        XCTAssertEqual(CareGap(days: 1, source: .starting).text, "Every day")
        XCTAssertEqual(CareGap(days: 9, source: .learned).text, "Every 9 days")
        XCTAssertEqual(CareGap(days: 42, source: .starting).text, "Every 6 weeks")
        XCTAssertEqual(CareGap(days: 182, source: .starting).text, "Every 6 months")
    }

    // MARK: What Today says

    func testSinceCountsCalendarDays() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: .now)!
        func before(_ days: Int) -> Date { calendar.date(byAdding: .day, value: -days, to: now)! }
        XCTAssertEqual(CareLine.since(now.addingTimeInterval(-3600), now: now), "Today")
        XCTAssertEqual(CareLine.since(before(1), now: now), "Yesterday")
        XCTAssertEqual(CareLine.since(before(9), now: now), "9 days ago")
        XCTAssertEqual(CareLine.since(before(35), now: now), "5 weeks ago")
    }

    func testPastUsualIsAQuarterOverAndNeverForTwiceADay() {
        let week = CareGap(days: 7, source: .learned)
        XCTAssertFalse(CareLine.pastUsual(last: daysAgo(8), gap: week))
        XCTAssertTrue(CareLine.pastUsual(last: daysAgo(9), gap: week))
        XCTAssertFalse(CareLine.pastUsual(last: daysAgo(3), gap: CareGap(days: 0.5, source: .starting)))
        XCTAssertFalse(CareLine.pastUsual(last: daysAgo(30), gap: nil))
    }

    func testBookedReadsTheDay() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: .now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!.addingTimeInterval(3600)
        XCTAssertTrue(CareLine.booked(tomorrow, now: now).hasPrefix("Booked · tomorrow "))
        let later = calendar.date(byAdding: .day, value: 20, to: now)!
        XCTAssertEqual(CareLine.booked(later, now: now), "Booked · " + later.formatted(.dateTime.day().month(.wide)))
    }

    // MARK: Booking and marking done

    func testABookedVisitIsNotDoneUntilMarked() {
        let at = Date.now.addingTimeInterval(3 * 86_400)
        let visit = store.logEach(.care, for: [bea], at: at, detail: CareItem.dentist.key, dose: Event.booked)[0]
        XCTAssertTrue(visit.isBooked)
        XCTAssertNil(store.lastCare(CareItem.dentist.key, for: bea))
        XCTAssertEqual(store.booked(CareItem.dentist.key, for: bea), visit)
        store.markDone(visit)
        XCTAssertFalse(visit.isBooked)
        XCTAssertNil(store.booked(CareItem.dentist.key, for: bea))
        // Marked done before the day it was booked for: it happened now.
        XCTAssertLessThan(abs(store.lastCare(CareItem.dentist.key, for: bea)!.startedAt!.timeIntervalSinceNow), 5)
    }

    // MARK: A family's own

    func testOwnItemsAreAddedNamedAndRemoved() {
        let swim = store.addCareItem(name: "Swimming lessons", icon: "figure.pool.swim")
        XCTAssertEqual(swim?.key, "own.swimming lessons")
        XCTAssertNil(store.addCareItem(name: "swimming lessons ", icon: "star"), "Added twice")
        XCTAssertEqual(store.careItems().last?.name, "Swimming lessons")
        XCTAssertEqual(CareItem.name(forKey: "own.swimming lessons"), "Swimming lessons")
        XCTAssertEqual(CareItem.name(forKey: "bath"), "Bath")
        store.removeCareItem(swim!)
        XCTAssertEqual(store.careItems().count, CareItem.builtIn.count)
    }

    // MARK: Reminders

    func testAReminderComesTheEveningTheUsualGapIsUp() {
        store.setCareGap(.bath, days: 2)
        store.logEach(.care, for: [bea], at: Date.now.addingTimeInterval(-3600), detail: CareItem.bath.key)
        let (when, body) = ReminderStore.careMoment(.bath, child: bea, minutes: 18 * 60, store: store)!
        let expected = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0,
                                             of: Date.now.addingTimeInterval(-3600 + 2 * 86_400))!
        XCTAssertEqual(when, expected)
        XCTAssertTrue(body.hasPrefix("Last time was"))
        XCTAssertFalse(body.lowercased().contains("overdue"))
    }

    func testAVisitReminderComesTheEveningBefore() {
        let at = Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date.now.addingTimeInterval(4 * 86_400))!
        store.logEach(.care, for: [bea], at: at, detail: CareItem.dentist.key, dose: Event.booked)
        let (when, body) = ReminderStore.careMoment(.dentist, child: bea, minutes: 18 * 60, store: store)!
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: when, to: at).day, 0)
        XCTAssertEqual(Calendar.current.component(.hour, from: when), 18)
        XCTAssertTrue(body.hasPrefix("Booked for tomorrow at"))
    }
}
