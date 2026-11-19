import SwiftUI

// Special days in the scenes (Tom, 18 November 2026): secular, and by place. Celebrations without the religion
// (fireworks, eggs, pumpkins, lights and presents), shown only where the day is marked, in that place's season,
// with a switch in Settings to turn them off. Never more than one at a time.

enum SpecialDay: String, CaseIterable, Identifiable {
    case newYearsEve, bonfireNight, halloween, easter, christmas

    var id: String { rawValue }

    /// The switch in Settings. On unless turned off.
    static let onKey = "specialDaysOn"

    var title: String {
        switch self {
        case .newYearsEve: "New Year's Eve"
        case .bonfireNight: "Bonfire Night"
        case .halloween: "Halloween"
        case .easter: "Easter"
        case .christmas: "Christmas"
        }
    }

    /// Where it is marked. Nil means everywhere.
    var regions: Set<String>? {
        switch self {
        case .newYearsEve: nil
        // Guy Fawkes Night: Britain, the islands, and New Zealand, which keeps it with fireworks.
        case .bonfireNight: ["GB", "IM", "JE", "GG", "NZ"]
        case .halloween: ["GB", "IE", "US", "CA", "AU", "NZ"]
        case .easter: Self.easterRegions
        case .christmas: Self.christmasRegions
        }
    }

    /// Where 25 December is marked as a public holiday. A starting list, not a judgement.
    static let christmasRegions: Set<String> = [
        "GB", "IE", "IM", "JE", "GG", "FR", "DE", "ES", "PT", "IT", "NL", "BE", "LU", "CH", "AT", "DK", "SE", "NO", "FI",
        "IS", "PL", "CZ", "SK", "HU", "SI", "HR", "RO", "BG", "GR", "CY", "MT", "EE", "LV", "LT", "UA",
        "US", "CA", "MX", "BR", "AR", "CL", "CO", "PE", "UY", "PY", "BO", "EC", "VE", "CR", "PA", "GT", "HN", "SV",
        "NI", "DO", "PR", "JM", "TT", "AU", "NZ", "FJ", "PG", "WS", "TO", "ZA", "KE", "NG", "GH", "UG", "TZ", "ZM",
        "ZW", "NA", "BW", "PH", "KR", "SG", "HK",
    ]

    /// Where the Western Easter weekend is marked. Places that keep the Orthodox Easter, on another date, are left
    /// out rather than shown on the wrong weekend.
    static let easterRegions: Set<String> = christmasRegions.subtracting(["GR", "CY", "RO", "BG", "UA", "KR", "SG", "HK"])

    /// Which special day it is, if any, for a moment in a place.
    static func on(_ date: Date, region: String?, calendar: Calendar = .current) -> SpecialDay? {
        let parts = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        let found: SpecialDay? = {
            switch (month, day) {
            case (12, 31): return .newYearsEve
            // Just past midnight is still the night.
            case (1, 1) where (parts.hour ?? 12) < 2: return .newYearsEve
            case (11, 5): return .bonfireNight
            case (10, 29...31): return .halloween
            case (12, 24...26): return .christmas
            default:
                guard let sunday = easterSunday(year, calendar: calendar),
                      let gap = calendar.dateComponents([.day], from: sunday, to: calendar.startOfDay(for: date)).day else { return nil }
                // Good Friday to Easter Monday.
                return (-2...1).contains(gap) ? .easter : nil
            }
        }()
        guard let found else { return nil }
        if let regions = found.regions, !regions.contains(region ?? "") { return nil }
        return found
    }

    /// Easter Sunday in the Western calendar (the anonymous Gregorian method).
    static func easterSunday(_ year: Int, calendar: Calendar = .current) -> Date? {
        let a = year % 19, b = year / 100, c = year % 100, d = b / 4, e = b % 4
        let f = (b + 8) / 25, g = (b - f + 1) / 3, h = (19 * a + b - d - g + 15) % 30
        let i = c / 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31, day = (h + l - 7 * m + 114) % 31 + 1
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// Today's, if the switch is on.
    static var today: SpecialDay? {
        let defaults = UserDefaults.standard
        #if DEBUG
        // For checking: launch with "-debugDay halloween" (or newYearsEve, bonfireNight, easter, christmas, none).
        if let forced = defaults.string(forKey: "debugDay") { return SpecialDay(rawValue: forced) }
        #endif
        guard defaults.object(forKey: onKey) as? Bool ?? true else { return nil }
        // Asked for by every frame of the scene, so worked out once a minute, not each time.
        let now = Date.now
        if let kept = Self.kept, now < kept.until { return kept.day }
        let day = on(now, region: Locale.current.region?.identifier)
        kept = (now.addingTimeInterval(60), day)
        return day
    }

    nonisolated(unsafe) private static var kept: (until: Date, day: SpecialDay?)?

    /// Fireworks in the night sky, and in the window after dark.
    var fireworks: Bool { self == .newYearsEve || self == .bonfireNight }
}

// MARK: Pictures. Flat and without an outline, like the rest of the world outdoors.

/// A round, ribbed pumpkin. After dark it glows from inside, with two round eyes and a small smile, never teeth.
struct Pumpkin: View {
    var night = false
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let body = CGRect(x: 0, y: h * 0.22, width: w, height: h * 0.78)
            if night {
                let flicker = 0.85 + 0.15 * sin(t * 9) * sin(t * 3.7)
                context.fill(Path(ellipseIn: body.insetBy(dx: -w * 0.5, dy: -h * 0.4)),
                             with: .radialGradient(Gradient(colors: [Color(hex: 0xFFB347).opacity(0.35 * flicker), .clear]),
                                                   center: CGPoint(x: body.midX, y: body.midY), startRadius: 2, endRadius: w))
            }
            let orange = Color(hex: night ? 0xC0703A : 0xF08A3C), rib = Color(hex: night ? 0xA35A2C : 0xDB7430)
            // Three lobes, the middle one in front.
            for (dx, scale) in [(-0.22, 0.62), (0.22, 0.62)] as [(CGFloat, CGFloat)] {
                let lobe = CGRect(x: body.midX + body.width * dx - body.width * scale / 2, y: body.minY, width: body.width * scale, height: body.height)
                context.fill(Path(ellipseIn: lobe), with: .color(rib))
            }
            context.fill(Path(ellipseIn: CGRect(x: body.midX - body.width * 0.3, y: body.minY, width: body.width * 0.6, height: body.height)), with: .color(orange))
            // The stem.
            var stem = Path()
            stem.move(to: CGPoint(x: w * 0.5, y: h * 0.26))
            stem.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.02), control: CGPoint(x: w * 0.5, y: h * 0.08))
            context.stroke(stem, with: .color(Color(hex: night ? 0x4E6A48 : 0x6E9A5A)), style: StrokeStyle(lineWidth: max(w * 0.1, 2), lineCap: .round))
            if night {
                let light = Color(hex: 0xFFD27A)
                for side in [-1.0, 1.0] as [CGFloat] {
                    context.fill(Path(ellipseIn: CGRect(x: body.midX + side * w * 0.14 - w * 0.06, y: body.minY + body.height * 0.3, width: w * 0.12, height: w * 0.12)), with: .color(light))
                }
                var smile = Path()
                smile.move(to: CGPoint(x: body.midX - w * 0.14, y: body.minY + body.height * 0.58))
                smile.addQuadCurve(to: CGPoint(x: body.midX + w * 0.14, y: body.minY + body.height * 0.58),
                                   control: CGPoint(x: body.midX, y: body.minY + body.height * 0.8))
                context.stroke(smile, with: .color(light), style: StrokeStyle(lineWidth: max(w * 0.07, 1.5), lineCap: .round))
            }
        }
    }
}

/// A painted egg, lying in the grass.
struct PaintedEgg: View {
    var colour: UInt32
    var band: UInt32
    var night = false
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var egg = Path()
            egg.move(to: CGPoint(x: w / 2, y: 0))
            egg.addCurve(to: CGPoint(x: w, y: h * 0.62), control1: CGPoint(x: w * 0.82, y: 0), control2: CGPoint(x: w, y: h * 0.32))
            egg.addCurve(to: CGPoint(x: 0, y: h * 0.62), control1: CGPoint(x: w, y: h * 1.08), control2: CGPoint(x: 0, y: h * 1.08))
            egg.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: 0, y: h * 0.32), control2: CGPoint(x: w * 0.18, y: 0))
            context.fill(egg, with: .color(Color(hex: colour).opacity(night ? 0.6 : 1)))
            var zigzag = Path()
            let y = h * 0.52
            zigzag.move(to: CGPoint(x: 0, y: y))
            for step in 1...6 { zigzag.addLine(to: CGPoint(x: w * CGFloat(step) / 6, y: y + (step.isMultiple(of: 2) ? 0 : -h * 0.12))) }
            var clipped = context
            clipped.clip(to: egg)
            clipped.stroke(zigzag, with: .color(Color(hex: band).opacity(night ? 0.6 : 1)), style: StrokeStyle(lineWidth: max(h * 0.12, 1.5), lineJoin: .round))
        }
    }
}

/// A present with a ribbon and a bow.
struct Present: View {
    var colour: UInt32 = 0xE5553B
    var ribbon: UInt32 = 0xF4BE2C
    var night = false
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let dim = night ? 0.62 : 1.0
            let box = CGRect(x: 0, y: h * 0.3, width: w, height: h * 0.7)
            context.fill(Path(roundedRect: box, cornerRadius: 2.5), with: .color(Color(hex: colour).opacity(dim)))
            context.fill(Path(CGRect(x: w * 0.42, y: box.minY, width: w * 0.16, height: box.height)), with: .color(Color(hex: ribbon).opacity(dim)))
            context.fill(Path(CGRect(x: 0, y: box.minY + box.height * 0.32, width: w, height: box.height * 0.16)), with: .color(Color(hex: ribbon).opacity(dim)))
            for side in [-1.0, 1.0] as [CGFloat] {
                context.fill(Path(ellipseIn: CGRect(x: w / 2 + (side < 0 ? -w * 0.34 : w * 0.02), y: h * 0.06, width: w * 0.32, height: h * 0.26)),
                             with: .color(Color(hex: ribbon).opacity(dim)))
            }
        }
    }
}

/// A small fir tree with a star on top.
struct LittleTree: View {
    var night = false
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(CGRect(x: w * 0.42, y: h * 0.84, width: w * 0.16, height: h * 0.16)), with: .color(Color(hex: night ? 0x5A4A5A : 0xA98A68)))
            let green = Color(hex: night ? 0x2F5A5A : 0x4F8F5F)
            for (index, tier) in ([(0.18, 0.5), (0.4, 0.68), (0.6, 0.88)] as [(CGFloat, CGFloat)]).enumerated() {
                let half = w * (0.22 + 0.14 * CGFloat(index))
                var layer = Path()
                layer.move(to: CGPoint(x: w / 2, y: h * tier.0 - h * 0.1))
                layer.addLine(to: CGPoint(x: w / 2 + half, y: h * tier.1))
                layer.addLine(to: CGPoint(x: w / 2 - half, y: h * tier.1))
                layer.closeSubpath()
                context.fill(layer, with: .color(green))
            }
            // Baubles that twinkle after dark.
            for (index, at) in ([(0.42, 0.42), (0.6, 0.6), (0.36, 0.78), (0.66, 0.82), (0.5, 0.64)] as [(CGFloat, CGFloat)]).enumerated() {
                let colour: UInt32 = [0xE5553B, 0xF4BE2C, 0xBFD9F5][index % 3]
                let twinkle = night ? 0.6 + 0.4 * sin(t * 2.4 + Double(index) * 1.7) : 1
                context.fill(Path(ellipseIn: CGRect(x: w * at.0 - 2, y: h * at.1 - 2, width: 4, height: 4)), with: .color(Color(hex: colour).opacity(twinkle)))
            }
            let star = CGPoint(x: w / 2, y: h * 0.06)
            if night {
                context.fill(Path(ellipseIn: CGRect(x: star.x - 9, y: star.y - 9, width: 18, height: 18)),
                             with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE38A).opacity(0.5), .clear]), center: star, startRadius: 0, endRadius: 9))
            }
            var points: [CGPoint] = []
            for index in 0..<10 {
                let angle = Double(index) / 10 * 2 * .pi - .pi / 2, reach: CGFloat = index.isMultiple(of: 2) ? 5 : 2.2
                points.append(CGPoint(x: star.x + CGFloat(cos(angle)) * reach, y: star.y + CGFloat(sin(angle)) * reach))
            }
            var shape = Path()
            shape.addLines(points)
            shape.closeSubpath()
            context.fill(shape, with: .color(Color(hex: 0xF4BE2C)))
        }
    }
}

/// A string of fairy lights hung across the top of the picture, dipping between two points.
struct FairyLights: View {
    var t = 0.0
    var night = false
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var wire = Path()
            var bulbs: [CGPoint] = []
            let swags = 3
            for swag in 0..<swags {
                let x0 = w * CGFloat(swag) / CGFloat(swags), x1 = w * CGFloat(swag + 1) / CGFloat(swags)
                let control = CGPoint(x: (x0 + x1) / 2, y: h * 1.6)
                if swag == 0 { wire.move(to: CGPoint(x: x0, y: 0)) }
                wire.addQuadCurve(to: CGPoint(x: x1, y: 0), control: control)
                for step in 1..<6 {
                    let along = CGFloat(step) / 6
                    let x = (1 - along) * (1 - along) * x0 + 2 * (1 - along) * along * control.x + along * along * x1
                    let y = 2 * (1 - along) * along * control.y
                    bulbs.append(CGPoint(x: x, y: y))
                }
            }
            context.stroke(wire, with: .color(Color(hex: night ? 0x2A2A44 : 0x5E6A5A).opacity(0.7)), style: StrokeStyle(lineWidth: 1))
            for (index, bulb) in bulbs.enumerated() {
                let colour: UInt32 = [0xF58A70, 0xF4BE2C, 0x8FD3A8, 0xBFD9F5][index % 4]
                let twinkle = 0.55 + 0.45 * sin(t * 2.1 + Double(index) * 2.3)
                if night {
                    context.fill(Path(ellipseIn: CGRect(x: bulb.x - 7, y: bulb.y - 5, width: 14, height: 14)),
                                 with: .radialGradient(Gradient(colors: [Color(hex: colour).opacity(0.45 * twinkle), .clear]),
                                                       center: CGPoint(x: bulb.x, y: bulb.y + 2), startRadius: 0, endRadius: 7))
                }
                context.fill(Path(ellipseIn: CGRect(x: bulb.x - 2, y: bulb.y - 0.5, width: 4, height: 5.5)),
                             with: .color(Color(hex: colour).opacity(night ? 0.6 + 0.4 * twinkle : 1)))
            }
        }
    }
}

/// A bonfire: crossed logs, flames that flicker, sparks going up, and its warm light on the ground.
struct Bonfire: View {
    var t = 0.0
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w / 2, y: h * 0.88)
            context.fill(Path(ellipseIn: CGRect(x: base.x - w * 0.7, y: base.y - h * 0.5, width: w * 1.4, height: h * 0.9)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFFB347).opacity(0.32), .clear]), center: base, startRadius: 4, endRadius: w * 0.7))
            for (index, colour) in ([0xF58A50, 0xFFB347, 0xFFE08A] as [UInt32]).enumerated() {
                let scale = 1 - CGFloat(index) * 0.28
                let sway = CGFloat(sin(t * 6 + Double(index) * 1.3)) * w * 0.04
                let tall = h * 0.72 * scale * (0.92 + 0.08 * CGFloat(sin(t * 11 + Double(index))))
                var flame = Path()
                flame.move(to: CGPoint(x: base.x - w * 0.3 * scale, y: base.y))
                flame.addQuadCurve(to: CGPoint(x: base.x + sway, y: base.y - tall), control: CGPoint(x: base.x - w * 0.34 * scale, y: base.y - tall * 0.55))
                flame.addQuadCurve(to: CGPoint(x: base.x + w * 0.3 * scale, y: base.y), control: CGPoint(x: base.x + w * 0.34 * scale, y: base.y - tall * 0.55))
                flame.closeSubpath()
                context.fill(flame, with: .color(Color(hex: colour)))
            }
            for turn in [-18.0, 18.0] {
                var log = context
                log.translateBy(x: base.x, y: base.y + 2)
                log.rotate(by: .degrees(turn))
                log.fill(Path(roundedRect: CGRect(x: -w * 0.38, y: -h * 0.04, width: w * 0.76, height: h * 0.08), cornerRadius: h * 0.04),
                         with: .color(Color(hex: 0x5A3E3A)))
            }
            for index in 0..<6 {
                var random = SeededRandom(UInt64(index) &* 977 &+ 3)
                let life = (t * random.range(0.5, 0.8) + random.unit()).truncatingRemainder(dividingBy: 1)
                let x = base.x + CGFloat(random.range(-0.3, 0.3)) * w + CGFloat(sin(t * 3 + Double(index))) * 3
                let y = base.y - h * 0.4 - CGFloat(life) * h * 0.9
                context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)), with: .color(Color(hex: 0xFFD27A).opacity(1 - life)))
            }
        }
    }
}
