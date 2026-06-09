import SwiftUI

struct WWDC26GlassObject: View {
    var scale: CGFloat = 1.0
    var showBase: Bool = true

    var body: some View {
        let unitSize = WWDC26ObjectMetrics.unitSize(showBase: showBase)

        ZStack(alignment: .top) {
            if showBase {
                WWDC26BaseView()
                    .offset(y: WWDC26ObjectMetrics.baseVerticalOffset)
            }

            WWDC26GlassOverlay(scale: 1.0)
                .offset(x: WWDC26ObjectMetrics.glassHorizontalOffset(showBase: showBase))
        }
        .frame(width: unitSize.width, height: unitSize.height)
        .scaleEffect(scale)
    }
}

#Preview("WWDC26 Object With Base") {
    ZStack {
        SimulatorCameraBackground()
        WWDC26GlassObject()
    }
}

#Preview("WWDC26 Object Without Base") {
    ZStack {
        SimulatorCameraBackground()
        WWDC26GlassObject(showBase: false)
    }
}
