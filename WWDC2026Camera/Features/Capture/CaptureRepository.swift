import Photos
import UIKit

protocol CaptureRepositoryProtocol: Sendable {
    func startCamera() async throws
    func stopCamera() async
    func capturePhoto() async throws -> Data
    func saveToPhotoLibrary(_ image: UIImage) async throws
}

struct LiveCaptureRepository: CaptureRepositoryProtocol {
    private let cameraSession: CameraSession

    init(cameraSession: CameraSession) {
        self.cameraSession = cameraSession
    }

    func startCamera() async throws {
        try await cameraSession.start()
    }

    func stopCamera() async {
        await cameraSession.stop()
    }

    func capturePhoto() async throws -> Data {
        try await cameraSession.capturePhoto()
    }

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw CaptureRepositoryError.photoLibraryUnauthorized
        }

        let preparedImage = image.preparedForPhotoLibrary()

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: preparedImage)
            }
        } catch {
            guard let jpegData = preparedImage.jpegData(compressionQuality: 0.95) else {
                throw CaptureRepositoryError.saveFailed
            }

            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: jpegData, options: nil)
            }
        }
    }
}

enum CaptureRepositoryError: Error, LocalizedError {
    case photoLibraryUnauthorized
    case compositionFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .photoLibraryUnauthorized:
            "写真ライブラリへのアクセスが必要です。設定アプリから許可してください。"
        case .compositionFailed:
            "写真の合成に失敗しました。もう一度お試しください。"
        case .saveFailed:
            "写真の保存に失敗しました。もう一度お試しください。"
        }
    }
}

private extension UIImage {
    func preparedForPhotoLibrary() -> UIImage {
        if cgImage != nil {
            return self
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
