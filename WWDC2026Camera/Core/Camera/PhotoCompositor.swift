import UIKit

struct OverlayTransform: Sendable, Equatable {
    var offset: CGSize
    var scale: CGFloat
    var previewSize: CGSize
    var showBase: Bool = true

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

enum PhotoCompositor {
    nonisolated static func normalizedImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image.normalizedUpOrientation()
    }

    nonisolated static func overlayRect(for transform: OverlayTransform, photoSize: CGSize) -> CGRect? {
        guard photoSize.width > 0, photoSize.height > 0 else { return nil }

        let previewSize = effectivePreviewSize(transform.previewSize)
        let previewCenter = CGPoint(
            x: previewSize.width / 2 + transform.offset.width,
            y: previewSize.height / 2 + transform.offset.height
        )

        let mappedCenter = AspectFillMapper.map(
            point: previewCenter,
            from: previewSize,
            to: photoSize
        )

        let mappedScale = transform.scale * AspectFillMapper.scaleFactor(
            from: previewSize,
            to: photoSize
        )

        let unitSize = WWDC26ObjectMetrics.unitSize(showBase: transform.showBase)
        let overlayWidth = unitSize.width * mappedScale
        let overlayHeight = unitSize.height * mappedScale

        var patchRect = CGRect(
            x: mappedCenter.x - overlayWidth / 2,
            y: mappedCenter.y - overlayHeight / 2,
            width: overlayWidth,
            height: overlayHeight
        )
        patchRect = patchRect.intersection(CGRect(origin: .zero, size: photoSize))

        guard patchRect.width > 0, patchRect.height > 0 else { return nil }
        return patchRect
    }

    nonisolated static func composite(
        photo: UIImage,
        overlaySnapshot: UIImage?,
        transform: OverlayTransform
    ) -> UIImage? {
        let photoSize = photo.size
        guard let patchRect = overlayRect(for: transform, photoSize: photoSize) else {
            return photo
        }

        if let overlaySnapshot {
            return drawPhotoWithOverlaySnapshot(
                photo: photo,
                overlaySnapshot: overlaySnapshot,
                patchRect: patchRect
            )
        }

        let unitWidth = WWDC26ObjectMetrics.unitSize(showBase: transform.showBase).width
        return drawPhotoWithOverlayFallback(
            photo: photo,
            patchRect: patchRect,
            overlayScale: patchRect.width / unitWidth
        )
    }

    nonisolated private static func effectivePreviewSize(_ previewSize: CGSize) -> CGSize {
        if previewSize.width > 0, previewSize.height > 0 {
            return previewSize
        }
        return CGSize(width: 390, height: 844)
    }

    nonisolated private static func drawPhotoWithOverlaySnapshot(
        photo: UIImage,
        overlaySnapshot: UIImage,
        patchRect: CGRect
    ) -> UIImage? {
        let photoSize = photo.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = photo.scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: photoSize, format: format).image { _ in
            photo.draw(in: CGRect(origin: .zero, size: photoSize))
            overlaySnapshot.draw(in: patchRect)
        }
    }

    nonisolated private static func drawPhotoWithOverlayFallback(
        photo: UIImage,
        patchRect: CGRect,
        overlayScale: CGFloat
    ) -> UIImage? {
        let photoSize = photo.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = photo.scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: photoSize, format: format).image { context in
            photo.draw(in: CGRect(origin: .zero, size: photoSize))
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: patchRect.midX, y: patchRect.midY)
            context.cgContext.scaleBy(x: overlayScale, y: overlayScale)
            context.cgContext.translateBy(
                x: -WWDC26SlabMetrics.defaultWidth / 2,
                y: -WWDC26SlabMetrics.defaultHeight / 2
            )
            context.cgContext.setAlpha(0.35)
            context.cgContext.fill(
                CGRect(
                    x: 0,
                    y: 0,
                    width: WWDC26SlabMetrics.defaultWidth,
                    height: WWDC26SlabMetrics.defaultHeight
                )
            )
            context.cgContext.restoreGState()
        }
    }
}

extension UIImage {
    nonisolated func normalizedUpOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
