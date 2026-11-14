import SwiftUI

/// Puggle's family and friends, as drawn on the canvas ("The cast, to scale") and cut into rigs by
/// tools/make_cast_rigs.py. They share her part names, so the rig gives them her breathing, blinking
/// and head tilts, and they borrow her nod, wave and hop.
enum CastMember: String, CaseIterable, Identifiable {
    case nan, mum, dad, pop, pebble, quill, kip, digby, sunny

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var grownUp: Bool { self == .nan || self == .mum || self == .dad || self == .pop }

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

/// Who is with Puggle today, where they stand, and what they are doing.
struct Company: Equatable {
    let member: CastMember
    /// Where they stand, as a share of the width from the middle.
    let x: CGFloat
    var activity: CastActivity = .with

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
    @StateObject private var controller: CastController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.outfit) private var outfit

    init(company: Company, puggleReacted: Int, quiet: Bool, appeared: Bool, dark: Bool, rain: Bool = false) {
        self.company = company
        self.puggleReacted = puggleReacted
        self.quiet = quiet
        self.appeared = appeared
        self.dark = dark
        let outfit = company.member.outfitToday()
        _controller = StateObject(wrappedValue: CastController(company.member, rig: outfit.rig, look: outfit.look, rain: rain))
    }

    private var sleeps: Bool { company.activity == .dozing || (quiet && !company.member.grownUp) }

    /// They are holding an umbrella: in the rain, or Nan's as a parasol in the heat.
    private var umbrellaUp: Bool {
        controller.rig?.rig.sideroom != nil && (outfit == "rain" || (outfit == "sun" && company.member == .nan))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse().fill(dark ? Color(hex: 0x15163A).opacity(0.3) : Palette.fixedInk.opacity(0.1))
                .frame(width: 76, height: 8)
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
                // An umbrella is held out to one side. Standing to her right, they are turned round so it is
                // on the side nearer her, and its canopy stays clear of the edge of the screen.
                .scaleEffect(x: umbrellaUp && company.x > 0 ? -1 : 1, y: 1)
        }
        .offset(y: appeared ? 0 : 50)
        .opacity(appeared ? 1 : 0)
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
            // A wave hello a moment after she arrives, then small things at their own pace.
            try? await Task.sleep(for: .seconds(1.4))
            controller.play("greet")
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
