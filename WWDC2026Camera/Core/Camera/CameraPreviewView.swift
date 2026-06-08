import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let source: PreviewSource

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        source.connect(to: view)
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

final class PreviewUIView: UIView, PreviewTarget {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
#if targetEnvironment(simulator)
        backgroundColor = UIColor.systemGray6
#endif
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor
    func setSession(_ session: AVCaptureSession) {
        previewLayer.session = session
    }
}

struct SimulatorCameraBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.65, blue: 0.45),
                Color(red: 0.25, green: 0.45, blue: 0.30),
                Color(red: 0.55, green: 0.70, blue: 0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
