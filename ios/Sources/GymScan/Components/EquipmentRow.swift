import SwiftUI

struct EquipmentRow: View {
    let equipment: Equipment
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: equipment.type.iconName)
                .font(.title3)
                .foregroundStyle(equipment.isEnabled ? GymScanTheme.accent : GymScanTheme.textSecondary)
                .frame(width: 40, height: 40)
                .background(equipment.isEnabled ? GymScanTheme.accent.opacity(0.15) : GymScanTheme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(equipment.type.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(equipment.isEnabled ? GymScanTheme.textPrimary : GymScanTheme.textSecondary)

                HStack(spacing: 6) {
                    if let details = equipment.details, !details.isEmpty {
                        Text(details)
                            .font(.caption)
                            .foregroundStyle(GymScanTheme.textSecondary)
                    }

                    ConfidenceBadge(confidence: equipment.confidence)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { equipment.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(GymScanTheme.accent)
        }
        .padding(12)
        .background(GymScanTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(equipment.isEnabled ? 1.0 : 0.6)
    }
}

struct ConfidenceBadge: View {
    let confidence: ConfidenceLevel

    var color: Color {
        switch confidence {
        case .high: return GymScanTheme.accentSecondary
        case .medium: return GymScanTheme.accent
        case .low: return GymScanTheme.destructive
        }
    }

    var body: some View {
        Text(confidence.displayName)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
