import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Main row
                HStack(spacing: 12) {
                    Text("\(exercise.order)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(GymScanTheme.accent)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(GymScanTheme.textPrimary)

                        HStack(spacing: 8) {
                            Label(exercise.equipmentType.displayName, systemImage: exercise.equipmentType.iconName)
                                .font(.caption)
                                .foregroundStyle(GymScanTheme.textSecondary)
                        }

                        // Muscle tags
                        if !exercise.primaryMuscles.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                                    Text(muscle.displayName)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(muscle.tagColor)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(muscle.tagColor.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(exercise.sets) x \(exercise.reps)")
                            .font(.subheadline.bold())
                            .foregroundStyle(GymScanTheme.accent)

                        Text("\(exercise.restSeconds)s rest")
                            .font(.caption)
                            .foregroundStyle(GymScanTheme.textSecondary.opacity(0.7))
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(GymScanTheme.textSecondary)
                }
                .padding(14)

                // Expanded details
                if isExpanded {
                    Divider()
                        .overlay(GymScanTheme.surfaceLight)
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(icon: "repeat", label: "Sets", value: "\(exercise.sets)")
                        DetailRow(icon: "number", label: "Reps", value: exercise.reps)
                        DetailRow(icon: "timer", label: "Rest", value: "\(exercise.restSeconds) seconds")

                        if let notes = exercise.notes, !notes.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(GymScanTheme.accent)
                                    .font(.caption)
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(GymScanTheme.textSecondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(14)
                }
            }
            .background(GymScanTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(GymScanTheme.accent)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(GymScanTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(GymScanTheme.textPrimary)
        }
    }
}
