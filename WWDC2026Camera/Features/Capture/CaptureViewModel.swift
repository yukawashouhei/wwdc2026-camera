import Observation
import UIKit

@MainActor
@Observable
final class CaptureViewModel {
    var overlayOffset = CGSize.zero
    var overlayScale: CGFloat = 1.0
    var previewSize = CGSize.zero
    var isCapturing = false
    var showSaveConfirmation = false
    var errorMessage: String?

    let previewSource: PreviewSource

    private let repository: any CaptureRepositoryProtocol
    private var magnificationBaseScale: CGFloat = 1.0

    init(repository: any CaptureRepositoryProtocol, previewSource: PreviewSource) {
        self.repository = repository
        self.previewSource = previewSource
    }

    func onAppear() async {
        do {
            try await repository.startCamera()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func onDisappear() async {
        await repository.stopCamera()
    }

    func updatePreviewSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        previewSize = size
    }

    func dragChanged(translation: CGSize) {
        overlayOffset = translation
    }

    func dragEnded() {}

    func magnificationChanged(_ value: CGFloat) {
        let newScale = magnificationBaseScale * value
        overlayScale = min(max(newScale, 0.5), 2.0)
    }

    func magnificationEnded(_ value: CGFloat) {
        magnificationBaseScale = min(max(magnificationBaseScale * value, 0.5), 2.0)
        overlayScale = magnificationBaseScale
    }

    func capturePhoto() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        do {
            let data = try await repository.capturePhoto()
            guard let photo = PhotoCompositor.normalizedImage(from: data) else {
                throw CaptureRepositoryError.compositionFailed
            }

            let transform = OverlayTransform(
                offset: overlayOffset,
                scale: overlayScale,
                previewSize: previewSize
            )

            guard let composited = PhotoCompositor.composite(photo: photo, transform: transform) else {
                throw CaptureRepositoryError.compositionFailed
            }

            try await repository.saveToPhotoLibrary(composited)
            showSaveConfirmation = true

            try? await Task.sleep(for: .seconds(1.5))
            showSaveConfirmation = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
