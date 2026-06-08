import SwiftUI

struct WWDC26GlassOverlay: View {
    var scale: CGFloat = 1.0

    private let slabWidth = WWDC26SlabMetrics.defaultWidth
    private let slabHeight = WWDC26SlabMetrics.defaultHeight

    var body: some View {
        ZStack {
            depthGlassLayer
            mainGlassLayer
            edgeHighlightLayer
            topRimHighlight
        }
        .frame(width: slabWidth, height: slabHeight)
        .scaleEffect(scale)
    }

    private var depthGlassLayer: some View {
        Color.clear
            .frame(width: slabWidth, height: slabHeight)
            .glassEffect(.regular.tint(.white.opacity(0.12)), in: WWDC26SlabBodyShape())
            .mask { glassBodyMask }
            .offset(x: 1.5, y: 2.5)
            .opacity(0.55)
    }

    private var mainGlassLayer: some View {
        Color.clear
            .frame(width: slabWidth, height: slabHeight)
            .glassEffect(.clear, in: WWDC26SlabBodyShape())
            .mask { glassBodyMask }
    }

    private var edgeHighlightLayer: some View {
        WWDC26OutlineShape()
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.9),
                        .white.opacity(0.2),
                        .white.opacity(0.05),
                        .white.opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: slabWidth, height: slabHeight)
    }

    private var topRimHighlight: some View {
        WWDC26OutlineShape()
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.6),
                        .white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .center
                ),
                lineWidth: 1
            )
            .frame(width: slabWidth, height: slabHeight)
            .opacity(0.5)
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
