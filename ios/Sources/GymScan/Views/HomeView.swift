import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gym.createdAt, order: .reverse) private var gyms: [Gym]
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @State private var showScanFlow = false
    @State private var scanViewModel = ScanViewModel()
    @State private var workoutViewModel = WorkoutViewModel()
    @State private var path = NavigationPath()
    @State private var isDemoLoading = false
    @State private var hasHandledInitialChoice = false

    var initialScanChoice: FirstScanChoice? = nil

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    scanButton
                    demoScanButton
                    recentGymsSection
                    recentWorkoutsSection
                }
                .padding()
            }
            .background(GymScanTheme.background)
            .navigationTitle("GymScan")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Scan Error", isPresented: Binding(
                get: { scanViewModel.scanState == .error && scanViewModel.error != nil },
                set: { if !$0 { scanViewModel.reset() } }
            )) {
                Button("OK") { scanViewModel.reset() }
            } message: {
                Text(scanViewModel.error ?? "Something went wrong")
            }
            .navigationDestination(for: ScanFlowStep.self) { step in
                switch step {
                case .capture:
                    VideoCaptureView(scanViewModel: scanViewModel, onNavigate: { step in path.append(step) }, onDismiss: { if !path.isEmpty { path.removeLast() } })
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
                    SessionTrackerView(workoutViewModel: workoutViewModel, path: $path)
                }
            }
            .navigationDestination(for: WorkoutDetail.self) { detail in
                WorkoutDisplayView(workoutViewModel: workoutViewModel, path: $path)
                    .onAppear {
                        workoutViewModel.exercises = detail.workout.exercises
                        workoutViewModel.currentWorkout = detail.workout
                    }
            }
        }
        .task {
            guard !hasHandledInitialChoice, let choice = initialScanChoice else { return }
            hasHandledInitialChoice = true
            switch choice {
            case .scanNow:
                scanViewModel.reset()
                workoutViewModel.reset()
                path.append(ScanFlowStep.capture)
            case .demo:
                scanViewModel.reset()
                workoutViewModel.reset()
                scanViewModel.isDemo = true
                workoutViewModel.isDemo = true
                isDemoLoading = true
                let frames = DemoDataProvider.sampleFrames()
                await scanViewModel.processFrames(frames, modelContext: modelContext)
                isDemoLoading = false
                if scanViewModel.scanState == .complete {
                    path.append(ScanFlowStep.equipment)
                }
            }
        }
    }

    private var scanButton: some View {
        Button {
            scanViewModel.reset()
            workoutViewModel.reset()
            path.append(ScanFlowStep.capture)
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Hero image
                Group {
                    if let url = Bundle.main.url(forResource: "hero-gym", withExtension: "jpg"),
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 280)
                            .clipped()
                    } else {
                        LinearGradient(
                            colors: [GymScanTheme.surfaceLight, GymScanTheme.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 280)
                        .overlay {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(GymScanTheme.accent.opacity(0.5))
                        }
                    }
                }

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.3),
                        .init(color: GymScanTheme.background.opacity(0.6), location: 0.6),
                        .init(color: GymScanTheme.background.opacity(0.95), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("SCAN A GYM")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text("Point your camera and get a workout")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var demoScanButton: some View {
        Button {
            scanViewModel.reset()
            workoutViewModel.reset()
            scanViewModel.isDemo = true
            workoutViewModel.isDemo = true
            isDemoLoading = true
            Task {
                let frames = DemoDataProvider.sampleFrames()
                await scanViewModel.processFrames(frames, modelContext: modelContext)
                isDemoLoading = false
                if scanViewModel.scanState == .complete {
                    path.append(ScanFlowStep.equipment)
                }
            }
        } label: {
            HStack(spacing: 10) {
                if isDemoLoading {
                    ProgressView()
                        .tint(GymScanTheme.accent)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GymScanTheme.accent)
                }
                Text(isDemoLoading ? "ANALYZING..." : "TRY A DEMO")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(GymScanTheme.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(GymScanTheme.surface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDemoLoading)
    }

    private var recentGymsSection: some View {
        Group {
            if !gyms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT GYMS")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(GymScanTheme.textSecondary)

                    ForEach(gyms.prefix(5)) { gym in
                        GymRow(gym: gym)
                    }
                }
            }
        }
    }

    private var recentWorkoutsSection: some View {
        Group {
            if !workouts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT WORKOUTS")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(GymScanTheme.textSecondary)

                    ForEach(workouts.prefix(5)) { workout in
                        Button {
                            workoutViewModel.currentWorkout = workout
                            workoutViewModel.exercises = workout.exercises
                            path.append(ScanFlowStep.workout)
                        } label: {
                            WorkoutRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Navigation

enum ScanFlowStep: Hashable {
    case capture
    case equipment
    case muscles
    case generating
    case workout
    case session
}

struct WorkoutDetail: Hashable {
    let workout: Workout

    func hash(into hasher: inout Hasher) {
        hasher.combine(workout.id)
    }

    static func == (lhs: WorkoutDetail, rhs: WorkoutDetail) -> Bool {
        lhs.workout.id == rhs.workout.id
    }
}

// MARK: - Row Views

struct GymRow: View {
    let gym: Gym

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.title3)
                .foregroundStyle(GymScanTheme.accent)
                .frame(width: 40, height: 40)
                .background(GymScanTheme.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(gym.name ?? "Unnamed Gym")
                    .font(.subheadline.bold())
                    .foregroundStyle(GymScanTheme.textPrimary)
                Text("\(gym.equipment.count) equipment items")
                    .font(.caption)
                    .foregroundStyle(GymScanTheme.textSecondary)
            }

            Spacer()

            Text(gym.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(GymScanTheme.textSecondary.opacity(0.7))
        }
        .padding(12)
        .background(GymScanTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.completed ? "checkmark.circle.fill" : "figure.strengthtraining.traditional")
                .font(.title3)
                .foregroundStyle(workout.completed ? GymScanTheme.accentSecondary : GymScanTheme.accent)
                .frame(width: 40, height: 40)
                .background(
                    workout.completed
                        ? GymScanTheme.accentSecondary.opacity(0.15)
                        : GymScanTheme.accent.opacity(0.15)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.targetMuscles.map(\.displayName).joined(separator: ", "))
                    .font(.subheadline.bold())
                    .foregroundStyle(GymScanTheme.textPrimary)
                    .lineLimit(1)
                Text("\(workout.exercises.count) exercises, \(workout.durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(GymScanTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if workout.completed {
                    Text("Completed")
                        .font(.caption2)
                        .foregroundStyle(GymScanTheme.accentSecondary)
                }
                Text(workout.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(GymScanTheme.textSecondary.opacity(0.7))
            }
        }
        .padding(12)
        .background(GymScanTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Gym.self, Equipment.self, Workout.self, UserProfile.self], inMemory: true)
}
