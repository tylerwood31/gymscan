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

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    scanButton
                    recentGymsSection
                    recentWorkoutsSection
                }
                .padding()
            }
            .navigationTitle("GymScan")
            .navigationDestination(for: ScanFlowStep.self) { step in
                switch step {
                case .capture:
                    VideoCaptureView(scanViewModel: scanViewModel, path: $path)
                case .equipment:
                    EquipmentConfirmationView(scanViewModel: scanViewModel, path: $path)
                case .muscles:
                    MuscleSelectionView(
                        scanViewModel: scanViewModel,
                        workoutViewModel: workoutViewModel,
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
    }

    private var scanButton: some View {
        Button {
            scanViewModel.reset()
            workoutViewModel.reset()
            path.append(ScanFlowStep.capture)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 28, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan a Gym")
                        .font(.title2.bold())
                    Text("Record a quick video to detect equipment")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(20)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.blue, .indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var recentGymsSection: some View {
        Group {
            if !gyms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Gyms")
                        .font(.headline)

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
                    Text("Recent Workouts")
                        .font(.headline)

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
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(gym.name ?? "Unnamed Gym")
                    .font(.subheadline.bold())
                Text("\(gym.equipment.count) equipment items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(gym.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.completed ? "checkmark.circle.fill" : "figure.strengthtraining.traditional")
                .font(.title3)
                .foregroundStyle(workout.completed ? .green : .orange)
                .frame(width: 40, height: 40)
                .background(workout.completed ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.targetMuscles.map(\.displayName).joined(separator: ", "))
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(workout.exercises.count) exercises, \(workout.durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if workout.completed {
                    Text("Completed")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                Text(workout.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Gym.self, Equipment.self, Workout.self], inMemory: true)
}
