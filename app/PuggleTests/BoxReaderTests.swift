import XCTest
@testable import Puggle

final class BoxReaderTests: XCTestCase {
    private func line(_ text: String, x: CGFloat, y: CGFloat, confidence: Float = 1) -> ReadLine {
        ReadLine(text: text, box: CGRect(x: x, y: y, width: 0.2, height: 0.03), confidence: confidence)
    }

    func testAgesAndWhereTheyStart() {
        XCTAssertEqual(BoxReader.age(in: "Up to 2 weeks")?.from, AgeMark(count: 0, unit: .weeks))
        XCTAssertEqual(BoxReader.age(in: "3 - 5 months")?.from, AgeMark(count: 3, unit: .months))
        XCTAssertEqual(BoxReader.age(in: "6 months to 2 years")?.from, AgeMark(count: 6, unit: .months))
        XCTAssertEqual(BoxReader.age(in: "2-3 yrs")?.from, AgeMark(count: 2, unit: .years))
        XCTAssertEqual(BoxReader.age(in: "12 months+")?.from, AgeMark(count: 12, unit: .months))
        XCTAssertEqual(BoxReader.age(in: "2.5 years")?.from, AgeMark(count: 30, unit: .months))
        XCTAssertNil(BoxReader.age(in: "Leave at least 4 hours between doses"))
        XCTAssertNil(BoxReader.age(in: "120 mg in 5 ml"))
    }

    func testATinsTableIsPutBackIntoRows() {
        let lines = [
            line("Feeding guide", x: 0.1, y: 0.9),
            line("Age of baby", x: 0.1, y: 0.8), line("Water", x: 0.5, y: 0.8), line("Scoops", x: 0.75, y: 0.8),
            line("Up to 2 weeks", x: 0.1, y: 0.7), line("60 ml", x: 0.5, y: 0.7), line("2", x: 0.75, y: 0.7),
            line("2-4 weeks", x: 0.1, y: 0.6), line("90 ml", x: 0.5, y: 0.6), line("3", x: 0.75, y: 0.6, confidence: 0.3),
            // Read as one line: split into its numbers.
            line("1-2 months 120 ml 4", x: 0.1, y: 0.5),
            line("Always use the scoop provided", x: 0.1, y: 0.3),
        ]
        let read = BoxReader.table(from: lines, kind: .formula)
        XCTAssertEqual(read.table.columns, ["Water", "Scoops"])
        XCTAssertEqual(read.table.rows.map(\.age), ["Up to 2 weeks", "2-4 weeks", "1-2 months"])
        XCTAssertEqual(read.table.rows.map(\.values), [["60 ml", "2"], ["90 ml", "3"], ["120 ml", "4"]])
        XCTAssertEqual(read.table.rows.map(\.from), [AgeMark(count: 0, unit: .weeks), AgeMark(count: 2, unit: .weeks), AgeMark(count: 1, unit: .months)])
        XCTAssertEqual(read.unsure, [BoxReader.Cell(row: read.table.rows[1].id, column: 1)], "Only the doubtful 3")
    }

    func testADecimalIsAlwaysWorthASecondLook() {
        XCTAssertTrue(BoxReader.isShaky("2.5 ml", confidence: 1))
        XCTAssertTrue(BoxReader.isShaky("1O ml", confidence: 1))
        XCTAssertFalse(BoxReader.isShaky("5 ml", confidence: 1))
    }

    func testTheRowChangeShowsTwoDaysBeforeAndOnTheDay() throws {
        let calendar = Calendar.current
        let birth = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 8))!
        let table = BoxTable(columns: ["Water", "Scoops"], rows: [
            .init(age: "3 to 5 months", from: AgeMark(count: 3, unit: .months), values: ["180 ml", "6"]),
            .init(age: "6 to 8 months", from: AgeMark(count: 6, unit: .months), values: ["210 ml", "7"]),
            .init(age: "By weight", from: nil, values: ["", ""]),
        ])
        func at(_ month: Int, _ day: Int, _ hour: Int = 12) -> Date { calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))! }
        XCTAssertNil(table.change(birth: birth, now: at(11, 12)), "Three days before: nothing")
        let change = try XCTUnwrap(table.change(birth: birth, now: at(11, 13, 9)))
        XCTAssertEqual(change.from, AgeMark(count: 6, unit: .months))
        XCTAssertEqual(change.before?.age, "3 to 5 months")
        XCTAssertNotNil(table.change(birth: birth, now: at(11, 15, 22)), "Still shown on the day")
        XCTAssertNil(table.change(birth: birth, now: at(11, 16, 1)), "Gone the day after")
    }

    @MainActor
    func testASavedTinIsSharedWithTheFamilyAndOnlyParentsSave() throws {
        let store = FamilyStore(persistence: Persistence(inMemory: true))
        store.isSample = true
        _ = store.currentFamily()
        let table = BoxTable(columns: ["Water", "Scoops"], rows: [.init(age: "Up to 2 weeks", from: AgeMark(count: 0, unit: .weeks), values: ["60 ml", "2"])])
        let tin = try XCTUnwrap(store.saveGuide(replacing: nil, kind: .formula, name: "Tin A", strength: nil, table: table,
                                                photo: Data([1, 2, 3]), gap: nil, limit: nil))
        XCTAssertEqual(store.formulaGuide(), tin)
        XCTAssertEqual(tin.table, table)
        XCTAssertEqual(tin.family, store.existingFamily())
        // Read again: replaces, never adds.
        store.saveGuide(replacing: tin, kind: .formula, name: "Tin B", strength: nil, table: table, photo: nil, gap: nil, limit: nil)
        XCTAssertEqual(store.guides(.formula).count, 1)
        XCTAssertEqual(store.formulaGuide()?.name, "Tin B")
        XCTAssertNil(store.formulaGuide()?.photo, "Keep this photo off")
        store.roleOverride = .helper
        store.refreshRole()
        XCTAssertNil(store.saveGuide(replacing: nil, kind: .formula, name: "Tin C", strength: nil, table: table, photo: nil, gap: nil, limit: nil))
    }

    func testAMedicineBoxLineKeepsItsDoseAndFlagsTheDecimal() {
        let lines = [
            line("Paracetamol", x: 0.1, y: 0.9),
            line("3-6 months: 2.5 ml", x: 0.1, y: 0.7),
            line("6-24 months: 5 ml", x: 0.1, y: 0.6),
            line("Water (ml)", x: 0.1, y: 0.3),
        ]
        let read = BoxReader.table(from: lines, kind: .medicine)
        XCTAssertEqual(read.table.columns, ["Each dose"])
        XCTAssertEqual(read.table.rows.map(\.values), [["2.5 ml"], ["5 ml"]])
        XCTAssertEqual(read.unsure, [BoxReader.Cell(row: read.table.rows[0].id, column: 0)])
    }

    // MARK: A bottle

    /// What the front half of a medicine bottle's label reads as: two small tables with sentences between
    /// them, and the last column lost round the curve.
    private func bottleFront() -> [ReadLine] {
        [line("For the relief of fever after vaccination at 2, 3 and 4 months", x: 0.1, y: 0.95),
         line("Child's Age", x: 0.1, y: 0.9), line("How much", x: 0.4, y: 0.9),
         line("2-3 months", x: 0.1, y: 0.85), line("2.5 ml - If necessary, after 4-6 hours", x: 0.4, y: 0.85),
         line("• Do not give to babies less than 2 months of age", x: 0.1, y: 0.8),
         line("than 2 doses. This is to ensure that fever that may be", x: 0.1, y: 0.75),
         line("Child's Age", x: 0.1, y: 0.7), line("How much", x: 0.4, y: 0.7),
         line("3-6 months", x: 0.1, y: 0.65), line("2.5 ml", x: 0.4, y: 0.65),
         line("6-24 months", x: 0.1, y: 0.6), line("5 ml", x: 0.4, y: 0.6),
         line("2-4 years", x: 0.1, y: 0.55), line("7.5 ml (5 ml + 2.5 ml)", x: 0.4, y: 0.55),
         line("4-6 years", x: 0.1, y: 0.5), line("10 ml (5 ml + 5 ml)", x: 0.4, y: 0.5),
         line("• Do not give more than 4 doses in any 24 hour period", x: 0.1, y: 0.45)]
    }

    func testABottlesLabelKeepsItsRowsAndLeavesTheSentencesOut() {
        let read = BoxReader.table(from: bottleFront(), kind: .medicine)
        XCTAssertEqual(read.table.rows.map(\.age), ["2-3 months", "3-6 months", "6-24 months", "2-4 years", "4-6 years"])
        XCTAssertEqual(read.table.columns.count, 1, "One long row does not give every row empty columns")
        XCTAssertEqual(read.table.rows.map(\.values), [["2.5 ml - If necessary, after 4-6 hours"], ["2.5 ml"], ["5 ml"],
                                                         ["7.5 ml (5 ml + 2.5 ml)"], ["10 ml (5 ml + 5 ml)"]])
    }

    func testASecondPhotoRoundTheBottleAddsItsColumn() {
        let first = BoxReader.table(from: bottleFront(), kind: .medicine).table
        // Turned a little: the ages are off the edge, the amounts and the last column show.
        let turned = [line("How much", x: 0.1, y: 0.9), line("How often", x: 0.6, y: 0.9),
                      line("2.5 ml - If necessary, after 4-6 hours", x: 0.1, y: 0.85), line("a second dose", x: 0.6, y: 0.85),
                      line("How much", x: 0.1, y: 0.7), line("How often", x: 0.6, y: 0.7),
                      line("2.5 ml", x: 0.1, y: 0.65), line("Up to 4 times a day", x: 0.6, y: 0.65),
                      line("5 ml", x: 0.1, y: 0.6), line("Up to 4 times a day", x: 0.6, y: 0.6),
                      line("7.5 ml (5 ml + 2.5 ml)", x: 0.1, y: 0.55), line("Up to 4 times a day", x: 0.6, y: 0.55),
                      line("10 ml (5 ml + 5 ml)", x: 0.1, y: 0.5), line("Up to 4 times a day", x: 0.6, y: 0.5)]
        let joined = BoxReader.merged(first, with: BoxReader.table(from: turned, kind: .medicine).table,
                                      loose: BoxReader.looseRows(from: turned), kind: .medicine)
        XCTAssertEqual(joined.rows.map(\.age), first.rows.map(\.age), "No rows are made up")
        XCTAssertEqual(joined.columns.count, 2)
        XCTAssertEqual(joined.rows.map { $0.values[0] }, first.rows.map { $0.values[0] }, "Nothing already read is replaced")
        XCTAssertEqual(joined.rows.map { $0.values[1] }, ["a second dose", "Up to 4 times a day", "Up to 4 times a day", "Up to 4 times a day", "Up to 4 times a day"])
    }

    func testASecondPhotoWithNewAgesAddsRowsInOrder() {
        let top = BoxReader.table(from: [line("3-6 months", x: 0.1, y: 0.6), line("2.5 ml", x: 0.5, y: 0.6),
                                         line("2-4 years", x: 0.1, y: 0.5), line("7.5 ml", x: 0.5, y: 0.5)], kind: .medicine).table
        let rest = BoxReader.table(from: [line("6-24 months", x: 0.1, y: 0.6), line("5 ml", x: 0.5, y: 0.6),
                                          line("2-4 years", x: 0.1, y: 0.5), line("9 ml", x: 0.5, y: 0.5)], kind: .medicine).table
        let joined = BoxReader.merged(top, with: rest, loose: [], kind: .medicine)
        XCTAssertEqual(joined.rows.map(\.age), ["3-6 months", "6-24 months", "2-4 years"])
        XCTAssertEqual(joined.rows.map(\.values), [["2.5 ml"], ["5 ml"], ["7.5 ml"]], "The first reading of a row stands")
    }
}
