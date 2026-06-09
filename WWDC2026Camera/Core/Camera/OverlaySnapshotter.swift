import SwiftUI
import UIKit

enum OverlaySnapshotter {
    static let glassOverlayIdentifier = "wwdc26.glass.overlay"

    @MainActor
    static func snapshot(identifier: String = glassOverlayIdentifier) -> UIImage? {
        guard let window = keyWindow else { return nil }
        guard let view = findView(withAccessibilityIdentifier: identifier, in: window) else { return nil }
        return renderSnapshot(of: view)
    }

    @MainActor
    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    @MainActor
    private static func findView(withAccessibilityIdentifier identifier: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == identifier {
            return root
        }

        for subview in root.subviews {
            if let found = findView(withAccessibilityIdentifier: identifier, in: subview) {
                return found
            }
        }

        return nil
    }

    @MainActor
    private static func renderSnapshot(of view: UIView) -> UIImage? {
        guard view.window != nil else { return nil }

        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = view.window?.screen.scale ?? UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}

struct GlassOverlayHost: UIViewControllerRepresentable {
    var scale: CGFloat
    var identifier: String = OverlaySnapshotter.glassOverlayIdentifier

    func makeUIViewController(context: Context) -> UIHostingController<WWDC26GlassOverlay> {
        let host = UIHostingController(rootView: WWDC26GlassOverlay(scale: scale))
        host.view.backgroundColor = .clear
        host.view.accessibilityIdentifier = identifier
        return host
    }

    func updateUIViewController(_ host: UIHostingController<WWDC26GlassOverlay>, context: Context) {
        host.rootView = WWDC26GlassOverlay(scale: scale)
        host.view.accessibilityIdentifier = identifier
    }
}
