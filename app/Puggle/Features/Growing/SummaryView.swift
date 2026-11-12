import PDFKit
import SwiftUI
import UIKit

/// A one-page summary of the last seven days for the GP, the child health
/// nurse or day care. Only what the family logged; no judgements.
struct SummaryView: View {
    @ObservedObject var child: Child
    @State private var url: URL?

    var body: some View {
        VStack(spacing: 0) {
            if let url {
                PDFPreview(url: url)
                ShareLink(item: url) {
                    Label("Share or print", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PillButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                Spacer()
                Text("The summary could not be made.")
                    .foregroundStyle(Palette.muted)
                Spacer()
            }
        }
        .background(Palette.sand)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { url = SummaryPDF(child: child).write() }
    }
}

private struct PDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = .clear
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}

/// Draws the page. A4, black on white, so it prints cleanly.
struct SummaryPDF {
    let child: Child
    var days = 7

    private let page = CGRect(x: 0, y: 0, width: 595, height: 842)
    private let margin: CGFloat = 48

    private struct DayRow {
        let day: Date
        var bottles = 0, bottleML = 0.0, breastfeeds = 0, sleep = 0.0, nappies = 0, dirty = 0, potty = 0, solids = 0
    }

    func write() -> URL? {
        let name = child.displayName.replacingOccurrences(of: "/", with: "-")
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name)-summary-\(stamp).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                draw()
            }
            return url
        } catch {
            return nil
        }
    }

    // MARK: Data

    private var events: [Event] { Array(child.events ?? []) }

    private func rows() -> [DayRow] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var result: [DayRow] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            var row = DayRow(day: start)
            for event in events {
                guard let at = event.startedAt else { continue }
                if event.kind == .sleep {
                    row.sleep += event.asleepSeconds(from: max(at, start), to: min(event.endedAt ?? .now, end))
                    continue
                }
                guard at >= start, at < end else { continue }
                switch event.kind {
                case .bottle:
                    row.bottles += 1
                    row.bottleML += event.amountML
                case .breastfeed: row.breastfeeds += 1
                case .nappy:
                    row.nappies += 1
                    if event.detail == "Dirty" || event.detail == "Both" { row.dirty += 1 }
                case .potty: row.potty += 1
                case .solids: row.solids += 1
                default: break
                }
            }
            result.append(row)
        }
        return result
    }

    // MARK: Drawing

    private let ink = UIColor.black
    private let grey = UIColor(white: 0.35, alpha: 1)

    private func text(_ string: String, at point: CGPoint, font: UIFont, colour: UIColor? = nil, width: CGFloat? = nil) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: colour ?? ink]
        let box = CGSize(width: width ?? page.width - margin * 2, height: .greatestFiniteMagnitude)
        let needed = (string as NSString).boundingRect(with: box, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        (string as NSString).draw(with: CGRect(origin: point, size: CGSize(width: box.width, height: ceil(needed.height) + 2)), options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        return ceil(needed.height)
    }

    private func rule(at y: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: page.width - margin, y: y))
        UIColor(white: 0.75, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private func draw() {
        let title = UIFont.systemFont(ofSize: 24, weight: .bold)
        let heading = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let body = UIFont.systemFont(ofSize: 11)
        let small = UIFont.systemFont(ofSize: 9.5)
        var y = margin

        y += text(child.displayName, at: CGPoint(x: margin, y: y), font: title) + 4
        var about: [String] = []
        if let birth = child.birthDate {
            about.append("Born \(birth.formatted(.dateTime.day().month(.wide).year())) (\(child.ageTextFull))")
        }
        let table = rows()
        if let first = table.first?.day, let last = table.last?.day {
            let range = "\(first.formatted(.dateTime.day().month(.wide))) to \(last.formatted(.dateTime.day().month(.wide).year()))"
            about.append("Summary for \(range)")
        }
        y += text(about.joined(separator: ". ") + ".", at: CGPoint(x: margin, y: y), font: body, colour: grey) + 18

        // The week, one row a day.
        y += text("The last \(days) days", at: CGPoint(x: margin, y: y), font: heading) + 8
        let columns: [(String, CGFloat)] = [("Day", 0), ("Bottles", 95), ("Breastfeeds", 205), ("Sleep", 285), ("Nappies", 345), ("Potty", 425), ("Solids", 465)]
        for (label, x) in columns {
            _ = text(label, at: CGPoint(x: margin + x, y: y), font: small, colour: grey)
        }
        y += 16
        rule(at: y - 3)
        for row in table {
            let cells: [String] = [
                row.day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)),
                row.bottles == 0 ? "–" : (row.bottleML > 0 ? "\(row.bottles), \(Int(row.bottleML)) ml" : "\(row.bottles)"),
                row.breastfeeds == 0 ? "–" : "\(row.breastfeeds)",
                row.sleep < 60 ? "–" : Elapsed.short(from: Date.now.addingTimeInterval(-row.sleep), to: .now),
                row.nappies == 0 ? "–" : (row.dirty > 0 ? "\(row.nappies) (\(row.dirty) dirty)" : "\(row.nappies)"),
                row.potty == 0 ? "–" : "\(row.potty)",
                row.solids == 0 ? "–" : "\(row.solids)",
            ]
            for (index, cell) in cells.enumerated() {
                _ = text(cell, at: CGPoint(x: margin + columns[index].1, y: y), font: body)
            }
            y += 18
        }
        rule(at: y)
        y += 16

        // Weight
        let weights = events
            .filter { $0.kind == .weight && $0.value > 0 }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
            .prefix(4)
        if !weights.isEmpty {
            y += text("Weight", at: CGPoint(x: margin, y: y), font: heading) + 6
            for weight in weights {
                let day = (weight.startedAt ?? .now).formatted(.dateTime.day().month(.wide).year())
                y += text("\(day): \(Int(weight.value).formatted()) g", at: CGPoint(x: margin, y: y), font: body) + 4
            }
            y += 12
        }

        // Health, over a longer window because it is rarer.
        let since = Date.now.addingTimeInterval(-14 * 24 * 3600)
        let health = events
            .filter { $0.kind.isHealth && ($0.startedAt ?? .distantPast) >= since }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
        if !health.isEmpty {
            y += text("Medicine, temperature and vaccinations, last 14 days", at: CGPoint(x: margin, y: y), font: heading) + 6
            let room = page.height - margin - 40
            for (index, entry) in health.enumerated() {
                if y > room - 16 {
                    y += text("And \(health.count - index) more.", at: CGPoint(x: margin, y: y), font: body, colour: grey) + 4
                    break
                }
                let when = (entry.startedAt ?? .now).formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
                var line = "\(when): \(entry.summary)"
                if let note = entry.note, !note.isEmpty { line += " (\(note))" }
                y += text(line, at: CGPoint(x: margin, y: y), font: body) + 4
            }
        }

        let made = Date.now.formatted(.dateTime.day().month(.wide).year())
        _ = text("Made on \(made) from what the family logged. Days with nothing logged show a dash, which may mean it was not recorded.",
                 at: CGPoint(x: margin, y: page.height - margin - 28), font: small, colour: grey)
    }
}
