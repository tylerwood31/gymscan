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
                    Text("\(exercise.order + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.blue)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            Label(exercise.equipmentType.displayName, systemImage: exercise.equipmentType.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(exercise.sets) x \(exercise.reps)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)

                        Text("\(exercise.restSeconds)s rest")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)

                // Expanded details
                if isExpanded {
                    Divider()
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(icon: "repeat", label: "Sets", value: "\(exercise.sets)")
                        DetailRow(icon: "number", label: "Reps", value: exercise.reps)
                        DetailRow(icon: "timer", label: "Rest", value: "\(exercise.restSeconds) seconds")

                        if let notes = exercise.notes, !notes.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(14)
                }
            }
            .background(.regularMaterial)
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
                .foregroundStyle(.blue)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
        }
    }
}
