import SwiftUI

struct WWDC26BaseView: View {
    private let baseSize = WWDC26ObjectMetrics.baseSize

    var body: some View {
        ZStack {
            WWDC26BaseShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.24),
                            Color(white: 0.10),
                            Color(white: 0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            WWDC26BaseShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.18),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
        }
        .frame(width: baseSize.width, height: baseSize.height)
        .shadow(color: .black.opacity(0.45), radius: 5, x: 0, y: 3)
    }
}

#Preview("WWDC26 Base") {
    ZStack {
        Color.gray.opacity(0.3)
        WWDC26BaseView()
    }
}
