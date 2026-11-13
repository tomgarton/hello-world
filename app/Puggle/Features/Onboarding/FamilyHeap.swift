import CoreMotion
import SpriteKit
import SwiftUI

/// The end of first run: shapes drop in and pile up, a few carrying the initials of the
/// family. The phone's tilt moves the heap and a shape can be thrown. Puggle stands on top.
struct FamilyHeap: View {
    /// One per person: their initial and colour. Plain shapes fill the heap out to thirteen.
    struct Letter: Hashable {
        var initial: String
        var colour: Color
    }

    let letters: [Letter]
    /// Names, read by VoiceOver in place of the picture.
    let names: String
    /// Changing this drops everything again.
    var round = 0
    var onLanded: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var top = HeapTop()
    @StateObject private var puggle = PuggleController()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                SpriteView(scene: scene(size: geometry.size), options: [.allowsTransparency])
                    .id(round)
                if let point = top.point {
                    PuggleView(controller: puggle)
                        .frame(height: 112)
                        .position(x: point.x, y: max(point.y - 50, 56))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(names)
        .onChange(of: top.landed) { _, landed in
            guard landed else { return }
            if !reduceMotion { puggle.celebrate() }
            onLanded()
        }
        .onChange(of: round) { _, _ in top.reset() }
    }

    private func scene(size: CGSize) -> HeapScene {
        let scene = HeapScene(size: size)
        scene.letters = letters.map { ($0.initial, UIColor($0.colour)) }
        scene.quick = reduceMotion
        scene.top = top
        return scene
    }
}

/// Where the top of the heap is, in the view's own points, for Puggle to stand on.
@MainActor
final class HeapTop: ObservableObject {
    @Published var point: CGPoint?
    @Published var landed = false

    func reset() {
        point = nil
        landed = false
    }

    func update(_ new: CGPoint) {
        guard let point else { self.point = new; return }
        if abs(point.x - new.x) > 1.5 || abs(point.y - new.y) > 1.5 { self.point = new }
    }
}

final class HeapScene: SKScene {
    var letters: [(String, UIColor)] = []
    /// Reduce Motion: the heap is shown already landed.
    var quick = false
    weak var top: HeapTop?

    private let motion = CMMotionManager()
    private var shapes: [SKSpriteNode] = []
    private var dragged: SKSpriteNode?
    private var lastTouch: (point: CGPoint, time: TimeInterval)?
    private var throwVelocity = CGVector.zero
    private var startedAt: TimeInterval?
    private var landed = false

    /// The brand palette: the four brights and the four soft fields.
    private static let plainColours: [UIColor] = ([
        0xF4BE2C, 0xBFD9F5, 0x2A62B8, 0xF3D9C9, 0xE5553B, 0xCFE5D2, 0x3C9A5F, 0xF4E7B0,
    ] as [UInt32]).map { UIColor(Color(hex: $0)) }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        // Walls and a floor, with the open top far above the screen so nothing escapes.
        let box = CGRect(x: 0, y: 0, width: size.width, height: size.height * 3)
        physicsBody = SKPhysicsBody(edgeLoopFrom: box)
        physicsBody?.friction = 0.6
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        drop()
        if quick {
            // Run the fall out of sight, then show it landed.
            isPaused = false
            speed = 12
            physicsWorld.speed = 12
            alpha = 0
        }
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 30
            motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let gravity = data?.gravity else { return }
                self?.physicsWorld.gravity = CGVector(dx: gravity.x * 9.8, dy: gravity.y * 9.8)
            }
        }
    }

    override func willMove(from view: SKView) { motion.stopDeviceMotionUpdates() }

    private func drop() {
        let total = max(13, letters.count)
        let side = min(size.width / 3.4, size.height / 3.9) * sqrt(13 / CGFloat(total))
        var seed = SeededRandom(UInt64(letters.map(\.0).joined().hashValue & 0xFFFF) &+ 11)
        // The lettered shapes are spread through the drop, so they don't all end at the bottom.
        let slots = Array(0..<total)
        let letterSlots = Set(letters.indices.map { index in
            letters.count <= 1 ? total / 2 : Int(Double(index) * Double(total - 1) / Double(letters.count - 1))
        })
        var letterIndex = 0
        // Shapes that hold a letter well, in turn, so two of the same initial still differ.
        let letterKinds = HeapShape.forLetters
        for slot in slots {
            var kind = HeapShape.allCases[(slot * 3 + 1) % HeapShape.allCases.count]
            var letter: (String, UIColor)?
            if letterSlots.contains(slot), letterIndex < letters.count {
                letter = letters[letterIndex]
                kind = letterKinds[letterIndex % letterKinds.count]
                letterIndex += 1
            }
            let colour = letter?.1 ?? Self.plainColours[slot % Self.plainColours.count]
            let node = HeapShape.node(kind, side: side * seed.range(0.85, 1.12), colour: colour, letter: letter?.0)
            node.position = CGPoint(x: seed.range(side * 0.6, size.width - side * 0.6), y: size.height + side)
            node.zRotation = seed.range(-0.6, 0.6)
            node.physicsBody?.usesPreciseCollisionDetection = true
            shapes.append(node)
            // One after another from just above the top, so nothing falls fast enough to pass through.
            run(.sequence([.wait(forDuration: 0.11 * Double(slot)), .run { [weak self] in self?.addChild(node) }]))
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if startedAt == nil { startedAt = currentTime }
        let elapsed = (currentTime - (startedAt ?? currentTime)) * Double(speed)
        if !landed, elapsed > 0.11 * Double(shapes.count) + 0.9 {
            let still = shapes.allSatisfy { node in
                guard let body = node.physicsBody else { return true }
                return hypot(body.velocity.dx, body.velocity.dy) < 25 || node.position.y > size.height
            }
            if still || elapsed > 4.5 {
                landed = true
                if quick { speed = 1; physicsWorld.speed = 1; alpha = 1 }
                Task { @MainActor [weak top] in top?.landed = true }
            }
        }
    }

    override func didSimulatePhysics() {
        // She appears once the heap has landed, then rides it as the phone tilts.
        guard landed else { return }
        // The highest shape near the middle, so Puggle stays on the heap and not up a wall.
        let middle = shapes.filter { $0.parent != nil }.filter { abs($0.position.x - size.width / 2) < size.width * 0.3 && $0.position.y < size.height }
        // The shapes are round-ish and fill most of their square, so the top is near half the side above the centre,
        // however the shape has turned. A rotated bounding box would stand her in mid-air.
        func crown(_ node: SKSpriteNode) -> CGFloat { node.position.y + node.size.height * 0.42 }
        guard let highest = (middle.isEmpty ? shapes : middle).max(by: { crown($0) < crown($1) }) else { return }
        let point = CGPoint(x: highest.position.x, y: size.height - crown(highest))
        Task { @MainActor [weak top] in top?.update(point) }
    }

    // MARK: Throwing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard let node = nodes(at: point).compactMap({ $0 as? SKSpriteNode }).first(where: shapes.contains) else { return }
        dragged = node
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.velocity = .zero
        lastTouch = (point, touch.timestamp)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragged, let last = lastTouch else { return }
        let point = touch.location(in: self)
        let dt = max(touch.timestamp - last.time, 1.0 / 120)
        throwVelocity = CGVector(dx: (point.x - last.point.x) / dt, dy: (point.y - last.point.y) / dt)
        dragged.position = point
        dragged.physicsBody?.velocity = .zero
        lastTouch = (point, touch.timestamp)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let dragged else { return }
        dragged.physicsBody?.affectedByGravity = true
        let cap: CGFloat = 2200
        dragged.physicsBody?.velocity = CGVector(dx: max(-cap, min(cap, throwVelocity.dx)), dy: max(-cap, min(cap, throwVelocity.dy)))
        self.dragged = nil
        throwVelocity = .zero
        Haptics.tap()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { touchesEnded(touches, with: event) }
}

/// The shapes of the heap: all convex, so each collides on its true outline.
/// The brand book's soft shapes, drawn flat with no outline, as everywhere in the world around the cast.
/// Each collides on its own drawn edge, so a quatrefoil or a blossom nests into the heap as it looks.
enum HeapShape: String, CaseIterable {
    case quatrefoil, pill, scallop, softSquare = "soft-square", softHexagon = "soft-hexagon", pebble, halfPill = "half-pill", blossom

    /// Shapes that hold a letter well.
    static let forLetters: [HeapShape] = [.quatrefoil, .softSquare, .blossom, .softHexagon, .pebble]

    static func node(_ kind: HeapShape, side: CGFloat, colour: UIColor, letter: String?) -> SKSpriteNode {
        let size = CGSize(width: side, height: side)
        let shape = UIImage(named: "shape-\(kind.rawValue)")?.withTintColor(colour, renderingMode: .alwaysOriginal)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            shape?.draw(in: CGRect(origin: .zero, size: size))
            if let letter {
                let font = UIFont.systemFont(ofSize: side * 0.4, weight: .heavy)
                let rounded = font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: side * 0.4) } ?? font
                let ink = colour.isDark ? UIColor(Palette.fixedPaper) : UIColor(Palette.fixedInk)
                let text = NSAttributedString(string: letter, attributes: [.font: rounded, .foregroundColor: ink])
                let measured = text.size()
                let lift: CGFloat = kind == .halfPill ? side * 0.08 : 0
                text.draw(at: CGPoint(x: (side - measured.width) / 2, y: (side - measured.height) / 2 + lift))
            }
        }
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture, size: size)
        node.physicsBody = SKPhysicsBody(texture: texture, alphaThreshold: 0.5, size: size)
        node.physicsBody?.restitution = 0.15
        node.physicsBody?.friction = 0.7
        node.physicsBody?.density = 1.2
        node.physicsBody?.angularDamping = 0.4
        return node
    }
}

private extension UIColor {
    var isDark: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b < 0.55
    }
}

private extension SeededRandom {
    mutating func range(_ low: CGFloat, _ high: CGFloat) -> CGFloat { CGFloat(range(Double(low), Double(high))) }
}
