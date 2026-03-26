import Foundation
import SwiftData

@Observable
@MainActor
final class WorkoutViewModel {
    var selectedMuscles: Set<MuscleGroup> = []
    var selectedDuration: Int = 30
    var isGenerating = false
    var currentWorkout: Workout?
    var exercises: [Exercise] = []
    var error: String?

    // Session tracker state
    var currentExerciseIndex: Int = 0
    var completedSets: [UUID: Set<Int>] = [:]
    var isResting = false
    var restTimeRemaining: Int = 0
    var isWorkoutActive = false
    var isWorkoutComplete = false

    private let apiClient = APIClient.shared
    private var restTimer: Timer?

    var currentExercise: Exercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var totalExercises: Int { exercises.count }

    var completedExerciseCount: Int {
        exercises.filter { exercise in
            let completed = completedSets[exercise.id] ?? []
            return completed.count >= exercise.sets
        }.count
    }

    var durations: [Int] { [15, 30, 45, 60] }

    func generateWorkout(gymId: String, modelContext: ModelContext) async {
        guard !selectedMuscles.isEmpty else {
            error = "Please select at least one muscle group"
            return
        }

        isGenerating = true
        error = nil

        do {
            let response = try await apiClient.generateWorkout(
                gymId: gymId,
                targetMuscles: selectedMuscles.map(\.rawValue),
                durationMinutes: selectedDuration
            )

            let exerciseList = response.exercises.map { item in
                Exercise(
                    name: item.name,
                    equipmentType: EquipmentType(rawValue: item.equipmentType) ?? .other,
                    sets: item.sets,
                    reps: item.reps,
                    restSeconds: item.restSeconds,
                    notes: item.notes,
                    order: item.order
                )
            }

            let workout = Workout(
                id: UUID(uuidString: response.workoutId) ?? UUID(),
                gymId: UUID(uuidString: gymId) ?? UUID(),
                targetMuscles: Array(selectedMuscles),
                durationMinutes: selectedDuration,
                exercises: exerciseList
            )

            modelContext.insert(workout)
            try modelContext.save()

            currentWorkout = workout
            exercises = exerciseList
            isGenerating = false
        } catch {
            self.error = error.localizedDescription
            isGenerating = false
        }
    }

    // MARK: - Session Tracker

    func startWorkout() {
        isWorkoutActive = true
        currentExerciseIndex = 0
        completedSets = [:]
        isWorkoutComplete = false
    }

    func completeSet(for exercise: Exercise, setIndex: Int) {
        var sets = completedSets[exercise.id] ?? []
        sets.insert(setIndex)
        completedSets[exercise.id] = sets

        if sets.count >= exercise.sets {
            // All sets done for this exercise
            if currentExerciseIndex < exercises.count - 1 {
                // Start rest before next exercise
                startRest(seconds: exercise.restSeconds)
            } else {
                // Last exercise done
                isWorkoutComplete = true
            }
        } else {
            // Rest between sets
            startRest(seconds: exercise.restSeconds)
        }
    }

    func isSetCompleted(exercise: Exercise, setIndex: Int) -> Bool {
        completedSets[exercise.id]?.contains(setIndex) ?? false
    }

    func completedSetCount(for exercise: Exercise) -> Int {
        completedSets[exercise.id]?.count ?? 0
    }

    func moveToNextExercise() {
        cancelRest()
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
        }
    }

    func moveToPreviousExercise() {
        cancelRest()
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
        }
    }

    func completeWorkout(modelContext: ModelContext) async {
        guard let workout = currentWorkout else { return }

        workout.completed = true
        workout.completedAt = Date()
        try? modelContext.save()

        let completedIndices = exercises.enumerated().compactMap { index, exercise in
            let sets = completedSets[exercise.id] ?? []
            return sets.count >= exercise.sets ? index : nil
        }

        do {
            try await apiClient.completeWorkout(
                workoutId: workout.id.uuidString,
                completedAt: Date(),
                exercisesCompleted: completedIndices
            )
        } catch {
            // Non-critical -- workout is saved locally
        }

        isWorkoutActive = false
    }

    // MARK: - Rest Timer

    private func startRest(seconds: Int) {
        isResting = true
        restTimeRemaining = seconds
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.cancelRest()
                }
            }
        }
    }

    func cancelRest() {
        isResting = false
        restTimeRemaining = 0
        restTimer?.invalidate()
        restTimer = nil
    }

    func reset() {
        selectedMuscles = []
        selectedDuration = 30
        isGenerating = false
        currentWorkout = nil
        exercises = []
        error = nil
        currentExerciseIndex = 0
        completedSets = [:]
        isResting = false
        restTimeRemaining = 0
        isWorkoutActive = false
        isWorkoutComplete = false
        restTimer?.invalidate()
        restTimer = nil
    }
}
