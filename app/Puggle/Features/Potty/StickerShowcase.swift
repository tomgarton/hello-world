import CoreMotion
import SceneKit
import SwiftUI

/// How a sticker catches the light when it turns.
extension StickerStyle {
    /// Rainbow shimmer across the foil: strong for rainbow and pearl, softer for the rest.
    var holo: Float {
        switch foil {
        case .rainbow?, .pearl?: 1
        case .sea?, .sunset?: 0.75
        case .gold?: 0.45
        case nil: 0
        }
    }

    /// Specks that glint as it turns: gold and sunset are the glittery ones.
    var glitter: Float {
        switch foil {
        case .gold?, .sunset?: 1
        case .rainbow?, .sea?, .pearl?: 0.45
        case nil: 0
        }
    }
}

/// The back of a sticker, as a picture for the 3D sticker: card with the
/// details pressed into it, the way a medal's back is engraved.
private struct StickerBack: View {
    let sticker: EarnedSticker
    let size: CGFloat

    private var shape: some View { Image(sticker.style.shape).resizable().scaledToFit() }

    /// Pressed into the card: dark text with a light edge below it.
    private func engraved(_ text: String, size points: CGFloat, weight: Font.Weight, tracking: CGFloat = 0, opacity: Double = 1) -> some View {
        let font = Font.system(size: points, weight: weight, design: .rounded)
        return ZStack {
            Text(text).font(font).tracking(tracking).foregroundStyle(.white.opacity(0.85)).offset(y: points * 0.06)
            Text(text).font(font).tracking(tracking).foregroundStyle(Color(hex: 0x6E6252).opacity(opacity))
        }
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .minimumScaleFactor(0.6)
    }

    var body: some View {
        ZStack {
            shape.foregroundStyle(Color(hex: 0xF4EFE4))
            shape.foregroundStyle(Color(hex: 0xE9E2D3)).scaleEffect(0.86)
            // A fine pressed line just inside the edge.
            shape.foregroundStyle(Color(hex: 0xDCD3C2)).scaleEffect(0.8)
            shape.foregroundStyle(Color(hex: 0xE9E2D3)).scaleEffect(0.785)
            VStack(spacing: size * 0.022) {
                if !sticker.child.isEmpty {
                    engraved(sticker.child.uppercased(), size: size * 0.045, weight: .bold, tracking: size * 0.008, opacity: 0.75)
                }
                engraved(sticker.title, size: size * 0.085, weight: .heavy)
                if !sticker.detail.isEmpty {
                    engraved(sticker.detail, size: size * 0.048, weight: .medium, opacity: 0.85)
                        .padding(.horizontal, size * 0.02)
                }
                if let date = sticker.earnedOn {
                    engraved(date.formatted(.dateTime.day().month(.abbreviated).year()), size: size * 0.042, weight: .semibold, opacity: 0.75)
                        .padding(.top, size * 0.012)
                }
            }
            .frame(width: size * 0.5)
        }
        .frame(width: size, height: size)
    }
}

/// Builds the sticker as a real object: a front with its foil, a back, and a
/// thin edge, under a light, so turning it shows depth and moving highlights.
@MainActor
private enum StickerModel {
    static let textureSize: CGFloat = 768
    /// Card, not a coin.
    static let thickness: Float = 0.016

    /// Bends the flat sticker into a gentle curve: each point moves back by
    /// how far it is from the middle, squared, so it flexes like card.
    static let flex = """
    uniform float bend;
    uniform float bendSign;
    #pragma body
    float x = _geometry.position.x;
    _geometry.position.z += bend * bendSign * x * x * 1.6;
    float3 n = _geometry.normal;
    n.x -= bend * bendSign * x * 3.2 * n.z;
    _geometry.normal = normalize(n);
    """

    /// Every material on the sticker, so the bend can be set on all of them at once.
    static func materials(in node: SCNNode) -> [SCNMaterial] {
        (node.geometry?.materials ?? []) + node.childNodes.flatMap { materials(in: $0) }
    }

    /// Shimmer and glitter, worked out per pixel from the angle it is seen at.
    static let foil = """
    uniform float holo;
    uniform float glitter;
    #pragma body
    float3 V = normalize(_surface.view);
    float3 N = normalize(_surface.normal);
    float2 uv = _surface.diffuseTexcoord;
    float4 base = _surface.diffuse;
    float lum = dot(base.rgb, float3(0.299, 0.587, 0.114));
    // Only the foil: not the white edge, and not the dark lines of the picture.
    float foilArea = (1.0 - smoothstep(0.86, 0.97, min(base.r, min(base.g, base.b)))) * smoothstep(0.32, 0.55, lum);
    float facing = clamp(dot(N, V), 0.0, 1.0);
    // Bands of colour that slide across as the angle changes.
    float t = uv.x * 1.6 + uv.y * 1.1 + V.x * 2.6 - V.y * 2.0 + (1.0 - facing) * 1.5;
    float3 rainbow = 0.5 + 0.5 * cos(6.28318 * (t + float3(0.0, 0.33, 0.67)));
    float3 shimmer = mix(base.rgb, base.rgb * 0.55 + rainbow * 0.6, holo * foilArea * 0.85);
    // Glitter: tiny cells, each lit only at its own angle.
    float2 grid = uv * 140.0;
    float2 cell = floor(grid);
    float h = fract(sin(dot(cell, float2(12.9898, 78.233))) * 43758.5453);
    float h2 = fract(h * 91.7);
    // A round speck, somewhere in its cell, a different size each.
    float2 spot = float2(fract(h * 13.1), fract(h * 27.3)) * 0.5 + 0.25;
    float dot = 1.0 - smoothstep(0.08 + h2 * 0.1, 0.2 + h2 * 0.12, length(grid - cell - spot));
    float glint = pow(max(0.0, cos(h * 41.0 + V.x * 26.0 + V.y * 21.0)), 220.0) * step(0.62, h2) * dot;
    float3 spark = float3(1.0, 0.97, 0.9) * glint * glitter * foilArea * 1.6;
    _surface.diffuse = float4(shimmer, base.a);
    _surface.emission = float4(spark + rainbow * holo * foilArea * 0.12 * (1.0 - facing), 1.0);
    """

    /// Cut-out: anything outside the sticker's shape is not drawn.
    static let cutOut = """
    #pragma body
    if (_output.color.a < 0.5) { discard_fragment(); }
    """

    static func image<V: View>(_ view: V) -> UIImage? {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
        renderer.scale = 1
        renderer.isOpaque = false
        return renderer.uiImage
    }

    static func make(_ sticker: EarnedSticker) -> SCNNode {
        let side = textureSize
        let front = image(StickerView(style: sticker.style, size: side).shadow(radius: 0).compositingGroup())
        let back = image(StickerBack(sticker: sticker, size: side))
        let silhouette = image(Image(sticker.style.shape).resizable().scaledToFit().foregroundStyle(.white).frame(width: side, height: side))

        let root = SCNNode()
        let half = thickness / 2

        // The face, with its foil.
        let frontPlane = SCNPlane(width: 1, height: 1)
        frontPlane.widthSegmentCount = 32
        let frontMaterial = SCNMaterial()
        frontMaterial.diffuse.contents = front
        frontMaterial.lightingModel = .blinn
        frontMaterial.specular.contents = UIColor(white: sticker.style.foil == nil ? 0.25 : 0.7, alpha: 1)
        frontMaterial.shininess = 60
        frontMaterial.shaderModifiers = [.geometry: flex, .surface: foil, .fragment: cutOut]
        frontMaterial.setValue(NSNumber(value: 1), forKey: "bendSign")
        frontMaterial.setValue(NSNumber(value: sticker.style.holo), forKey: "holo")
        frontMaterial.setValue(NSNumber(value: sticker.style.glitter), forKey: "glitter")
        frontPlane.materials = [frontMaterial]
        let frontNode = SCNNode(geometry: frontPlane)
        frontNode.position.z = half
        root.addChildNode(frontNode)

        // The back, facing the other way so it reads the right way round.
        let backPlane = SCNPlane(width: 1, height: 1)
        backPlane.widthSegmentCount = 32
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = back
        backMaterial.lightingModel = .blinn
        backMaterial.specular.contents = UIColor(white: 0.12, alpha: 1)
        backMaterial.shaderModifiers = [.geometry: flex, .fragment: cutOut]
        // Turned round, so its own "back" is the other way.
        backMaterial.setValue(NSNumber(value: -1), forKey: "bendSign")
        backPlane.materials = [backMaterial]
        let backNode = SCNNode(geometry: backPlane)
        backNode.position.z = -half
        backNode.eulerAngles.y = .pi
        root.addChildNode(backNode)

        // The edge: thin slices of the outline between the two faces.
        let slices = 6
        for index in 1..<slices {
            let slice = SCNPlane(width: 1, height: 1)
            slice.widthSegmentCount = 32
            let material = SCNMaterial()
            material.diffuse.contents = silhouette
            material.multiply.contents = UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1)
            material.lightingModel = .lambert
            material.isDoubleSided = true
            material.shaderModifiers = [.geometry: flex, .fragment: cutOut]
            material.setValue(NSNumber(value: 1), forKey: "bendSign")
            slice.materials = [material]
            let node = SCNNode(geometry: slice)
            node.position.z = -half + thickness * Float(index) / Float(slices)
            root.addChildNode(node)
        }
        return root
    }
}

/// The 3D sticker, turned by the finger and tilted a little by the phone.
private struct StickerScene: UIViewRepresentable {
    let sticker: EarnedSticker
    let model: StickerSpin

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isUserInteractionEnabled = false
        view.rendersContinuously = true

        let scene = SCNScene()
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 30
        camera.position = SCNVector3(0, 0, 2.6)
        scene.rootNode.addChildNode(camera)

        // A soft room light, and a key light above and to the left for the highlights.
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 650
        scene.rootNode.addChildNode(ambient)
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 650
        key.eulerAngles = SCNVector3(-0.55, -0.45, 0)
        scene.rootNode.addChildNode(key)

        let sticker = StickerModel.make(self.sticker)
        model.materials = StickerModel.materials(in: sticker)
        model.setBend(0)
        model.tilt.addChildNode(sticker)
        model.spin.addChildNode(model.tilt)
        scene.rootNode.addChildNode(model.spin)
        view.scene = scene
        model.start()
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}

    static func dismantleUIView(_ view: SCNView, coordinator: ()) {
        view.scene = nil
    }
}

/// Holds the turning: the finger turns `spin`, the phone's tilt nudges `tilt`.
@MainActor
final class StickerSpin: ObservableObject {
    let spin = SCNNode()
    let tilt = SCNNode()
    private let motion = CMMotionManager()
    private var reference: CMAttitude?
    private var startYaw: Float = 0
    private var startPitch: Float = 0
    var reduceMotion = false
    var materials: [SCNMaterial] = []
    // The flex: how bent it is now, and the last finger position and time, for speed.
    private var bend: Float = 0
    private var lastX: CGFloat = 0
    private var lastTime: TimeInterval = 0
    private var wobble: Timer?

    func setBend(_ value: Float) {
        bend = value
        for material in materials { material.setValue(NSNumber(value: value), forKey: "bend") }
    }

    /// Lets go of the bend: it springs back past flat and settles, like card.
    private func release(from start: Float) {
        wobble?.invalidate()
        guard !reduceMotion, abs(start) > 0.005 else { setBend(0); return }
        let began = CACurrentMediaTime()
        wobble = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { timer.invalidate(); return }
                let t = Float(CACurrentMediaTime() - began)
                let value = start * exp(-5.5 * t) * cos(15 * t)
                self.setBend(value)
                if t > 1.2 { self.setBend(0); timer.invalidate() }
            }
        }
    }

    func start() {
        guard !reduceMotion else { return }
        // Handed over with a spin.
        spin.eulerAngles.y = -2 * .pi
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.3
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.25, 1)
        spin.eulerAngles.y = 0
        SCNTransaction.commit()
        // Tilting the phone moves the light across the foil.
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1 / 60
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let attitude = data?.attitude else { return }
            if reference == nil { reference = attitude.copy() as? CMAttitude }
            if let reference { attitude.multiply(byInverseOf: reference) }
            tilt.eulerAngles = SCNVector3(Float(max(-0.35, min(0.35, attitude.pitch * 0.6))),
                                          Float(max(-0.35, min(0.35, attitude.roll * 0.6))), 0)
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        wobble?.invalidate()
    }

    func began() {
        wobble?.invalidate()
        lastX = 0
        lastTime = CACurrentMediaTime()
        spin.removeAllActions()
        startYaw = spin.presentation.eulerAngles.y
        startPitch = spin.presentation.eulerAngles.x
        spin.eulerAngles = spin.presentation.eulerAngles
    }

    func moved(_ translation: CGSize) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        spin.eulerAngles.y = startYaw + Float(translation.width) * 0.011
        spin.eulerAngles.x = max(-0.9, min(0.9, startPitch + Float(translation.height) * 0.008))
        SCNTransaction.commit()
        // Bends with the speed of the finger, a little behind it.
        let now = CACurrentMediaTime()
        let elapsed = max(now - lastTime, 1 / 120)
        let speed = Float((translation.width - lastX) / elapsed)
        lastX = translation.width
        lastTime = now
        guard !reduceMotion else { return }
        let target = max(-0.22, min(0.22, -speed * 0.00012))
        setBend(bend * 0.75 + target * 0.25)
    }

    /// Let go: it carries on with the flick, slows, and comes to rest face up or face down.
    func ended(velocity: CGSize) {
        // A flick gives the bend one more push before it springs back.
        release(from: max(-0.22, min(0.22, bend - Float(velocity.width) * 0.00004)))
        let current = spin.eulerAngles.y
        let coast = current + Float(velocity.width) * 0.011 * 0.28
        let rest = (coast / .pi).rounded() * .pi
        let distance = abs(rest - current)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = Double(min(2.2, max(0.6, distance * 0.45)))
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.15, 0.85, 0.3, 1)
        spin.eulerAngles.y = rest
        spin.eulerAngles.x = 0
        SCNTransaction.commit()
        if distance > 0.3 { Haptics.tap() }
    }

    func turnOver() {
        began()
        ended(velocity: CGSize(width: CGFloat.pi / 0.011 / 0.28, height: 0))
    }
}

/// One earned sticker, large, to turn over in your fingers.
struct StickerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let sticker: EarnedSticker
    @StateObject private var model = StickerSpin()
    @State private var dragging = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Spacer(minLength: 0)
                StickerScene(sticker: sticker, model: model)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 420)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !dragging { dragging = true; model.began() }
                                model.moved(value.translation)
                            }
                            .onEnded { value in
                                dragging = false
                                model.ended(velocity: value.velocity)
                            }
                    )
                    .accessibilityElement()
                    .accessibilityLabel("\(sticker.title) sticker")
                    .accessibilityHint("Drag to turn it over")
                    .accessibilityAction(named: "Turn over") { model.turnOver() }
                VStack(spacing: 6) {
                    Text(sticker.title)
                        .displayFont(28)
                        .multilineTextAlignment(.center)
                    if let date = sticker.earnedOn {
                        Text(sticker.child.isEmpty ? date.formatted(date: .long, time: .omitted)
                                                   : "\(sticker.child) · \(date.formatted(date: .long, time: .omitted))")
                            .foregroundStyle(Palette.muted)
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
                Text("Turn it with your finger, or tilt the phone")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Palette.sand)
            .foregroundStyle(Palette.ink)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .onAppear { model.reduceMotion = reduceMotion }
        .onDisappear { model.stop() }
    }
}
