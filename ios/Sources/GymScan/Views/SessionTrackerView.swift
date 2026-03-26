import SwiftUI

struct SessionTrackerView: View {
    @Bindable var workoutViewModel: WorkoutViewModel
    @Binding var path: NavigationPath
    var onComplete: (() -> Void)? = nil
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
                .background(GymScanTheme.background)

                // Rest timer overlay
                if workoutViewModel.isResting {
                    restTimerOverlay
                }

                bottomControls
            }
        }
        .background(GymScanTheme.background)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCompleteAlert = true
                } label: {
                    Text("End")
                        .foregroundStyle(GymScanTheme.destructive)
                }
            }
        }
        .alert("End Workout?", isPresented: $showCompleteAlert) {
            Button("End Workout", role: .destructive) {
                Task {
                    await workoutViewModel.completeWorkout(modelContext: modelContext)
                    if let onComplete {
                        onComplete()
                    } else {
                        path.removeLast(path.count)
                    }
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
                        .fill(GymScanTheme.surfaceLight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(GymScanTheme.accent)
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
                    .foregroundStyle(GymScanTheme.textSecondary)
                Spacer()
                Text("\(workoutViewModel.completedExerciseCount) completed")
                    .font(.caption)
                    .foregroundStyle(GymScanTheme.accentSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(GymScanTheme.background)
    }

    private var progressValue: Double {
        guard workoutViewModel.totalExercises > 0 else { return 0 }
        return Double(workoutViewModel.completedExerciseCount) / Double(workoutViewModel.totalExercises)
    }

    private func exerciseHeader(_ exercise: Exercise) -> some View {
        VStack(spacing: 8) {
            Image(systemName: exercise.equipmentType.iconName)
                .font(.system(size: 36))
                .foregroundStyle(GymScanTheme.accent)

            Text(exercise.name)
                .font(.title2.bold())
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Label("\(exercise.sets) sets", systemImage: "repeat")
                Label(exercise.reps, systemImage: "number")
                Label("\(exercise.restSeconds)s rest", systemImage: "timer")
            }
            .font(.subheadline)
            .foregroundStyle(GymScanTheme.textSecondary)

            Text(exercise.equipmentType.displayName)
                .font(.caption)
                .foregroundStyle(GymScanTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(GymScanTheme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func setsGrid(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets")
                .font(.headline)
                .foregroundStyle(GymScanTheme.textPrimary)

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
                                    .foregroundStyle(GymScanTheme.accentSecondary)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 32))
                                    .foregroundStyle(GymScanTheme.textSecondary)
                            }
                            Text("Set \(setIndex + 1)")
                                .font(.caption)
                                .foregroundStyle(GymScanTheme.textSecondary)
                            Text(exercise.reps)
                                .font(.caption2)
                                .foregroundStyle(GymScanTheme.textSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            workoutViewModel.isSetCompleted(exercise: exercise, setIndex: setIndex)
                                ? GymScanTheme.accentSecondary.opacity(0.1)
                                : GymScanTheme.surface
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
                .foregroundStyle(GymScanTheme.accent)

            Text(notes)
                .font(.subheadline)
                .foregroundStyle(GymScanTheme.textSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GymScanTheme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var restTimerOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 12) {
                Text("Rest")
                    .font(.headline)
                    .foregroundStyle(GymScanTheme.textSecondary)

                Text("\(workoutViewModel.restTimeRemaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(GymScanTheme.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: workoutViewModel.restTimeRemaining)

                Text("seconds")
                    .font(.subheadline)
                    .foregroundStyle(GymScanTheme.textSecondary)

                Button("Skip Rest") {
                    workoutViewModel.cancelRest()
                }
                .font(.subheadline.bold())
                .foregroundStyle(GymScanTheme.textSecondary)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(GymScanTheme.surface.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding()
            Spacer()
        }
        .background(GymScanTheme.background.opacity(0.7))
        .transition(.opacity)
    }

    private var bottomControls: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(GymScanTheme.surfaceLight)
            HStack(spacing: 16) {
                Button {
                    workoutViewModel.moveToPreviousExercise()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundStyle(GymScanTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(GymScanTheme.surfaceLight)
                        .clipShape(Circle())
                }
                .disabled(workoutViewModel.currentExerciseIndex == 0)

                Spacer()

                Button {
                    workoutViewModel.moveToNextExercise()
                } label: {
                    HStack(spacing: 6) {
                        Text("NEXT")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .foregroundStyle(GymScanTheme.background)
                    .background(GymScanTheme.accentGradient)
                    .clipShape(Capsule())
                }
                .disabled(workoutViewModel.currentExerciseIndex >= workoutViewModel.totalExercises - 1)
            }
            .padding()
        }
        .background(GymScanTheme.surface)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(GymScanTheme.accent)

            Text("Workout Complete!")
                .font(.title.bold())
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)

            Text("\(workoutViewModel.completedExerciseCount) of \(workoutViewModel.totalExercises) exercises completed")
                .font(.subheadline)
                .foregroundStyle(GymScanTheme.textSecondary)

            Button {
                Task {
                    await workoutViewModel.completeWorkout(modelContext: modelContext)
                    if let onComplete {
                        onComplete()
                    } else {
                        path.removeLast(path.count)
                    }
                }
            } label: {
                Text("DONE")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1.5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(GymScanTheme.background)
                    .background(GymScanTheme.accentGradient)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .background(GymScanTheme.background)
    }
}
