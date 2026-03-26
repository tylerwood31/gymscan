import SwiftUI

struct MuscleGroupPicker: View {
    @Binding var selectedMuscles: Set<MuscleGroup>

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(MuscleGroup.allCases) { muscle in
                MuscleGroupPill(
                    muscle: muscle,
                    isSelected: selectedMuscles.contains(muscle)
                ) {
                    if muscle == .fullBody {
                        // Full body toggles off everything else
                        if selectedMuscles.contains(.fullBody) {
                            selectedMuscles.remove(.fullBody)
                        } else {
                            selectedMuscles = [.fullBody]
                        }
                    } else {
                        selectedMuscles.remove(.fullBody)
                        if selectedMuscles.contains(muscle) {
                            selectedMuscles.remove(muscle)
                        } else {
                            selectedMuscles.insert(muscle)
                        }
                    }
                }
            }
        }
    }
}

struct MuscleGroupPill: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: muscle.iconName)
                    .font(.body)
                Text(muscle.displayName)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(isSelected ? GymScanTheme.textPrimary : GymScanTheme.textSecondary)
            .background(isSelected ? GymScanTheme.accent.opacity(0.2) : GymScanTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? GymScanTheme.accent : GymScanTheme.surfaceLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
