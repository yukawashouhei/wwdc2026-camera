import CoreGraphics
import Testing
import UIKit
@testable import WWDC2026Camera

@Suite("AspectFillMapper")
struct PhotoCompositorTests {
    @Test("Maps center when photo is wider than preview")
    func mapCenterWidePhoto() {
        let previewSize = CGSize(width: 390, height: 844)
        let photoSize = CGSize(width: 4032, height: 3024)
        let previewCenter = CGPoint(x: 195, y: 422)

        let mapped = AspectFillMapper.map(
            point: previewCenter,
            from: previewSize,
            to: photoSize
        )

        #expect(mapped.x > 0)
        #expect(mapped.y > 0)
        #expect(mapped.x < photoSize.width)
        #expect(mapped.y < photoSize.height)
    }

    @Test("Maps center when photo is taller than preview")
    func mapCenterTallPhoto() {
        let previewSize = CGSize(width: 844, height: 390)
        let photoSize = CGSize(width: 3024, height: 4032)
        let previewCenter = CGPoint(x: 422, y: 195)

        let mapped = AspectFillMapper.map(
            point: previewCenter,
            from: previewSize,
            to: photoSize
        )

        #expect(mapped.x > 0)
        #expect(mapped.y > 0)
        #expect(mapped.x < photoSize.width)
        #expect(mapped.y < photoSize.height)
    }

    @Test("Scale factor is positive for square preview")
    func scaleFactorSquarePreview() {
        let previewSize = CGSize(width: 400, height: 400)
        let photoSize = CGSize(width: 3000, height: 4000)

        let scale = AspectFillMapper.scaleFactor(from: previewSize, to: photoSize)
        #expect(scale > 0)
    }

    @Test("Preserves preview center in square aspect ratios")
    func preservesCenterForSquareAspects() {
        let size = CGSize(width: 500, height: 500)
        let center = CGPoint(x: 250, y: 250)

        let mapped = AspectFillMapper.map(point: center, from: size, to: size)
        #expect(mapped.x == 250)
        #expect(mapped.y == 250)
    }
}

@Suite("WWDC26ObjectMetrics")
struct WWDC26ObjectMetricsTests {
    @Test("Unit with base is taller than slab-only unit")
    func unitWithBaseIsTaller() {
        let slabOnly = WWDC26ObjectMetrics.unitSize(showBase: false)
        let withBase = WWDC26ObjectMetrics.unitSize(showBase: true)

        #expect(withBase.height > slabOnly.height)
        #expect(withBase.width >= slabOnly.width)
    }

    @Test("Base is wider than glass slab for centered mounting")
    func baseIsWiderThanSlab() {
        #expect(WWDC26ObjectMetrics.baseSize.width > WWDC26ObjectMetrics.slabSize.width)
    }

    @Test("Base shape produces non-empty path")
    func baseShapeIsNonEmpty() {
        let rect = CGRect(origin: .zero, size: WWDC26ObjectMetrics.baseSize)
        let path = WWDC26BaseShape().path(in: rect)

        #expect(!path.isEmpty)
        #expect(path.boundingRect.width > 0)
        #expect(path.boundingRect.height > 0)
    }
}

@Suite("WWDC26SlabMetrics")
struct WWDC26SlabMetricsTests {
    @Test("Maintains SVG viewBox aspect ratio")
    func maintainsSVGAspectRatio() {
        let expected = 506.0 / 728.0
        #expect(abs(WWDC26SlabMetrics.aspectRatio - expected) < 0.0001)
        #expect(abs(WWDC26SlabMetrics.defaultHeight - (220 / expected)) < 0.0001)
    }

    @Test("Slab body shape produces non-empty path")
    func slabBodyShapeIsNonEmpty() {
        let rect = CGRect(x: 0, y: 0, width: 220, height: WWDC26SlabMetrics.defaultHeight)
        let path = WWDC26SlabBodyShape().path(in: rect)
        #expect(!path.isEmpty)
        #expect(path.boundingRect.width > 0)
        #expect(path.boundingRect.height > 0)
    }
}

@Suite("OverlayTransform")
struct OverlayTransformTests {
    @Test("Default vertical offset shifts preview center upward")
    func defaultOffsetShiftsCenterUpward() {
        let previewSize = CGSize(width: 390, height: 844)
        let photoSize = CGSize(width: 390, height: 844)
        let defaultCenter = CGPoint(
            x: previewSize.width / 2,
            y: previewSize.height / 2 + OverlayTransform.defaultVerticalOffset
        )
        let originCenter = CGPoint(
            x: previewSize.width / 2,
            y: previewSize.height / 2
        )

        let mappedDefault = AspectFillMapper.map(
            point: defaultCenter,
            from: previewSize,
            to: photoSize
        )
        let mappedOrigin = AspectFillMapper.map(
            point: originCenter,
            from: previewSize,
            to: photoSize
        )

        #expect(mappedDefault.y < mappedOrigin.y)
        #expect(abs(mappedOrigin.y - mappedDefault.y - 10) < 0.001)
    }
}

@Suite("PhotoCompositor")
struct PhotoCompositorCompositeTests {
    @Test("Overlay rect height changes when base is toggled")
    func overlayRectHeightChangesWithBase() {
        let photoSize = CGSize(width: 4032, height: 3024)
        let previewSize = CGSize(width: 390, height: 844)
        let offset = CGSize(width: 0, height: OverlayTransform.defaultVerticalOffset)

        let withBase = PhotoCompositor.overlayRect(
            for: OverlayTransform(
                offset: offset,
                scale: 1.0,
                previewSize: previewSize,
                showBase: true
            ),
            photoSize: photoSize
        )
        let withoutBase = PhotoCompositor.overlayRect(
            for: OverlayTransform(
                offset: offset,
                scale: 1.0,
                previewSize: previewSize,
                showBase: false
            ),
            photoSize: photoSize
        )

        #expect(withBase != nil)
        #expect(withoutBase != nil)
        #expect(withBase!.height > withoutBase!.height)
    }

    @Test("Overlay rect stays within photo bounds")
    func overlayRectWithinBounds() {
        let photoSize = CGSize(width: 4032, height: 3024)
        let transform = OverlayTransform(
            offset: CGSize(width: 0, height: OverlayTransform.defaultVerticalOffset),
            scale: 1.0,
            previewSize: CGSize(width: 390, height: 844)
        )

        let rect = PhotoCompositor.overlayRect(for: transform, photoSize: photoSize)

        #expect(rect != nil)
        #expect(rect!.minX >= 0)
        #expect(rect!.minY >= 0)
        #expect(rect!.maxX <= photoSize.width)
        #expect(rect!.maxY <= photoSize.height)
    }

    @Test("Composite with overlay snapshot preserves photo dimensions")
    func compositePreservesPhotoDimensions() {
        let photoSize = CGSize(width: 400, height: 300)
        let photo = makeSolidImage(size: photoSize, color: .green)
        let overlay = makeSolidImage(size: CGSize(width: 80, height: 120), color: .red)
        let transform = OverlayTransform(
            offset: .zero,
            scale: 1.0,
            previewSize: photoSize
        )

        let result = PhotoCompositor.composite(
            photo: photo,
            overlaySnapshot: overlay,
            transform: transform
        )

        #expect(result != nil)
        #expect(result?.size == photoSize)
    }

    @Test("Composite without snapshot still returns photo")
    func compositeWithoutSnapshotUsesFallback() {
        let photoSize = CGSize(width: 400, height: 300)
        let photo = makeSolidImage(size: photoSize, color: .blue)
        let transform = OverlayTransform(
            offset: .zero,
            scale: 1.0,
            previewSize: photoSize
        )

        let result = PhotoCompositor.composite(
            photo: photo,
            overlaySnapshot: nil,
            transform: transform
        )

        #expect(result != nil)
        #expect(result?.size == photoSize)
    }
}

private func makeSolidImage(size: CGSize, color: UIColor) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}
