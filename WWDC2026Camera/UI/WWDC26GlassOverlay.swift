import SwiftUI

struct WWDC26GlassOverlay: View {
    var scale: CGFloat = 1.0

    private let slabWidth: CGFloat = 180
    private let slabHeight: CGFloat = 320
    private let cornerRadius: CGFloat = 48

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape
                .fill(.clear)
                .frame(width: slabWidth, height: slabHeight)
                .glassEffect(.regular, in: shape)
                .mask { glassMask(shape: shape) }

            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.85),
                            .white.opacity(0.15),
                            .white.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: slabWidth, height: slabHeight)
        }
        .scaleEffect(scale)
    }

    private func glassMask(shape: RoundedRectangle) -> some View {
        ZStack {
            shape
                .fill(.white)
                .frame(width: slabWidth, height: slabHeight)
            cutoutText
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private var cutoutText: some View {
        VStack(spacing: -4) {
            Text("WW")
            Text("DC")
            Text("26")
        }
        .font(.system(size: 52, weight: .bold, design: .rounded))
        .multilineTextAlignment(.center)
        .frame(width: slabWidth, height: slabHeight)
    }
}

#Preview("WWDC26 Overlay") {
    ZStack {
        SimulatorCameraBackground()
        WWDC26GlassOverlay()
    }
}
