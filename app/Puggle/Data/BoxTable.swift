import CoreData
import Foundation
import UIKit
import Vision

/// A medicine box or a formula tin.
enum GuideKind: String {
    case medicine, formula

    var thing: String { self == .medicine ? "box" : "tin" }
    var readTitle: String { self == .medicine ? "Read a box" : "Read a tin" }
    var defaultColumns: [String] { self == .medicine ? ["Each dose"] : ["Water", "Scoops"] }
}

/// The age a row of a table starts at, in the box's own unit.
struct AgeMark: Codable, Equatable, Hashable {
    enum Unit: String, Codable, CaseIterable, Identifiable {
        case weeks, months, years
        var id: String { rawValue }
    }

    var count: Int
    var unit: Unit

    /// The day a child born on `birth` reaches this age.
    func date(from birth: Date) -> Date? {
        let calendar = Calendar.current
        switch unit {
        case .weeks: return calendar.date(byAdding: .day, value: count * 7, to: birth)
        case .months: return calendar.date(byAdding: .month, value: count, to: birth)
        case .years: return calendar.date(byAdding: .year, value: count, to: birth)
        }
    }

    /// "6 months", "1 year".
    var words: String { count == 1 ? "1 \(unit.rawValue.dropLast())" : "\(count) \(unit.rawValue)" }
}

/// A table copied from a box or tin: a row for each age, as the box prints it.
/// The app copies it out and does no sums with it.
struct BoxTable: Codable, Equatable {
    var columns: [String]
    var rows: [Row]

    struct Row: Codable, Equatable, Identifiable {
        var id = UUID()
        /// As on the box: "3 to 5 months".
        var age: String
        /// Where the row starts, confirmed by a person. Nil for a row by weight or anything else.
        var from: AgeMark?
        var values: [String]
    }

    static func decode(_ json: String?) -> BoxTable? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BoxTable.self, from: data)
    }

    var json: String? { (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } }

    /// A row that starts within the next two days, or today, for a child born on `birth`:
    /// the day it starts, the row before and the new row.
    func change(birth: Date, now: Date = .now) -> (on: Date, before: Row?, after: Row, from: AgeMark)? {
        upcoming(birth: birth).first { item in
            let calendar = Calendar.current
            let day = calendar.startOfDay(for: item.on)
            guard let shown = calendar.date(byAdding: .day, value: -2, to: day),
                  let gone = calendar.date(byAdding: .day, value: 1, to: day) else { return false }
            return now >= shown && now < gone
        }
    }

    /// Every row that starts after birth, in order, with the row before it.
    func upcoming(birth: Date) -> [(on: Date, before: Row?, after: Row, from: AgeMark)] {
        let placed = rows.compactMap { row -> (Row, AgeMark, Date)? in
            guard let from = row.from, let date = from.date(from: birth) else { return nil }
            return (row, from, date)
        }.sorted { $0.2 < $1.2 }
        return placed.enumerated().compactMap { index, item in
            guard item.2 > birth else { return nil }
            return (item.2, index > 0 ? placed[index - 1].0 : nil, item.0, item.1)
        }
    }
}

// MARK: Reading a photo

/// Text read from a photo, with where it sits. Boxes are 0 to 1, from the bottom left, as Vision gives them.
struct ReadLine: Equatable {
    var text: String
    var box: CGRect
    var confidence: Float
}

enum BoxReader {
    /// A cell of a read table: the row, and the column (-1 for the age).
    struct Cell: Hashable {
        var row: UUID
        var column: Int
    }

    /// Reads the text in a photo on the phone itself; nothing leaves it.
    static func lines(in image: UIImage) async -> [ReadLine] {
        guard let cg = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations.compactMap { observation in
                    guard let best = observation.topCandidates(1).first else { return nil }
                    return ReadLine(text: best.string, box: observation.boundingBox, confidence: best.confidence)
                })
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-GB", "en-AU", "en-US"]
            let handler = VNImageRequestHandler(cgImage: cg, orientation: CGImagePropertyOrientation(image.imageOrientation))
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) } catch { continuation.resume(returning: []) }
            }
        }
    }

    // MARK: Ages

    private static let unit = "(weeks?|wks?|months?|mths?|mnths?|mos?|years?|yrs?)"
    private static let number = "(\\d+(?:[.,]\\d+)?)"

    private static func unit(_ text: String?) -> AgeMark.Unit? {
        switch text?.lowercased().first {
        case "w": .weeks
        case "m": .months
        case "y": .years
        default: nil
        }
    }

    private static func mark(_ count: String, _ unitText: String?) -> AgeMark? {
        guard let value = Double(count.replacingOccurrences(of: ",", with: ".")), let unit = unit(unitText) else { return nil }
        if value == value.rounded() { return AgeMark(count: Int(value), unit: unit) }
        switch unit {
        case .years: return AgeMark(count: Int((value * 12).rounded()), unit: .months)
        case .months: return AgeMark(count: Int((value * 4.345).rounded()), unit: .weeks)
        case .weeks: return AgeMark(count: Int(value.rounded()), unit: .weeks)
        }
    }

    /// Finds an age or age range in text: where it is, and the age the range starts at.
    static func age(in text: String) -> (range: Range<String.Index>, from: AgeMark)? {
        let dash = "(?:-|–|—|to)"
        let patterns: [(String, ([String]) -> AgeMark?)] = [
            ("(?:up to|under|birth to|newborn to|from birth to|0 ?\(dash))\\s*\(number)\\s*\(unit)\\b",
             { m in unit(m[2]).map { AgeMark(count: 0, unit: $0) } }),
            ("\\b\(number)\\s*\(unit)?\\s*\(dash)\\s*\(number)\\s*\(unit)\\b",
             { m in mark(m[1], m[2].isEmpty ? m[4] : m[2]) }),
            ("\\b\(number)\\s*\(unit)\\s*(?:\\+|and over|and older|or over|or older|plus|onwards)",
             { m in mark(m[1], m[2]) }),
            ("(?:over|from|after)\\s*\(number)\\s*\(unit)\\b", { m in mark(m[1], m[2]) }),
            ("\\b\(number)\\s*\(unit)\\b", { m in mark(m[1], m[2]) }),
        ]
        for (pattern, make) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let whole = Range(match.range, in: text) else { continue }
            let groups = (0..<match.numberOfRanges).map { index in
                Range(match.range(at: index), in: text).map { String(text[$0]) } ?? ""
            }
            if let from = make(groups) { return (whole, from) }
        }
        return nil
    }

    // MARK: Tables

    private static let measure = try! NSRegularExpression(
        pattern: "\\d+(?:[.,]\\d+)?\\s*(?:ml|mls|scoops?|tsp|mg|fl\\.? ?oz|oz|tablets?)?", options: [.caseInsensitive])

    /// A cell holding only numbers and units ("60 ml 2") is split into one value each.
    private static func split(_ cell: String) -> [String] {
        let range = NSRange(cell.startIndex..., in: cell)
        let rest = measure.stringByReplacingMatches(in: cell, range: range, withTemplate: "")
        guard rest.rangeOfCharacter(from: .letters) == nil else { return [cell] }
        let parts = measure.matches(in: cell, range: range).compactMap { Range($0.range, in: cell).map { String(cell[$0]).trimmingCharacters(in: .whitespaces) } }
        return parts.isEmpty ? [cell] : parts
    }

    private static let shaky = try! NSRegularExpression(pattern: "\\d[.,]\\d|\\d[OoIlSB]|[OoIlSB]\\d")

    /// Whether a value is worth a second look: read with doubt, or with a decimal point or a letter that looks like a digit.
    static func isShaky(_ text: String, confidence: Float) -> Bool {
        confidence < 0.8 || shaky.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.whitespaces.union(.punctuationCharacters).subtracting(CharacterSet(charactersIn: "+.()")))
            .replacingOccurrences(of: "^\\)|\\($", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// Puts the read text back into rows by where it sits, keeps the rows that start with an age,
    /// and returns the table with the cells worth a second look.
    static func table(from lines: [ReadLine], kind: GuideKind) -> (table: BoxTable, unsure: Set<Cell>) {
        // Rows: lines whose middles are level with each other.
        var grouped: [(mid: CGFloat, height: CGFloat, lines: [ReadLine])] = []
        for line in lines.sorted(by: { $0.box.midY > $1.box.midY }) {
            if let last = grouped.indices.last,
               abs(grouped[last].mid - line.box.midY) < 0.5 * max(grouped[last].height, line.box.height) {
                grouped[last].lines.append(line)
                let all = grouped[last].lines
                grouped[last].mid = all.map(\.box.midY).reduce(0, +) / CGFloat(all.count)
                grouped[last].height = all.map(\.box.height).max() ?? line.box.height
            } else {
                grouped.append((line.box.midY, line.box.height, [line]))
            }
        }
        let rows = grouped.map { $0.lines.sorted { $0.box.minX < $1.box.minX } }

        var table = BoxTable(columns: [], rows: [])
        var unsure = Set<Cell>()
        var firstAgeRow: Int?
        for (index, cells) in rows.enumerated() {
            // The age is in one cell, or across the first few.
            var ageText: String?, from: AgeMark?, values: [(String, Float)] = []
            for count in 1...cells.count {
                let joined = cells.prefix(count).map(\.text).joined(separator: " ")
                guard let found = age(in: joined) else { continue }
                ageText = clean(String(joined[found.range]))
                from = found.from
                let rest = clean(joined.replacingCharacters(in: found.range, with: " "))
                if !rest.isEmpty { values.append((rest, cells.prefix(count).map(\.confidence).min() ?? 1)) }
                values += cells.dropFirst(count).map { ($0.text, $0.confidence) }
                break
            }
            guard let ageText else { continue }
            if firstAgeRow == nil { firstAgeRow = index }
            var row = BoxTable.Row(age: ageText, from: from, values: [])
            var shakyColumns: [Int] = []
            for (text, confidence) in values {
                for part in split(text) {
                    let value = clean(part)
                    guard !value.isEmpty else { continue }
                    if isShaky(value, confidence: confidence) { shakyColumns.append(row.values.count) }
                    row.values.append(value)
                }
            }
            shakyColumns.forEach { unsure.insert(Cell(row: row.id, column: $0)) }
            table.rows.append(row)
        }

        let width = max(table.rows.map(\.values.count).max() ?? 0, 1)
        for index in table.rows.indices {
            table.rows[index].values += Array(repeating: "", count: max(0, width - table.rows[index].values.count))
        }
        // Headings: the row just above the first age, if it has the right number of cells.
        if let first = firstAgeRow, first > 0 {
            let heads = rows[first - 1].map { clean($0.text) }.filter { !$0.isEmpty }
            if heads.count == width + 1 { table.columns = Array(heads.dropFirst()) }
            else if heads.count == width, width >= 2 { table.columns = heads }
        }
        if table.columns.count != width {
            let defaults = kind.defaultColumns
            table.columns = (0..<width).map { $0 < defaults.count ? defaults[$0] : "Column \($0 + 1)" }
        }
        return (table, unsure)
    }

    /// A photo made small enough to share with the family: about 1600 points on its long side.
    static func keepable(_ image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 1600 / max(longest, 1))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.6) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: Kept with the family

extension Guide {
    var kind: GuideKind { GuideKind(rawValue: kindRaw ?? "") ?? .medicine }
    var table: BoxTable? { BoxTable.decode(rows) }
    var hasBox: Bool { !(table?.rows.isEmpty ?? true) || photo != nil }
}

extension FamilyStore {
    /// The family's saved boxes or tins of one kind, newest first.
    func guides(_ kind: GuideKind) -> [Guide] {
        guard let family = existingFamily() else { return [] }
        return (family.guides ?? []).filter { !$0.isDeleted && $0.kindRaw == kind.rawValue }
            .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
    }

    /// The tin most recently read, if one has been.
    func formulaGuide() -> Guide? { guides(.formula).first { $0.hasBox } }

    /// The saved box for a medicine, by name, if it has a table or a photo.
    func medicineBox(named name: String) -> Guide? {
        let key = MedicineRules.key(name)
        guard !key.isEmpty else { return nil }
        return guides(.medicine).first { $0.key == key && $0.hasBox }
    }

    /// Saves what was read and checked, for the whole family. Parents only.
    /// `replacing` is the box or tin this one takes the place of.
    @discardableResult
    func saveGuide(replacing existing: Guide?, kind: GuideKind, name: String, strength: String?,
                   table: BoxTable?, photo: Data?, gap: Double?, limit: Int?, at now: Date = .now) -> Guide? {
        let name = name.trimmingCharacters(in: .whitespaces)
        let key = MedicineRules.key(name)
        guard isParent, !key.isEmpty else { return nil }
        let family = currentFamily()
        let guide = existing ?? guides(kind).first { $0.key == key } ?? {
            let new = Guide(context: context)
            place(new, with: family)
            new.id = UUID()
            new.family = family
            return new
        }()
        guide.kindRaw = kind.rawValue
        guide.name = name
        guide.key = key
        guide.strength = strength?.isEmpty == true ? nil : strength
        guide.rows = (table?.rows.isEmpty ?? true) ? nil : table?.json
        guide.photo = photo
        guide.readAt = now
        guide.updatedAt = now
        if kind == .medicine {
            guide.gapHours = gap ?? 0
            guide.doseLimit = Int16(clamping: limit ?? 0)
            if !isSample { MedicineRules.adopt(gap: gap, limit: limit, forKey: key) }
        }
        persistence.save()
        return guide
    }

    func deleteGuide(_ guide: Guide) {
        guard isParent else { return }
        context.delete(guide)
        persistence.save()
    }
}

extension Child {
    /// "Ollie is 5 months", "Ollie is 3 weeks", "Bea is 2½ years".
    func ageLine(now: Date = .now) -> String? {
        guard let birth = birthDate else { return nil }
        let months = Patterns.months(from: birth, to: now)
        if months == 0 {
            let weeks = max(Calendar.current.dateComponents([.day], from: birth, to: now).day ?? 0, 0) / 7
            return "\(displayName) is \(weeks == 1 ? "1 week" : "\(weeks) weeks")"
        }
        return "\(displayName) is \(Patterns.ageWords(months))"
    }
}
