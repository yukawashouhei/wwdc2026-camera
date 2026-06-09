import SwiftUI

enum WWDC26BaseSVGPaths: Sendable {
    nonisolated static let viewBoxWidth: CGFloat = 568
    nonisolated static let viewBoxHeight: CGFloat = 265

    nonisolated static let bottomRim =
        "M9.52527 213.682V227.182C11.6919 238.848 27.1253 262.482 71.5253 263.682C115.925 264.882 369.025 255.848 490.025 251.182C511.192 249.182 554.525 237.682 558.525 207.682"

    nonisolated static let lowerBody =
        "M1.02523 116.182V191.682C-0.141435 199.182 3.02523 215.482 25.0252 220.682C47.0252 225.882 371.525 220.848 531.025 217.682C542.692 215.348 566.225 206.982 567.025 192.182C567.825 177.382 565.692 134.682 564.525 115.182"

    nonisolated static let slot =
        "M153.025 75.6818V43.1818C172.225 43.1818 331.859 42.1818 408.525 42.1818V75.6818H153.025Z"

    nonisolated static let dome =
        "M44.0253 22.1818C51.2253 9.78181 61.692 7.01515 66.0253 7.18181C199.025 4.51515 468.325 -0.518184 481.525 0.681816C494.725 1.88182 506.692 11.8485 511.025 16.6818C526.525 40.0152 558.825 91.5818 564.025 111.182C569.225 130.782 514.192 142.348 486.025 145.682L63.5253 148.682C1.92531 142.282 -3.14136 119.015 2.02531 108.182C13.0253 84.6818 36.8253 34.5818 44.0253 22.1818Z"

    nonisolated static let silhouettePaths: [String] = [dome, lowerBody, bottomRim]
}

enum WWDC26ObjectMetrics: Sendable {
    nonisolated static let slabToBaseScale = WWDC26SlabMetrics.defaultWidth / WWDC26SlabMetrics.viewBoxWidth

    nonisolated static var slabSize: CGSize {
        CGSize(
            width: WWDC26SlabMetrics.defaultWidth,
            height: WWDC26SlabMetrics.defaultHeight
        )
    }

    nonisolated static var baseSize: CGSize {
        CGSize(
            width: WWDC26BaseSVGPaths.viewBoxWidth * slabToBaseScale,
            height: WWDC26BaseSVGPaths.viewBoxHeight * slabToBaseScale
        )
    }

    nonisolated static let baseOverlap: CGFloat = 46

    nonisolated static func unitSize(showBase: Bool) -> CGSize {
        guard showBase else { return slabSize }

        return CGSize(
            width: max(slabSize.width, baseSize.width),
            height: slabSize.height + baseSize.height - baseOverlap
        )
    }

    nonisolated static func glassHorizontalOffset(showBase: Bool) -> CGFloat {
        let unitWidth = unitSize(showBase: showBase).width
        return (unitWidth - slabSize.width) / 2
    }

    nonisolated static var baseVerticalOffset: CGFloat {
        slabSize.height - baseOverlap
    }
}

struct WWDC26BaseShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var combined = Path()
        for svgPath in WWDC26BaseSVGPaths.silhouettePaths {
            combined.addPath(
                SVGPathParser.path(
                    from: svgPath,
                    in: rect,
                    viewBoxWidth: WWDC26BaseSVGPaths.viewBoxWidth,
                    viewBoxHeight: WWDC26BaseSVGPaths.viewBoxHeight
                )
            )
        }
        return combined
    }
}
