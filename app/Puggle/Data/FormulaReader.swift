import CoreGraphics
import Foundation

/// Reads the feeding table on a formula tin by what each thing is, not only by where it sits.
///
/// A tin's table is always the same shape: an age, sometimes a weight, the water for a feed, the scoops for a
/// feed, and the feeds in 24 hours. On a round tin the right-hand columns sit higher or lower than their rows,
/// and the reader misses some of the single digits out there. Putting the text back into rows by height alone
/// (as `BoxReader.table` does, which suits a flat medicine box) then puts numbers in the wrong rows.
///
/// So here each piece is told apart by its unit: "210ml" is water, "8.0 kg" and "18lb" are weight, and a bare
/// number is scoops or feeds. The scoops do not depend on being read at all: the tin says how much water one
/// scoop takes ("1 level scoop to each 30ml"), so they are worked out from the water, and the numbers that
/// were read show how far the photo slants. That slant then puts the feeds in the right rows. A feed count
/// that was not read is left empty and marked, for a person to fill in from the photo.
enum FormulaReader {
    static let weight = "Weight"
    static let water = "Water"
    static let scoops = "Scoops"
    static let feeds = "Feeds in 24 hours"

    private static let waterText = try! NSRegularExpression(pattern: "^(\\d{2,3})\\s*m[lI]s?$", options: [.caseInsensitive])
    private static let weightText = try! NSRegularExpression(pattern: "^\\d+(?:[.,]\\d+)?\\s*(?:kg|lbs?)$", options: [.caseInsensitive])
    private static let countText = try! NSRegularExpression(pattern: "^\\d{1,2}$")
    private static let scoopRule = try! NSRegularExpression(
        pattern: "(\\d+)\\s*level(?:led)?\\s*scoops?[^.]*?(\\d+)\\s*ml", options: [.caseInsensitive])

    private static func whole(_ regex: NSRegularExpression, _ text: String) -> NSTextCheckingResult? {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
    }

    /// How much water one scoop takes, from the tin's own words: "Add 1 level scoop of powder to each 30ml".
    static func waterPerScoop(in lines: [ReadLine]) -> Int? {
        for line in lines {
            guard let match = whole(scoopRule, line.text),
                  let count = Range(match.range(at: 1), in: line.text).flatMap({ Int(line.text[$0]) }),
                  let amount = Range(match.range(at: 2), in: line.text).flatMap({ Int(line.text[$0]) }),
                  count > 0, amount % count == 0 else { continue }
            return amount / count
        }
        return nil
    }

    /// The tin's table, or nil if this is not a table with feeds in a day (then the plain reader has it).
    static func table(from lines: [ReadLine]) -> (table: BoxTable, unsure: Set<BoxReader.Cell>)? {
        let texts = lines.map { $0.text.trimmingCharacters(in: .whitespaces) }
        // The rows: short lines that start with an age.
        var marks: [(line: ReadLine, text: String, from: AgeMark)] = []
        for (line, text) in zip(lines, texts) where text.count <= 24 {
            guard let found = BoxReader.age(in: text),
                  text.distance(from: text.startIndex, to: found.range.lowerBound) <= 3,
                  found.range.upperBound == text.endIndex else { continue }
            marks.append((line, text, found.from))
        }
        marks.sort { $0.line.box.midY > $1.line.box.midY }
        guard marks.count >= 3 else { return nil }
        let gaps = zip(marks, marks.dropFirst()).map { $0.line.box.midY - $1.line.box.midY }.sorted()
        let pitch = gaps[gaps.count / 2]
        guard pitch > 0 else { return nil }
        let left = marks.map(\.line.box.minX).min() ?? 0

        /// The row a piece of text belongs to: the nearest in height once the slant is taken off.
        func row(of box: CGRect, slant: CGFloat = 0) -> (index: Int, off: CGFloat)? {
            let y = box.midY - slant * (box.midX - left)
            let best = marks.indices.min { abs(marks[$0].line.box.midY - y) < abs(marks[$1].line.box.midY - y) }
            guard let best, abs(marks[best].line.box.midY - y) < 0.6 * pitch else { return nil }
            return (best, abs(marks[best].line.box.midY - y))
        }

        var waters = [Int?](repeating: nil, count: marks.count)
        var waterDoubt = Set<Int>()
        var weights = [[(x: CGFloat, text: String)]](repeating: [], count: marks.count)
        var counts: [ReadLine] = []
        var waterEdge: CGFloat = 0
        for (line, text) in zip(lines, texts) {
            if let match = whole(waterText, text), let index = row(of: line.box)?.index, waters[index] == nil,
               let amount = Range(match.range(at: 1), in: text).flatMap({ Int(text[$0]) }) {
                waters[index] = amount
                if line.confidence < 0.8 { waterDoubt.insert(index) }
                waterEdge = max(waterEdge, line.box.maxX)
            } else if whole(weightText, text) != nil, let index = row(of: line.box)?.index {
                weights[index].append((line.box.minX, text))
            } else if whole(countText, text) != nil {
                counts.append(line)
            }
        }
        guard waters.compactMap({ $0 }).count >= 3 else { return nil }
        counts = counts.filter { $0.box.minX > waterEdge }

        // Bare numbers right of the water are scoops, then feeds. Two columns show as two groups from left
        // to right; the widest gap between them is where one ends and the other begins.
        let sorted = counts.sorted { $0.box.midX < $1.box.midX }
        var scoopLines = sorted, feedLines: [ReadLine] = []
        if let split = zip(sorted.indices, sorted.indices.dropFirst())
            .max(by: { sorted[$0.1].box.midX - sorted[$0.0].box.midX < sorted[$1.1].box.midX - sorted[$1.0].box.midX }),
           sorted[split.1].box.midX - sorted[split.0].box.midX > 0.03 {
            scoopLines = Array(sorted[...split.0])
            feedLines = Array(sorted[split.1...])
        }

        // How much water a scoop takes: from the tin's words, or, if the photo missed them, whichever usual
        // amount makes at least two of the scoops that were read agree with their water.
        var perScoop = waterPerScoop(in: lines)
        func workedOut(_ index: Int, per: Int? = nil) -> Int? {
            guard let per = per ?? perScoop, let amount = waters[index], amount % per == 0 else { return nil }
            return amount / per
        }
        /// How many of these numbers agree with the scoops worked out from the water, at a given slant.
        func agreeing(_ some: [ReadLine], slant: CGFloat, per: Int? = nil) -> Int {
            some.filter { line in row(of: line.box, slant: slant).map { workedOut($0.index, per: per) == Int(line.text.trimmingCharacters(in: .whitespaces)) } ?? false }.count
        }
        // The slant that makes the most scoops agree; the flattest of those that tie.
        let tries = stride(from: -0.1, through: 0.1, by: 0.004).map { CGFloat($0) }.sorted { abs($0) < abs($1) }
        func bestSlant(per: Int) -> (slant: CGFloat, agree: Int) {
            var best: (slant: CGFloat, agree: Int) = (0, agreeing(scoopLines, slant: 0, per: per))
            for slant in tries {
                let agree = agreeing(scoopLines, slant: slant, per: per)
                if agree > best.agree { best = (slant, agree) }
            }
            return best
        }
        var slant: CGFloat = 0
        if !scoopLines.isEmpty {
            if let per = perScoop {
                let best = bestSlant(per: per)
                slant = best.slant
                // One column of numbers that are not the scoops: they are the feeds.
                if feedLines.isEmpty, best.agree * 2 < scoopLines.count {
                    feedLines = scoopLines
                    scoopLines = []
                    slant = 0
                }
            } else if let found = [30, 60, 25, 50].map({ (per: $0, fit: bestSlant(per: $0)) }).max(by: { $0.fit.agree < $1.fit.agree }), found.fit.agree >= 2 {
                perScoop = found.per
                slant = found.fit.slant
            }
        }
        // Only a table that counts feeds in a day is read this way.
        let saysFeeds = texts.contains { $0.range(of: "feeds", options: .caseInsensitive) != nil || $0.range(of: "24 hours", options: .caseInsensitive) != nil }
        guard !feedLines.isEmpty || saysFeeds else { return nil }

        func placed(_ some: [ReadLine]) -> [Int: Int] {
            var best: [Int: (value: Int, off: CGFloat)] = [:]
            for line in some {
                guard let at = row(of: line.box, slant: slant), let value = Int(line.text.trimmingCharacters(in: .whitespaces)) else { continue }
                if let held = best[at.index], held.off <= at.off { continue }
                best[at.index] = (value, at.off)
            }
            return best.mapValues(\.value)
        }
        let readScoops = placed(scoopLines), readFeeds = placed(feedLines)
        let hasWeight = weights.contains { !$0.isEmpty }

        var table = BoxTable(columns: (hasWeight ? [weight] : []) + [water, scoops, feeds], rows: [])
        var unsure = Set<BoxReader.Cell>()
        let first = hasWeight ? 1 : 0
        for index in marks.indices {
            guard let amount = waters[index] else { continue }
            var row = BoxTable.Row(age: marks[index].text, from: marks[index].from, values: [])
            if hasWeight { row.values.append(weights[index].sorted { $0.x < $1.x }.map(\.text).joined(separator: ", ")) }
            row.values.append("\(amount) ml")
            if waterDoubt.contains(index) { unsure.insert(BoxReader.Cell(row: row.id, column: first)) }
            // Scoops: what was read, checked against the water; or worked out from the water when not read.
            let read = readScoops[index], sum = workedOut(index)
            row.values.append((read ?? sum).map(String.init) ?? "")
            if read == nil || (sum != nil && read != sum) { unsure.insert(BoxReader.Cell(row: row.id, column: first + 1)) }
            row.values.append(readFeeds[index].map(String.init) ?? "")
            if readFeeds[index] == nil { unsure.insert(BoxReader.Cell(row: row.id, column: first + 2)) }
            table.rows.append(row)
        }
        return (table, unsure)
    }

    /// Whether a table was read as a tin's feeding table.
    static func reads(_ table: BoxTable?) -> Bool { table?.columns.contains(feeds) ?? false }

    /// A second photo of the same table. It fills what the first left empty and takes nothing away; where the
    /// two disagree the first stays and the cell is marked. Rows pair up in order when both photos found the
    /// same number, which a misread age cannot upset; otherwise by the age they start at.
    static func merged(_ table: BoxTable, unsure: Set<BoxReader.Cell>, with more: BoxTable, unsure moreUnsure: Set<BoxReader.Cell>)
        -> (table: BoxTable, unsure: Set<BoxReader.Cell>) {
        guard table.columns == more.columns else { return (table, unsure) }
        var result = table, doubts = unsure
        for (offset, other) in more.rows.enumerated() {
            let index = table.rows.count == more.rows.count ? offset : result.rows.firstIndex { $0.from == other.from }
            guard let index else {
                result.rows.append(other)
                doubts.formUnion(moreUnsure.filter { $0.row == other.id })
                continue
            }
            let id = result.rows[index].id
            for column in other.values.indices where column < result.rows[index].values.count {
                let mine = result.rows[index].values[column], theirs = other.values[column]
                let cell = BoxReader.Cell(row: id, column: column)
                let theirDoubt = moreUnsure.contains(BoxReader.Cell(row: other.id, column: column))
                if mine.isEmpty, !theirs.isEmpty {
                    result.rows[index].values[column] = theirs
                    if theirDoubt { doubts.insert(cell) } else { doubts.remove(cell) }
                } else if !theirs.isEmpty, mine != theirs {
                    doubts.insert(cell)
                } else if mine == theirs, !mine.isEmpty, !theirDoubt {
                    // Read the same twice, and surely the second time.
                    doubts.remove(cell)
                }
            }
        }
        func days(_ row: BoxTable.Row) -> Int {
            guard let from = row.from else { return .max }
            return from.count * (from.unit == .weeks ? 7 : from.unit == .months ? 30 : 365)
        }
        result.rows = result.rows.enumerated().sorted { (days($0.element), $0.offset) < (days($1.element), $1.offset) }.map(\.element)
        return (result, doubts)
    }
}

/// What a tin suggests for one day at one age: so many feeds of so much.
struct FormulaDay: Equatable {
    /// The row's own words: "6 months".
    let age: String
    let water: Int
    let feeds: Int
    let scoops: Int?

    var total: Int { water * feeds }
    var totalScoops: Int? { scoops.map { $0 * feeds } }
}

extension BoxTable {
    /// The row for a child born on `birth`: the last one that has started. Nil unless the row says both how
    /// much water a feed takes and how many feeds there are in a day.
    func formulaDay(birth: Date, now: Date = .now) -> FormulaDay? {
        let started = rows.compactMap { row -> (Row, Date)? in
            guard let date = row.from?.date(from: birth), date <= now else { return nil }
            return (row, date)
        }
        guard let row = started.max(by: { $0.1 < $1.1 })?.0 else { return nil }
        func number(_ name: String) -> Int? {
            guard let column = columns.firstIndex(of: name), row.values.indices.contains(column) else { return nil }
            let digits = row.values[column].prefix { $0.isNumber }
            return Int(digits)
        }
        // A tin read before this reader has "Water" and "Scoops" and nothing about feeds: no day to give.
        guard let water = number(FormulaReader.water), let feeds = number(FormulaReader.feeds), water > 0, feeds > 0 else { return nil }
        return FormulaDay(age: row.age, water: water, feeds: feeds, scoops: number(FormulaReader.scoops))
    }
}
