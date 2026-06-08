import SwiftUI
import UIKit

struct OverlayTransform: Sendable, Equatable {
    var offset: CGSize
    var scale: CGFloat
    var previewSize: CGSize

    nonisolated static let defaultVerticalOffset: CGFloat = -10
}

enum AspectFillMapper: Sendable {
    nonisolated static func map(point: CGPoint, from previewSize: CGSize, to photoSize: CGSize) -> CGPoint {
        guard previewSize.width > 0, previewSize.height > 0 else { return point }

        let previewAspect = previewSize.width / previewSize.height
        let photoAspect = photoSize.width / photoSize.height

        if photoAspect > previewAspect {
            let visibleWidth = photoSize.height * previewAspect
            let xOffset = (photoSize.width - visibleWidth) / 2
            let scale = photoSize.height / previewSize.height
            return CGPoint(
                x: point.x * scale + xOffset,
                y: point.y * scale
            )
        } else {
            let visibleHeight = photoSize.width / previewAspect
            let yOffset = (photoSize.height - visibleHeight) / 2
            let scale = photoSize.width / previewSize.width
            return CGPoint(
                x: point.x * scale,
                y: point.y * scale + yOffset
            )
        }
    }

    nonisolated static func scaleFactor(from previewSize: CGSize, to photoSize: CGSize) -> CGFloat {
        guard previewSize.width > 0, previewSize.height > 0 else { return 1 }

        let previewAspect = previewSize.width / previewSize.height
        let photoAspect = photoSize.width / photoSize.height

        if photoAspect > previewAspect {
            return photoSize.height / previewSize.height
        } else {
            return photoSize.width / previewSize.width
        }
    }
}

@MainActor
enum PhotoCompositor {
    static func normalizedImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image.normalizedUpOrientation()
    }

    static func composite(photo: UIImage, transform: OverlayTransform) -> UIImage? {
        let photoSize = photo.size
        guard photoSize.width > 0, photoSize.height > 0 else { return nil }

        let previewCenter = CGPoint(
            x: transform.previewSize.width / 2 + transform.offset.width,
            y: transform.previewSize.height / 2 + transform.offset.height
        )

        let mappedCenter = AspectFillMapper.map(
            point: previewCenter,
            from: transform.previewSize,
            to: photoSize
        )

        let mappedScale = transform.scale * AspectFillMapper.scaleFactor(
            from: transform.previewSize,
            to: photoSize
        )

        let content = CompositeContentView(
            photo: photo,
            overlayCenter: mappedCenter,
            overlayScale: mappedScale,
            canvasSize: photoSize
        )

        return renderToImage(content, size: photoSize, scale: photo.scale)
    }

    static func renderToImage<V: View>(_ view: V, size: CGSize, scale: CGFloat) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.bounds = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .clear

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = hostingController
        window.isHidden = false
        window.layoutIfNeeded()
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = max(scale, 1)
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            hostingController.view.drawHierarchy(
                in: hostingController.view.bounds,
                afterScreenUpdates: true
            )
        }
    }
}

private struct CompositeContentView: View {
    let photo: UIImage
    let overlayCenter: CGPoint
    let overlayScale: CGFloat
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()

            WWDC26GlassOverlay(scale: overlayScale)
                .position(overlayCenter)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}

private extension UIImage {
    func normalizedUpOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
