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

    // MARK: Waking together, and where a sleep is listed

    func testTwoWakingTogetherCanBeUndoneOneAtATime() {
        let bea = store.addChild(name: "Bea", birthDate: Date.now.addingTimeInterval(-900 * 86_400), colourIndex: 0)
        let ivy = store.addChild(name: "Ivy", birthDate: Date.now.addingTimeInterval(-150 * 86_400), colourIndex: 1)
        store.startSleep(for: [bea, ivy])
        store.endSleep(for: bea)
        store.endSleep(for: ivy)
        XCTAssertEqual(store.lastSaved?.events.count, 2, "both wakings are offered")
        let saved = store.lastSaved?.id

        let beasSleep = try! XCTUnwrap(store.latest(.sleep, for: bea))
        store.undo(beasSleep)
        XCTAssertNotNil(store.activeSleep(for: bea), "Bea is asleep again")
        XCTAssertNil(store.activeSleep(for: ivy), "Ivy stays awake")
        XCTAssertEqual(store.lastSaved?.events.count, 1)
        XCTAssertEqual(store.lastSaved?.id, saved, "taking one off is not a new save")

        let ivysSleep = try! XCTUnwrap(store.latest(.sleep, for: ivy))
        store.forget(ivysSleep)
        XCTAssertNil(store.lastSaved)
        XCTAssertNil(store.activeSleep(for: ivy), "dismissing changes nothing")
    }

    func testAFinishedSleepIsListedWhenItEnded() {
        let bea = store.addChild(name: "Bea", birthDate: Date.now.addingTimeInterval(-900 * 86_400), colourIndex: 0)
        let began = Date.now.addingTimeInterval(-11 * 3600), ended = Date.now.addingTimeInterval(-60)
        let sleep = store.log(.sleep, for: [bea], at: began, end: ended)
        XCTAssertEqual(sleep.listedAt, ended)
        let running = store.log(.sleep, for: [bea], at: began)
        XCTAssertEqual(running.listedAt, began, "a sleep still going is listed where it began")
        let nappy = store.log(.nappy, for: [bea], at: began, end: nil, detail: "Wet")
        XCTAssertEqual(nappy.listedAt, began)
    }

    func testANewChildNeedsABirthDateChosen() {
        var draft = ChildDraft()
        draft.name = "Ollie"
        XCTAssertFalse(draft.isComplete, "the date is never guessed")
        draft.birthDateChosen = true
        draft.birthDate = Date.now.addingTimeInterval(-900 * 86_400)
        XCTAssertTrue(draft.isComplete)
    }

    func testDeleteEverythingRemovesWhatIsOwned() {
        let ollie = store.addChild(name: "Ollie", birthDate: .now, colourIndex: 0)
        store.log(.nappy, for: [ollie], at: .now, detail: "Wet")
        XCTAssertTrue(store.deleteEverything(), "nothing is left on this phone")
        XCTAssertFalse(store.hasJoinedFamily)
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

    func testAnAccidentNeverTakesAPottyDayAway() {
        let bea = store.addChild(name: "Bea", birthDate: Date.now.addingTimeInterval(-900 * 86_400),
                                 colourIndex: 1, pottyTraining: true)
        // Both on the same day whatever the time is now: just after midnight,
        // "half an hour ago" and "twenty minutes ago" fall on different days.
        let noon = Calendar.current.startOfDay(for: .now).addingTimeInterval(-12 * 3600)
        store.logEach(.potty, for: [bea], at: noon, detail: "Wee")
        store.logEach(.potty, for: [bea], at: noon.addingTimeInterval(600), detail: "Accident")
        XCTAssertTrue(store.earnedStickers(for: bea).map(\.id).contains("dry-1"), "the wee still counts")
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

    // MARK: Parent, helper and viewer

    func testAHelperCanChangeOnlyTheirOwnEntries() {
        store.authorOverride = "Alex"
        let theirs = store.logEach(.bottle, for: [ollie], amountML: 120)[0]
        store.authorOverride = "Nan"
        let mine = store.logEach(.nappy, for: [ollie], detail: "Wet")[0]
        store.roleOverride = .helper
        store.refreshRole()
        XCTAssertTrue(store.canLog)
        XCTAssertTrue(store.canChange(mine))
        XCTAssertFalse(store.canChange(theirs))
    }

    func testAViewerCanChangeNothing() {
        let entry = store.logEach(.nappy, for: [ollie], detail: "Wet")[0]
        store.roleOverride = .viewer
        store.refreshRole()
        XCTAssertFalse(store.canLog)
        XCTAssertFalse(store.canChange(entry))
    }

    func testAParentCanChangeAnyEntry() {
        store.authorOverride = "Nan"
        let entry = store.logEach(.nappy, for: [ollie], detail: "Wet")[0]
        store.authorOverride = "Alex"
        store.refreshRole()
        XCTAssertEqual(store.role, .parent)
        XCTAssertTrue(store.canChange(entry))
    }

    func testAViewersChangesAreNotKept() {
        store.persistence.readOnly = true
        store.logEach(.nappy, for: [ollie], detail: "Wet")
        XCTAssertNil(store.latest(.nappy, for: ollie))
        store.persistence.readOnly = false
    }

    func testPeopleAreListedHolderFirstThenByLevel() {
        let family = store.currentFamily()
        func add(_ name: String, _ role: Role, holds: Bool = false) {
            let person = Person(context: store.context)
            person.id = UUID()
            person.name = name
            person.role = role
            person.holdsFamily = holds
            person.createdAt = .now
            person.family = family
        }
        add("Pop", .viewer)
        add("Nan", .helper)
        add("Robin", .parent)
        add("Alex", .parent, holds: true)
        XCTAssertEqual(store.people().map(\.displayName), ["Alex", "Robin", "Nan", "Pop"])
    }

    // MARK: Fixes from the usability findings

    func testAHelperCannotDeleteSomeoneElsesEntryByAnyRoute() {
        store.authorOverride = "Alex"
        let theirs = store.logEach(.nappy, for: [ollie], detail: "Wet")[0]
        store.startSleep(for: ollie)
        store.authorOverride = "Nan"
        store.roleOverride = .helper
        store.refreshRole()
        store.delete(theirs)
        XCTAssertTrue(theirs.isLive, "The store itself refuses, whatever screen asked")
        // A sleep someone else started moments ago is ended, not removed.
        store.cancelSleep(for: ollie)
        XCTAssertNil(store.activeSleep(for: ollie))
        XCTAssertNotNil(store.latest(.sleep, for: ollie))
    }

    func testAChildDraftSaysWhatIsMissing() {
        var draft = ChildDraft()
        XCTAssertEqual(draft.missing, "Add a name to carry on.")
        draft.name = "Ivy"
        XCTAssertEqual(draft.missing, "Choose a birth date to carry on.")
        draft.birthDateChosen = true
        draft.birthDate = Date.now.addingTimeInterval(-60 * 86_400)
        XCTAssertEqual(draft.missing, "Choose how they feed to carry on.")
        draft.feeding = .neither
        XCTAssertNil(draft.missing)
        XCTAssertTrue(draft.isComplete)
    }

    func testSmallFeedsMoveInSmallSteps() {
        guard !Units.ounces else { return }
        XCTAssertEqual(Units.volumeStep(from: 60, down: true), 10)
        XCTAssertEqual(Units.volumeStep(from: 30, down: true), 5)
        XCTAssertEqual(Units.volumeStep(from: 25, down: false), 5)
        XCTAssertEqual(Units.volumeStep(from: 30, down: false), 10)
        XCTAssertEqual(Units.volumeFloor, 5)
    }

    func testAMedicineRuleSavedForTheFamilyReachesThisPhonesCopy() {
        // As if another phone had saved it: a shared record, and nothing here yet.
        let name = "Test syrup \(UUID().uuidString.prefix(6))"
        let key = MedicineRules.key(name)
        store.isSample = false
        defer { MedicineRules.adopt(gap: nil, limit: nil, forKey: key); store.isSample = true }
        let guide = Guide(context: store.context)
        guide.id = UUID()
        guide.kindRaw = "medicine"
        guide.name = name
        guide.key = key
        guide.gapHours = 4
        guide.doseLimit = 4
        guide.updatedAt = .now
        guide.family = store.currentFamily()
        XCTAssertNil(MedicineRules.gap(for: name))
        store.syncMedicineRules()
        XCTAssertEqual(MedicineRules.gap(for: name), 4)
        XCTAssertEqual(MedicineRules.limit(for: name), 4)
        // A parent changing it here changes the shared record, not a second one.
        store.shareRule(name: name, gap: 6, limit: 3)
        XCTAssertEqual(guide.gapHours, 6)
        XCTAssertEqual((store.currentFamily().guides ?? []).filter { $0.key == key }.count, 1)
    }

    // MARK: Backups

    private func shelf() -> BackupShelf {
        BackupShelf(directory: FileManager.default.temporaryDirectory.appendingPathComponent("backups-\(UUID().uuidString)"))
    }

    func testBringingBackWhatIsMissingRemovesNothing() throws {
        store.backups = shelf()
        store.logEach(.bottle, for: [ollie], at: ago(minutes: 30), amountML: 120)
        let lost = store.logEach(.nappy, for: [ollie], at: ago(minutes: 20), detail: "Wet")[0]
        let entry = try XCTUnwrap(store.backUp(.manual))
        XCTAssertEqual(entry.entries, 2)
        store.delete(lost)
        store.logEach(.note, for: [ollie], note: "Logged after the backup")
        let copy = try XCTUnwrap(store.backups.load(entry))
        let back = store.restoreMissing(from: copy)
        XCTAssertEqual(back.entries, 1)
        XCTAssertNotNil(store.latest(.nappy, for: ollie))
        XCTAssertNotNil(store.latest(.note, for: ollie), "What was logged since is kept")
        XCTAssertTrue(store.restoreMissing(from: copy).isNothing, "A second time adds nothing twice")
    }

    func testADeletedChildComesBackWithTheirEntries() throws {
        store.backups = shelf()
        store.logEach(.bottle, for: [ollie], amountML: 150)
        let entry = try XCTUnwrap(store.backUp(.manual))
        store.delete(ollie)
        let back = store.restoreMissing(from: try XCTUnwrap(store.backups.load(entry)))
        XCTAssertEqual(back.children, 1)
        let children = store.currentFamily().children ?? []
        XCTAssertEqual(children.first?.name, "Ollie")
        XCTAssertEqual(children.first?.events?.count, 1)
    }

    func testGoingBackExactlyDropsWhatCameAfterAndCanBeTakenBack() throws {
        store.backups = shelf()
        store.logEach(.bottle, for: [ollie], at: ago(minutes: 30), amountML: 120)
        let entry = try XCTUnwrap(store.backUp(.manual))
        store.logEach(.nappy, for: [ollie], detail: "Wet")
        XCTAssertTrue(store.restoreExactly(from: try XCTUnwrap(store.backups.load(entry))))
        let family = store.currentFamily()
        XCTAssertEqual(family.events?.count, 1)
        XCTAssertEqual(family.children?.count, 1)
        // The moment before going back was kept too.
        let before = try XCTUnwrap(store.backups.entries.first { $0.reason == BackupReason.beforeRestore.rawValue })
        XCTAssertEqual(before.entries, 2)
    }

    func testAHelperCannotGoBackToABackup() throws {
        store.backups = shelf()
        store.logEach(.bottle, for: [ollie], amountML: 120)
        let copy = try XCTUnwrap(store.snapshot(reason: .manual))
        store.roleOverride = .helper
        store.refreshRole()
        XCTAssertFalse(store.restoreExactly(from: copy))
        XCTAssertTrue(store.restoreMissing(from: copy).isNothing)
    }

    // MARK: Import

    private func exportFiles() -> [(name: String, data: Data)] {
        [("Ollie B. Test_formula.csv", Data("\u{FEFF}Baby,Time,Amount (ml),Note\nOllie B. Test,\"22/06/2025, 07:30\",120\nOllie B. Test,\"02/06/2025, 19:15\",150,\"Took it slowly, then all\"\n".utf8)),
         ("Ollie B. Test_sleep.csv", Data("Baby,Time,Duration(minutes),Note\nOllie B. Test,\"21/06/2025, 12:25\",114\n".utf8)),
         ("Ollie B. Test_diaper.csv", Data("Baby,Time,Status,Note\nOllie B. Test,\"22/06/2025, 09:53\",Mixed\n".utf8)),
         ("Ollie B. Test_growth.csv", Data("Baby,Time,Length (cm),Weight (kg),Head size (cm),Note\nOllie B. Test,\"02/04/2025, 17:01\",73,9.17,45\n".utf8)),
         ("pump.csv", Data("Time,Start Side,Left duration (min),Right duration (min),Total Duration (min),Left amount (ml),Right amount (ml),Total amount (ml),Note\n\"13/05/2024, 01:30\",Right,10,10,20,,,\n".utf8))]
    }

    func testAnExportIsReadIntoTheRightKindsAndDates() {
        let reading = Importer.read(files: exportFiles())
        XCTAssertEqual(reading.babies, ["Ollie B. Test"])
        XCTAssertEqual(reading.count(.bottle), 2)
        XCTAssertEqual(reading.count(.sleep), 1)
        XCTAssertEqual(reading.count(.nappy), 1)
        XCTAssertEqual(reading.count(.weight), 1)
        XCTAssertEqual(reading.count(.pump), 0)
        XCTAssertTrue(reading.leftOut.contains("1 pumping sessions with no amount."))
        // 22/06 can only be the 22nd of June: the file settles day-first by itself.
        let bottle = reading.drafts.last { $0.kind == .bottle }
        let parts = Calendar.current.dateComponents([.day, .month, .hour, .minute], from: bottle?.start ?? .distantPast)
        XCTAssertEqual([parts.day, parts.month, parts.hour, parts.minute], [22, 6, 7, 30])
        XCTAssertEqual(reading.drafts.first { $0.note != nil && $0.kind == .bottle }?.note, "Took it slowly, then all")
        let weight = reading.drafts.first { $0.kind == .weight }
        XCTAssertEqual(weight?.value ?? 0, 9170, accuracy: 0.5)
        XCTAssertEqual(weight?.note, "Length 73 cm · Head 45 cm")
        XCTAssertEqual(reading.drafts.first { $0.kind == .nappy }?.detail, "Both")
        let sleep = reading.drafts.first { $0.kind == .sleep }
        XCTAssertEqual(sleep?.end?.timeIntervalSince(sleep?.start ?? .now), 114 * 60)
    }

    func testImportingTwiceAddsNothingTwiceAndCanBeUndone() {
        store.backups = shelf()
        let logged = store.logEach(.nappy, for: [ollie], detail: "Wet")[0]
        let reading = Importer.read(files: exportFiles())
        let first = store.importDrafts(reading.drafts, children: ["Ollie B. Test": ollie])
        XCTAssertEqual(first.added, 5)
        let second = store.importDrafts(reading.drafts, children: ["Ollie B. Test": ollie])
        XCTAssertEqual(second.added, 0)
        XCTAssertEqual(second.repeats, 5)
        XCTAssertEqual(store.undoImport(batch: first.batch), 5)
        XCTAssertTrue(logged.isLive, "What was logged here is not touched")
        XCTAssertEqual(store.currentFamily().events?.count, 1)
    }

    // MARK: Patterns

    /// Builds days of entries quickly, through the importer, for a child born `born` days ago.
    private func days(_ build: (Int, Date) -> [Importer.Draft]) -> [Importer.Draft] {
        let today = Calendar.current.startOfDay(for: .now)
        return (1...300).flatMap { back in build(back, Calendar.current.date(byAdding: .day, value: -back, to: today)!) }
    }

    private func at(_ day: Date, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    func testPatternsFindASteadyBedtimeTheEndOfNightBottlesAndFewerNaps() {
        store.backups = shelf()
        let baby = store.addChild(name: "Ivy", birthDate: Date.now.addingTimeInterval(-300 * 86_400), colourIndex: 1, feeding: .bottle)
        let drafts = days { back, day in
            let young = back > 150
            // Bedtime moves about while young, then settles around 19:40.
            let bed = young ? at(day, 21, 0).addingTimeInterval(Double((back % 7) * 25) * 60) : at(day, 19, 35 + (back % 3) * 5)
            var list = [Importer.Draft(baby: "Ivy", kind: .sleep, start: bed, end: bed.addingTimeInterval(10 * 3600))]
            list.append(.init(baby: "Ivy", kind: .sleep, start: at(day, 13), end: at(day, 14, 30)))
            if young { list.append(.init(baby: "Ivy", kind: .sleep, start: at(day, 9, 30), end: at(day, 10, 30))) }
            for hour in [7, 12, 17] { list.append(.init(baby: "Ivy", kind: .bottle, start: at(day, hour), amountML: 150)) }
            if young { list.append(.init(baby: "Ivy", kind: .bottle, start: at(day, 2), amountML: 120)) }
            return list
        }
        store.importDrafts(drafts, children: ["Ivy": baby])
        let p = Patterns.make(child: baby)
        XCTAssertGreaterThan(p.months.count, 6)
        let texts = p.changes.map(\.text)
        XCTAssertTrue(texts.contains { $0.hasPrefix("Since ") && $0.contains("bedtime has usually been around") }, "\(texts)")
        XCTAssertTrue(texts.contains { $0.hasPrefix("The last bottle logged between 22:00 and 05:00 was at") }, "\(texts)")
        XCTAssertTrue(texts.contains { $0.contains("most days had 1 nap. Before that, most had 2.") }, "\(texts)")
        XCTAssertNil(p.prompt)
    }

    func testABedtimeThatMovesLaterIsPointedOut() {
        store.backups = shelf()
        let baby = store.addChild(name: "Ivy", birthDate: Date.now.addingTimeInterval(-200 * 86_400), colourIndex: 1, feeding: .bottle)
        let drafts = days { back, day in
            guard back <= 28 else { return [] }
            let bed = back <= 14 ? at(day, 20, 45) : at(day, 19, 40)
            return [.init(baby: "Ivy", kind: .sleep, start: bed, end: bed.addingTimeInterval(9 * 3600))]
        }
        store.importDrafts(drafts, children: ["Ivy": baby])
        let prompt = Patterns.make(child: baby).prompt
        XCTAssertEqual(prompt, "Bedtimes in the last two weeks were about 1h 05m later than in the two weeks before.")
    }

    func testPatternsSayNothingWithTooLittleLogged() {
        store.logEach(.bottle, for: [ollie], amountML: 120)
        let p = Patterns.make(child: ollie)
        XCTAssertTrue(p.months.isEmpty)
        XCTAssertEqual(p.bestMonthDays, 1, "One day with entries counts towards the five")
    }

    // MARK: Joining with children of your own

    /// A family as if it had arrived from someone else's iCloud, in the shared store.
    private func joinedFamily() -> (Family, Child) {
        let shared = store.persistence.sharedStore!
        let family = Family(context: store.context)
        store.context.assign(family, to: shared)
        family.id = UUID()
        family.name = "Their family"
        family.createdAt = .now
        let child = Child(context: store.context)
        store.context.assign(child, to: shared)
        child.id = UUID()
        child.name = "Bea"
        child.birthDate = Date.now.addingTimeInterval(-400 * 86_400)
        child.createdAt = .now
        child.family = family
        store.persistence.save()
        return (family, child)
    }

    func testAJoinedFamilyIsShownAloneAndOwnChildrenCanBeBroughtIn() throws {
        store.isSample = false
        store.backups = shelf()
        defer { store.isSample = true }
        store.logEach(.bottle, for: [ollie], amountML: 120)
        let (family, bea) = joinedFamily()
        XCTAssertEqual(store.existingFamily(), family)
        XCTAssertEqual(store.onScreen([ollie, bea]), [bea], "Only the family on screen")
        XCTAssertEqual(store.ownChildrenBesideJoined.map(\.displayName), ["Ollie"])
        let moved = store.bringOwnChildrenIn()
        XCTAssertEqual(moved.children, 1)
        XCTAssertEqual(moved.entries, 1)
        XCTAssertTrue(store.ownChildrenBesideJoined.isEmpty)
        let names = (family.children ?? []).map(\.displayName).sorted()
        XCTAssertEqual(names, ["Bea", "Ollie"])
        let ollieNow = try XCTUnwrap(family.children?.first { $0.displayName == "Ollie" })
        XCTAssertEqual(ollieNow.objectID.persistentStore, store.persistence.sharedStore, "Saved where the family lives")
        XCTAssertEqual(ollieNow.events?.count, 1)
        XCTAssertTrue(store.backups.entries.contains { $0.reason == BackupReason.beforeBringingIn.rawValue })
    }
}
