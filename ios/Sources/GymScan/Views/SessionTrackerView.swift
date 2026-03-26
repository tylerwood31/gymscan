import SwiftUI

struct SessionTrackerView: View {
    @Bindable var workoutViewModel: WorkoutViewModel
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @State private var showCompleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress header
            progressHeader

            if workoutViewModel.isWorkoutComplete {
                completionView
            } else if let exercise = workoutViewModel.currentExercise {
                ScrollView {
                    VStack(spacing: 20) {
                        exerciseHeader(exercise)
                        setsGrid(exercise)
                        if let notes = exercise.notes, !notes.isEmpty {
                            notesSection(notes)
                        }
                    }
                    .padding()
                }

                // Rest timer overlay
                if workoutViewModel.isResting {
                    restTimerOverlay
                }

                bottomControls
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCompleteAlert = true
                } label: {
                    Text("End")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("End Workout?", isPresented: $showCompleteAlert) {
            Button("End Workout", role: .destructive) {
                Task {
                    await workoutViewModel.completeWorkout(modelContext: modelContext)
                    path.removeLast(path.count)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(.green)
                        .frame(
                            width: geometry.size.width * progressValue,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: progressValue)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Exercise \(workoutViewModel.currentExerciseIndex + 1) of \(workoutViewModel.totalExercises)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(workoutViewModel.completedExerciseCount) completed")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var progressValue: Double {
        guard workoutViewModel.totalExercises > 0 else { return 0 }
        return Double(workoutViewModel.completedExerciseCount) / Double(workoutViewModel.totalExercises)
    }

    private func exerciseHeader(_ exercise: Exercise) -> some View {
        VStack(spacing: 8) {
            Image(systemName: exercise.equipmentType.iconName)
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text(exercise.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Label("\(exercise.sets) sets", systemImage: "repeat")
                Label(exercise.reps, systemImage: "number")
                Label("\(exercise.restSeconds)s rest", systemImage: "timer")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(exercise.equipmentType.displayName)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func setsGrid(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: min(exercise.sets, 4)), spacing: 12) {
                ForEach(0..<exercise.sets, id: \.self) { setIndex in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            workoutViewModel.completeSet(for: exercise, setIndex: setIndex)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            if workoutViewModel.isSetCompleted(exercise: exercise, setIndex: setIndex) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.gray)
                            }
                            Text("Set \(setIndex + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(exercise.reps)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            workoutViewModel.isSetCompleted(exercise: exercise, setIndex: setIndex)
                                ? Color.green.opacity(0.1)
                                : Color.gray.opacity(0.05)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(workoutViewModel.isSetCompleted(exercise: exercise, setIndex: setIndex))
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Coaching Notes", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var restTimerOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 12) {
                Text("Rest")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(workoutViewModel.restTimeRemaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: workoutViewModel.restTimeRemaining)

                Text("seconds")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Skip Rest") {
                    workoutViewModel.cancelRest()
                }
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding()
            Spacer()
        }
        .background(.black.opacity(0.3))
        .transition(.opacity)
    }

    private var bottomControls: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                Button {
                    workoutViewModel.moveToPreviousExercise()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .frame(width: 44, height: 44)
                        .background(.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(workoutViewModel.currentExerciseIndex == 0)

                Spacer()

                Button {
                    workoutViewModel.moveToNextExercise()
                } label: {
                    HStack {
                        Text("Next Exercise")
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.right")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(.blue)
                    .clipShape(Capsule())
                }
                .disabled(workoutViewModel.currentExerciseIndex >= workoutViewModel.totalExercises - 1)
            }
            .padding()
        }
        .background(.regularMaterial)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("Workout Complete!")
                .font(.title.bold())

            Text("\(workoutViewModel.completedExerciseCount) of \(workoutViewModel.totalExercises) exercises completed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await workoutViewModel.completeWorkout(modelContext: modelContext)
                    path.removeLast(path.count)
                }
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .foregroundStyle(.white)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}
