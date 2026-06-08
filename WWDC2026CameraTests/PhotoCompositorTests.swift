import CoreGraphics
import Testing
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
