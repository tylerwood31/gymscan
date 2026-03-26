import SwiftUI

struct MuscleSelectionView: View {
    @Bindable var scanViewModel: ScanViewModel
    @Bindable var workoutViewModel: WorkoutViewModel
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    muscleGroupSection
                    durationSection
                }
                .padding()
            }

            generateButton
        }
        .navigationTitle("Build Your Workout")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(workoutViewModel.error ?? "Something went wrong")
        }
    }

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Muscles")
                .font(.headline)

            MuscleGroupPicker(selectedMuscles: $workoutViewModel.selectedMuscles)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)

            Picker("Duration", selection: $workoutViewModel.selectedDuration) {
                ForEach(workoutViewModel.durations, id: \.self) { duration in
                    Text("\(duration) min").tag(duration)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var generateButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                guard let gymId = scanViewModel.currentGymId else { return }
                Task {
                    await workoutViewModel.generateWorkout(gymId: gymId, modelContext: modelContext)
                    if workoutViewModel.error != nil {
                        showError = true
                    } else {
                        path.append(ScanFlowStep.workout)
                    }
                }
            } label: {
                HStack {
                    if workoutViewModel.isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(workoutViewModel.isGenerating ? "Generating..." : "Generate Workout")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white)
                .background(workoutViewModel.selectedMuscles.isEmpty ? .gray : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(workoutViewModel.selectedMuscles.isEmpty || workoutViewModel.isGenerating)
            .padding()
        }
        .background(.regularMaterial)
    }
}
