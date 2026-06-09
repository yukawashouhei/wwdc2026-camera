import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class CaptureViewModel {
    var overlayOffset = CGSize(width: 0, height: OverlayTransform.defaultVerticalOffset)
    var overlayScale: CGFloat = 1.0
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

    func capturePhoto() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        do {
            try await performCaptureWithTimeout()
        } catch {
            logger.error("Capture flow failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func performCaptureWithTimeout() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let gate = CaptureCompletionGate()

            let work = Task { @MainActor in
                do {
                    try await self.performCapture()
                    gate.finishOnce {
                        continuation.resume()
                    }
                } catch {
                    gate.finishOnce {
                        continuation.resume(throwing: error)
                    }
                }
            }

            Task {
                try? await Task.sleep(for: .seconds(20))
                gate.finishOnce {
                    work.cancel()
                    continuation.resume(throwing: CaptureRepositoryError.captureTimedOut)
                }
            }
        }
    }

    private func performCapture() async throws {
        let overlaySnapshot = OverlaySnapshotter.snapshot()
        logger.info("Overlay snapshot captured: \(overlaySnapshot != nil)")

        let data = try await repository.capturePhoto()
        logger.info("Photo captured: \(data.count) bytes")

        let effectivePreviewSize = previewSize.width > 0 && previewSize.height > 0
            ? previewSize
            : UIScreen.main.bounds.size

        let transform = OverlayTransform(
            offset: overlayOffset,
            scale: overlayScale,
            previewSize: effectivePreviewSize
        )

        let composited = try compositePhoto(
            data: data,
            overlaySnapshot: overlaySnapshot,
            transform: transform
        )

        try await repository.saveToPhotoLibrary(composited)
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

private final class CaptureCompletionGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isFinished = false

    func finishOnce(_ action: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else { return }
        isFinished = true
        action()
    }
}
