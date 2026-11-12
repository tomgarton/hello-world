import CoreData
import SwiftUI
import UIKit

/// Holds the screen's edges against stray swipes: a swipe up from the bottom
/// (or down from the top) first shows the Home bar, and only a second swipe
/// leaves. iOS only asks the screen on top for this, so the screen has to be
/// shown by this controller for it to work; a SwiftUI full-screen cover
/// doesn't pass the request on.
final class ProtectedHostingController<Content: View>: UIHostingController<Content> {
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { false }
    override var childForScreenEdgesDeferringSystemGestures: UIViewController? { nil }
    override var childForHomeIndicatorAutoHidden: UIViewController? { nil }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
}

/// Closes a screen shown with `protectedCover`. Inside one, call this rather
/// than `dismiss`, which only knows about SwiftUI's own presentations.
private struct CloseCoverKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var closeCover: (() -> Void)? {
        get { self[CloseCoverKey.self] }
        set { self[CloseCoverKey.self] = newValue }
    }
}

/// Like `fullScreenCover(item:)`, but the screen holds back the Home swipe.
private struct ProtectedCover<Item: Identifiable, Cover: View>: ViewModifier {
    @Binding var item: Item?
    let cover: (Item) -> Cover

    @EnvironmentObject private var store: FamilyStore
    @EnvironmentObject private var sample: SampleFamily
    @Environment(\.managedObjectContext) private var context
    @Environment(\.puggleNight) private var night
    @State private var shown: UIViewController?

    func body(content: Content) -> some View {
        content
            .onChange(of: item?.id) { _, id in
                if id != nil { present() } else { close(animated: true) }
            }
            .onAppear { if item != nil { present() } }
    }

    private func present() {
        guard shown == nil, let item, let top = Self.topController() else { return }
        let binding = $item
        let screen = cover(item)
            .environmentObject(store)
            .environmentObject(sample)
            .environment(\.managedObjectContext, context)
            .environment(\.puggleNight, night)
            .environment(\.closeCover) { binding.wrappedValue = nil }
            .tint(Palette.ink)
            .toggleStyle(PuggleToggleStyle())
            .foregroundStyle(Palette.ink)
        let controller = ProtectedHostingController(rootView: AnyView(screen))
        controller.modalPresentationStyle = .fullScreen
        shown = controller
        top.present(controller, animated: true)
    }

    private func close(animated: Bool) {
        guard let controller = shown else { return }
        shown = nil
        controller.presentingViewController?.dismiss(animated: animated)
    }

    private static func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        // The app's own window, not the privacy cover above it.
        var top = scene?.windows.first { $0.windowLevel == .normal }?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}

/// For a yes/no flag rather than an item.
private struct Flag: Identifiable { let id = 0 }

extension View {
    func protectedCover<Item: Identifiable, Cover: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Cover) -> some View {
        modifier(ProtectedCover(item: item, cover: content))
    }

    func protectedCover<Cover: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Cover) -> some View {
        let item = Binding<Flag?>(get: { isPresented.wrappedValue ? Flag() : nil },
                                  set: { isPresented.wrappedValue = $0 != nil })
        return modifier(ProtectedCover(item: item, cover: { _ in content() }))
    }
}
