import SwiftUI

enum WWDC26ObjectMetrics: Sendable {
    nonisolated static let baseWidth: CGFloat = 247
    nonisolated static let baseHeight: CGFloat = 115
    nonisolated static let baseCornerRadius: CGFloat = 26
    nonisolated static let trayHorizontalInset: CGFloat = 14
    nonisolated static let trayCornerRadius: CGFloat = 18
    nonisolated static let trayHeightRatio: CGFloat = 0.38
    nonisolated static let lowerBodyHeightRatio: CGFloat = 0.72
    nonisolated static let slotHeight: CGFloat = 10
    nonisolated static let slotWidthRatio: CGFloat = 0.55
    nonisolated static let baseOverlap: CGFloat = 46

    nonisolated static var slabSize: CGSize {
        CGSize(
            width: WWDC26SlabMetrics.defaultWidth,
            height: WWDC26SlabMetrics.defaultHeight
        )
    }

    nonisolated static var baseSize: CGSize {
        CGSize(width: baseWidth, height: baseHeight)
    }

    nonisolated static func unitSize(showBase: Bool) -> CGSize {
        guard showBase else { return slabSize }

        return CGSize(
            width: max(slabSize.width, baseSize.width),
            height: slabSize.height + baseSize.height - baseOverlap
        )
    }

    nonisolated static var baseVerticalOffset: CGFloat {
        slabSize.height - baseOverlap
    }

    nonisolated static func lowerBodyRect(in rect: CGRect) -> CGRect {
        let height = rect.height * lowerBodyHeightRatio
        return CGRect(
            x: rect.minX,
            y: rect.maxY - height,
            width: rect.width,
            height: height
        )
    }

    nonisolated static func trayRect(in rect: CGRect) -> CGRect {
        let trayHeight = rect.height * trayHeightRatio
        return CGRect(
            x: rect.minX + trayHorizontalInset,
            y: rect.minY,
            width: rect.width - trayHorizontalInset * 2,
            height: trayHeight
        )
    }
}

struct WWDC26BaseShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var combined = Path()
        combined.addRoundedRect(
            in: WWDC26ObjectMetrics.lowerBodyRect(in: rect),
            cornerSize: CGSize(
                width: WWDC26ObjectMetrics.baseCornerRadius,
                height: WWDC26ObjectMetrics.baseCornerRadius
            )
        )
        combined.addRoundedRect(
            in: WWDC26ObjectMetrics.trayRect(in: rect),
            cornerSize: CGSize(
                width: WWDC26ObjectMetrics.trayCornerRadius,
                height: WWDC26ObjectMetrics.trayCornerRadius
            )
        )
        return combined
    }
}
