import SwiftUI

struct WWDC26BaseView: View {
    private let size = WWDC26ObjectMetrics.baseSize

    var body: some View {
        ZStack(alignment: .bottom) {
            groundShadow

            lowerPedestalBlock

            upperTrayBlock

            reflectionBand

            glassSlot

            topEdgeHighlights
        }
        .frame(width: size.width, height: size.height)
    }

    private var groundShadow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        .black.opacity(0.35),
                        .black.opacity(0.12),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.45
                )
            )
            .frame(width: size.width * 0.92, height: size.height * 0.14)
            .offset(y: -2)
    }

    private var lowerPedestalBlock: some View {
        RoundedRectangle(cornerRadius: WWDC26ObjectMetrics.baseCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.18),
                        Color(white: 0.08),
                        Color(white: 0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size.width, height: size.height * WWDC26ObjectMetrics.lowerBodyHeightRatio)
    }

    private var upperTrayBlock: some View {
        let trayWidth = size.width - WWDC26ObjectMetrics.trayHorizontalInset * 2
        let trayHeight = size.height * WWDC26ObjectMetrics.trayHeightRatio

        return RoundedRectangle(cornerRadius: WWDC26ObjectMetrics.trayCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.28),
                        Color(white: 0.14),
                        Color(white: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: trayWidth, height: trayHeight)
            .offset(y: -(size.height * 0.30))
    }

    private var reflectionBand: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.10),
                        .white.opacity(0.04),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .blendMode(.screen)
            .frame(width: size.width * 0.78, height: 3)
            .offset(y: -(size.height * 0.12))
    }

    private var glassSlot: some View {
        let slotWidth = WWDC26ObjectMetrics.slabSize.width * WWDC26ObjectMetrics.slotWidthRatio

        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.04),
                        Color(white: 0.10)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: slotWidth, height: WWDC26ObjectMetrics.slotHeight)
            .offset(y: -(size.height * 0.44))
    }

    private var topEdgeHighlights: some View {
        ZStack {
            RoundedRectangle(cornerRadius: WWDC26ObjectMetrics.trayCornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.20), lineWidth: 1)
                .frame(
                    width: size.width - WWDC26ObjectMetrics.trayHorizontalInset * 2,
                    height: size.height * WWDC26ObjectMetrics.trayHeightRatio
                )
                .offset(y: -(size.height * 0.30))

            RoundedRectangle(cornerRadius: WWDC26ObjectMetrics.baseCornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.8)
                .frame(width: size.width, height: size.height * WWDC26ObjectMetrics.lowerBodyHeightRatio)
                .offset(y: 0)
        }
    }
}

#Preview("WWDC26 Base") {
    ZStack {
        Color.gray.opacity(0.3)
        WWDC26BaseView()
    }
}
