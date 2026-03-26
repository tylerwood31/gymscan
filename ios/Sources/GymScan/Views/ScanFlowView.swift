import SwiftUI
import SwiftData

struct ScanFlowView: View {
    @Bindable var scanViewModel: ScanViewModel
    @Bindable var workoutViewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()
    @State private var isDemoLoading = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if scanViewModel.isDemo {
                    demoLoadingView
                } else {
                    VideoCaptureView(scanViewModel: scanViewModel, onNavigate: navigateForward, onDismiss: { dismiss() })
                }
            }
            .navigationDestination(for: ScanFlowStep.self) { step in
                switch step {
                case .capture:
                    // Should not be reached -- capture is the root
                    EmptyView()
                case .equipment:
                    EquipmentConfirmationView(scanViewModel: scanViewModel, path: $path)
                case .muscles:
                    MuscleSelectionView(
                        scanViewModel: scanViewModel,
                        workoutViewModel: workoutViewModel,
                        path: $path
                    )
                case .generating:
                    WorkoutGeneratingView(
                        workoutViewModel: workoutViewModel,
                        scanViewModel: scanViewModel,
                        path: $path
                    )
                case .workout:
                    WorkoutDisplayView(workoutViewModel: workoutViewModel, path: $path)
                case .session:
                    SessionTrackerView(
                        workoutViewModel: workoutViewModel,
                        path: $path,
                        onComplete: { dismiss() }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GymScanTheme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(GymScanTheme.surface.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onDisappear {
            // Reset state when the flow is dismissed so next launch is fresh
            scanViewModel.reset()
            workoutViewModel.reset()
        }
    }

    // MARK: - Demo Flow

    private var demoLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()

            if isDemoLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(GymScanTheme.accent)

                Text("Analyzing sample gym...")
                    .font(.headline)
                    .foregroundStyle(GymScanTheme.textPrimary)

                Text("This may take a moment")
                    .font(.subheadline)
                    .foregroundStyle(GymScanTheme.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GymScanTheme.background)
        .task {
            isDemoLoading = true
            let frames = DemoDataProvider.sampleFrames()
            await scanViewModel.processFrames(frames, modelContext: modelContext)
            isDemoLoading = false
            if scanViewModel.scanState == .complete {
                path.append(ScanFlowStep.equipment)
            }
        }
    }

    // MARK: - Navigation

    private func navigateForward(_ step: ScanFlowStep) {
        path.append(step)
    }
}
