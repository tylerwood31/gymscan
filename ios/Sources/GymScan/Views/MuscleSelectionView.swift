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
            .background(GymScanTheme.background)

            generateButton
        }
        .background(GymScanTheme.background)
        .navigationTitle("Build Your Workout")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(workoutViewModel.error ?? "Something went wrong")
        }
    }

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TARGET MUSCLES")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(GymScanTheme.textSecondary)

            MuscleGroupPicker(selectedMuscles: $workoutViewModel.selectedMuscles)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DURATION")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(GymScanTheme.textSecondary)

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
                .overlay(GymScanTheme.surfaceLight)
            Button {
                path.append(ScanFlowStep.generating)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text("GENERATE WORKOUT")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(GymScanTheme.background)
                .background(
                    workoutViewModel.selectedMuscles.isEmpty
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(GymScanTheme.accentGradient)
                )
                .clipShape(Capsule())
            }
            .disabled(workoutViewModel.selectedMuscles.isEmpty)
            .padding()
        }
        .background(GymScanTheme.surface)
    }
}
