@preconcurrency import AVFoundation
import Foundation
import UIKit

enum CameraSessionError: Error, LocalizedError {
    case unauthorized
    case configurationFailed
    case noPhotoData
    case captureTimedOut
    case sessionNotRunning

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "カメラへのアクセスが許可されていません。"
        case .configurationFailed:
            "カメラの設定に失敗しました。"
        case .noPhotoData:
            "写真データを取得できませんでした。"
        case .captureTimedOut:
            "写真の撮影がタイムアウトしました。もう一度お試しください。"
        case .sessionNotRunning:
            "カメラセッションが起動していません。"
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
    private nonisolated(unsafe) var inFlightCapture: PhotoCaptureRequest?
    private nonisolated let sessionQueue = DispatchSerialQueue(label: "com.wwdc2026.camera.session")

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
        try await withTaskCancellationHandler {
            try await capturePhotoOnSessionQueue()
        } onCancel: {
            self.sessionQueue.async {
                self.cancelInFlightCapture(reason: CancellationError())
            }
        }
#endif
    }

#if !targetEnvironment(simulator)
    private func capturePhotoOnSessionQueue() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [captureSession, photoOutput, sessionQueue] in
                self.inFlightCapture?.fail(CameraSessionError.captureTimedOut)

                let request = PhotoCaptureRequest(continuation: continuation) { [self] finishedRequest in
                    self.clearInFlightCapture(finishedRequest)
                }
                self.inFlightCapture = request

                sessionQueue.asyncAfter(deadline: .now() + 15) { [weak request] in
                    request?.fail(CameraSessionError.captureTimedOut)
                }

                guard captureSession.isRunning else {
                    request.fail(CameraSessionError.sessionNotRunning)
                    self.clearInFlightCapture(request)
                    return
                }

                do {
                    try CameraSession.configureIfNeeded(
                        captureSession: captureSession,
                        photoOutput: photoOutput,
                        isConfigured: &self.isConfigured
                    )

                    let settings = CameraSession.makePhotoSettings(for: photoOutput)

                    photoOutput.capturePhoto(with: settings, delegate: request.delegate)
                } catch {
                    request.fail(error)
                    self.clearInFlightCapture(request)
                }
            }
        }
    }

    private nonisolated func cancelInFlightCapture(reason: Error) {
        inFlightCapture?.fail(reason)
        inFlightCapture = nil
    }

    private nonisolated func clearInFlightCapture(_ request: PhotoCaptureRequest) {
        if inFlightCapture === request {
            inFlightCapture = nil
        }
    }

    private nonisolated static func makePhotoSettings(for photoOutput: AVCapturePhotoOutput) -> AVCapturePhotoSettings {
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }

        let dimensions = photoOutput.maxPhotoDimensions
        if dimensions.width > 0, dimensions.height > 0 {
            settings.maxPhotoDimensions = dimensions
        }

        return settings
    }
#endif

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

        photoOutput.isAutoDeferredPhotoDeliveryEnabled = false
        photoOutput.maxPhotoQualityPrioritization = .balanced

        if let dimensions = camera.activeFormat.supportedMaxPhotoDimensions.max(by: {
            $0.width * $0.height < $1.width * $1.height
        }) {
            photoOutput.maxPhotoDimensions = dimensions
        }
    }
}

private final class PhotoCaptureRequest: @unchecked Sendable {
    private let continuation: CheckedContinuation<Data, Error>
    private let onFinish: @Sendable (PhotoCaptureRequest) -> Void
    private let lock = NSLock()
    private nonisolated(unsafe) var hasResumed = false
    private nonisolated(unsafe) var pendingData: Data?
    private nonisolated(unsafe) var storedDelegate: PhotoCaptureDelegate?

    nonisolated var delegate: PhotoCaptureDelegate {
        if let storedDelegate {
            return storedDelegate
        }
        let created = PhotoCaptureDelegate(request: self)
        storedDelegate = created
        return created
    }

    nonisolated init(
        continuation: CheckedContinuation<Data, Error>,
        onFinish: @escaping @Sendable (PhotoCaptureRequest) -> Void
    ) {
        self.continuation = continuation
        self.onFinish = onFinish
    }

    nonisolated func storeData(_ data: Data) {
        lock.lock()
        pendingData = data
        lock.unlock()
    }

    nonisolated func completeCapture(error: Error?) {
        if let error {
            fail(error)
            return
        }

        lock.lock()
        defer { lock.unlock() }
        guard !hasResumed else { return }
        hasResumed = true

        if let pendingData {
            continuation.resume(returning: pendingData)
            onFinish(self)
        } else {
            continuation.resume(throwing: CameraSessionError.noPhotoData)
            onFinish(self)
        }
    }

    nonisolated func fail(_ error: Error) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasResumed else { return }
        hasResumed = true

        continuation.resume(throwing: error)
        onFinish(self)
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private unowned let request: PhotoCaptureRequest

    nonisolated init(request: PhotoCaptureRequest) {
        self.request = request
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            request.fail(error)
            return
        }

        if let data = photo.fileDataRepresentation(), !data.isEmpty {
            request.storeData(data)
        }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?,
        error: Error?
    ) {
        if let error {
            request.fail(error)
            return
        }

        if let data = deferredPhotoProxy?.fileDataRepresentation(), !data.isEmpty {
            request.storeData(data)
        }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        request.completeCapture(error: error)
    }
}
