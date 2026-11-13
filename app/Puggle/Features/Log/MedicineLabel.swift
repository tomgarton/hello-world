import PhotosUI
import SwiftUI
import UIKit
import Vision

/// What the family set for a medicine, by name: the smallest gap between doses
/// and the most doses in 24 hours. The app only checks against these; it never
/// suggests them. They are read from here, on this phone, so a check never
/// waits on anything; `FamilyStore.syncMedicineRules()` keeps this copy in step
/// with the family's shared one.
enum MedicineRules {
    /// Called when a rule is set on this phone, so it can be shared with the family.
    static var onSet: ((_ name: String, _ gap: Double?, _ limit: Int?) -> Void)?

    /// Takes the family's value for a medicine, without sharing it back.
    static func adopt(gap: Double?, limit: Int?, forKey k: String) {
        var gaps = UserDefaults.standard.dictionary(forKey: gapsKey) as? [String: Double] ?? [:]
        var limits = UserDefaults.standard.dictionary(forKey: limitsKey) as? [String: Int] ?? [:]
        guard gaps[k] != gap || limits[k] != limit else { return }
        gaps[k] = gap
        limits[k] = limit
        UserDefaults.standard.set(gaps, forKey: gapsKey)
        UserDefaults.standard.set(limits, forKey: limitsKey)
    }

    private static let gapsKey = "medicineGaps"
    private static let limitsKey = "medicineLimits"

    static func key(_ name: String) -> String { name.trimmingCharacters(in: .whitespaces).lowercased() }

    static func gap(for name: String) -> Double? {
        let gaps = UserDefaults.standard.dictionary(forKey: gapsKey) as? [String: Double] ?? [:]
        return gaps[key(name)].flatMap { $0 > 0 ? $0 : nil }
    }

    static func limit(for name: String) -> Int? {
        let limits = UserDefaults.standard.dictionary(forKey: limitsKey) as? [String: Int] ?? [:]
        return limits[key(name)].flatMap { $0 > 0 ? $0 : nil }
    }

    static func set(gap: Double?, limit: Int?, for name: String) {
        let k = key(name)
        guard !k.isEmpty else { return }
        var gaps = UserDefaults.standard.dictionary(forKey: gapsKey) as? [String: Double] ?? [:]
        gaps[k] = gap
        UserDefaults.standard.set(gaps, forKey: gapsKey)
        var limits = UserDefaults.standard.dictionary(forKey: limitsKey) as? [String: Int] ?? [:]
        limits[k] = limit
        UserDefaults.standard.set(limits, forKey: limitsKey)
        onSet?(name, gap, limit)
    }

    /// Every medicine name with a gap or a limit set.
    static var names: Set<String> {
        let gaps = UserDefaults.standard.dictionary(forKey: gapsKey) as? [String: Double] ?? [:]
        let limits = UserDefaults.standard.dictionary(forKey: limitsKey) as? [String: Int] ?? [:]
        return Set(gaps.keys).union(limits.keys)
    }
}

extension FamilyStore {
    /// Doses of a medicine, by name, for a child, oldest first.
    func doses(of name: String, for child: Child) -> [Event] {
        let wanted = MedicineRules.key(name)
        return (child.events ?? [])
            .filter { $0.kind == .medicine && MedicineRules.key($0.detail ?? "") == wanted }
            .sorted { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) }
    }

    /// The earliest the next dose fits inside what the parent set: after the
    /// gap, and with fewer than the most doses in the last 24 hours. Nil if
    /// nothing is set or nothing has been given.
    func nextDose(of name: String, for child: Child, now: Date = .now) -> Date? {
        let gap = MedicineRules.gap(for: name), limit = MedicineRules.limit(for: name)
        guard gap != nil || limit != nil else { return nil }
        let given = doses(of: name, for: child).compactMap(\.startedAt).filter { $0 <= now }
        guard let last = given.last else { return nil }
        var next = last.addingTimeInterval((gap ?? 0) * 3600)
        if let limit, given.count >= limit {
            // The dose that has to drop out of the 24 hours before another fits.
            let window = given.suffix(limit)
            if let first = window.first { next = max(next, first.addingTimeInterval(24 * 3600)) }
        }
        return next
    }

    /// "2 of 3 in 24 hours · next from 19:45", for the medicine sheet.
    func doseSummary(of name: String, for child: Child, now: Date = .now) -> String? {
        let given = doses(of: name, for: child).compactMap(\.startedAt).filter { $0 <= now }
        guard let last = given.last else { return nil }
        var parts = ["Last at \(last.formatted(date: .omitted, time: .shortened))"]
        if let limit = MedicineRules.limit(for: name) {
            let recent = given.filter { $0 > now.addingTimeInterval(-24 * 3600) }.count
            parts.append("\(recent) of \(limit) in 24 hours")
        }
        if let next = nextDose(of: name, for: child, now: now), next > now {
            parts.append("next from \(next.formatted(date: .omitted, time: .shortened))")
        }
        return parts.joined(separator: " · ")
    }

    /// For the child's row on Today: the medicine whose next dose is soonest
    /// but not yet, as "Calpol · from 19:45".
    func nextDoseLine(for child: Child, now: Date = .now) -> String? {
        let names = Set((child.events ?? [])
            .filter { $0.kind == .medicine && ($0.startedAt ?? .distantPast) > now.addingTimeInterval(-24 * 3600) }
            .compactMap(\.detail))
        let upcoming = names.compactMap { name -> (String, Date)? in
            guard let next = nextDose(of: name, for: child, now: now), next > now else { return nil }
            return (name, next)
        }
        guard let soonest = upcoming.min(by: { $0.1 < $1.1 }) else { return nil }
        return "\(soonest.0) · from \(soonest.1.formatted(date: .omitted, time: .shortened))"
    }
}

// MARK: Reading the box

/// What was read from a medicine box. Every field is only a suggestion until
/// the parent confirms it against the box.
struct LabelReading: Equatable {
    var name = ""
    var strength: String?
    var limit: Int?
    var gap: Double?
    /// Lines from the box about ages and amounts, shown for the parent to read.
    var dosingLines: [String] = []
    var found: Bool { !name.isEmpty || strength != nil || limit != nil || gap != nil || !dosingLines.isEmpty }

    private static let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8]

    private static func number(_ text: String) -> Double? {
        Double(text) ?? words[text.lowercased()].map(Double.init)
    }

    private static func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (0..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).map { String(text[$0]) } }
    }

    /// Pulls the usual label phrases out of the text: the strength, the most
    /// doses in 24 hours and the smallest gap. Lines about ages are passed on
    /// as they are: the app never picks a dose for an age.
    static func parse(lines: [(text: String, height: CGFloat)]) -> LabelReading {
        var reading = LabelReading()
        let all = lines.map(\.text).joined(separator: " ").replacingOccurrences(of: "  ", with: " ")
        let count = "(\\d+|one|two|three|four|five|six|seven|eight)"
        for pattern in ["(?:not|no) more than \(count) (?:doses|times) in (?:any )?24 hours",
                        "max(?:imum)?(?: of)? \(count) doses (?:in|per) (?:any )?24 hours",
                        "\(count) doses (?:in|per) (?:any )?24 hours"] {
            if let m = firstMatch(pattern, in: all), let n = number(m[1]) { reading.limit = Int(n); break }
        }
        for pattern in ["(?:at least|leave) (\\d+(?:\\.\\d+)?) hours? between",
                        "(\\d+(?:\\.\\d+)?) hours? between (?:each )?doses",
                        "every (\\d+(?:\\.\\d+)?)(?: ?(?:-|to) ?\\d+)? hours"] {
            if let m = firstMatch(pattern, in: all), let n = Double(m[1]) { reading.gap = n; break }
        }
        if let m = firstMatch("(\\d+(?:\\.\\d+)? ?mg) ?(?:/|per|in|in each) ?(\\d+(?:\\.\\d+)? ?ml)", in: all) {
            reading.strength = "\(m[1]) in \(m[2])"
        }
        reading.dosingLines = lines.map(\.text).filter { line in
            let lower = line.lowercased()
            return (lower.contains("month") || lower.contains("year") || lower.contains("yrs"))
                && (lower.contains("ml") || lower.contains("tablet") || lower.contains("spoon") || lower.contains("dose"))
        }
        // The name is usually the biggest words on the front.
        reading.name = lines
            .filter { $0.text.count >= 3 && $0.text.count <= 40 && $0.text.rangeOfCharacter(from: .letters) != nil }
            .max { $0.height < $1.height }?.text
            .trimmingCharacters(in: .whitespaces) ?? ""
        return reading
    }

    /// Reads the text in a photo on the phone itself; nothing leaves it.
    static func read(_ image: UIImage) async -> LabelReading {
        guard let cg = image.cgImage else { return LabelReading() }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { observation -> (String, CGFloat)? in
                    guard let best = observation.topCandidates(1).first else { return nil }
                    return (best.string, observation.boundingBox.height)
                }
                continuation.resume(returning: parse(lines: lines.map { (text: $0.0, height: $0.1) }))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-GB", "en-AU", "en-US"]
            let handler = VNImageRequestHandler(cgImage: cg, orientation: CGImagePropertyOrientation(image.imageOrientation))
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) } catch { continuation.resume(returning: LabelReading()) }
            }
        }
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

/// The system camera, for one photo.
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    /// The front camera, for a photo of yourself.
    var front = false
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        if front, UIImagePickerController.isCameraDeviceAvailable(.front) { picker.cameraDevice = .front }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: Shared with the family

extension FamilyStore {
    private func guides(in family: Family) -> [Guide] {
        (family.guides ?? []).filter { !$0.isDeleted && $0.kindRaw == "medicine" }
    }

    /// Saves a medicine's rules where the whole family can see them. Parents only.
    func shareRule(name: String, gap: Double?, limit: Int?) {
        guard !isSample, isParent, let family = existingFamily() else { return }
        let key = MedicineRules.key(name)
        guard !key.isEmpty else { return }
        let guide = guides(in: family).first { $0.key == key } ?? {
            let new = Guide(context: context)
            place(new, with: family)
            new.id = UUID()
            new.kindRaw = "medicine"
            new.key = key
            new.family = family
            return new
        }()
        let gapValue = gap ?? 0, limitValue = Int16(clamping: limit ?? 0)
        guard guide.isInserted || guide.gapHours != gapValue || guide.doseLimit != limitValue else { return }
        guide.name = name.trimmingCharacters(in: .whitespaces)
        guide.gapHours = gapValue
        guide.doseLimit = limitValue
        guide.updatedAt = .now
        persistence.save()
    }

    /// Brings this phone's copy of the rules in step with the family's.
    /// The family's value wins. Rules set here before sharing existed are sent up once, by a parent.
    func syncMedicineRules() {
        guard !isSample, let family = existingFamily() else { return }
        var newest: [String: Guide] = [:]
        var extras: [Guide] = []
        for guide in guides(in: family) {
            guard let key = guide.key, !key.isEmpty else { continue }
            if let have = newest[key] {
                let keep = (guide.updatedAt ?? .distantPast) > (have.updatedAt ?? .distantPast) ? guide : have
                extras.append(keep == guide ? have : guide)
                newest[key] = keep
            } else {
                newest[key] = guide
            }
        }
        for (key, guide) in newest {
            MedicineRules.adopt(gap: guide.gapHours > 0 ? guide.gapHours : nil,
                                limit: guide.doseLimit > 0 ? Int(guide.doseLimit) : nil, forKey: key)
        }
        guard isParent else { return }
        // Two phones saved the same medicine before they met: keep the newer.
        if !extras.isEmpty {
            extras.forEach(context.delete)
            persistence.save()
        }
        for key in MedicineRules.names where newest[key] == nil {
            shareRule(name: key, gap: MedicineRules.gap(for: key), limit: MedicineRules.limit(for: key))
        }
    }
}
