import AVFoundation
import UIKit

@Observable
@MainActor
final class CameraManager: NSObject {
    var isRecording = false
    var recordingProgress: Double = 0
    var error: String?

    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var outputURL: URL?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var continuation: CheckedContinuation<URL, any Error>?

    static let maxDuration: TimeInterval = 20
    static let minDuration: TimeInterval = 5

    var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func setupSession() throws {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCameraAvailable
        }

        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(videoInput)

        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        let output = AVCaptureMovieFileOutput()
        output.maxRecordedDuration = CMTime(seconds: Self.maxDuration + 1, preferredTimescale: 600)
        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill

        self.captureSession = session
        self.movieOutput = output
        self.previewLayer = layer
    }

    func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        let capturedSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            capturedSession.startRunning()
        }
    }

    func stopSession() {
        guard let session = captureSession, session.isRunning else { return }
        let capturedSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            capturedSession.stopRunning()
        }
    }

    func startRecording() async throws -> URL {
        guard let output = movieOutput else {
            throw CameraError.notConfigured
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "gymscan_\(UUID().uuidString).mov"
        let url = tempDir.appendingPathComponent(fileName)
        self.outputURL = url

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.isRecording = true
            self.recordingProgress = 0
            self.recordingStartTime = Date()

            output.startRecording(to: url, recordingDelegate: self)

            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let startTime = self.recordingStartTime else { return }
                    let elapsed = Date().timeIntervalSince(startTime)
                    self.recordingProgress = min(elapsed / Self.maxDuration, 1.0)

                    if elapsed >= Self.maxDuration {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording, let output = movieOutput, output.isRecording else { return }
        recordingTimer?.invalidate()
        recordingTimer = nil
        output.stopRecording()
    }

    func cleanup() {
        stopSession()
        captureSession = nil
        movieOutput = nil
        previewLayer = nil
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        Task { @MainActor in
            self.isRecording = false
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil

            if let error {
                self.continuation?.resume(throwing: error)
            } else {
                self.continuation?.resume(returning: outputFileURL)
            }
            self.continuation = nil
        }
    }
}

enum CameraError: LocalizedError {
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case notConfigured
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable: return "No camera available on this device"
        case .cannotAddInput: return "Cannot configure camera input"
        case .cannotAddOutput: return "Cannot configure video output"
        case .notConfigured: return "Camera not properly configured"
        case .permissionDenied: return "Camera permission denied"
        }
    }
}
