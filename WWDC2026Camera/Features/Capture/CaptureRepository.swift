import Photos
import UIKit

protocol CaptureRepositoryProtocol: Sendable {
    nonisolated func startCamera() async throws
    nonisolated func stopCamera() async
    nonisolated func capturePhoto() async throws -> Data
    nonisolated func saveToPhotoLibrary(_ imageData: Data) async throws
}

struct LiveCaptureRepository: CaptureRepositoryProtocol {
    private let cameraSession: CameraSession

    init(cameraSession: CameraSession) {
        self.cameraSession = cameraSession
    }

    nonisolated func startCamera() async throws {
        try await cameraSession.start()
    }

    nonisolated func stopCamera() async {
        await cameraSession.stop()
    }

    nonisolated func capturePhoto() async throws -> Data {
        try await cameraSession.capturePhoto()
    }

    nonisolated func saveToPhotoLibrary(_ imageData: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw CaptureRepositoryError.photoLibraryUnauthorized
        }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: nil)
        }
    }
}

enum CaptureRepositoryError: Error, LocalizedError {
    case photoLibraryUnauthorized
    case compositionFailed
    case saveFailed
    case captureTimedOut

    var errorDescription: String? {
        switch self {
        case .photoLibraryUnauthorized:
            "写真ライブラリへのアクセスが必要です。設定アプリから許可してください。"
        case .compositionFailed:
            "写真の合成に失敗しました。もう一度お試しください。"
        case .saveFailed:
            "写真の保存に失敗しました。もう一度お試しください。"
        case .captureTimedOut:
            "撮影処理がタイムアウトしました。もう一度お試しください。"
        }
    }
}
