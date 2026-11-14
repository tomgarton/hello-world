import Compression
import CoreData
import CryptoKit
import Foundation

/// Reads another tracker's export and turns it into entries here.
///
/// Understood today: the CSV export from "Baby Tracker" (one file per activity,
/// named "<Baby>_diaper.csv", "<Baby>_formula.csv" and so on, plus "pump.csv"),
/// given as the zip it exports or as the CSV files themselves. Nothing leaves
/// the phone: the files are read here and then let go.
enum Importer {
    /// One entry waiting to be imported.
    struct Draft: Equatable {
        var baby: String
        var kind: EventKind
        var start: Date
        var end: Date?
        var amountML = 0.0
        var detail: String?
        var note: String?
        var dose: String?
        var value = 0.0
        var leftSeconds = 0.0
        var rightSeconds = 0.0
    }

    /// Everything found in the files, before anything is saved.
    struct Reading {
        var drafts: [Draft] = []
        /// Plain sentences about what was left out, for the person to read.
        var leftOut: [String] = []
        var files = 0

        var babies: [String] { Array(Set(drafts.map(\.baby))).sorted() }
        var range: ClosedRange<Date>? {
            guard let first = drafts.map(\.start).min(), let last = drafts.map(\.start).max() else { return nil }
            return first...last
        }
        func count(_ kind: EventKind, baby: String? = nil) -> Int {
            drafts.filter { $0.kind == kind && (baby == nil || $0.baby == baby) }.count
        }
    }

    // MARK: Reading files

    /// Reads a zip of CSV files, or CSV files, from where the person chose them.
    static func read(_ urls: [URL]) -> Reading {
        var files: [(name: String, data: Data)] = []
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { continue }
            if data.prefix(2) == Data([0x50, 0x4B]) {
                files += Zip.entries(in: data).filter { $0.name.lowercased().hasSuffix(".csv") && !$0.name.contains("__MACOSX") }
            } else {
                files.append((url.lastPathComponent, data))
            }
        }
        return read(files: files)
    }

    static func read(files: [(name: String, data: Data)]) -> Reading {
        var reading = Reading()
        var tables: [(kind: String, rows: [[String: String]])] = []
        for file in files {
            let base = (file.name as NSString).lastPathComponent.lowercased()
            guard base.hasSuffix(".csv") else { continue }
            let stem = String(base.dropLast(4))
            let kind = stem.split(separator: "_").last.map(String.init) ?? stem
            guard let text = String(data: file.data, encoding: .utf8) else {
                reading.leftOut.append("\((file.name as NSString).lastPathComponent) couldn't be read.")
                continue
            }
            reading.files += 1
            tables.append((kind, CSV.rows(text)))
        }
        // Dates are written the way the phone that exported them was set: day first or month first.
        let dayFirst = Dates.isDayFirst(tables.flatMap { $0.rows.compactMap { $0["time"] } })
        for table in tables {
            convert(table.kind, table.rows, dayFirst: dayFirst, into: &reading)
        }
        reading.drafts.sort { $0.start < $1.start }
        return reading
    }

    private static func convert(_ kind: String, _ rows: [[String: String]], dayFirst: Bool, into reading: inout Reading) {
        var badDates = 0, empty = 0
        func number(_ text: String?) -> Double? {
            guard let text = text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
            return Double(text.replacingOccurrences(of: ",", with: "."))
        }
        func text(_ value: String?) -> String? {
            let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        for row in rows {
            guard let start = Dates.parse(row["time"] ?? "", dayFirst: dayFirst) else { badDates += 1; continue }
            let baby = text(row["baby"]) ?? ""
            let note = text(row["note"])
            var draft = Draft(baby: baby, kind: .note, start: start, note: note)
            switch kind {
            case "diaper", "nappy":
                draft.kind = .nappy
                switch (row["status"] ?? "").lowercased() {
                case "wet": draft.detail = "Wet"
                case "dirty": draft.detail = "Dirty"
                case "mixed", "both": draft.detail = "Both"
                case "dry": draft.detail = "Dry"
                default: draft.detail = text(row["status"])
                }
            case "formula":
                draft.kind = .bottle
                draft.detail = "Formula"
                draft.amountML = number(row["amount (ml)"]) ?? ounces(row["amount (oz)"]) ?? 0
            case "expressed":
                draft.kind = .bottle
                draft.detail = "Breast milk"
                draft.amountML = number(row["amount (ml)"]) ?? ounces(row["amount (oz)"]) ?? 0
            case "nursing":
                draft.kind = .breastfeed
                let left = (number(row["left duration (min)"]) ?? 0) * 60
                let right = (number(row["right duration (min)"]) ?? 0) * 60
                let total = max((number(row["total duration (min)"]) ?? 0) * 60, left + right)
                draft.leftSeconds = left
                draft.rightSeconds = right
                draft.end = start.addingTimeInterval(total)
                draft.detail = left > 0 && right > 0 ? "Both" : (right > 0 ? "Right" : (left > 0 ? "Left" : text(row["start side"])))
            case "sleep":
                draft.kind = .sleep
                guard let minutes = number(row["duration(minutes)"] ?? row["duration (minutes)"]), minutes > 0 else { empty += 1; continue }
                draft.end = start.addingTimeInterval(minutes * 60)
            case "growth":
                var extras: [String] = []
                if let length = text(row["length (cm)"]) { extras.append("Length \(length) cm") }
                if let head = text(row["head size (cm)"]) { extras.append("Head \(head) cm") }
                let joined = (extras + [note].compactMap { $0 }).joined(separator: " · ")
                if let kg = number(row["weight (kg)"]), kg > 0 {
                    draft.kind = .weight
                    draft.value = kg * 1000
                } else if let lb = number(row["weight (lb)"]), lb > 0 {
                    draft.kind = .weight
                    draft.value = lb * Units.gramsPerPound
                } else if extras.isEmpty {
                    empty += 1; continue
                }
                // Length and head size have nowhere of their own yet, so they are kept in the note.
                draft.note = joined.isEmpty ? nil : joined
            case "milestone":
                draft.kind = .milestone
                draft.detail = text(row["milestone"])
            case "vaccine":
                draft.kind = .vaccination
                draft.detail = text(row["vaccine"])
                draft.note = [text(row["description"]), note].compactMap { $0 }.joined(separator: " · ").nilIfBlank
            case "supplement":
                draft.kind = .solids
                draft.detail = text(row["other food"])
                let amount = [text(row["amount"]), text(row["unit"])].compactMap { $0 }.joined(separator: " ")
                draft.note = [amount.nilIfBlank, note].compactMap { $0 }.joined(separator: " · ").nilIfBlank
            case "pump":
                guard let total = number(row["total amount (ml)"]), total > 0 else { empty += 1; continue }
                draft.kind = .pump
                draft.amountML = total
                draft.value = number(row["left amount (ml)"]) ?? 0
                draft.detail = Pump.fridge
            case "medicine", "medication":
                draft.kind = .medicine
                draft.detail = text(row["medicine"]) ?? text(row["medication"])
                draft.dose = [text(row["amount"]), text(row["unit"])].compactMap { $0 }.joined(separator: " ").nilIfBlank
            case "temperature":
                guard let degrees = number(row["temperature"] ?? row["temperature (c)"]) else { empty += 1; continue }
                draft.kind = .temperature
                draft.value = degrees
            default:
                reading.leftOut.append("\(rows.count) rows in the \"\(kind)\" file. That kind isn't understood yet.")
                return
            }
            reading.drafts.append(draft)
        }
        if badDates > 0 { reading.leftOut.append("\(badDates) \(kind) rows with a date that couldn't be read.") }
        if empty > 0 {
            reading.leftOut.append(kind == "pump" ? "\(empty) pumping sessions with no amount." : "\(empty) \(kind) rows with nothing in them.")
        }
    }

    private static func ounces(_ text: String?) -> Double? {
        guard let text, let value = Double(text.trimmingCharacters(in: .whitespaces)) else { return nil }
        return value * Units.mlPerOz
    }

    // MARK: CSV

    enum CSV {
        /// Rows keyed by lower-case header. Handles quotes, commas inside quotes, and a missing last column.
        static func rows(_ text: String) -> [[String: String]] {
            var records: [[String]] = [], field = "", record: [String] = [], quoted = false
            var characters = Array(text.unicodeScalars)
            if characters.first == "\u{FEFF}" { characters.removeFirst() }
            var index = 0
            while index < characters.count {
                let c = characters[index]
                if quoted {
                    if c == "\"" {
                        if index + 1 < characters.count, characters[index + 1] == "\"" { field.unicodeScalars.append(c); index += 1 } else { quoted = false }
                    } else { field.unicodeScalars.append(c) }
                } else if c == "\"" {
                    quoted = true
                } else if c == "," {
                    record.append(field); field = ""
                } else if c == "\n" || c == "\r" {
                    if c == "\r", index + 1 < characters.count, characters[index + 1] == "\n" { index += 1 }
                    record.append(field); field = ""
                    if record.contains(where: { !$0.isEmpty }) { records.append(record) }
                    record = []
                } else {
                    field.unicodeScalars.append(c)
                }
                index += 1
            }
            record.append(field)
            if record.contains(where: { !$0.isEmpty }) { records.append(record) }
            guard let header = records.first?.map({ $0.trimmingCharacters(in: .whitespaces).lowercased() }) else { return [] }
            return records.dropFirst().map { values in
                var row: [String: String] = [:]
                for (i, name) in header.enumerated() where i < values.count { row[name] = values[i] }
                return row
            }
        }
    }

    // MARK: Dates

    enum Dates {
        private static func parts(_ text: String) -> (a: Int, b: Int, year: Int, hour: Int, minute: Int)? {
            let pieces = text.split(whereSeparator: { ", ".contains($0) }).map(String.init)
            guard pieces.count >= 2 else { return nil }
            let date = pieces[0].split(whereSeparator: { "/-.".contains($0) }).compactMap { Int($0) }
            let clock = pieces[1].split(separator: ":").compactMap { Int($0.prefix(2)) }
            guard date.count == 3, clock.count >= 2 else { return nil }
            var hour = clock[0]
            let suffix = pieces.count > 2 ? pieces[2].lowercased() : pieces[1].lowercased()
            if suffix.contains("pm"), hour < 12 { hour += 12 }
            if suffix.contains("am"), hour == 12 { hour = 0 }
            // A four-digit number first means year, month, day.
            if date[0] > 31 { return (date[2], date[1], date[0], hour, clock[1]) }
            return (date[0], date[1], date[2] < 100 ? 2000 + date[2] : date[2], hour, clock[1])
        }

        /// True if the first number is the day. Decided from the file itself: a first number over 12 settles it.
        static func isDayFirst(_ samples: [String]) -> Bool {
            var firstOver = false, secondOver = false
            for sample in samples {
                guard let p = parts(sample) else { continue }
                if p.a > 12 { firstOver = true }
                if p.b > 12 { secondOver = true }
            }
            if firstOver { return true }
            if secondOver { return false }
            // Nothing in the file settles it: go by how this phone writes dates.
            let order = DateFormatter.dateFormat(fromTemplate: "dM", options: 0, locale: .current) ?? "dM"
            return (order.firstIndex(of: "d") ?? order.startIndex) < (order.firstIndex(of: "M") ?? order.endIndex)
        }

        static func parse(_ text: String, dayFirst: Bool) -> Date? {
            guard let p = parts(text) else { return nil }
            var components = DateComponents()
            components.year = p.year
            components.day = dayFirst ? p.a : p.b
            components.month = dayFirst ? p.b : p.a
            components.hour = p.hour
            components.minute = p.minute
            guard (1...12).contains(components.month ?? 0), (1...31).contains(components.day ?? 0) else { return nil }
            return Calendar.current.date(from: components)
        }
    }

    // MARK: Zip

    /// Just enough of the zip format to open an export: stored and deflated files.
    enum Zip {
        static func entries(in data: Data) -> [(name: String, data: Data)] {
            let bytes = [UInt8](data)
            func u16(_ at: Int) -> Int { at + 1 < bytes.count ? Int(bytes[at]) | Int(bytes[at + 1]) << 8 : 0 }
            func u32(_ at: Int) -> Int { at + 3 < bytes.count ? u16(at) | u16(at + 2) << 16 : 0 }
            // The directory is at the end; find its marker.
            var end = bytes.count - 22
            while end >= 0, !(bytes[end] == 0x50 && bytes[end + 1] == 0x4B && bytes[end + 2] == 0x05 && bytes[end + 3] == 0x06) { end -= 1 }
            guard end >= 0 else { return [] }
            let count = u16(end + 10)
            var at = u32(end + 16)
            var found: [(String, Data)] = []
            for _ in 0..<count {
                guard at + 46 <= bytes.count, u32(at) == 0x02014B50 else { break }
                let method = u16(at + 10), packed = u32(at + 20), size = u32(at + 24)
                let nameLength = u16(at + 28), extra = u16(at + 30), comment = u16(at + 32), local = u32(at + 42)
                let name = String(decoding: bytes[(at + 46)..<min(at + 46 + nameLength, bytes.count)], as: UTF8.self)
                at += 46 + nameLength + extra + comment
                guard local + 30 <= bytes.count, u32(local) == 0x04034B50 else { continue }
                let start = local + 30 + u16(local + 26) + u16(local + 28)
                guard start + packed <= bytes.count, !name.hasSuffix("/") else { continue }
                let body = Array(bytes[start..<(start + packed)])
                if method == 0 {
                    found.append((name, Data(body)))
                } else if method == 8, size > 0 {
                    var out = [UInt8](repeating: 0, count: size)
                    let written = compression_decode_buffer(&out, size, body, body.count, nil, COMPRESSION_ZLIB)
                    if written == size { found.append((name, Data(out))) }
                }
            }
            return found
        }
    }
}

private extension String {
    var nilIfBlank: String? { trimmingCharacters(in: .whitespaces).isEmpty ? nil : self }
}

extension FamilyStore {
    /// What an import did.
    struct Imported: Equatable {
        var added = 0
        /// Already imported from the same file before.
        var repeats = 0
        /// An entry of the same kind for the same child within a minute was already here.
        var alreadyHere = 0
        var batch = ""
    }

    private static let importPrefix = "import-"

    /// The mark on the entries of the most recent import, so it can be taken back.
    var lastImportBatch: String? {
        get { UserDefaults.standard.string(forKey: "lastImportBatch") }
        set { UserDefaults.standard.set(newValue, forKey: "lastImportBatch") }
    }

    /// Saves the drafts as entries. `children` says which child each baby in the file is.
    /// A backup is taken first, and every entry carries the import's mark so the whole import can be undone.
    @discardableResult
    func importDrafts(_ drafts: [Importer.Draft], children: [String: Child]) -> Imported {
        guard isParent else { return Imported() }
        backUpQuietly(.beforeImport)
        let family = currentFamily()
        var result = Imported(batch: Self.importPrefix + UUID().uuidString.prefix(8))
        var have = Set((family.events ?? []).filter { !$0.isDeleted }.compactMap(\.id))
        // Minutes already taken, by child and kind, to spot the same thing logged in both apps.
        // Only what was here before the import counts: two bottles in the same minute of one file are both kept.
        var taken: [String: Set<Int>] = [:]
        for event in family.events ?? [] where !event.isDeleted {
            guard let start = event.startedAt else { continue }
            for child in event.children ?? [] {
                taken["\(child.objectID)|\(event.kindRaw ?? "")", default: []].insert(Int(start.timeIntervalSince1970 / 60))
            }
            if (event.children ?? []).isEmpty { taken["|\(event.kindRaw ?? "")", default: []].insert(Int(start.timeIntervalSince1970 / 60)) }
        }
        for draft in drafts {
            let child = children[draft.baby]
            // Pumping belongs to the parent, so it needs no child. Everything else does.
            guard child != nil || draft.kind == .pump else { continue }
            // The same row always makes the same id, so importing a file twice adds nothing twice.
            let seed = [child?.id?.uuidString ?? "", draft.kind.rawValue, String(Int(draft.start.timeIntervalSince1970)),
                        String(draft.amountML), draft.detail ?? "", String(draft.value)].joined(separator: "|")
            let id = Self.uuid(from: seed)
            if have.contains(id) { result.repeats += 1; continue }
            let slot = "\(child.map { "\($0.objectID)" } ?? "")|\(draft.kind.rawValue)"
            let minute = Int(draft.start.timeIntervalSince1970 / 60)
            if let minutes = taken[slot], minutes.contains(minute) || minutes.contains(minute - 1) || minutes.contains(minute + 1) {
                result.alreadyHere += 1; continue
            }
            let event = Event(context: context)
            place(event, with: family)
            event.id = id
            event.kind = draft.kind
            event.startedAt = draft.start
            event.endedAt = draft.end
            event.amountML = draft.amountML
            event.detail = draft.detail
            event.note = draft.note
            event.dose = draft.dose
            event.value = draft.value
            event.leftSeconds = draft.leftSeconds
            event.rightSeconds = draft.rightSeconds
            event.createdAt = .now
            event.loggedByID = result.batch
            event.family = family
            if let child { event.children = [child] }
            have.insert(id)
            result.added += 1
        }
        persistence.save()
        if result.added > 0 { lastImportBatch = result.batch }
        return result
    }

    /// How many entries the last import still has here.
    func importedCount(batch: String) -> Int {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(format: "loggedByID == %@", batch)
        return (try? context.count(for: request)) ?? 0
    }

    /// Takes a whole import back out. Entries logged here are not touched.
    @discardableResult
    func undoImport(batch: String) -> Int {
        guard isParent, batch.hasPrefix(Self.importPrefix) else { return 0 }
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(format: "loggedByID == %@", batch)
        let events = (try? context.fetch(request)) ?? []
        lastSaved = nil
        events.forEach(context.delete)
        persistence.save()
        if lastImportBatch == batch { lastImportBatch = nil }
        return events.count
    }

    private static func uuid(from seed: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data(seed.utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
