import SwiftUI

/// A soft block standing in for something that is still loading, with a slow
/// sheen passing over it. Still with Reduce Motion.
struct SkeletonBlock: View {
    var corner: CGFloat = 12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Palette.field)
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(colors: [.clear, Palette.paper.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: phase * geometry.size.width)
                }
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1.4 }
            }
            .accessibilityHidden(true)
    }
}

/// The shape of Today while a family is loading: the scene, the date, two
/// children, two tiles and the day's entries.
struct TodaySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SkeletonBlock(corner: 0).frame(height: PuggleHeader.sceneHeight).padding(.horizontal, -16)
            SkeletonBlock().frame(width: 250, height: 30)
            SkeletonBlock().frame(width: 190, height: 18)
            SkeletonBlock(corner: 22).frame(height: 84)
            SkeletonBlock(corner: 22).frame(height: 84)
            HStack(spacing: 10) {
                SkeletonBlock(corner: 22).frame(height: 108)
                SkeletonBlock(corner: 22).frame(height: 108)
            }
            SkeletonBlock(corner: 18).frame(height: 220)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.sand)
        .ignoresSafeArea(edges: .top)
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

/// What the splash looks like now. The season picks the shape and the time
/// of day picks the colour, so it changes quietly through the day and the year.
struct SplashLook {
    enum Season: Int, CaseIterable { case spring, summer, autumn, winter }
    enum Time: Int, CaseIterable { case morning, day, evening }

    let season: Season
    let time: Time

    /// Seasons follow the phone's region: the south of the world has summer in December.
    static var now: SplashLook {
        let calendar = Calendar.current
        var month = calendar.component(.month, from: .now)
        var hour = calendar.component(.hour, from: .now)
        #if DEBUG
        // For checking: launch with "-debugMonth 7" or "-debugHour 18".
        if let forced = UserDefaults.standard.string(forKey: "debugMonth").flatMap(Int.init) { month = forced }
        if let forced = UserDefaults.standard.string(forKey: "debugHour").flatMap(Int.init) { hour = forced }
        #endif
        let season = Self.season(forMonth: month)
        let time: Time = switch hour {
        case 5..<11: .morning
        case 17..<21: .evening
        default: .day
        }
        return SplashLook(season: season, time: time)
    }

    /// The season a month falls in here: northern by month, turned half a year for the south.
    static func season(forMonth month: Int) -> Season {
        let southern: Set<String> = ["AU", "NZ", "ZA", "AR", "CL", "UY", "PY", "BO", "PE", "BR", "FJ", "PG", "NA", "BW", "ZW", "MZ", "MG", "LS", "SZ"]
        let south = southern.contains(Locale.current.region?.identifier ?? "")
        let northern: Season = switch month {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .autumn
        default: .winter
        }
        return south ? Season(rawValue: (northern.rawValue + 2) % 4) ?? northern : northern
    }

    /// One shape per season: blossom, a scalloped sun, a quatrefoil leaf, a soft snowflake.
    var shape: String {
        switch season {
        case .spring: "shape-blossom"
        case .summer: "shape-pebble"
        case .autumn: "shape-quatrefoil"
        case .winter: "shape-soft-hexagon"
        }
    }

    /// A tint of the page colour by day; after dark it is the page colour itself.
    var background: Color {
        switch time {
        case .morning: Color(light: 0xF6E7D8, dark: 0x16120F, night: 0x0B0908)
        case .day: Palette.sand
        case .evening: Color(light: 0xEEE5EC, dark: 0x16120F, night: 0x0B0908)
        }
    }
}

/// One shape, a shade off the background, in a wide diamond grid that drifts
/// slowly down and across. Still with Reduce Motion.
struct ShapePattern: View {
    let shape: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let cell: CGFloat = 92

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                guard let image = context.resolveSymbol(id: 0) else { return }
                let cell = Self.cell
                // The pattern repeats every two rows; drift five points a second.
                let period = cell * 2
                let drift = reduceMotion ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)) * 5
                let shift = drift.truncatingRemainder(dividingBy: period)
                let columns = Int(size.width / cell) + 2, rows = Int(size.height / (cell / 2)) + 2
                for row in -5..<rows {
                    for column in -3..<columns {
                        let stagger = row.isMultiple(of: 2) ? 0 : cell / 2
                        let x = CGFloat(column) * cell + stagger + shift
                        let y = CGFloat(row) * cell / 2 + shift
                        context.draw(image, at: CGPoint(x: x, y: y))
                    }
                }
            } symbols: {
                // Tinted here, so the shape follows day, dark and night.
                Image(shape).resizable().scaledToFit()
                    .foregroundStyle(Palette.ink.opacity(0.05))
                    .frame(width: 34, height: 34)
                    .tag(0)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
