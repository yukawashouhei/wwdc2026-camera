import AVFoundation
import Foundation
import UIKit

enum CameraSessionError: Error, LocalizedError {
    case unauthorized
    case configurationFailed
    case noPhotoData

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "カメラへのアクセスが許可されていません。"
        case .configurationFailed:
            "カメラの設定に失敗しました。"
        case .noPhotoData:
            "写真データを取得できませんでした。"
        }
    }
}

protocol PreviewSource: Sendable {
    @MainActor
    func connect(to target: PreviewTarget)
}

protocol PreviewTarget: AnyObject {
    @MainActor
    func setSession(_ session: AVCaptureSession)
}

struct DefaultPreviewSource: PreviewSource {
    private nonisolated(unsafe) let session: AVCaptureSession

    nonisolated init(session: AVCaptureSession) {
        self.session = session
    }

    @MainActor
    func connect(to target: PreviewTarget) {
        target.setSession(session)
    }
}

actor CameraSession {
    nonisolated let previewSource: PreviewSource

    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) let photoOutput = AVCapturePhotoOutput()
    private nonisolated(unsafe) var isConfigured = false
    private let sessionQueue = DispatchSerialQueue(label: "com.wwdc2026.camera.session")

    init() {
        previewSource = DefaultPreviewSource(session: captureSession)
    }

    func requestAccessIfNeeded() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { throw CameraSessionError.unauthorized }
        default:
            throw CameraSessionError.unauthorized
        }
    }

    func start() async throws {
#if targetEnvironment(simulator)
        return
#else
        try await requestAccessIfNeeded()
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [captureSession] in
                do {
                    try CameraSession.configureIfNeeded(
                        captureSession: captureSession,
                        photoOutput: self.photoOutput,
                        isConfigured: &self.isConfigured
                    )
                    guard !captureSession.isRunning else {
                        continuation.resume()
                        return
                    }
                    captureSession.startRunning()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
#endif
    }

    func stop() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [captureSession] in
                guard captureSession.isRunning else {
                    continuation.resume()
                    return
                }
                captureSession.stopRunning()
                continuation.resume()
            }
        }
    }

    func capturePhoto() async throws -> Data {
#if targetEnvironment(simulator)
        return try makeSimulatorPhotoData()
#else
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [captureSession, photoOutput] in
                do {
                    try CameraSession.configureIfNeeded(
                        captureSession: captureSession,
                        photoOutput: photoOutput,
                        isConfigured: &self.isConfigured
                    )

                    let settings: AVCapturePhotoSettings
                    if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                    } else {
                        settings = AVCapturePhotoSettings()
                    }

                    photoOutput.capturePhoto(
                        with: settings,
                        delegate: PhotoCaptureDelegate(continuation: continuation)
                    )
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
#endif
    }

#if targetEnvironment(simulator)
    private func makeSimulatorPhotoData() throws -> Data {
        let size = CGSize(width: 1170, height: 2532)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors = [
                UIColor(red: 0.45, green: 0.65, blue: 0.45, alpha: 1).cgColor,
                UIColor(red: 0.25, green: 0.45, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.55, green: 0.70, blue: 0.85, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 0.5, 1]
            )!
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw CameraSessionError.noPhotoData
        }
        return data
    }
#endif

    private nonisolated static func configureIfNeeded(
        captureSession: AVCaptureSession,
        photoOutput: AVCapturePhotoOutput,
        isConfigured: inout Bool
    ) throws {
        guard !isConfigured else { return }

        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
            isConfigured = true
        }

        captureSession.sessionPreset = .photo

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(input)
        else {
            throw CameraSessionError.configurationFailed
        }

        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.addInput(input)

        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraSessionError.configurationFailed
        }

        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        captureSession.addOutput(photoOutput)

        if let dimensions = camera.activeFormat.supportedMaxPhotoDimensions.last {
            photoOutput.maxPhotoDimensions = dimensions
        }
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<Data, Error>
    private nonisolated(unsafe) var photoData: Data?
    private let lock = NSLock()
    private nonisolated(unsafe) var hasResumed = false

    nonisolated init(continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            resumeOnce(throwing: error)
            return
        }
        photoData = photo.fileDataRepresentation()
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error {
            resumeOnce(throwing: error)
            return
        }

        guard let photoData else {
            resumeOnce(throwing: CameraSessionError.noPhotoData)
            return
        }

        resumeOnce(returning: photoData)
    }

    nonisolated private func resumeOnce(returning data: Data) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(returning: data)
    }

    nonisolated private func resumeOnce(throwing error: Error) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(throwing: error)
    }
}
