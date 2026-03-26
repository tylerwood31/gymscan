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

            startButton
        }
        .navigationTitle("Your Workout")
        .navigationBarTitleDisplayMode(.large)
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
                value: "\(workoutViewModel.currentWorkout?.durationMinutes ?? 30)",
                label: "Minutes"
            )
            StatBadge(
                icon: "flame",
                value: "\(workoutViewModel.currentWorkout?.targetMuscles.count ?? 0)",
                label: "Muscle Groups"
            )
        }
        .padding(.vertical, 8)
    }

    private var startButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                workoutViewModel.startWorkout()
                path.append(ScanFlowStep.session)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .background(.regularMaterial)
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
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
