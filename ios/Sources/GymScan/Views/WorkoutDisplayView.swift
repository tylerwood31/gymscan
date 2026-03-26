import SwiftUI

struct WorkoutDisplayView: View {
    @Bindable var workoutViewModel: WorkoutViewModel
    @Binding var path: NavigationPath
    @State private var expandedExercise: UUID?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    summaryHeader

                    ForEach(workoutViewModel.exercises) { exercise in
                        ExerciseCard(
                            exercise: exercise,
                            isExpanded: expandedExercise == exercise.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedExercise == exercise.id {
                                    expandedExercise = nil
                                } else {
                                    expandedExercise = exercise.id
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(GymScanTheme.background)

            startButton
        }
        .background(GymScanTheme.background)
        .navigationTitle("Your Workout")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var muscleGroupDisplay: String {
        guard let workout = workoutViewModel.currentWorkout else { return "0" }
        let muscles = workout.targetMuscles
        if muscles.contains(.fullBody) {
            return "Full Body"
        }
        return muscles.map(\.displayName).joined(separator: ", ")
    }

    private var estimatedMinutes: Int {
        let totalSeconds = workoutViewModel.exercises.reduce(0) { $0 + $1.estimatedSeconds }
        return max(1, (totalSeconds + 180) / 60) // +3 min warmup
    }

    private var summaryHeader: some View {
        HStack(spacing: 20) {
            StatBadge(
                icon: "figure.strengthtraining.traditional",
                value: "\(workoutViewModel.exercises.count)",
                label: "Exercises"
            )
            StatBadge(
                icon: "clock",
                value: "~\(estimatedMinutes)",
                label: "Minutes"
            )
            StatBadge(
                icon: "flame",
                value: muscleGroupDisplay,
                label: "Muscles"
            )
        }
        .padding(.vertical, 8)
    }

    private var startButton: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(GymScanTheme.surfaceLight)
            Button {
                workoutViewModel.startWorkout()
                path.append(ScanFlowStep.session)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("START WORKOUT")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(GymScanTheme.background)
                .background(GymScanTheme.accentGradient)
                .clipShape(Capsule())
            }
            .padding()
        }
        .background(GymScanTheme.surface)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(GymScanTheme.accent)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(GymScanTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(GymScanTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(GymScanTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
