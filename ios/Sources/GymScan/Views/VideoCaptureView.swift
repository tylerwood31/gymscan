import SwiftUI
import AVFoundation

struct VideoCaptureView: View {
    @Bindable var scanViewModel: ScanViewModel
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @State private var cameraManager = CameraManager()
    @State private var hasPermission = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch scanViewModel.scanState {
            case .idle:
                cameraContent
            case .recording:
                cameraContent
            case .extractingFrames, .uploading, .processing:
                processingContent
            case .complete:
                Color.clear
                    .onAppear {
                        path.append(ScanFlowStep.equipment)
                    }
            case .error:
                errorContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Scan Gym")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            hasPermission = await cameraManager.requestPermission()
            if hasPermission {
                do {
                    try cameraManager.setupSession()
                    cameraManager.startSession()
                } catch {
                    scanViewModel.error = error.localizedDescription
                    scanViewModel.scanState = .error
                }
            } else {
                showPermissionAlert = true
            }
        }
        .onDisappear {
            cameraManager.cleanup()
        }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                path.removeLast()
            }
        } message: {
            Text("GymScan needs camera access to scan gym equipment. Please enable it in Settings.")
        }
    }

    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Guide overlay
                if !cameraManager.isRecording {
                    guideOverlay
                        .transition(.opacity)
                }

                // Recording indicator
                if cameraManager.isRecording {
                    recordingOverlay
                        .transition(.opacity)
                }

                Spacer()

                // Controls
                recordButton
                    .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: cameraManager.isRecording)
    }

    private var guideOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.white)

            Text("Slowly pan around the gym")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Try to capture all equipment from different angles")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 32)
    }

    private var recordingOverlay: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 12, height: 12)
                Text("Recording")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.red)
                        .frame(width: geometry.size.width * cameraManager.recordingProgress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)

            Text("\(Int(cameraManager.recordingProgress * CameraManager.maxDuration))s / \(Int(CameraManager.maxDuration))s")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .monospacedDigit()
        }
    }

    private var recordButton: some View {
        Button {
            if cameraManager.isRecording {
                cameraManager.stopRecording()
            } else {
                Task {
                    scanViewModel.scanState = .recording
                    do {
                        let videoURL = try await cameraManager.startRecording()
                        await scanViewModel.processVideo(at: videoURL, modelContext: modelContext)
                    } catch {
                        scanViewModel.error = error.localizedDescription
                        scanViewModel.scanState = .error
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                if cameraManager.isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 28, height: 28)
                } else {
                    Circle()
                        .fill(.red)
                        .frame(width: 60, height: 60)
                }
            }
        }
    }

    private var processingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text(scanViewModel.frameExtractionProgress)
                .font(.headline)
                .foregroundStyle(.white)

            Text("This may take a moment...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Something went wrong")
                .font(.title3.bold())
                .foregroundStyle(.white)

            if let error = scanViewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Button("Try Again") {
                scanViewModel.scanState = .idle
                scanViewModel.error = nil
                cameraManager.startSession()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraManager.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
