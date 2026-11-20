import XCTest
@testable import Puggle

/// The tin reader, against what the phone's text recognition gave for two photos of one round tin
/// (15 November 2026): the right-hand columns sit higher than their rows, and some digits were not read.
final class FormulaReaderTests: XCTestCase {
    private func lines(_ items: [(String, Double, Double, Double, Double)]) -> [ReadLine] {
        items.map { ReadLine(text: $0.0, box: CGRect(x: $0.1, y: $0.2, width: $0.3, height: $0.4), confidence: 1) }
    }

    /// Close up: the slant is slight.
    private let close: [(String, Double, Double, Double, Double)] = [
        ("Add 1 level scoop of powder to each 30ml of water", 0.110, 0.783, 0.820, 0.043),
        ("This feeding table should only be used as a guide. All", 0.109, 0.765, 0.826, 0.041),
        ("babies are different and so may require more or less", 0.110, 0.748, 0.826, 0.038),
        ("than is shown below. Kendamil First Infant Milk should", 0.110, 0.731, 0.823, 0.038),
        ("be fed on demand.If you need advice talk to your", 0.110, 0.713, 0.826, 0.036),
        ("healthcare professional.", 0.110, 0.705, 0.375, 0.020),
        ("Water", 0.644, 0.702, 0.076, 0.017),
        ("Scoops Feeds per", 0.755, 0.694, 0.178, 0.022),
        ("Weight of baby", 0.372, 0.686, 0.187, 0.023),
        ("Age of baby", 0.113, 0.684, 0.133, 0.022),
        ("per feed a", 0.606, 0.686, 0.114, 0.016),
        ("per teed•", 0.735, 0.683, 0.104, 0.016),
        ("24 hours", 0.834, 0.679, 0.103, 0.019),
        ("7lb", 0.511, 0.666, 0.054, 0.016),
        ("90ml", 0.631, 0.664, 0.088, 0.017),
        ("3.0 kg", 0.363, 0.663, 0.104, 0.020),
        ("Birth-1 week", 0.110, 0.664, 0.196, 0.017),
        ("3", 0.817, 0.664, 0.019, 0.012),
        ("6", 0.915, 0.661, 0.016, 0.013),
        ("8lb", 0.508, 0.647, 0.057, 0.016),
        ("120ml", 0.612, 0.645, 0.107, 0.017),
        ("3.5 kg", 0.363, 0.644, 0.104, 0.020),
        ("1-4 weeks", 0.107, 0.645, 0.158, 0.017),
        ("4", 0.811, 0.645, 0.022, 0.013),
        ("5", 0.915, 0.644, 0.016, 0.015),
        ("10lb", 0.489, 0.628, 0.076, 0.016),
        ("1-2 months", 0.110, 0.628, 0.177, 0.015),
        ("120ml", 0.615, 0.628, 0.101, 0.015),
        ("4", 0.814, 0.628, 0.019, 0.013),
        ("4.5 kg", 0.360, 0.625, 0.104, 0.018),
        ("5", 0.817, 0.610, 0.019, 0.013),
        ("3 months", 0.110, 0.609, 0.142, 0.017),
        ("12lb", 0.492, 0.609, 0.073, 0.016),
        ("150ml", 0.615, 0.609, 0.101, 0.015),
        ("5.5 kg", 0.363, 0.606, 0.101, 0.018),
        ("4-5 months", 0.107, 0.588, 0.185, 0.018),
        ("14lb", 0.489, 0.589, 0.076, 0.016),
        ("6.5 kg", 0.360, 0.587, 0.107, 0.019),
        ("180ml", 0.612, 0.589, 0.104, 0.015),
        ("4", 0.912, 0.577, 0.019, 0.012),
        ("6 months", 0.107, 0.571, 0.148, 0.016),
        ("210ml", 0.615, 0.570, 0.104, 0.016),
        ("18lb", 0.489, 0.570, 0.076, 0.016),
        ("8.0 kg", 0.360, 0.567, 0.101, 0.018),
        ("7", 0.814, 0.555, 0.022, 0.016),
        ("7-12 months", 0.107, 0.552, 0.196, 0.017),
        ("210ml", 0.615, 0.552, 0.101, 0.015),
        ("* freshly boiled and cooled; '1 level scoop = 4.3g", 0.104, 0.526, 0.789, 0.025),
        ("Assumes weaning at 6 months.", 0.106, 0.504, 0.535, 0.028),
    ]

    /// Further back: the scoops sit most of a row higher than their ages.
    private let wide: [(String, Double, Double, Double, Double)] = [
        ("than is shown below. Kendamil First Infant Milk should", 0.237, 0.628, 0.571, 0.015),
        ("be fed on demand. Ifyou need advice talk to your", 0.240, 0.616, 0.568, 0.013),
        ("Scoops Feeds per", 0.675, 0.603, 0.129, 0.012),
        ("healthcare professional.", 0.237, 0.602, 0.259, 0.015),
        ("Water", 0.599, 0.602, 0.050, 0.012),
        ("24 hours", 0.748, 0.596, 0.057, 0.009),
        ("per feed", 0.662, 0.593, 0.063, 0.010),
        ("per feed*", 0.571, 0.592, 0.082, 0.012),
        ("Age of baby", 0.237, 0.589, 0.095, 0.015),
        ("Weight of baby", 0.413, 0.589, 0.126, 0.013),
        ("6", 0.792, 0.583, 0.009, 0.007),
        ("3", 0.716, 0.580, 0.016, 0.010),
        ("Birth-1 week", 0.239, 0.575, 0.136, 0.014),
        ("7lb", 0.508, 0.576, 0.038, 0.012),
        ("90ml", 0.587, 0.576, 0.063, 0.012),
        ("3.0 kg", 0.407, 0.574, 0.073, 0.013),
        ("1-4 weeks", 0.240, 0.562, 0.107, 0.015),
        ("120ml", 0.577, 0.564, 0.073, 0.010),
        ("8lb", 0.505, 0.563, 0.041, 0.012),
        ("3.5 kg", 0.410, 0.561, 0.070, 0.013),
        ("4", 0.716, 0.557, 0.016, 0.009),
        ("1-2 months", 0.240, 0.551, 0.123, 0.014),
        ("120ml", 0.574, 0.551, 0.076, 0.012),
        ("4.5 kg", 0.407, 0.549, 0.073, 0.013),
        ("10lb", 0.489, 0.549, 0.057, 0.012),
        ("5", 0.716, 0.544, 0.016, 0.010),
        ("150ml", 0.577, 0.539, 0.073, 0.012),
        ("3 months", 0.238, 0.537, 0.105, 0.016),
        ("12lb", 0.492, 0.538, 0.054, 0.012),
        ("5.5 kg", 0.410, 0.535, 0.069, 0.015),
        ("6", 0.716, 0.531, 0.016, 0.010),
        ("4-5 months", 0.238, 0.523, 0.130, 0.017),
        ("180ml", 0.574, 0.526, 0.076, 0.012),
        ("14lb", 0.492, 0.525, 0.054, 0.012),
        ("6.5 kg", 0.410, 0.523, 0.069, 0.013),
        ("7", 0.716, 0.520, 0.016, 0.009),
        ("6 months", 0.238, 0.511, 0.108, 0.017),
        ("210ml", 0.577, 0.513, 0.069, 0.012),
        ("18lb", 0.489, 0.512, 0.057, 0.012),
        ("8.0 kg", 0.407, 0.510, 0.073, 0.013),
        ("7-12 months", 0.238, 0.498, 0.140, 0.019),
        ("210ml", 0.577, 0.501, 0.069, 0.012),
        ("•freshly boiled and cooled; b1 level scoop = 4.3g", 0.240, 0.485, 0.536, 0.021),
    ]

    private let ages = ["Birth-1 week", "1-4 weeks", "1-2 months", "3 months", "4-5 months", "6 months", "7-12 months"]
    private let water = ["90 ml", "120 ml", "120 ml", "150 ml", "180 ml", "210 ml", "210 ml"]
    private let scoops = ["3", "4", "4", "5", "6", "7", "7"]

    func testTheCloseUpPhotoGivesEveryRowItsWaterAndScoops() throws {
        let read = try XCTUnwrap(FormulaReader.table(from: lines(close)))
        XCTAssertEqual(read.table.columns, ["Weight", "Water", "Scoops", "Feeds in 24 hours"])
        XCTAssertEqual(read.table.rows.map(\.age), ages)
        XCTAssertEqual(read.table.rows.map { $0.values[1] }, water)
        XCTAssertEqual(read.table.rows.map { $0.values[2] }, scoops, "Read, or worked out from 30 ml a scoop")
        XCTAssertEqual(read.table.rows.map { $0.values[0] }.first, "3.0 kg, 7lb")
        XCTAssertEqual(read.table.rows.last?.values[0], "", "The last row has no weight on the tin")
        // The feeds that were read are in their own rows; the rest are empty and marked, never guessed.
        XCTAssertEqual(read.table.rows.map { $0.values[3] }, ["6", "5", "", "", "", "4", ""])
        for row in read.table.rows where row.values[3].isEmpty {
            XCTAssertTrue(read.unsure.contains(BoxReader.Cell(row: row.id, column: 3)))
        }
        XCTAssertFalse(read.unsure.contains { $0.column == 0 }, "A weight is never marked")
    }

    func testTheSlantedPhotoStillPutsNumbersInTheirRows() throws {
        let read = try XCTUnwrap(FormulaReader.table(from: lines(wide)))
        XCTAssertEqual(read.table.rows.map(\.age), ages)
        XCTAssertEqual(read.table.rows.map { $0.values[1] }, water)
        XCTAssertEqual(read.table.rows.map { $0.values[2] }, scoops)
        XCTAssertEqual(read.table.rows[0].values[3], "6")
    }

    func testTwoPhotosFillEachOthersGaps() throws {
        let first = try XCTUnwrap(FormulaReader.table(from: lines(wide)))
        let second = try XCTUnwrap(FormulaReader.table(from: lines(close)))
        let both = FormulaReader.merged(first.table, unsure: first.unsure, with: second.table, unsure: second.unsure)
        XCTAssertEqual(both.table.rows.count, 7, "No row is added for an age read differently")
        XCTAssertEqual(both.table.rows.map { $0.values[3] }, ["6", "5", "", "", "", "4", ""])
        XCTAssertEqual(both.table.rows.map(\.id), first.table.rows.map(\.id))
    }

    func testTheTinSaysHowMuchWaterAScoopTakes() {
        XCTAssertEqual(FormulaReader.waterPerScoop(in: lines(close)), 30)
    }

    func testAWeightInPoundsIsNotADoubtfulNumber() {
        XCTAssertFalse(BoxReader.isShaky("18lb", confidence: 1))
        XCTAssertFalse(BoxReader.isShaky("7lb", confidence: 1))
        XCTAssertTrue(BoxReader.isShaky("1l0", confidence: 1))
    }

    func testTheDayATinSuggests() throws {
        var table = try XCTUnwrap(FormulaReader.table(from: lines(close))).table
        table.rows[5].values[3] = "4"
        let birth = try XCTUnwrap(Calendar.current.date(byAdding: .month, value: -6, to: .now))
        let day = try XCTUnwrap(table.formulaDay(birth: birth.addingTimeInterval(-86400)))
        XCTAssertEqual(day.age, "6 months")
        XCTAssertEqual(day.total, 840)
        XCTAssertEqual(day.totalScoops, 28)
        // A row with no feeds gives no day.
        let younger = try XCTUnwrap(Calendar.current.date(byAdding: .month, value: -3, to: .now))
        XCTAssertNil(table.formulaDay(birth: younger.addingTimeInterval(-86400)))
    }

    func testMilkTodayIsSetBesideTheTinAndNeverOverIt() {
        let tin = FormulaDay(age: "6 months", water: 210, feeds: 4, scoops: 7)
        let day = MilkDay(drunk: 630, bottles: 3, guide: tin)
        XCTAssertEqual(day.summary, "\(Units.volume(630)) in 3 bottles")
        XCTAssertEqual(day.line, "\(Units.volume(630)) today · Tin suggests about \(Units.volume(840))")
        XCTAssertEqual(day.guideLine, "The tin suggests about \(Units.volume(840)) a day at 6 months: 4 feeds of \(Units.volume(210)), 28 scoops.")
        XCTAssertEqual(day.share ?? 0, 0.75, accuracy: 0.001)
        XCTAssertEqual(MilkDay(drunk: 1000, bottles: 5, guide: tin).share, 1, "Past the tin's figure is not over anything")
        // No tin: the total alone. No bottles: nothing on the card's line.
        XCTAssertEqual(MilkDay(drunk: 300, bottles: 2, guide: nil).line, "\(Units.volume(300)) today")
        XCTAssertNil(MilkDay(drunk: 0, bottles: 0, guide: tin).line)
    }
}
