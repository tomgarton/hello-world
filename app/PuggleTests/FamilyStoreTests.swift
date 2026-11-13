import CoreData
import XCTest
@testable import Puggle

/// The logic a family relies on every day, each test in a fresh in-memory store.
@MainActor
final class FamilyStoreTests: XCTestCase {
    private var store: FamilyStore!
    private var ollie: Child!

    override func setUp() async throws {
        store = FamilyStore(persistence: Persistence(inMemory: true))
        store.isSample = true // keeps tests from writing to this device's Recently deleted
        ollie = store.addChild(name: "Ollie", birthDate: Date.now.addingTimeInterval(-150 * 86_400),
                               colourIndex: 0, feeding: .both)
    }

    private func ago(minutes: Double) -> Date { Date.now.addingTimeInterval(-minutes * 60) }

    // MARK: Logging and undo

    func testLoggingABottleKeepsItsDetails() {
        let events = store.logEach(.bottle, for: [ollie], at: ago(minutes: 5), amountML: 150, detail: "Formula")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(store.latest(.bottle, for: ollie)?.amountML, 150)
        XCTAssertEqual(store.latest(.bottle, for: ollie)?.summary, "Bottle · 150 ml · formula")
    }

    func testUndoRemovesWhatWasJustSaved() {
        store.logEach(.nappy, for: [ollie], detail: "Wet")
        XCTAssertNotNil(store.latest(.nappy, for: ollie))
        store.undoLastSaved()
        XCTAssertNil(store.latest(.nappy, for: ollie))
        XCTAssertNil(store.lastSaved)
    }

    func testTwinsBottlesAreOnePerChildWithTheirOwnAmounts() {
        let bea = store.addChild(name: "Bea", birthDate: ollie.birthDate!, colourIndex: 1, feeding: .bottle)
        let events = store.logBottles([(ollie, 120), (bea, 90)], at: .now, detail: "Formula", note: nil)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(store.latest(.bottle, for: ollie)?.amountML, 120)
        XCTAssertEqual(store.latest(.bottle, for: bea)?.amountML, 90)
    }

    func testLogAgainCopiesTheEntryAtTheTimeNow() {
        let first = store.logEach(.bottle, for: [ollie], at: ago(minutes: 180), amountML: 160, detail: "Formula")[0]
        let again = store.logAgain(first)
        XCTAssertEqual(again.count, 1)
        XCTAssertEqual(again[0].amountML, 160)
        XCTAssertEqual(again[0].detail, "Formula")
        XCTAssertLessThan(abs(again[0].startedAt!.timeIntervalSinceNow), 5)
    }

    func testMedicinesAndSleepsAreNotOfferedAgain() {
        let medicine = store.logEach(.medicine, for: [ollie], detail: "Calpol", dose: "2.5 ml")[0]
        XCTAssertFalse(store.canLogAgain(medicine))
        XCTAssertTrue(store.logAgain(medicine).isEmpty)
    }

    // MARK: Deleting and bringing back

    func testDeletedEntryCanBeRestoredWithItsDetails() {
        let bottle = store.logEach(.bottle, for: [ollie], at: ago(minutes: 30), amountML: 150, detail: "Breast milk",
                                   note: "Before bath")[0]
        let id = bottle.id
        store.delete(bottle)
        XCTAssertNil(store.latest(.bottle, for: ollie))
        let gone = try! XCTUnwrap(store.justDeleted)
        let back = try! XCTUnwrap(store.restore(gone))
        XCTAssertEqual(back.id, id)
        XCTAssertEqual(back.amountML, 150)
        XCTAssertEqual(back.detail, "Breast milk")
        XCTAssertEqual(back.note, "Before bath")
        XCTAssertEqual(back.sortedChildren, [ollie])
    }

    func testRestoreWaitsUntilAnotherSaveClearsTheUndo() {
        let nappy = store.logEach(.nappy, for: [ollie], detail: "Wet")[0]
        store.delete(nappy)
        XCTAssertNotNil(store.justDeleted)
        store.logEach(.nappy, for: [ollie], detail: "Dirty")
        XCTAssertNil(store.justDeleted, "a new save replaces the Deleted bar with Last saved")
    }

    // MARK: Sleep

    func testSleepStartsAndEnds() {
        store.startSleep(for: ollie)
        XCTAssertNotNil(store.activeSleep(for: ollie))
        store.endSleep(for: ollie)
        XCTAssertNil(store.activeSleep(for: ollie))
        XCTAssertNotNil(store.latest(.sleep, for: ollie)?.endedAt)
    }

    func testOnlyOneOpenSleepPerChild() {
        store.startSleep(for: ollie)
        store.startSleep(for: ollie)
        XCTAssertEqual((ollie.events ?? []).filter { $0.kind == .sleep }.count, 1)
    }

    func testANightWakingIsLeftOutOfTheSleepTotal() {
        let sleep = store.log(.sleep, for: [ollie], at: ago(minutes: 300), end: ago(minutes: 20))
        sleep.addWaking(from: ago(minutes: 200), to: ago(minutes: 170))
        let asleep = sleep.asleepSeconds(from: sleep.startedAt!, to: sleep.endedAt!)
        XCTAssertEqual(asleep / 60, 250, accuracy: 1, "280 minutes in bed, 30 awake")
        XCTAssertEqual(sleep.wokeText, "woke once")
    }

    func testBackToSleepCarriesOnTheSameSleepAndUndoEndsItAgain() {
        let sleep = store.log(.sleep, for: [ollie], at: ago(minutes: 240), end: ago(minutes: 10))
        store.resumeSleep(sleep)
        XCTAssertNil(sleep.endedAt)
        XCTAssertEqual(sleep.wakingIntervals.count, 1)
        store.undoLastSaved()
        XCTAssertNotNil(sleep.endedAt)
        XCTAssertEqual(sleep.wakingIntervals.count, 0)
    }

    func testTwinsGoDownTogetherWithOneUndo() {
        let bea = store.addChild(name: "Bea", birthDate: ollie.birthDate!, colourIndex: 1)
        store.startSleep(for: [ollie, bea])
        XCTAssertNotNil(store.activeSleep(for: ollie))
        XCTAssertNotNil(store.activeSleep(for: bea))
        store.undoLastSaved()
        XCTAssertNil(store.activeSleep(for: ollie))
        XCTAssertNil(store.activeSleep(for: bea))
    }

    // MARK: Feeds

    func testFeedTimerFinishesWithTheSideUsed() {
        store.tapFeedSide("Left", for: ollie)
        XCTAssertNotNil(store.activeFeed(for: ollie))
        store.finishFeed(for: ollie)
        XCTAssertNil(store.activeFeed(for: ollie))
        XCTAssertEqual(store.latest(.breastfeed, for: ollie)?.detail, "Left")
    }

    func testAFeedLeftRunningForTwoHoursIsQueried() {
        let feed = store.log(.breastfeed, for: [ollie], at: ago(minutes: 120))
        feed.runningSide = "Left"
        feed.sideStartedAt = ago(minutes: 120)
        XCTAssertEqual(store.staleFeed(among: [ollie]), feed)
    }

    // MARK: Medicines

    func testNextDoseWaitsForTheGapTheParentSet() {
        let name = "Test syrup \(UUID().uuidString.prefix(6))"
        MedicineRules.set(gap: 4, limit: nil, for: name)
        store.logEach(.medicine, for: [ollie], at: ago(minutes: 60), detail: name)
        let next = try! XCTUnwrap(store.nextDose(of: name, for: ollie))
        XCTAssertEqual(next.timeIntervalSinceNow / 60, 180, accuracy: 1)
        MedicineRules.set(gap: nil, limit: nil, for: name)
    }

    func testTheDailyLimitHoldsTheNextDoseUntilTheFirstDropsOut() {
        let name = "Test drops \(UUID().uuidString.prefix(6))"
        MedicineRules.set(gap: 1, limit: 2, for: name)
        store.logEach(.medicine, for: [ollie], at: ago(minutes: 600), detail: name)
        store.logEach(.medicine, for: [ollie], at: ago(minutes: 60), detail: name)
        let next = try! XCTUnwrap(store.nextDose(of: name, for: ollie))
        // The first was 10 hours ago, so a third fits 14 hours from now.
        XCTAssertEqual(next.timeIntervalSinceNow / 3600, 14, accuracy: 0.05)
        MedicineRules.set(gap: nil, limit: nil, for: name)
    }

    func testNoRulesMeansNoNextDose() {
        store.logEach(.medicine, for: [ollie], detail: "No rules here")
        XCTAssertNil(store.nextDose(of: "No rules here", for: ollie))
    }

    // MARK: Pumping

    func testMilkOnHandAddsPumpsAndTakesBreastMilkBottlesFromTheFridgeFirst() {
        store.setMilkOnHand(MilkOnHand(fridge: 0, freezer: 100))
        store.logPump(left: 60, right: 60, to: Pump.fridge, at: .now.addingTimeInterval(1), note: nil)
        store.logEach(.bottle, for: [ollie], at: .now.addingTimeInterval(2), amountML: 150, detail: "Breast milk")
        let milk = store.milkOnHand()
        XCTAssertEqual(milk.fridge, 0)
        XCTAssertEqual(milk.freezer, 70, "120 in the fridge was used first, then 30 from the freezer")
    }

    func testFormulaBottlesLeaveTheMilkAlone() {
        store.setMilkOnHand(MilkOnHand(fridge: 200, freezer: 0))
        store.logEach(.bottle, for: [ollie], at: .now.addingTimeInterval(1), amountML: 150, detail: "Formula")
        XCTAssertEqual(store.milkOnHand().fridge, 200)
    }

    // MARK: Stamps and stickers

    func testFiveStampsFillACardAndEarnItsSticker() {
        let bea = store.addChild(name: "Bea", birthDate: Date.now.addingTimeInterval(-900 * 86_400),
                                 colourIndex: 1, pottyTraining: true)
        for minutes in stride(from: 50.0, through: 10, by: -10) {
            let potty = store.logEach(.potty, for: [bea], at: ago(minutes: minutes), detail: "Wee")[0]
            store.setSticker("star:red", on: potty)
        }
        XCTAssertEqual(store.stampCards(for: bea).count, 1)
        XCTAssertEqual(store.stampCards(for: bea).first?.count, Stamp.perCard)
        let earned = store.earnedStickers(for: bea).map(\.id)
        XCTAssertTrue(earned.contains("card-1"))
        XCTAssertTrue(earned.contains("wee"))
        XCTAssertTrue(earned.contains("dry-1"))
    }

    func testAnAccidentStopsThatDayCountingAsDry() {
        let bea = store.addChild(name: "Bea", birthDate: Date.now.addingTimeInterval(-900 * 86_400),
                                 colourIndex: 1, pottyTraining: true)
        // Both on the same day whatever the time is now: just after midnight,
        // "half an hour ago" and "twenty minutes ago" fall on different days.
        let noon = Calendar.current.startOfDay(for: .now).addingTimeInterval(-12 * 3600)
        store.logEach(.potty, for: [bea], at: noon, detail: "Wee")
        store.logEach(.potty, for: [bea], at: noon.addingTimeInterval(600), detail: "Accident")
        XCTAssertFalse(store.earnedStickers(for: bea).map(\.id).contains("dry-1"))
    }

    // MARK: Export

    func testExportHasAHeaderAndARowPerEntry() throws {
        store.logEach(.bottle, for: [ollie], amountML: 120, detail: "Formula")
        store.logEach(.nappy, for: [ollie], detail: "Wet")
        let url = try XCTUnwrap(store.exportCSV())
        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(whereSeparator: \.isNewline)
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].lowercased().contains("child"))
    }
}
