import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class CaptureViewModel {
    var overlayOffset = CGSize(width: 0, height: OverlayTransform.defaultVerticalOffset)
    var overlayScale: CGFloat = 1.0
    var showBase = true
    var previewSize = CGSize.zero
    var isCapturing = false
    var showSaveConfirmation = false
    var errorMessage: String?

    let previewSource: PreviewSource

    private let repository: any CaptureRepositoryProtocol
    private var magnificationBaseScale: CGFloat = 1.0
    private let logger = Logger(subsystem: "com.wwdc2026.camera", category: "Capture")

    init(repository: any CaptureRepositoryProtocol, previewSource: PreviewSource) {
        self.repository = repository
        self.previewSource = previewSource
    }

    func onAppear() async {
        do {
            try await repository.startCamera()
        } catch {
            logger.error("Camera start failed: \(error.localizedDescription)")
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

    func toggleBase() {
        showBase.toggle()
    }

    func capturePhoto() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        do {
            try await performCapture()
        } catch {
            logger.error("Capture flow failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func performCapture() async throws {
        let overlaySnapshot = OverlaySnapshotter.snapshot()

        let data = try await repository.capturePhoto()
        logger.info("Photo captured: \(data.count) bytes")

        let transform = OverlayTransform(
            offset: overlayOffset,
            scale: overlayScale,
            previewSize: previewSize,
            showBase: showBase
        )

        let composited = try compositePhoto(
            data: data,
            overlaySnapshot: overlaySnapshot,
            transform: transform
        )

        guard let jpegData = composited.jpegData(compressionQuality: 0.95) else {
            throw CaptureRepositoryError.saveFailed
        }

        try await repository.saveToPhotoLibrary(jpegData)
        logger.info("Photo saved to library")
        showSaveConfirmation = true

        try? await Task.sleep(for: .seconds(1.5))
        showSaveConfirmation = false
    }

    private func compositePhoto(
        data: Data,
        overlaySnapshot: UIImage?,
        transform: OverlayTransform
    ) throws -> UIImage {
        guard let photo = PhotoCompositor.normalizedImage(from: data) else {
            throw CaptureRepositoryError.compositionFailed
        }

        guard let composited = PhotoCompositor.composite(
            photo: photo,
            overlaySnapshot: overlaySnapshot,
            transform: transform
        ) else {
            throw CaptureRepositoryError.compositionFailed
        }

        return composited
    }
}
