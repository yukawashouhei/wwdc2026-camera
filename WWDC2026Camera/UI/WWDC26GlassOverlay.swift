import SwiftUI

struct WWDC26GlassOverlay: View {
    var scale: CGFloat = 1.0

    private let slabWidth = WWDC26SlabMetrics.defaultWidth
    private let slabHeight = WWDC26SlabMetrics.defaultHeight

    var body: some View {
        ZStack {
            innerEdgeShadow
            depthGlassLayer
            mainGlassLayer
            topBlackGradient
            topReflectionHighlight
            edgeHighlightLayer
            topRimHighlight
        }
        .frame(width: slabWidth, height: slabHeight)
        .scaleEffect(scale)
    }

    private var depthGlassLayer: some View {
        Color.clear
            .frame(width: slabWidth, height: slabHeight)
            .glassEffect(.regular.tint(.white.opacity(0.04)), in: WWDC26SlabBodyShape())
            .mask { glassBodyMask }
            .offset(x: 0.5, y: 1.0)
            .opacity(0.25)
    }

    private var mainGlassLayer: some View {
        Color.clear
            .frame(width: slabWidth, height: slabHeight)
            .glassEffect(.clear, in: WWDC26SlabBodyShape())
            .mask { glassBodyMask }
    }

    private var topBlackGradient: some View {
        LinearGradient(
            colors: [
                .black.opacity(1.0),
                .black.opacity(0.92),
                .black.opacity(0.4),
                .clear
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.38)
        )
        .frame(width: slabWidth, height: slabHeight)
        .mask { glassBodyMask }
    }

    private var topReflectionHighlight: some View {
        LinearGradient(
            colors: [
                .white.opacity(0.22),
                .white.opacity(0.06),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: UnitPoint(x: 0.65, y: 0.4)
        )
        .blendMode(.screen)
        .frame(width: slabWidth, height: slabHeight)
        .mask { glassBodyMask }
    }

    private var innerEdgeShadow: some View {
        WWDC26OutlineShape()
            .stroke(
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.08),
                        .black.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
            .frame(width: slabWidth, height: slabHeight)
            .offset(y: 1)
    }

    private var edgeHighlightLayer: some View {
        WWDC26OutlineShape()
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.55),
                        .white.opacity(0.15),
                        .white.opacity(0.05),
                        .white.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .frame(width: slabWidth, height: slabHeight)
    }

    private var topRimHighlight: some View {
        WWDC26OutlineShape()
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.35),
                        .white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .center
                ),
                lineWidth: 1
            )
            .frame(width: slabWidth, height: slabHeight)
            .opacity(0.25)
    }

    private var glassBodyMask: some View {
        ZStack {
            WWDC26SlabBodyShape()
                .fill(.white)
            WWDC26LetterCutoutShape()
                .fill(.white)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
}

#Preview("WWDC26 Overlay") {
    ZStack {
        SimulatorCameraBackground()
        WWDC26GlassOverlay()
    }
}
