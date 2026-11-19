import SwiftUI

/// Puggle's family and friends, as drawn on the canvas ("The cast, to scale") and cut into rigs by
/// tools/make_cast_rigs.py. They share her part names, so the rig gives them her breathing, blinking
/// and head tilts, and they borrow her nod, wave and hop.
enum CastMember: String, CaseIterable, Identifiable {
    case nan, mum, dad, pop, pebble, quill, kip, digby, sunny

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var grownUp: Bool { self == .nan || self == .mum || self == .dad || self == .pop }
    var isParent: Bool { self == .mum || self == .dad }

    /// Each drawing's size and headroom, read once.
    private static let drawn: [CastMember: (height: CGFloat, headroom: CGFloat)] = Dictionary(uniqueKeysWithValues: allCases.map { member in
        let rig = Rig.load(member.rawValue)
        return (member, (rig?.size[1] ?? 300, rig?.headroom ?? 0))
    })

    /// How big they are beside Puggle. Everyone is drawn at her scale, so they share her head size; the
    /// older friends are a touch bigger all over, as on the canvas.
    private var scale: CGFloat {
        switch self {
        case .nan: 0.95
        case .mum: 0.98
        case .dad: 1
        case .pop: 0.97
        case .pebble: 0.74
        case .quill: 1
        case .kip: 1.06
        case .digby: 1.1
        case .sunny: 1.14
        }
    }

    /// The height of their drawing beside Puggle at 118 points, including any room above the head for an umbrella.
    var height: CGFloat { 118 / 300 * (Self.drawn[self]?.height ?? 300) * scale }

    /// How much of that height is empty space above the head.
    var headroom: CGFloat { 118 / 300 * (Self.drawn[self]?.headroom ?? 0) * scale }

    /// The garments this character has, as rig names. The first is how the canvas draws them.
    var garments: [String] {
        switch self {
        case .quill: ["quill", "quill-jumper", "quill-tee"]
        case .kip: ["kip", "kip-dungarees", "kip-jumper"]
        case .digby: ["digby", "digby-dungarees"]
        case .mum: ["mum", "mum-skirt", "mum-trousers"]
        case .dad: ["dad", "dad-jumper", "dad-overalls"]
        case .nan: ["nan", "nan-apron", "nan-skirt"]
        case .pop: ["pop", "pop-waistcoat", "pop-jumper"]
        default: [rawValue]
        }
    }

    /// What they have on today: which garment, and which of its colours. It changes from day to day and
    /// is the same all day, as getting dressed is. Each of them has their own pattern, so two friends
    /// seldom change on the same morning.
    func outfitToday() -> (rig: String, look: Int) {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let turn = day + (CastMember.allCases.firstIndex(of: self) ?? 0) * 3
        var garment = turn % garments.count, look = (turn / 2) % 4
        #if DEBUG
        // For checking: "-debugWear 1" (which garment) and "-debugLook 2" (which colour).
        if let forced = UserDefaults.standard.string(forKey: "debugWear").flatMap(Int.init) { garment = forced % garments.count }
        if let forced = UserDefaults.standard.string(forKey: "debugLook").flatMap(Int.init) { look = forced }
        #endif
        return (garments[garment], look)
    }

    /// The drawing's own proportions.
    var aspect: CGFloat { 240 / (Self.drawn[self]?.height ?? 300) }
}

/// What someone is doing in the scene with her.
enum CastActivity {
    /// Standing with her: a wave hello, a nod now and then.
    case with
    /// Asleep on their feet, as Kip is anywhere. A tap on Puggle wakes them for a moment.
    case dozing
    /// Digging in the sand.
    case digging
}

/// How someone is placed in the scene.
enum CastPose: Equatable {
    case standing
    /// Sitting at the tea table: lower, behind it.
    case atTable
    /// In the armchair by the bed, for a story, or dozing while babysitting.
    case armchair
    /// In a sleeping bag on the bedroom floor on a sleepover: sitting up, or tucked in asleep.
    case bagSitting, bagLying

}

/// Who is with Puggle today, where they stand, and what they are doing.
struct Company: Equatable {
    let member: CastMember
    /// Where they stand, as a share of the width from the middle.
    let x: CGFloat
    var activity: CastActivity = .with
    var pose: CastPose = .standing

    /// Everyone with her: at tea her family round the table, at bedtime whoever is reading or sleeping over,
    /// anywhere else today's one companion (or nobody).
    static func gathering(kind: SceneKind, room: Room?, afterDark: Bool, bed: BedPose?, minute: Int) -> [Company] {
        switch room {
        case .dining: return tea().others
        case .bedroom: return bedtime(bed ?? .asleep, minute: minute)
        default: return today(kind: kind, room: room, afterDark: afterDark).map { [$0] } ?? []
        }
    }

    /// Tea: Mum and Dad either side of her every evening; Nan or Pop some evenings, or the friend staying
    /// the night. Four at most, so everyone fits. `puggle` is where her own place is.
    static func tea() -> (others: [Company], puggle: CGFloat) {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        var guest: CastMember? = Evening.sleepover
        #if DEBUG
        // For checking: "-debugTea nan" (or pop, or a friend), or "none".
        if let forced = UserDefaults.standard.string(forKey: "debugTea") { guest = CastMember(rawValue: forced) }
        else if guest == nil, day % 3 == 1 { guest = day.isMultiple(of: 2) ? .nan : .pop }
        #else
        if guest == nil, day % 3 == 1 { guest = day.isMultiple(of: 2) ? .nan : .pop }
        #endif
        guard let guest else {
            return ([Company(member: .mum, x: -0.3, pose: .atTable), Company(member: .dad, x: 0.3, pose: .atTable)], 0)
        }
        // Mum, Puggle, the guest, Dad: a child guest sits next to her.
        return ([Company(member: .mum, x: -0.36, pose: .atTable), Company(member: guest, x: 0.12, pose: .atTable),
                 Company(member: .dad, x: 0.36, pose: .atTable)], -0.12)
    }

    /// Bedtime. While she reads, a grown-up sits in the armchair: Mum or Dad for a story, or Nan or Pop
    /// babysitting, who dozes off and stays until ten. A friend on a sleepover is in a sleeping bag on the
    /// floor all night. Late at night it is only her, and any friend.
    private static func bedtime(_ bed: BedPose, minute: Int) -> [Company] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now.addingTimeInterval(-6 * 3600)) ?? 0
        var here: [Company] = []
        if let friend = Evening.sleepover {
            here.append(Company(member: friend, x: 0.04, activity: bed == .reading ? .with : .dozing,
                                pose: bed == .reading ? .bagSitting : .bagLying))
        }
        var grownUp: CastMember = [.mum, .dad, .nan, .pop][day % 4]
        #if DEBUG
        // For checking: "-debugSitter nan" (or mum, dad, pop) for who is in the armchair.
        if let forced = UserDefaults.standard.string(forKey: "debugSitter").flatMap(CastMember.init) { grownUp = forced }
        #endif
        let late = minute < 6 * 60 || minute >= 22 * 60
        switch bed {
        case .reading, .up: here.append(Company(member: grownUp, x: 0.34, pose: .armchair))
        case .asleep where !late && !grownUp.isParent: here.append(Company(member: grownUp, x: 0.34, activity: .dozing, pose: .armchair))
        default: break
        }
        return here
    }

    /// Some days she is on her own; others her family or a friend is there. It changes each time
    /// the same place comes round, so a scene is not always the same company.
    static func today(kind: SceneKind, room: Room?, afterDark: Bool = false) -> Company? {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        #if DEBUG
        // For checking: "-debugCompany kip", or "none".
        if let forced = UserDefaults.standard.string(forKey: "debugCompany") {
            guard let member = CastMember(rawValue: forced) else { return nil }
            let here = (room.map(indoors) ?? outdoors(kind)).compactMap { $0 }
            if let match = here.first(where: { $0.member == member }), !afterDark || member.grownUp { return match }
            if !afterDark || member.grownUp { return Company(member: member, x: here.first?.x ?? 0.3) }
        }
        #endif
        if let room {
            let options = indoors(room)
            return options[(day + room.rawValue) % options.count]
        }
        // Outdoors after dark she is always with a grown-up, standing where that scene's company stands.
        if afterDark {
            let grownUps: [CastMember] = [.mum, .dad, .nan, .pop]
            let side = outdoors(kind).compactMap { $0 }.first?.x ?? 0.3
            return Company(member: grownUps[day % grownUps.count], x: side < 0 ? -0.3 : 0.26)
        }
        // An outdoor scene comes round every fourth day, so step through its company at that pace.
        let options = outdoors(kind)
        return options[(day / SceneKind.allCases.count) % options.count]
    }

    private static func outdoors(_ kind: SceneKind) -> [Company?] {
        switch kind {
        case .hills: [Company(member: .sunny, x: 0.3), nil, Company(member: .mum, x: 0.26), Company(member: .quill, x: 0.3)]
        case .beach: [Company(member: .digby, x: 0.3, activity: .digging), Company(member: .pop, x: 0.26), nil, Company(member: .dad, x: 0.26)]
        case .backyard: [Company(member: .dad, x: -0.3), nil, Company(member: .quill, x: -0.3), Company(member: .nan, x: -0.3)]
        case .bush: [Company(member: .kip, x: 0.3, activity: .dozing), Company(member: .nan, x: 0.26), nil, Company(member: .sunny, x: 0.3)]
        }
    }

    private static func indoors(_ room: Room) -> [Company?] {
        switch room {
        // Tea is always with a grown-up, on the window side, clear of the You button.
        case .dining: [Company(member: .mum, x: -0.37), Company(member: .dad, x: -0.37), Company(member: .nan, x: -0.37), Company(member: .pop, x: -0.37)]
        case .living: [Company(member: .nan, x: -0.27), Company(member: .pop, x: -0.27), nil, Company(member: .pebble, x: -0.24)]
        case .playroom: [Company(member: .kip, x: -0.25), Company(member: .digby, x: -0.25), Company(member: .pebble, x: 0.2),
                         Company(member: .sunny, x: -0.25), Company(member: .quill, x: -0.25), nil]
        // Someone to say goodnight, most nights.
        case .bedroom: [Company(member: .mum, x: 0.2), Company(member: .dad, x: 0.2), nil]
        }
    }
}

/// One cast member's rig and what it is doing.
@MainActor
final class CastController: ObservableObject {
    let member: CastMember
    let rig: RigRuntime?

    /// As the canvas draws them, or in a named garment and one of its colours. In the rain the garment is a raincoat's yellow.
    init(_ member: CastMember, rig name: String? = nil, look: Int = 0, rain: Bool = false) {
        self.member = member
        guard let drawn = Rig.load(name ?? member.rawValue) else { rig = nil; return }
        let looks = drawn.wardrobe?.looks ?? []
        let swaps = rain ? (drawn.wardrobe?.rain ?? [:]) : (looks.isEmpty ? [:] : looks[look % looks.count])
        rig = RigRuntime(rig: drawn.wearing(swaps))
    }

    func play(_ move: String) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        rig?.play(move)
    }

    var asleep: Bool {
        get { rig?.asleep ?? false }
        set { rig?.asleep = newValue; objectWillChange.send() }
    }
}

/// A cast member, drawn and moved by the rig. Still with Reduce Motion.
struct CastView: View {
    @ObservedObject var controller: CastController
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.puggleNight) private var night

    var body: some View {
        // They take the room their own drawing needs, and are drawn on a wider surface where something
        // they hold reaches past it, so an umbrella is not cut off at their sides.
        Color.clear
            .aspectRatio(controller.member.aspect, contentMode: .fit)
            .overlay {
                if let rig = controller.rig {
                    GeometryReader { box in
                        let extra = box.size.width * (rig.rig.sideroom ?? 0) * 2 / rig.rig.size[0]
                        RigView(runtime: rig, moving: !reduceMotion && !frozen)
                            .frame(width: box.size.width + extra, height: box.size.height)
                            .offset(x: -extra / 2)
                    }
                }
            }
        .brightness(night ? -0.18 : 0)
        .saturation(night ? 0.8 : 1)
        .accessibilityElement()
        .accessibilityLabel(controller.member.name)
    }
}

/// Whoever is with Puggle in the scene: standing on the same ground, behind her, living their own small life.
/// They wave when Today opens, nod now and then, and answer when she is tapped.
struct CompanyView: View {
    let company: Company
    /// Counts up each time Puggle reacts to a tap, so they can answer.
    let puggleReacted: Int
    /// A child is asleep: the children in the cast sleep too; grown-ups stay up, quietly.
    let quiet: Bool
    let appeared: Bool
    let dark: Bool
    /// The weather they are out in, for the rain landing on their umbrella. Nil indoors.
    var weather: Weather?
    var night = false
    /// Their arrival: counts up each time Today opens, and how they come in. See `Arrival`.
    var entrance = 0
    var arrive: ArrivalStyle = .none
    /// How far sideways the nearest edge of the scene is, for walking in.
    var edge: CGFloat = 0
    var delay: Double = 0
    var away = false
    @StateObject private var controller: CastController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.outfit) private var outfit

    init(company: Company, puggleReacted: Int, quiet: Bool, appeared: Bool, dark: Bool, rain: Bool = false, weather: Weather? = nil, night: Bool = false,
         entrance: Int = 0, arrive: ArrivalStyle = .none, edge: CGFloat = 0, delay: Double = 0, away: Bool = false) {
        self.away = away
        self.entrance = entrance
        self.arrive = arrive
        self.edge = edge
        self.delay = delay
        self.weather = weather
        self.night = night
        self.company = company
        self.puggleReacted = puggleReacted
        self.quiet = quiet
        self.appeared = appeared
        self.dark = dark
        let outfit = company.member.outfitToday()
        _controller = StateObject(wrappedValue: CastController(company.member, rig: outfit.rig, look: outfit.look, rain: rain))
    }

    /// A hello, picked each time: a wave with either hand or a nod, and for the children sometimes a hop.
    /// Now and then none at all: they just look up and carry on.
    static func hello(for member: CastMember, has: (String) -> Bool) -> String? {
        var choices = ["greet", "greet", "greet-left", "greet-left", "nod"]
        if !member.grownUp { choices += ["celebrate"] }
        choices += [""]
        let pick = choices.filter { $0.isEmpty || has($0) }.randomElement() ?? "greet"
        return pick.isEmpty ? nil : pick
    }

    private var sleeps: Bool { company.activity == .dozing || (quiet && !company.member.grownUp) }

    /// They are holding an umbrella: in the rain, or Nan's as a parasol in the heat.
    private var umbrellaUp: Bool {
        controller.rig?.rig.parts.contains { $0.id == "umbrella" } == true && (outfit == "rain" || (outfit == "sun" && company.member == .nan))
    }

    /// How far down from standing, in points, for sitting at the table, in the armchair or in a sleeping bag.
    private var drop: CGFloat {
        switch company.pose {
        case .standing: return 0
        // Sitting, they come down to the foot of the scene, where the cloth, the chair or the bag hides their feet.
        // Asleep in the bag they are upright too, head on a pillow and the bag up to their chin: every face in
        // the cast is drawn from the front, and turned on its side it no longer reads.
        case .atTable, .armchair, .bagSitting, .bagLying: return 26
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse().fill(dark ? Color(hex: 0x15163A).opacity(0.3) : Palette.fixedInk.opacity(0.1))
                .frame(width: 76, height: 8)
                .opacity(company.pose == .standing ? 1 : 0)
                .offset(y: 3)
            if company.activity == .digging, !sleeps {
                // The heap he has dug, beside him, and sand flying.
                TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { timeline in
                    let t = timeline.date.timeIntervalSince(SceneClock.start)
                    ZStack(alignment: .bottom) {
                        SandMound().frame(width: 70, height: 22).offset(x: 46, y: 4)
                        ForEach(0..<5, id: \.self) { i in
                            let fling = (t * 1.5 + Double(i) * 0.31).truncatingRemainder(dividingBy: 1)
                            Circle().fill(Color(hex: 0x8A6A3C).opacity(0.5 * (1 - fling))).frame(width: 3.5, height: 3.5)
                                .offset(x: 20 + CGFloat(fling) * 30 + CGFloat(i) * 2, y: -6 - CGFloat(sin(fling * .pi)) * (16 + CGFloat(i) * 3))
                        }
                    }
                }
            }
            CastView(controller: controller)
                .frame(height: company.member.height)
                .overlay {
                    // Rain landing on the umbrella, and dripping off its points. Turned with them below.
                    if outfit == "rain", umbrellaUp, let weather, let strength = Rain.strength(weather), !reduceMotion, let rig = controller.rig?.rig {
                        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                            UmbrellaRain(drawing: CGSize(width: rig.size[0], height: rig.size[1]), strength: strength, night: night,
                                         t: timeline.date.timeIntervalSince(SceneClock.start))
                        }
                        .accessibilityHidden(true)
                    }
                }
                // An umbrella is held out to one side. Standing to her right, they are turned round so it is
                // on the side nearer her, and its canopy stays clear of the edge of the screen.
                .scaleEffect(x: umbrellaUp && company.x > 0 ? -1 : 1, y: 1)
        }
        .offset(y: drop)
        .arrival(entrance, arrive, edge: edge, delay: delay, away: away) { [controller] in controller.rig?.walking = $0 }
        .allowsHitTesting(false)
        .onAppear { controller.asleep = sleeps }
        .onChange(of: sleeps) { _, now in
            if now { controller.asleep = true } else { controller.asleep = false; controller.play("wake") }
        }
        // She was tapped: a friend answers, and a dozing one wakes for a moment.
        .onChange(of: puggleReacted) { _, _ in
            Task {
                try? await Task.sleep(for: .seconds(0.45))
                if company.activity == .dozing, !quiet {
                    controller.asleep = false
                    controller.play("wake")
                    try? await Task.sleep(for: .seconds(6))
                    controller.asleep = true
                } else if !sleeps {
                    controller.play(company.member.grownUp ? "nod" : "greet")
                }
            }
        }
        .task(id: appeared) {
            guard appeared, !sleeps, !reduceMotion else { return }
            // A hello a moment after she arrives, then small things at their own pace. Each has their own hello and
            // their own moment, so a table of them never waves in step (Tom, 19 November 2026).
            try? await Task.sleep(for: .seconds(Double.random(in: 1.0...2.6)))
            if let hello = Self.hello(for: company.member, has: { controller.rig?.rig.moves?[$0] != nil }) {
                controller.play(hello)
            }
            var turn = 0
            while !Task.isCancelled {
                let digging = company.activity == .digging
                try? await Task.sleep(for: .seconds(digging ? 1.5 : Double.random(in: 9...17)))
                guard !Task.isCancelled, !sleeps else { continue }
                turn += 1
                // Digging is a bob down, over and over; otherwise mostly nods, a hop now and then for the children.
                if digging { controller.play("nod") }
                else if !company.member.grownUp && turn.isMultiple(of: 3) { controller.play("celebrate") }
                else { controller.play("nod") }
            }
        }
    }
}

// MARK: Portraits, for avatars

/// Anyone in the cast, Puggle included, as a round portrait: their head on one of the soft colours.
struct CastPortrait: View {
    /// The rig's name: "puggle", "kip", "nan"…
    let who: String
    var size: CGFloat = 64

    static let everyone: [String] = ["puggle"] + [CastMember.pebble, .kip, .quill, .digby, .sunny, .mum, .dad, .nan, .pop].map(\.rawValue)

    static func name(_ who: String) -> String { who.capitalized }

    /// A soft field behind each, so no two neighbours match.
    private var field: Color {
        let fields: [UInt32] = [0xBFD9F5, 0xF4E7B0, 0xCFE5D2, 0xF3D9C9, 0xE2D4F1]
        return Color(hex: fields[(Self.everyone.firstIndex(of: who) ?? 0) % fields.count])
    }

    var body: some View {
        ZStack(alignment: .top) {
            field
            if let rig = Rig.load(who) {
                // The head and shoulders: the drawing is scaled up and held by its top, and the circle crops the rest.
                let wide = size * 1.12
                RigFrame(rig: rig, states: [:])
                    .frame(width: wide, height: wide * rig.size[1] / rig.size[0])
                    .offset(y: size * 0.1 - wide / rig.size[0] * (rig.headroom ?? 0))
                    .frame(width: size, height: size, alignment: .top)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .environment(\.lineStyle, .chosen)
        .accessibilityLabel(Self.name(who))
    }

    /// The portrait as a picture, to keep as someone's photo.
    @MainActor static func image(of who: String) -> UIImage? {
        let renderer = ImageRenderer(content: CastPortrait(who: who, size: 300).clipShape(Rectangle()))
        renderer.scale = 1
        return renderer.uiImage
    }
}

/// "Choose a character": Puggle, her family and her friends, each with their name.
struct CharacterPicker: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (UIImage) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 14)], spacing: 18) {
                    ForEach(CastPortrait.everyone, id: \.self) { who in
                        Button {
                            guard let image = CastPortrait.image(of: who) else { return }
                            Haptics.tap()
                            onPick(image)
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                CastPortrait(who: who, size: 84)
                                Text(CastPortrait.name(who)).font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(CastPortrait.name(who))
                    }
                }
                .padding(20)
                Text("Puggle, her family and her friends. Pick one to stand in for a photo; you can change it any time.")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
            .background(Palette.sand)
            .navigationTitle("Choose a character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .foregroundStyle(Palette.ink)
        .presentationDetents([.medium, .large])
    }
}

/// Rain on a friend's umbrella: pops along the top of the canopy and drips off its points. Measured from the
/// canopy every rig with an umbrella shares (in the drawing's own units, the canopy runs from 84 to 296 across,
/// its top at 14 and its points at 92), placed the way the rig is drawn: centred, standing on the bottom.
struct UmbrellaRain: View {
    let drawing: CGSize
    let strength: Double
    let night: Bool
    let t: Double

    var body: some View {
        GeometryReader { box in
            let scale = box.size.height / drawing.height
            let place = { (x: CGFloat, y: CGFloat) -> CGPoint in
                CGPoint(x: box.size.width / 2 + (x - drawing.width / 2) * scale, y: box.size.height - (drawing.height - y) * scale)
            }
            // The canopy's top, two curves from point to crown to point, in short straight pieces.
            let curves: [(CGPoint, CGPoint, CGPoint)] = [(CGPoint(x: 84, y: 92), CGPoint(x: 90, y: 18), CGPoint(x: 190, y: 14)),
                                                         (CGPoint(x: 190, y: 14), CGPoint(x: 290, y: 18), CGPoint(x: 296, y: 92))]
            let ledges: [RainTarget] = curves.flatMap { a, c, b in
                (0..<4).map { i -> RainTarget in
                    func at(_ u: CGFloat) -> CGPoint {
                        let v = 1 - u
                        return place(v * v * a.x + 2 * v * u * c.x + u * u * b.x, v * v * a.y + 2 * v * u * c.y + u * u * b.y)
                    }
                    return .ledge(at(CGFloat(i) / 4), at(CGFloat(i + 1) / 4))
                }
            }
            let ground = box.size.height - 2
            RainHits(targets: ledges,
                     // Only off the points clear of them: the others would fall through their face.
                     drips: [243, 296].map { DripSpot(at: place($0, 94), lands: ground) },
                     strength: strength, night: night, t: t, rate: 4.5, salt: 11)
        }
        .allowsHitTesting(false)
    }
}
