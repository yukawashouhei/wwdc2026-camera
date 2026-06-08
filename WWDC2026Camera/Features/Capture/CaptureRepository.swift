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

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

enum CaptureRepositoryError: Error, LocalizedError {
    case photoLibraryUnauthorized
    case compositionFailed

    var errorDescription: String? {
        switch self {
        case .photoLibraryUnauthorized:
            "写真ライブラリへのアクセスが許可されていません。"
        case .compositionFailed:
            "写真の合成に失敗しました。"
        }
    }
}
