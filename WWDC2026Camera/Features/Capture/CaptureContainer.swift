import SwiftUI

struct CaptureContainer: View {
    @State private var viewModel: CaptureViewModel

    init() {
        let session = CameraSession()
        let repository = LiveCaptureRepository(cameraSession: session)
        _viewModel = State(
            initialValue: CaptureViewModel(
                repository: repository,
                previewSource: session.previewSource
            )
        )
    }

    var body: some View {
        CaptureView(viewModel: viewModel)
    }
}
